#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script will add given group to given project"
  echo "with all releveant roles"
  echo
  echo "Usage: $0 <project-id|project-name> <group1,group2,group3...>"
  exit 1
fi

project=${1}
groups=${2}
roles="member"

openstack project show $project &> /dev/null
if [[ $? -eq 0 ]]; then
  echo "Project exists..."
  echo "Adding groups..."
  IFS=','
  for group in $groups; do
    IFS=' '
    for role in $roles; do
      echo "Adding $group as $role in $project"
      openstack role add --project $project --group $group --group-domain=NTNU $role
    done
  done
  openstack role assignment list --project $project --names
else
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi
