#!/bin/bash

if [[ $# -lt 3 ]]; then
  echo "This script assignes users to projects; and if the project"
  echo "does not exist it will create them. The csv file should list"
  echo "the user->project mapings one on each line, with this format:"
  echo
  echo "<username>,<userDomain>,<projectname>"
  echo
  echo "Usage: $0 <input-csv> <project_descriptions> <expiry-date (dd.mm.yyyy)> [service] [run]"
  exit 1
fi

inputFile=$1
desc=$2
date=$3

shift;shift;shift

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
  username=$(echo $line | cut -d ',' -f 1)
  userdomain=$(echo $line | cut -d ',' -f 2)
  projectName=$(echo $line | cut -d ',' -f 3)

  openstack project show $projectName &> /dev/null
  if [[ $? -eq 0 ]]; then
    echo "A project with the name \"$projectName\" already exist." 
  else
    echo "Creating project $projectName - $(date +%y%m%d-%H%M%S)"
    $cmd openstack project create --description \
        "$desc" \
        --domain $userdomain $projectName
    $cmd openstack project set --property expiry=$date $projectName

    echo " -- Changing quotas"
    $cmd openstack quota set $projectName --cores 3 --instances 3 --ram 6144 
    $cmd openstack quota set $projectName --volume-type Fast --volumes 0
    $cmd openstack quota set $projectName --volume-type VeryFast --volumes 0
    $cmd openstack quota set $projectName --volume-type Unlimited --volumes 0
  fi

  noRoles=$(openstack role assignment list --project $projectName --user $username \
      --user-domain=$userdomain -f csv  | wc -l)
  if [[ $noRoles -le 1 ]]; then
    echo " -- Adding the user $username to $projectName"
    $cmd openstack role add --project $projectName --user $username \
        --user-domain=$userdomain _member_
    $cmd openstack role add --project $projectName --user $username \
        --user-domain=$userdomain heat_stack_owner
  else
    echo " -- User already present in the project"
  fi

  if [[ $serviceUser -eq 1 ]]; then
    serviceUserName="${projectName}_service"
    echo " -- Checking if service-user is present"
    noRoles=$(openstack role list --project $projectName --user \
        $serviceUserName -f csv  | wc -l)
    if [[ $noRoles -le 1 ]]; then
      echo " -- Adding the user $serviceUserName to $projectName"
      password=$(pwgen -s -1 12)
      $cmd echo $serviceUserName $password >> passwords.txt
      $cmd openstack user create --domain default --password $password --email \
          service@skyhigh.hig.no --description "Service user for $projectName" \
          $serviceUserName
      $cmd openstack role add --project $projectName --user $serviceUserName \
          _member_
      $cmd openstack role add --project $projectName --user $serviceUserName \
          heat_stack_owner
    else
      echo " -- User already present in the project"
    fi
  fi

  echo " -- DONE adding $username to $projectName"

  echo "Safe to Ctrl+C the next 5 seconds. $(date +%y%m%d-%H%M%S)"
  sleep 5
  echo "Not safe to Ctrl+C anymore"
done < "$inputFile"
