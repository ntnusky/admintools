#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

while getopts p: option; do
  case "${option}" in 
    p) projectPrefix=${OPTARG} ;;
  esac
done

if [[ -z $projectPrefix ]]; then
  echo "A script used to summarize the quotas for a range of openstack-projects"
  echo "with a common prefix"
  echo
  echo "Usage: $0 -p <project_prefix>"
  exit $EXIT_OK
fi

declare -A aggregate
aggregate['projects']=0

for project in $(openstack project list -f value -c Name | \
      egrep "^${projectPrefix}"); do
  echo "Prosjekt: $project"

  quota=$(openstack quota show $project -f json)

  aggregate['projects']=$((${aggregate['projects']} + 1))

  for key in cores floating-ips gigabytes instances snapshots ram volumes; do
    if [[ -z ${aggregate[$key]} ]]; then
      aggregate[$key]=$(echo $quota | jq ".[\"$key\"]")
    else
      aggregate[$key]=$((${aggregate[$key]} + $(echo $quota | jq ".[\"$key\"]")))
    fi
  done
done

echo
echo "Aggregated quotas for the ${aggregate['projects']} projects with a name staring with ${projectPrefix}:"
for key in "${!aggregate[@]}"; do 
  echo -n "${key}: " 

  if [[ " ram " =~ " ${key} " ]]; then
    echo "$(( ${aggregate[$key]} / 1024 )) GB" 
  elif [[ " gigabytes " =~ " ${key} " ]]; then
    echo "${aggregate[$key]} GB" 
  else
    echo "${aggregate[$key]}" 
  fi
done



