#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script will set the default quota for STUDENT_projects"
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
  openstack quota set --cores 4 $project
  openstack quota set --instances 4 $project
  openstack quota set --ram 8192 $project
  openstack quota set --gigabytes 20 $project
  openstack quota set --volumes 2 $project

  openstack quota show $project
else
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi
