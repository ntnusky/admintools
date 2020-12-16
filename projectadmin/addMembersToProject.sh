#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script will add given user to given project"
  echo "with all releveant roles"
  echo
  echo "Usage: $0 <project-id|project-name> <user1,user2,user3...>"
  exit 1
fi

project=${1}
users=${2}
roles="_member_ heat_stack_owner load-balancer_member creator"

openstack project show $project &> /dev/null
if [[ $? -eq 0 ]]; then
  echo "Project exists..."
  echo "Adding users..."
  IFS=','
  for user in $users; do
    IFS=' '
    for role in $roles; do
      echo "Adding $user as $role in $project"
      openstack role add --project $project --user $user --user-domain=NTNU $role
    done
  done
  openstack role assignment list --project $project --names
else
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi
