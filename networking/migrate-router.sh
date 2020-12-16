#!/bin/bash
set -e

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <router-ID> <new-neutronnet-hostname>"
  exit 1
fi

router=$1
newHost=$2

old=$(openstack network agent list --router $router -f value -c ID -c Host)
oldID=$(echo $old | awk '{ print $1 }')
oldHost=$(echo $old | awk '{ print $2 }')

newID=$(openstack network agent list --agent-type l3 --host $newHost \
    -f value -c ID)

if ! echo "$newID" | egrep \
  '^[a-f0-9]{8}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{12}$'; then
  echo "Could not determine an ID for a L3-agent on $newHost"
  exit 2
elif [[ $oldHost == $newHost ]]; then
  echo "Router is already on $newHost. No need to move"
  exit 3
else
  echo "Moving the router $router from $oldHost ($oldID) to $newHost ($newID)"
  openstack network agent remove router $oldID $router --l3
  echo "  - Removed the old router"
  openstack network agent add router $newID $router --l3
  echo "  - Created the new router"
  exit 0
fi

