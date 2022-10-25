#!/bin/bash
set -e

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <source-l3-agent> [<destination-l3-agent>]"
  exit 1
fi

sourceHost=$1
sourceID=$(openstack network agent list --agent-type l3 --host $sourceHost \
                -f value -c ID)

if ! echo "$sourceID" | egrep \
  '^[a-f0-9]{8}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{4}\-[a-f0-9]{12}$'; then
  echo "Could not determine an ID for a L3-agent on $sourceHost"
  exit 2
fi

if [[ -z $2 ]]; then
  routers=( $( \
    openstack network agent list --agent-type l3 -f value -c Host -c Alive | \
    grep -v XXX | grep -v $sourceHost | awk '{ print $1 }') )
else
  routers=( $2 )
fi

for id in $(openstack router list --agent $sourceID -f value -c ID); do
  echo moving the router $id to agent ${routers[0]}
  ./migrate-router.sh $id ${routers[0]} & 
  routers=("${routers[@]: -1}" "${routers[@]:0:${#routers[@]}-1}")
done

wait

exit 0
