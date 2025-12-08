#!/usr/bin/env bash

if [[ $# -eq 1 ]] && [[ $1 =~ ^delete$ ]]; then
  DELETE=1
elif [[ $# -eq 0 ]]; then
  DELETE=0
else
  echo "Usage: $0 [delete]"
  exit 1
fi

for flavor in $(openstack flavor list --private -f value -c Name --sort-column Name); do
  echo "Projects with access to $flavor that no longer exist"
  for project in $(openstack flavor show $flavor -f json -c access_project_ids | jq -r .access_project_ids[]); do
    if ! openstack project show $project &> /dev/null; then
      echo -n $project
      if [ $DELETE ]; then
        nova flavor-access-remove $flavor $project > /dev/null 2>&1
        echo " - Access removed!"
      fi
    fi
  done
  echo
done
