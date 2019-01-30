#!/bin/bash

# This function deletes all users from a project, optionally except for a single
# user. The function can take three arguments:
#  1 - A project ID or Name
#  2 - (Optional) A file-name to write the user ID's deleted to.
function delete_users {
  echo "Removing users and groups from project"

  local project=$1
  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
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
      openstack role remove --project $projectID --user $user $role $i
    fi

    if [[ ! -z $group ]]; then
      if [[ ! -z $statusfile ]]; then
        echo "GROUP:${group},${role}" >> $statusfile
      fi
      openstack role remove --project $projectID --group $group $role $i
    fi
  done  

  echo "Finished removing users and groups from the project"
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

  # Delete all LBaaS Healtmonitors
  echo "Deleting all LBaaS Healthmonitors"
  hms=$(neutron lbaas-healthmonitor-list -f value -c id)
  for hm in $hms; do
    neutron lbaas-healthmonitor-delete $hm
  done

  # Delete all LBaaS Pools
  echo "Deleting all LBaaS Pools"
  pools=$(neutron lbaas-pool-list -f value -c id)
  for pool in $pools; do
    neutron lbaas-pool-delete $pool
  done

  # Delete all LBaaS Listeners
  echo "Deleting all LBaaS Listeners"
  listeners=$(neutron lbaas-listener-list -f value -c id)
  for listener in $listeners; do
    neutron lbaas-listener-delete $listener
  done

  # Delete all LBaaS Loadbalancers
  echo "Deleting all LBaaS loadbalancers"
  lbs=$(neutron lbaas-loadbalancer-list -f value -c id)
  for lb in $lbs; do
    neutron lbaas-loadbalancer-delete $lb
  done

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

  # Delete all firewalls, policies and rules
  echo "Deleting firewalls"
  fws=$(neutron firewall-list -f value -c id)
  for fw in $fws; do
    neutron firewall-delete $fw
  done

  echo "Deleting firewall policies"
  policies=$(neutron firewall-policy-list -f value -c id)
  for policy in $policies; do
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
