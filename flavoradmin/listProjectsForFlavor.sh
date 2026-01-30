#!/usr/bin/env bash

. $(dirname $0)/../common.sh

need_admin
prereq

flavor=$1

projects=$(openstack flavor show $flavor -f json -c access_project_ids 2> /dev/null | jq -r .access_project_ids[])

if [[ -n "$projects" ]]; then
  echo "Project with access to the $flavor flavor"
  for project in $projects; do
    project_name=$(openstack project show -f value -c name $project)
    num_servers=$(openstack server list -f value --project $project --flavor $flavor | grep -v SHELVED | wc -l)
    echo -e "$project_name - $num_servers active servers"
  done
else
  echo "The flavor does not exist, or no projects has access to it"
fi
