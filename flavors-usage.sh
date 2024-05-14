#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

# Script which collecting projects using flavors matching a supplied egrep
# pattern.

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <egrep-pattern>"
  exit 1
fi

declare -A projects
declare -A instances

for flavor in $(openstack flavor list \
    --all -f value -c Name --sort-column Name | egrep $1); do
  echo "Collecting projects using $flavor"
  flavorID=$(openstack flavor show $flavor -f value -c id)
  for projectInstances in $(./flavor-usage.sh $flavorID); do
    data=(${projectInstances//,/ })
    projectID=${data[0]}
    projectName=${data[1]}
    instances=${data[2]}
    echo $projectInstances

    if [ ${instances[$projectID]+_} ]; then 
      ((instances[$projectID]++))
    else 
      instances[$projectID]=1
      projects[$projectID]=$projectName
    fi
  done
done

echo
echo "Final summary:"
for project in "${!projects[@]}"; do 
  echo "${projects[$project]} ($project): ${instances[$project]}"
done
