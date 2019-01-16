#!/bin/bash

function add_user {
  local project=$1
  local user=$2

  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)
  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)

  if [ $(openstack role assignment list --project $projectid --user $userid \
        --role _member_ | wc -l) -eq 1 ]; then
    echo Adding $user to $project as _member_
    openstack role add --project $projectid --user $userid _member_
  fi

  if [ $(openstack role assignment list --project $projectid --user $userid \
        --role heat_stack_owner | wc -l) -eq 1 ]; then
    echo Adding $user to $project as heat_stack_owner
    openstack role add --project $projectid --user $userid heat_stack_owner
  fi
}

function remove_user {
  local project=$1
  local user=$2

  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)
  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)

  unset even
  for roleinherit in $(openstack role assignment list --project $projectid \
        --user $userid -f value -c Role -c Inherited); do
    if [[ -z $even ]]; then
      role=$roleinherit
      even=1
      continue
    else
      inherit=$roleinherit
      unset even
    fi

    if [[ $inherit == "True" ]]; then
      extra="--inherited"
    else
      extra=""
    fi

    echo "Removing the role $role for the user $user from the project $project"
    openstack role remove --project $projectid --user $userid $role $extra
  done
}

function delete_users {
  echo "Removing users from project"                                           
  local project=$1

  if [[ ! -z $2 ]]; then
    local userid=$(openstack user show $2 -f value -c id 2> /dev/null) || \
    local userid=$(openstack user show $2 -f value -c id --domain=NTNU 2> /dev/null)
    echo " - Except for the user $2"
  else
    local userid="Ingen"
  fi

  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)

  local roles=$(openstack role assignment list --project $projectid -f value \
    -c Role -c User | grep -v $userid | awk '{ print $2 "," $1 }')      
                                                                               
  for userANDrole in $roles; do                                                
    userAndRole=$(echo $userANDrole | sed s/,/\ /)
    openstack role remove --project $projectID --user $userAndRole
  done  
  echo "Finished removing users from project"
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
    openstack stack delete $stackID --yes --wait
  done
}

function clean_nova {
  echo "Deleting virtual machines"
  vms=$(openstack server list -f value -c ID)
  for vm in $vms; do
    openstack server delete $vm
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
    interfaces=$(openstack router show -f value -c interfaces_info $router | \
      jq ".[] | .subnet_id" | tr -d '"')
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
  subnets=$(openstack subnet list -f value -c ID)
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

  # Delete all firewalls, policies and rules
  echo "Deleting firewalls"
  fws=$(neutron firewall-list -f value -c id)
  for fw in $fws; do
    neutron firewall-delete $fw
  done

  echo "Deleting firewall policies"
  policies=$(neutron firewall-policy-list -f value -c id)
  for policy in $policis; do
    neutron firewall-policy-delete $policy
  done

  echo "Deleting firewall rules"
  rules=$(neutron firewall-rule-list -f value -c id)
  for rule in $rules; do
    neutron firewall-rule-delete $rule
  done
}

function clean_swift {
  echo "Cleaning swift"
  for container in $(openstack container list -f value); do
    openstack container delete $container -r
  done
  echo "Finished cleaning swift"
}
