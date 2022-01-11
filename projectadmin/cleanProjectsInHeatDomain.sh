#!/bin/bash

set -e

. $(dirname "$0")/../common.sh
. $(dirname "$0")/functions.sh

prereq
need_admin

OSCMD=$(command -v openstack)

# Med brukere
#heat_projects='fecf962480704510b5e2a35e51e5f308-dceacf03-9291-4cfa-b0c5-c04f9d2'
# Uten brukere
#heat_projects='338bae0126f948d4b41bf20e879cc8ed-6ffadd3f-c8e8-426b-b0e2-6a810d8'

# Default loop
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
