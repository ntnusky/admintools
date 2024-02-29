#!/bin/bash

# To bulk create DNS records in shiftleader, this is a thing:
# /opt/shiftleader/manage.py dns_register --name foo.bar.baz --ipv4 1.2.3.4
# With that, personell with sufficient amounts of bash foo should be able to bulk create records

# This net should exist in the MISC-project at all times
net='ttm4135'

if [[ $# -lt 3 ]]; then
  echo "This script assignes users to projects; and if the project"
  echo "does not exist it will create them. The csv file should list"
  echo "the user->project mapings one on each line, with this format:"
  echo 
  echo "<projectname>,<username-A>,<username-B>..."
  echo
  echo "All projects will get a pre-allocated FIP in ntnu-global, tagged"
  echo "with course code and project name for easier listing"
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
  $cmd ./createProject.sh -n $projectName -d "$desc" -u $u -q TTM4135 \
                      -e $date

  if [[ $exists -eq 0 ]]; then
    projectID=$(openstack project show $projectName -f value -c id) 2> /dev/null
    $cmd ../networking/add_project_to_globalnet.sh $projectID

    $cmd neutron rbac-create --target-tenant $projectID \
      --action access_as_shared --type network $net

    $cmd openstack floating ip create --tag ttm4135 --tag $projectName --project $projectName ntnu-global
  fi

  echo " -- DONE adding $usernames to $projectName"

  echo "Safe to Ctrl+C the next 5 seconds. $(date +%y%m%d-%H%M%S)"
  sleep 5
  echo "Not safe to Ctrl+C anymore"
done < "$inputFile"
