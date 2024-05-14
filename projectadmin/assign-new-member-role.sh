#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

# This scripts iterates through all role-assignments of the _member_ role, and
# if there is no corresponding assignment of the member role the latter i
# created.
#
# This script is the first step of our migration to the new personas in keystone
# RBAC.

openstack implied role list

echo "Retrieving role IDs"
oldRole=$(openstack role show _member_ -f value -c id)
newRole=$(openstack role show member -f value -c id)

echo "Retrieving role assignments"
oldRoles=$(openstack role assignment list -f json --role $oldRole)
newRoles=$(openstack role assignment list -f json --role $newRole)

declare -A newAssignments
for assignment in $(echo $newRoles | jq -rc '.[]'); do
  project=$(echo $assignment | jq -r '.["Project"]')
  user=$(echo $assignment | jq -r '.["User"]')
  group=$(echo $assignment | jq -r '.["Group"]')
  inherited=$(echo $assignment | jq -r '.["Inherited"]')

  # Print an error if neither group nor user is set
  if [ -z "$group" ] && [ -z "$user" ]; then
    echo "Cannot figure out user/group for the following element:"
    echo $assignment
    continue
  elif [ -z "$group" ]; then
    key="${project}-${user}-${inherited}"
  else
    key="${project}-${group}-${inherited}"
  fi
  newAssignments[$key]=1
done

for assignment in $(echo $oldRoles | jq -rc '.[]'); do
  project=$(echo $assignment | jq -r '.["Project"]')
  user=$(echo $assignment | jq -r '.["User"]')
  group=$(echo $assignment | jq -r '.["Group"]')
  inherited=$(echo $assignment | jq -r '.["Inherited"]')

  # Print an error if neither group nor user is set
  if [ -z "$group" ] && [ -z "$user" ]; then
    echo "Cannot figure out user/group for the following element:"
    echo $assignment
    continue
  elif [ -z "$group" ]; then
    key="${project}-${user}-${inherited}"
    selector="--user ${user}"
  else
    key="${project}-${group}-${inherited}"
    selector="--group ${group}"
  fi

  if [[ $inherited == 'true' ]]; then
    i='--inherited'
  else
    i=''
  fi

  if [[ -z ${newAssignments[$key]} ]]; then
    echo "Adding ${selector} to the project ${project}"
    openstack role add --project ${project} ${selector} ${i} member
  fi
done
