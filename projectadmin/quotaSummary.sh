#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

while getopts adp: option; do
  case "${option}" in 
    a) all=1 ;;
    d) detail=1 ;;
    p) projectPrefix=${OPTARG} ;;
  esac
done

if [[ -z $projectPrefix ]] && [[ -z $all ]]; then
  echo "Either a prefix or the all (-a) flag is needed."
  echo "A script used to summarize the quotas for a range of openstack-projects"
  echo "with a common prefix"
  echo
  echo "Usage: $0 [-p <project_prefix>] [-d] [-a]"
  echo
  echo "Parameters:"
  echo " -a: Summarize all projects (mutually exclusive with -p)"
  echo " -d: Print details about all matching projects"
  echo " -p <project_prefix>: Defines the start of the project-name for"
  echo "                      projects to create a summary for. (mutually"
  echo "                      exclusive with -a)"
  exit $EXIT_OK
fi

if [[ ! -z $projectPrefix ]] && [[ ! -z $all ]]; then
  echo "Cannot both specify a prefix and request all projects"
  exit 1
fi
  

declare -A aggregate
aggregate['projects']=0

if [[ ! -z $all ]]; then
  projects=$(openstack project list --domain NTNU -f value -c Name | sort)
elif [[ ! -z $projectPrefix ]]; then
  projects=$(openstack project list --domain NTNU -f value -c Name | \
      egrep "^${projectPrefix}" | sort)
fi

for project in $projects; do
  if [[ -z $detail ]]; then
    echo -n .
  else
    echo "Project: $project"
    echo -n " - "
  fi

  quota=$(openstack quota show $project -f json)

  aggregate['projects']=$((${aggregate['projects']} + 1))

  for key in cores floating-ips gigabytes instances snapshots ram volumes; do
    if [[ ! -z $detail ]]; then
      echo -n "${key}:$(echo $quota | jq ".[\"$key\"]") "
    fi

    if [[ -z ${aggregate[$key]} ]]; then
      aggregate[$key]=$(echo $quota | jq ".[\"$key\"]")
    else
      aggregate[$key]=$((${aggregate[$key]} + $(echo $quota | jq ".[\"$key\"]")))
    fi
  done
  if [[ ! -z $detail ]]; then
    echo
  fi
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



