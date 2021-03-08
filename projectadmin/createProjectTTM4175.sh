#!/bin/bash

netName='ttm4115-net'
subnetName='ttm4115-subnet'
routerName='ttm4115-router'

subnetRange='192.168.0.0/24'
extNet='ntnu-internal'

if [[ $# -lt 3 ]]; then
  echo "This script assignes users to projects; and if the project"
  echo "does not exist it will create them. The csv file should list"
  echo "the user->project mapings one on each line, with this format:"
  echo 
  echo "<projectname>,<username-A>,<username-B>..."
  echo
  echo "All projects will get a network, subnet and a router pre-created"
  echo "ready for use"
  echo
  echo "Usage: $0 <input-csv> <project_descriptions> <expiry-date (dd.mm.yyyy)> [run]"
  exit 1
fi

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

inputFile=$1
desc=$2
date=$3

shift;shift;shift

if [[ $1 != 'run' ]]; then
  echo "This is a dry-run. Append "run" to your commandline if "
  echo "  you want to create these projects."
  cmd="echo ..."
else
  cmd=""
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
  projectName=$(echo $line | cut -d ',' -f 1)
  usernames=$(echo $line | cut -d ',' -f '2-')

  openstack project show $projectName &> /dev/null
  if [[ $? -eq 0 ]]; then
    exists=1
  else
    exists=0
  fi

  u=${usernames//\,/\ -u\ }
  $cmd ./createProject.sh -n $projectName -d "$desc" -u $u -t TTM4175 \
                      -e $date

  if [[ $exists -eq 0 ]]; then
    projectID=$(openstack project show $projectName -f value -c id) 2> /dev/null

    $cmd openstack network create --project $projectID $netName
    $cmd openstack subnet create --project $projectID --subnet-range $subnetRange --network $netName $subnetName
    $cmd openstack router create --project $projectID $routerName
    $cmd openstack router set --external-gateway $extNet $routerName
    $cmd openstack router add subnet $routerName $subnetName
  fi

  echo " -- DONE adding $username to $projectName"

  echo "Safe to Ctrl+C the next 5 seconds. $(date +%y%m%d-%H%M%S)"
  sleep 5
  echo "Not safe to Ctrl+C anymore"
done < "$inputFile"
