#!/bin/bash

if [[ $# -lt 3 ]]; then
  echo "This script assignes users to projects; and if the project"
  echo "does not exist it will create them. The csv file should list"
  echo "the user->project mapings one on each line, with this format:"
  echo 
  echo "<projectname>,<username1>[,<username2>[,<usernameN>]]"
  echo
  echo -n "Usage: $0 <input-csv> <project_descriptions> "
  echo "<expiry-date (dd.mm.yyyy)> <quota-name> <parent_project> [service] [run]"
  exit 1
fi

if [[ $# -lt 5 ]]; then
  ./createProject.sh -l
  exit 1
fi

inputFile=$1
desc=$2
date=$3
quota=$4
parent=$5

shift;shift;shift;shift;shift

if [[ $1 == 'service' ]]; then
  serviceUser=1
  shift
else
  serviceUser=0
fi

if [[ $1 != 'run' ]]; then
  echo "This is a dry-run. Append "run" to your commandline if "
  echo "  you want to create these projects."
  cmd="echo ..."
else
  cmd=""
fi

while IFS='' read -r line || [[ -n "$line" ]]; do
  projectName=$(echo $line | cut -d ',' -f 1)
  usernames=$(echo $line | cut -d ',' -f 2-)

  u=${usernames//\,/\ -u\ }

  if [[ $serviceUser -eq 1 ]]; then
    $cmd ./createProject.sh -n $projectName -d "$desc" -u $u \
      -p $parent -q $quota -e $date -s
  else
    $cmd ./createProject.sh -n $projectName -d "$desc" -u $u \
      -p $parent -q $quota -e $date
  fi

  echo "Safe to Ctrl+C the next 5 seconds. $(date +%y%m%d-%H%M%S)"
  sleep 5
  echo "Not safe to Ctrl+C anymore"
done < "$inputFile"
