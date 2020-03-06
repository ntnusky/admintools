#!/bin/bash

# This script will reset the state of a given instance,
# if it is stuck in either powering-on or powering-off

if [ $# -ne 1 ]; then
  echo "Usage: $0 <vm-id>"
  exit 1
fi

vm=$1
state=$(openstack server show "$vm" -f value -c 'OS-EXT-STS:task_state')

if [[ $state =~ powering-on ]]; then
  echo "$vm is stuck in $state"
  echo "Resetting state..."
  nova reset-state $vm
  nova reset-state --active $vm
  echo "Stopping VM $vm ..."
  openstack server stop $vm
  echo "Waiting for VM to be shut down"
  while [[ $(openstack server show "$vm" -f value -c 'OS-EXT-STS:task_state') =~ 'powering-on' ]]; do
    echo "Still waiting..."
    sleep 2
  done
  echo "Stuck state fixed. Powering-on VM $vm"
  openstack server start $vm
  echo "Job done :-)"
elif [[ $state =~ powering-off ]]; then
  echo "$vm is stuck in $state"
  nova reset-state --active $vm
  openstack server stop $vm
  echo "Waiting for VM to get rid of the stuck status.."
  while [[ $(openstack server show "$vm" -f value -c 'OS-EXT-STS:task_state') =~ 'powering-off' ]]; do
    echo "Still waiting..."
    sleep 2
  done
  echo "Job done :-)"
else
  echo "$state is not a problem!"
fi
