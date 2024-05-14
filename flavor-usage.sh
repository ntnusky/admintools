#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

# Script which collects and prints which projects are using a certain flavor.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <flavor>"
  exit 1
fi

declare -A projects

for server in $(openstack server list --all --flavor $1 -f value -c ID); do
  project=$(openstack server show $server -c project_id -f value)

  if [ ${projects[$project]+_} ]; then 
    ((projects[$project]++))
  else 
    projects[$project]=1
  fi
done

for project in "${!projects[@]}"; do 
  echo $project,$(openstack project show "$project" -f value -c name),${projects[$project]}
done
