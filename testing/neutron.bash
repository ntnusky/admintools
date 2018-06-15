#!/bin/bash
MYDIR="$(dirname "$(realpath "$0")")"
. $MYDIR/testlib.bash

echo="echo [NEUTRON]"

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
  starttime=$(date +%s)
  $echo "Creating a network with an IPv4 subnet attached to a new router."
  openstack network create testOpenstack.net || \
      fail "$echo" "Could not create network"
  openstack subnet create --subnet-range 192.168.0.0/28 --ip-version 4 \
      --network testOpenstack.net testOpenstack.subnet || \
      fail "$echo" "Could not create subnet"
  openstack router create testOpenstack.router || \
      fail "$echo" "Could not create router"
  openstack router set --external-gateway ntnu-internal testOpenstack.router || \
      fail "$echo" "Could not attatch router to ntnu-internal"
  openstack router add subnet testOpenstack.router testOpenstack.subnet || \
      fail "$echo" "Could not attatch subnet to router"
  endtime=$(date +%s)
  $echo "network created in $((endtime-starttime)) seconds"

  starttime=$(date +%s)
  $echo "Testing that the router comes online"
  
  attempts=0
  while [[ -z $success ]]; do
    ip=$(openstack router show testOpenstack.router | grep external_gateway | \
        cut -d '|' -f 3 | jq .external_fixed_ips | jq .[0].ip_address | \
        cut -d '"' -f 2) 
    $echo "Trying to ping ${ip}"
    if ping $ip -c 1 -W 2; then
      $echo "Got a response"
      success="ok"
    else
      ((attempts++))
      if [[ $attempts -gt 10 ]]; then
        fail "$echo" "Could not ping the new router at $ip"
      fi
    fi
    sleep 1
  done

  endtime=$(date +%s)
  $echo "The router is pingable at ${ip} after $((endtime-starttime)) seconds"
fi

if [[ ! -z $delete ]]; then
  starttime=$(date +%s)
  $echo "Deleting network, subnet and router"
  openstack router remove subnet testOpenstack.router testOpenstack.subnet || \
      fail "$echo" "Could not detatch subnet from router"
  openstack router delete testOpenstack.router || \
      fail "$echo" "Could not delete router"
  openstack subnet delete testOpenstack.subnet || \
      fail "$echo" "Could not delete subnet"
  openstack network delete testOpenstack.net || \
      fail "$echo" "Could not delete network"
  endtime=$(date +%s)
  $echo "network deleted in $((endtime-starttime)) seconds"
fi

exit 0
