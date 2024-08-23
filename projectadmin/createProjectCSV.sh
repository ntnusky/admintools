#!/bin/bash

if [[ $# -lt 3 ]]; then
  echo "This script assignes users to projects; and if the project"
  echo "does not exist it will create them. The csv file should list"
  echo "the user->project mapings one on each line, with this format:"
  echo 
  echo "<projectname>,<username1>[,<username2>[,<usernameN>]]"
  echo
  echo -n "Usage: $0 <input-csv> <project_descriptions> "
  echo "<expiry-date (dd.mm.yyyy)> <quota-name> [service] [run]"
  exit 1
fi

if [[ $# -lt 4 ]]; then
  ./createProject.sh -l
  exit 1
fi

inputFile=$1
desc=$2
date=$3
quota=$4

declare -a projectsNotCreated=()

shift;shift;shift;shift

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

#./verifyUsernames.sh $inputFile > /dev/null
#USER_OK=$?
#if [ $USER_OK -eq 1 ]; then
#  echo "There are invalid usernames in the CSV file. Exiting"
#  exit 1
#fi

while IFS='' read -r line || [[ -n "$line" ]]; do

  projectName=$(echo $line | cut -d ',' -f 1)
  usernames=$(echo $line | cut -d ',' -f 2-)

  if ! ./verifyUsernames.sh <(grep $projectName $inputFile) > /dev/null; then
    echo "Invalid username in $projectName"
    projectsNotCreated+=("${projectName}")
    continue
  fi

  u=${usernames//\,/\ -u\ }

  if [[ $serviceUser -eq 1 ]]; then
    $cmd ./createProject.sh -n $projectName -d "$desc" -u $u -q $quota -e $date -s
  else
    $cmd ./createProject.sh -n $projectName -d "$desc" -u $u -q $quota -e $date
  fi

  echo "Safe to Ctrl+C the next 5 seconds. $(date +%y%m%d-%H%M%S)"
  sleep 5
  echo "Not safe to Ctrl+C anymore"
done < "$inputFile"

if (( ${#projectsNotCreated[@]} )); then
  echo "The following projects were not created due to invalid username(s) in member list:"
  for p in "${projectsNotCreated[@]}"; do
    echo $p
  done
fi
