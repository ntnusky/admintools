#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "This script creates a STUDENT_ project, which are projects we "
  echo "hand out to students. It also sets appropriate quotas for this project"
  echo
  echo "Usage: $0 <username>"
  exit 1
fi

username=$1
projectName="STUDENT_${username}"

if [[ $(date +%m) -le 6 ]]; then
  expiry="30.06.$(date +%Y)"
else
  expiry="31.12.$(date +%Y)"
fi

openstack project show $projectName &> /dev/null
if [[ $? -eq 0 ]]; then
  echo "A project with the name \"$projectName\" already exist." 
else
  echo "Creating project $projectName"
  openstack project create --description \
      "Private playground for the STUDENT $username" \
      --domain NTNU $projectName
  openstack project set --property expiry=$date $projectName

  echo " -- Changing quotas"
  openstack quota set $projectName --cores 4 --instances 4 --ram 8192 \
                                    --gigabytes 20 --volumes 2
  openstack quota set $projectName --volume-type Fast --volumes 0
  openstack quota set $projectName --volume-type VeryFast --volumes 0
  openstack quota set $projectName --volume-type Unlimited --volumes 0
fi

noRoles=$(openstack role assignment list --project $projectName --user $username \
    --user-domain=NTNU -f csv  | wc -l)
if [[ $noRoles -le 1 ]]; then
  echo " -- Adding the user $username to $projectName"
  openstack role add --project $projectName --user $username \
      --user-domain=NTNU _member_
  openstack role add --project $projectName --user $username \
      --user-domain=NTNU heat_stack_owner
else
  echo " -- User already present in the project"
fi
