#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

function usage() {
  echo "This script lets you migrate off all instances from a certain"
  echo "compute-host. This is useful when a compute-node should be taken out of"
  echo "production-use. For instance to perform maintainance.".
  echo
  echo "The nova-compute service for the compute-node is disabled to prevent"
  echo "new VM's appearing on it"
  echo
  echo "Required paramters:"
  echo " -s <source-compute-server>: Which compute-node to migrate from"
  echo " -r <reason>: A description on why this host is emptied."
  echo
  echo "Optional paramters:"
  echo " -e: Do not disable the source host"
  echo " -h: Print this help text"
  echo " -d <destination-compute-server>: Which compute-node to migrate to."
  echo " -f: Fast migration. Do not wait for an instance to finish before"
  echo "     starting the next one"
  exit 1
}

if [ $# -eq 0 ]; then
  usage
fi

while getopts es:r:hd:f option
do
  case "${option}" in
    d) DESTINATION="${OPTARG}";;
    e) ENABLE=1;;
    f) FAST=1;;
    h) usage;;
    r) REASON="${OPTARG}";;
    s) SOURCE="${OPTARG}";;
    *) usage;; 
  esac
done

if [[ -z $SOURCE ]] || [[ -z $REASON ]]; then
  usage
fi

if [[ -z $FAST ]]; then
  w='--wait'
else
  w=''
fi

sourceStatus=$(openstack compute service list --service nova-compute \
    --host $SOURCE -f value -c Status)
if [[ -z $sourceStatus ]]; then
  echo "Could not find the source compute-host."
  exit 2
fi

sourceState=$(openstack compute service list --service nova-compute \
    --host $SOURCE -f value -c State)
if [[ $sourceState == 'down' ]]; then
  echo "Cannot migrate from $SOURCE as it seems to be down"
  exit 1
fi

if [[ -z $DESTINATION ]]; then
  d=''
else
  destinationStatus=$(openstack compute service list --service nova-compute \
      --host $DESTINATION -f value -c Status)
  if [[ -z $destinationStatus ]]; then
    echo "Could not find the destination compute-host."
    exit 2
  fi
  destinationState=$(openstack compute service list --service nova-compute \
      --host $DESTINATION -f value -c State)
  if [[ -z $destinationStatus ]]; then
    echo "Cannot migrate to $DESTINATION as it is disabled." 
    echo "To enable the host:"
    echo " - openstack compute service set --enabled $DESTINATION"
    exit 2
  fi

  d="--host ${DESTINATION}"
fi

if [[ $sourceStatus == 'enabled' ]] && [[ -z $ENABLE ]]; then
  echo Disabling the nova-compute service of $SOURCE
  openstack compute service set --disable --disable-reason "$REASON" \
    $SOURCE nova-compute
fi

echo "Start to live-migrate the active instances:"
openstack server list --host $SOURCE --all --long -c ID -c Name -c 'Image Name' \
    -c 'Flavor Name' --status ACTIVE 

for id in $(openstack server list --long --all --host $SOURCE \
  --status ACTIVE -f value -c ID); do 
  echo Live-migrating $id
  openstack server migrate --os-compute-api-version 2.30 --live $id $w $d
done

echo "cold-migrate the shutoff instances:"
openstack server list --host $SOURCE --all --long -c ID -c Name -c 'Image Name' \
    -c 'Flavor Name' --status SHUTOFF 

for id in $(openstack server list --long --all --host $SOURCE \
  --status SHUTOFF -f value -c ID); do 
  echo Migrating $id
  openstack server migrate --os-compute-api-version 2.56 $id $w $d
done

if [[ -z $FAST ]]; then
  echo "Marking migrations completed"
  for id in $(openstack server list --all --vm-state resized -f value -c ID); do 
    openstack server resize confirm $id; 
  done
else
  echo "Do not forget to mark migrations completed when they are done"
  echo -n 'for id in $(openstack server list --all --vm-state resized -f value '
  echo '-c ID); do openstack server resize confirm $id; done'
fi
