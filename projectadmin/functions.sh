#!/bin/bash

# This function deletes all users from a project, optionally except for a single
# user. The function can take three arguments:
#  1 - A project ID or Name
#  2 - (Optional) A file-name to write the user ID's deleted to.
function delete_users {
  echo "Removing users and groups from project"

  local project=$1
  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=heat 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)
  local statusfile=$2

  for roleA in $(openstack role assignment list --project $projectid -f json \
      | jq -c ".[]"); do
    local role=$(echo $roleA | jq -r '.["Role"]')
    local user=$(echo $roleA | jq -r '.["User"]')
    local group=$(echo $roleA | jq -r '.["Group"]')
    local inherited=$(echo $roleA | jq -r '.["Inherited"]')

    if [[ $inherited == "true" ]]; then
      i=" --inherited"
    else
      i=""
    fi

    if [[ ! -z $user ]]; then
      if [[ ! -z $statusfile ]]; then
        echo "USER:${user},${role}" >> $statusfile
      fi
      openstack role remove --project $projectid --user $user $role $i
    fi

    if [[ ! -z $group ]]; then
      if [[ ! -z $statusfile ]]; then
        echo "GROUP:${group},${role}" >> $statusfile
      fi
      openstack role remove --project $projectid --group $group $role $i
    fi
  done  

  echo "Finished removing users and groups from the project"
}

function delete_user {
  local user=$1

  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)
  local domain=$(openstack user show $userid -f value -c domain_id 2> /dev/null)
  local domain_name=$(openstack domain show $domain -f value -c name 2> /dev/null)

  if [[ -z $(openstack role assignment list --user $userid) ]]; then
    if [[ $domain_name == 'default' ]] || [[ $domain_name == 'heat' ]]; then
      echo "Deleting the user $user as its not in projects anymore." 
      openstack user delete $userid
    else
      echo "Cannot delete the user, as it is not in the openstack user database."
      echo "LDAP users needs to be deleted in the LDAP catalog, not here."
    fi
  else
    echo "The user is still member of some projects, and is thus not deleted."
  fi
}

# This function adds a users to a project.
# The function can take two arguments:
#  1 - A project ID or Name
#  2 - A user ID or Name 
function add_user {
  local project=$1
  local user=$2

  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)
  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)

  noRoles=$(openstack role assignment list --project $projectid --user $userid \
     -f csv  | wc -l)
  if [[ $noRoles -le 1 ]]; then
    echo "Adding $user to the project"
    openstack role add --project $projectid --user $userid member
    return 0
  else
    echo "$user is already present in the project"
    return 1
  fi
}

# This function removes a users from a project.
# The function can take two arguments:
#  1 - A project ID or Name
#  2 - A user ID or Name 
function remove_user {
  echo "Removing user from project"

  local project=$1
  local user=$2

  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)
  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)

  for roleA in $(openstack role assignment list --project $projectid \
      --user $userid -f json | jq -c ".[]"); do
    local role=$(echo $roleA | jq -r '.["Role"]')
    local user=$(echo $roleA | jq -r '.["User"]')
    local group=$(echo $roleA | jq -r '.["Group"]')
    local inherited=$(echo $roleA | jq -r '.["Inherited"]')

    if [[ $inherited == "true" ]]; then
      i=" --inherited"
    else
      i=""
    fi

    if [[ ! -z $user ]]; then
      if [[ ! -z $statusfile ]]; then
        echo "USER:${user},${role}" >> $statusfile
      fi
      openstack role remove --project $projectid --user $user $role $i
    fi

    if [[ ! -z $group ]]; then
      if [[ ! -z $statusfile ]]; then
        echo "GROUP:${group},${role}" >> $statusfile
      fi
      openstack role remove --project $projectid --group $group $role $i
    fi
  done  

  echo "Finished removing user from the project"
}

function set_project {
  local projectName=$1
  local projectID=$2

  echo "Setting $projectName as the current project"
  export OS_PROJECT_ID=$projectID
  export OS_PROJECT_NAME=$projectName
}

function clean_heat {
  echo "Deleting heat stacks"
  stackIDs=$(openstack stack list -f value -c ID)
  for stackID in $stackIDs; do
    openstack stack abandon --output-file /dev/null $stackID
  done
}

function clean_nova {
  echo "Deleting virtual machines"
  vms=$(openstack server list -f value -c ID)
  for vm in $vms; do
    openstack server unlock $vm
    openstack server delete --wait $vm
  done
}

function disable_nova {
  local project=$1
  local statusfile=$2

  echo "Turning off virtual machines"
  vms=$(openstack server list --project $project --status ACTIVE -f value -c ID)
  for vm in $vms; do
    openstack server stop $vm
    echo "VM:${vm}" >> $statusfile
  done
}

function clean_glance {
  echo "Deleting private images"
  images=$(openstack image list --private -f value -c ID)
  for image in $images; do
    openstack image set --unprotected $image
    openstack image delete $image
  done
}

function clean_cinder {
  # Delete all volume snapshots
  echo "Deleting snapshots"
  snapshots=$(openstack volume snapshot list -f value -c ID)
  for snap in $snapshots; do
    openstack volume snapshot delete $snap
  done

  # Delete all cinder volumes
  echo "Deleting volumes"
  volumes=$(openstack volume list -f value -c ID)
  for volume in $volumes; do
    openstack volume delete $volume
  done
}

function clean_neutron {
  local projectID=$1

  # Delete all floating IP's
  echo "Deleting floating IP's"
  ips=$(openstack floating ip list -f value -c ID)
  for ip in $ips; do
    openstack floating ip delete $ip
  done

  # Deleting all router->network links
  echo "Deleting all router->network links"
  routers=$(openstack router list -f value -c ID)
  for router in $routers; do
    interfaces=$(openstack router show -f json -c interfaces_info $router | \
      jq '.[] | .[] | .subnet_id' | tr -d '"')
    for interface in $interfaces; do
      openstack router remove subnet $router $interface
    done
  done

  # Delete all ports
  echo "Deleting ports"
  ports=$(openstack port list -f value -c id)
  for port in $ports; do
    openstack port delete $port
  done

  # Delete all routers
  echo "Deleting all routers"
  routers=$(openstack router list -f value -c ID)
  for router in $routers; do
    openstack router delete $router
  done

  # Delete all subnets
  echo "Deleting subnets"
  subnets=$(openstack subnet list --project $projectID -f value -c ID)
  for subnet in $subnets; do
    openstack subnet delete $subnet
  done

  # Delete all networks
  echo "Deleting networks"
  networks=$(openstack network list --long -f value -c ID -c Project | \
    grep $projectID | cut -d' ' -f1)
  for network in $networks; do
    openstack network delete $network
  done
}

function clean_neutron_rbac {
  local projectID=$1

  echo "Deleting RBAC rules"
  for rbac in $(openstack network rbac list --target-project $projectID -f value -c ID); do
    openstack network rbac delete $rbac
  done
}

function clean_swift {
  echo "Cleaning swift"
  for container in $(openstack container list -f value); do
    openstack container delete $container -r
  done
  echo "Finished cleaning swift"
}

function clean_octavia {
  echo "Cleaning octavia"
  for lb in $(openstack loadbalancer list -f value -c id); do
    openstack loadbalancer delete --cascade $lb
  done
  echo "Finished cleaning octavia"
}

function clean_magnum {
  echo "Deleting magnum clusters"
  for cluster in $(openstack coe cluster list -f value -c uuid); do
    openstack coe cluster delete $cluster
  done
  while [[ $(openstack coe cluster list -f value) != '' ]]; do
    echo "Watiing for clusters to be deleted"
    sleep 5
  done
  echo "Cleaning private cluster templates"
  # The modern openstackclient is not able to list the public/private information...
  for template in $(magnum cluster-template-list --fields public | grep False | grep -oE '[a-z0-9]{8}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{4}-[a-z0-9]{12}'); do
    openstack coe cluster template delete $template
  done
}


function create_serviceuser {
  local projectName=$1
  local extra=$2
  local serviceUserName="${projectName}_service"

  echo "Checking if service-user is present"
  local noRoles=$(openstack role assignment list --project $projectName --user \
      $serviceUserName -f csv  | wc -l)
  if [[ $noRoles -le 1 ]]; then
    echo "Adding the user $serviceUserName to $projectName"

    local password=$(pwgen -s -1 12)
    local file="$serviceUserName.password.txt"

    echo "Username: $serviceUserName" > $file
    echo "Password: $password" >> $file
    echo "The password ($password) is written to the file $file"

    openstack user create --domain default --password $password --email \
        serviceusers@localhost --description "Service user for $projectName" \
        $serviceUserName
    openstack role add --project $projectName --user $serviceUserName \
        member

    if [[ $extra == '--inherited' ]]; then
      openstack role add --project $projectName --user $serviceUserName \
          member --inherited
    fi

    # If the current user is not a part of the project, add it temporarly.
    result=0
    add_user $projectName $OS_USERNAME || result=1

    # Switch to the new project, and upload the service-user credentials to
    # swift.
    oldtenant=$OS_PROJECT_ID
    newtenant=$(openstack project show $projectName -f value -c id)
    export OS_PROJECT_ID=$newtenant
    openstack container create servicepassword &> /dev/null
    openstack object create servicepassword $file &> /dev/null

    # Delete the password-file after it is uploaded to swift.
    rm $file

    # Switch back to the admin-project
    export OS_PROJECT_ID=$oldtenant

    # If the current user was added temporarly, remove it again
    if [[ $result -eq 0 ]]; then
      remove_user $projectName $OS_USERNAME
    fi
  else
    echo "The project already have a service-user"
  fi
}
