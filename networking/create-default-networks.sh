#!/bin/bash

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <project-name|project-id> <internal|global>"
  exit 1
fi

if [[ $OS_PROJECT_NAME -ne 'admin' ]]; then
  echo "You must be authenticated as admin to run this script"
  exit 2
fi

projectid=$(openstack project show -f value -c id $1 2> /dev/null)
if [[ $? -ne 0 ]]; then
  echo "Could not find project: $1"
  exit 3
fi

if [[ $2 == 'internal' ]]; then
  extnet='ntnu-internal'
  v4='192.168.13.0/24'
elif [[ $2 == 'global' ]]; then
  extnet='ntnu-global'
  v4='192.168.14.0/24'
else 
  echo "You must select type internal or global. Not $2"
  exit 4
fi

project=$1

router=$(openstack router list -f value -c Name --project $project | \
  grep -e "^Router-${extnet}\$" )
if [[ -z ${router} ]] ; then
  echo "The router \"Router-$extnet\" dont exist. Creating it now:"
  openstack router create "Router-$extnet" \
    --external-gateway $extnet --project $project
else
  echo "The router \"Router-$extnet\" already exits."
fi
routerID=$(openstack router list -f value -c Name -c ID --project $project | \
    grep -e " Router-${extnet}\$" | cut -f 1 -d ' ')

network=$(openstack network list -f value -c Name --project $project | \
  grep -e "^Network-${extnet}\$" )
if [[ -z ${network} ]] ; then
  echo "The network \"Network-$extnet\" dont exist. Creating it now:"
  openstack network create "Network-$extnet" --project $project
else
  echo "The network \"Network-$extnet\" already exits."
fi

networkID=$(openstack network list -f value -c Name -c ID --project $project | \
    grep -e " Network-${extnet}\$" | cut -f 1 -d ' ')
subnet4=$(openstack subnet list --network $networkID -f value -c ID --ip-version 4)
subnet6=$(openstack subnet list --network $networkID -f value -c ID --ip-version 6)

if [[ -z $subnet4 ]]; then
  echo "Missing the v4-subnet. Creating it"
  openstack subnet create --project $project --subnet-range $v4 \
      --network $networkID "Subnet-$extnet-v4"
  subnet4=$(openstack subnet list --network $networkID -f value -c ID --ip-version 4)
else
  echo "The v4-subnet exists"
fi

if ! openstack router show $routerID | grep -q $subnet4; then
  echo "Adding the v4-subnet to the router"
  openstack router add subnet $routerID $subnet4
else
  echo "The v4-subnet is attached to the router"
fi

if [[ -z $subnet6 ]]; then
  echo "Missing the v6-subnet. Creating it"
  openstack subnet create --project $project --ip-version 6 \
      --ipv6-ra-mode slaac --ipv6-address-mode slaac \
      --subnet-pool selfservice-ipv6 --network $networkID "Subnet-$extnet-v6"
  subnet6=$(openstack subnet list --network $networkID -f value -c ID --ip-version 6)
else
  echo "The v6-subnet exists"
fi

if ! openstack router show $routerID | grep -q $subnet6; then
  echo "Adding the v6-subnet to the router"
  openstack router add subnet $routerID $subnet6
else
  echo "The v6-subnet is attached to the router"
fi
