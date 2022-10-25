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

declare -A quota
quota['VM']=0
quota['CPU']=0
quota['RAM']=0

declare -A usage
usage['projects']=0
usage['VM']=0
usage['CPU']=0
usage['RAM']=0

if [[ ! -z $all ]]; then
  projects=$(openstack project list --domain NTNU -f value -c Name | sort)
elif [[ ! -z $projectPrefix ]]; then
  projects=$(openstack project list --domain NTNU -f value -c Name | \
      egrep "^${projectPrefix}" | sort)
fi

for project in $projects; do
  . <(openstack limits show --project $project --absolute -f value | tr ' ' '=')

  if [[ -z $detail ]]; then
    echo -n .
  else
    echo "Project: $project"
    echo " - Instances: $totalInstancesUsed / $maxTotalInstances"
    echo " - VCPUs:     $totalCoresUsed / $maxTotalCores"
    echo " - RAM (GB):  $(($totalRAMUsed/1024)) / $(($maxTotalRAMSize/1024))"
  fi

  usage['projects']=$((${usage['projects']} + 1))

  quota['VM']=$((${quota['VM']}+$maxTotalInstances))
  usage['VM']=$((${usage['VM']}+$totalInstancesUsed))
  quota['CPU']=$((${quota['CPU']}+$maxTotalCores))
  usage['CPU']=$((${usage['CPU']}+$totalCoresUsed))
  quota['RAM']=$((${quota['RAM']}+$(($maxTotalRAMSize/1024))))
  usage['RAM']=$((${usage['RAM']}+$(($totalRAMUsed/1024))))

  if [[ ! -z $detail ]]; then
    echo
  fi
done

echo
echo "Aggregated quotas for the ${usage['projects']} projects with a name staring with ${projectPrefix}:"
for key in "${!quota[@]}"; do 
  echo -n "${key}: " 

  if [[ "${key}" =~ (RAM|Gigabytes) ]]; then
    echo "${usage[$key]} GB / ${quota[$key]} GB" 
  else
    echo "${usage[$key]} / ${quota[$key]}" 
  fi
done



