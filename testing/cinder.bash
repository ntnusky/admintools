#!/bin/bash
MYDIR="$(dirname "$(realpath "$0")")"
. $MYDIR/testlib.bash

echo="echo [CINDER]"

openstack image list &> /dev/null
if [[ $? -ne 0 ]]; then
  $echo "You are not logged in to an openstack cloud."
  exit 1
fi

while [[ ! -z $1 ]]; do
  if [[ $1 == 'create' ]]; then
    create='x'
  fi
  
  if [[ $1 == 'delete' ]]; then
    delete='x'
  fi
  shift
done

if [[ ! -z $create ]]; then
  $echo "Creating a volume"
  openstack volume create openstackTest.volume --size 2 || \
      fail "$echo" "Could not create volume"

  attempts=0
  while ! openstack volume show openstackTest.volume | grep available &> /dev/null; do
    ((attempts++))
    [[ $attempts -le 20 ]] || fail "$echo" "The volume did not become available"
    $echo "Waiting for the volume to be available"
    sleep 1
  done

  $echo "Attaching volume to VM"
  openstack server add volume openstackTest openstackTest.volume || \
      fail "$echo" "Could not attach volume to VM"
  
  sleep 5

  attempts=0
  fip=$(cat .openstackTesting.floatinIP.txt)
  while !  ssh -o StrictHostKeyChecking=no ubuntu@$fip \
        sudo fdisk -l /dev/vdb 2> /dev/null | grep "bytes," &> /dev/null; do
    ((attempts++))
    [[ $attempts -le 20 ]] || fail "$echo" "The volume did not appear in the VM"
    $echo "Waiting for the volume to be attached"
    sleep 5
  done
  $echo "Test was successful"
fi

if [[ ! -z $delete ]]; then
  $echo "Detatching the volume"
  openstack server remove volume openstackTest openstackTest.volume
  $echo "Deleting the volume"
  openstack volume delete openstackTest.volume || \
      fail "$echo" "Could not delete volume"
fi

exit 0
