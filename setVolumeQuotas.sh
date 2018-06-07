#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script will set quota for volume type Fast and VeryFast to 0"
  echo "for both volumes and snapshots"
  echo "for the given project id/name."
  echo
  echo "Usage: $0 <project-id|project-name>"
  exit 1
fi

project=${1}

openstack project show $project &> /dev/null
if [[ $? -eq 0 ]]; then
  echo "Project exists..."
  echo "Setting quotas..."
  openstack quota set --volume-type Fast --volumes 0 $project
  openstack quota set --volume-type Fast --snapshots 0 $project
  openstack quota set --volume-type VeryFast --volumes 0 $project
  openstack quota set --volume-type VeryFast --snapshots 0 $project

  openstack quota show $project
else
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi
