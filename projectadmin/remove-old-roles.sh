#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

role_to_be_removed="_member_ creator heat_stack_owner heat_stack_user load-balancer_member"
role_to_be_deleted="_member_ creator heat_stack_owner heat_stack_user"

for role in $role_to_be_removed; do
  a=$(openstack role assignment list --role $role -f json)
  for assignment in $(echo $a | jq -rc '.[]'); do
    project=$(echo $assignment | jq -r '.["Project"]')
    user=$(echo $assignment | jq -r '.["User"]')
    group=$(echo $assignment | jq -r '.["Group"]')
    inherited=$(echo $assignment | jq -r '.["Inherited"]')

    if [[ $inherited == 'true' ]]; then
      i='--inherited'
    else
      i=''
    fi

    # Print an error if neither group nor user is set
    if [ -z "$group" ] && [ -z "$user" ]; then
      echo "Cannot figure out user/group for the following element:"
      echo $assignment
      continue
    elif [ -z "$group" ]; then
      echo "Removing user ${user}'s role $role from $project"
      openstack role remove --project $project --user $user $i $role
    else
      echo "Removing group ${group}'s role $role from $project"
      openstack role remove --project $project --group $user $i $role
    fi
  done
done

for role in $role_to_be_deleted; do
  if openstack role show $role &> /dev/null; then
    echo "Deleting the role $role"
    openstack role delete $role
  fi
done
