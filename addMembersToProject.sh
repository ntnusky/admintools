#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script will add given user to given project"
  echo "fwith _member_ and heat_stack_owner roles"
  echo
  echo "Usage: $0 <project-id|project-name> <user1,user2,user3...>"
  exit 1
fi

project=${1}
users=${2}

openstack project show $project &> /dev/null
if [[ $? -eq 0 ]]; then
  echo "Project exists..."
  echo "Adding users..."
  IFS=','
  for user in $users; do
    echo "Adding $user as _member_ in $project"
    openstack role add --project $project --user $user --user-domain=NTNU _member_
    echo "Adding $user as heat_stack_owner in $project"
    openstack role add --project $project --user $user --user-domain=NTNU heat_stack_owner
  done
  openstack role assignment list --project $project --names
else
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi
