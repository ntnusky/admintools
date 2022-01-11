#!/bin/bash

set -e

. $(dirname "$0")/../common.sh
. $(dirname "$0")/functions.sh

prereq
need_admin

OSCMD=$(command -v openstack)

heat_projects=$($OSCMD project list --domain heat -f value -c Name)
for project in $heat_projects; do
  owner=$(echo $project | cut -d '-' -f1)
  ret=0
  $OSCMD project show $owner &> /dev/null || ret=$?
  if [ $ret -ne 0 ]; then
    echo "$project belongs to a deleted project"
    users=$($OSCMD role assignment list -f value -c User --project $project | sort | uniq)
    if [ ! -z "$users" ]; then
      echo "Deleting users from project..."
      delete_users $project
      echo "Deleting users..."
      for u in $users; do
        delete_user $u
      done
    fi
    echo "Deleting project"
    $OSCMD project delete $project
  else
    echo "$project belongs to a project that still exists: $owner"
  fi
done
