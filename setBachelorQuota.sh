#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script will set the default quota for bachelor projects"
  echo "According to https://www.ntnu.no/wiki/display/skyhigh/Quotas"
  echo
  echo "Usage: $0 <project-id|project-name>"
  exit 1
fi

project=${1}

openstack project show $project &> /dev/null
if [[ $? -eq 0 ]]; then
  echo "Project exists..."
  echo "Setting quotas..."
  openstack quota set --cores 16 $project
  openstack quota set --instances 16 $project
  openstack quota set --ram 32768 $project
  openstack quota set --gigabytes 40 $project
  openstack quota set --volumes 16 $project

  openstack quota show $project
else
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi
