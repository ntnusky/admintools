#!/bin/bash

set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

short=""

while getopts ati:c:r:p: option; do
  case "${option}" in 
    a) apply=1 ;;
    t) testing=1 ;;
    i) short+="-i ${OPTARG}"; long+="--instances ${OPTARG} " ;;
    c) short+="-c ${OPTARG}"; long+="--cores ${OPTARG} " ;;
    r) short+="-r ${OPTARG}"; long+="--ram $((${OPTARG}*1024))" ;;
    p) projectPrefix=${OPTARG} ;;
  esac
done

if [[ -z $projectPrefix || ( -z $apply && -z $testing ) || ( ! -z $apply && ! -z $testing ) ]]; then
  echo "Usage: $0 -p <project> -a|-t [-c <cores>] [-r <GB RAM>]"
  echo
  echo "Parameters:"
  echo " -p <project_prefix>: Which projects to change quota for"
  echo " -a Apply the new quotas if possible"
  echo " -t Test if the neq quotas can be set"
  echo " -i <N>: Number of instances"
  echo " -c <N>: Number of CPUs"
  echo " -r <N>: GBs of RAM"
  exit $EXIT_MISSINGARGS
fi

projects=$(openstack project list --domain NTNU -f value -c Name | \
    egrep "^${projectPrefix}" | sort)

for project in $projects; do
  if [[ $testing -eq 1 ]]; then
    set +e
    output=$(./quotaCheck.sh -p $project $short)
    if [[ $? -ne 0 ]]; then
      echo -n "Impossible quota! "
      echo "$output"
    fi
    set -e
  elif [[ $apply -eq 1 ]]; then
    echo Setting quota for $project
    openstack quota set $long $project || true
  fi
done
