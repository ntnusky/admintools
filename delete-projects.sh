#!/bin/bash

if [ $# -lt 1 ]; then
  echo "Usage: $0 <group_grep>"
  exit 1
fi

if [ $OS_PROJECT_NAME != "admin" ]; then
  echo "Needs to be authenticated as admin!"
  exit 2
fi

adminID=$(openstack user show admin | grep " id " | awk '{ print $4}')
adminProjectID=$OS_PROJECT_ID
userID=$(openstack user show $OS_USERNAME --domain=NTNU | grep " id " | \
  awk '{ print $4}')

for projectID in $(openstack project list | grep "$1" | awk '{ print $2 }'); do
  projectName=$(openstack project show $projectID | grep name | awk '{ print $4 }')
  if [[ -z $2 || $2 != "--yes-i-know-what-i-am-about-to-do" ]]; then
    echo "Your pattern matched the project $projectName"
    dryRun=1
  else
    dryRun=0
    echo "Deleting project: $projectName ($projectID)"

    # Add current user to project
    echo "Verifies that the current user actually is a member of the project"
    isMember=$(openstack role assignment list --project $projectName --user $userID \
      --names | grep -c _member_)
    if [ $isMember -lt 1 ]; then
      echo "Needs to add $OS_USERNAME as a _member_"
      openstack role add --project $projectName --user $userID _member_
    fi
  
    isHeatOw=$(openstack role assignment list --project $projectName --user $userID \
      --names | grep -c heat_stack_owner)
    if [ $isHeatOw -lt 1 ]; then
      echo "Needs to add $OS_USERNAME as heat_stack_owner"
      openstack role add --project $projectName --user $userID heat_stack_owner
    fi
  
    # Delete all other users in project
    echo "Removing users from project"
    roles=$(openstack role assignment list --project $projectID -f value \
      -c Role -c User | grep -v $userID | awk '{ print $2 "," $1 }')
  
    for userANDrole in $roles; do
      userAndRole=$(echo $userANDrole | sed s/,/\ /)
      openstack role remove --project $projectID --user $userAndRole
    done
  
    # Switch to project
    echo "Switching to project $projectName"
    export OS_PROJECT_ID=$projectID
    export OS_PROJECT_NAME=$projectName
  
    # Delete heat stacks
    echo "Deleting heat stacks"
    stackIDs=$(openstack stack list | \
      egrep [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for stackID in $stackIDs; do
      openstack stack delete $stackID --yes --wait
    done
  
    # Delete all vm's
    echo "Deleting virtual machines"
    vms=$(openstack server list | \
      egrep [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for vm in $vms; do
      openstack server delete $vm
    done

    # Delete all volume snapshots
    echo "Deleting snapshots"
    snapshots=$(openstack snapshot list -f value -c ID)
    for snap in $snapshots; do
      openstack snapshot delete $snap
    done
  
    # Delete all cinder volumes
    echo "Deleting volumes"
    volumes=$(openstack volume list | \
      egrep [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for volume in $volumes; do
      openstack volume delete $volume
    done

    # Delete all private images
    echo "Deleting private images"
    images=$(openstack image list --private -f value -c ID)
    for image in $images; do
      openstack image set --unprotected $image
      openstack image delete $image
    done

    # Delete all floating IP's
    echo "Deleting floating IP's"
    ips=$(openstack floating ip list | \
      egrep [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for ip in $ips; do
      openstack floating ip delete $ip
    done

    # Deleting all router->network links
    echo "Deleting all router->network links"
    routers=$(neutron router-list | \
      egrep \ [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for router in $routers; do
      interfaces=$(neutron router-port-list $router -f value)
      IFS=$'\n'
      for interface in $interfaces; do
        if [[ $interface =~ ^([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}).*\"subnet_id\":\ \"([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}) ]]; then
          neutron router-interface-delete $router ${BASH_REMATCH[2]}
        fi
      done
      unset IFS
    done

    # Delete all ports
    echo "Deleting ports"
    ports=$(neutron port-list | \
      egrep \ [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for port in $ports; do
      neutron port-delete $port
    done

    # Delete all routers
    echo "Deleting all routers"
    routers=$(openstack router list | \
      egrep \[0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
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


    # Delete all security groups
    echo "Deleting security groups"
    groups=$(openstack security group list | \
      egrep [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o)
    for group in $groups; do
      openstack security group delete $group
    done
  
    # Switch back to admin project
    echo "Switching back to the admin tenant"
    export OS_PROJECT_ID=$adminProjectID
    export OS_PROJECT_NAME=admin
 
    # Delete default security group from project. This MUST be done with the admin tenant context
    echo "Deleting default security group from project $projectName"
    default_sg_id=$(openstack security group list -f value | grep $projectID | cut -d' ' -f1)
    openstack security group delete $default_sg_id
 
    # Remove admin user from project
    echo "Removing $OS_USERNAME from $projectName"
    openstack role remove --project $projectName --user $userID _member_
    openstack role remove --project $projectName --user $userID heat_stack_owner
  
    # Delete project
    echo "Deleting the project $projectName"
    openstack project delete $projectID
  fi
done

if [[ $dryRun -eq 1 ]]; then
  echo "To actually delete these projects, run the command:"
  echo "$0 \"$1\" --yes-i-know-what-i-am-about-to-do"
fi
