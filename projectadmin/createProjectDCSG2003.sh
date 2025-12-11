#!/bin/bash

parent="DCSG2003_Workers"
net="dcsg2003"

if [[ $# -lt 3 ]]; then
  echo "This script assignes users to projects; and if the project"
  echo "does not exist it will create them. The csv file should list"
  echo "the user->project mapings one on each line, with this format:"
  echo 
  echo "Projects wil be created as a child of the project $parent, and the "
  echo "network $net will be shared with it."
  echo
  echo "<projectname>,<username-A>,<username-B>..."
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

  if [[ -z $usernames ]]; then
    usr=""
  else
    u=${usernames//\,/\ -u\ }
    usr="-u ${u}"
  fi

  $cmd ./createProject.sh -n $projectName -d "$desc" $usr -q DCSG2003 \
                      -p $parent -e $date -s

  if [[ $exists -eq 0 ]]; then
    projectID=$(openstack project show $projectName -f value -c id) 2> /dev/null
    $cmd neutron rbac-create --target-tenant $projectID \
        --action access_as_shared --type network $net
  fi
  echo " -- DONE adding $username to $projectName"

  echo "Safe to Ctrl+C the next 5 seconds. $(date +%y%m%d-%H%M%S)"
  sleep 5
  echo "Not safe to Ctrl+C anymore"
done < "$inputFile"
