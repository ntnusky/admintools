#!/bin/bash
MYDIR="$(dirname "$(realpath "$0")")"
. $MYDIR/testlib.bash

echo="echo [NOVA]"

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
  $echo "Creating a VM"
  openstack server create --image openstackTest.image --flavor m1.tiny \
      --key-name openstackTest --network testOpenstack.net \
      --security-group openstackTest.group openstackTest

  attempts=0
  while [[ -z $gotip ]]; do
    ip=$(openstack server show openstackTest | grep addresses | cut -d '=' -f 2 | \
        cut -d ' ' -f 1)
    if [[ $ip =~ [0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3} ]]; then
      $echo Got an IP
      gotip="yes"
    else
      $echo "Waiting for the VM to get an IP."
      ((attempts++))
      [[ $attempts -le 40 ]] || fail "$echo" "The VM did not get an IP" 
      sleep 1
    fi
  done

  $echo "Allocating a floating IP"
  fip=$(openstack floating ip create ntnu-internal | grep floating_ip_address \
      | awk '{ print $4 }')
  $echo "Got the IP $fip"

  $echo "Associating floating IP with server"
  openstack server add floating ip openstackTest $fip || fail "$echo" "Could not associate IP"

  echo $fip > .openstackTesting.floatinIP.txt

  attempts=0
  while [[ -z $pinged ]]; do
    $echo "Trying to ping the new server"
    if ping $fip -c 1 -W 2 &> /dev/null ; then
      pinged="yes"
      $echo "Ping successful."
    else
      $echo "No ping reply recieved."
      ((attempts++))
      [[ $attempts -le 20 ]] || fail "$echo" "The VM did not get online" 
      sleep 1
    fi
  done
  
  attempts=0
  while [[ -z $ssh ]]; do
    $echo "Trying to SSH to the machine"
    if ssh -o StrictHostKeyChecking=no ubuntu@$fip uptime &> /dev/null; then
      ssh="yes"
      $echo "SSH auth successful"
    else
      $echo "Could not connect with SSH"
      ((attempts++))
      [[ $attempts -le 20 ]] || fail "$echo" "The VM did not start in time"
      sleep 5
    fi
  done

  $echo "Test successful. Nova seems to work fine."
fi

if [[ ! -z $delete ]]; then
  $echo "Deleting the VM"
  openstack server delete openstackTest || fail "$echo" "Could not delete VM"
  $echo "Deleting the floating IP"
  fip=$(cat .openstackTesting.floatinIP.txt)
  openstack floating ip delete $fip || \
      fail "$echo" "Could not delete floating IP"
  rm .openstackTesting.floatinIP.txt
fi

exit 0
