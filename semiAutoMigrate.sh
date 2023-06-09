#!/bin/bash
from_node=$1
for a in $(openstack server list --host $from_node --all -f value -c ID -c Status | grep ACTIVE | cut -d' ' -f1); do
  echo "migrating $a"
  read -p "migrate to node: " to_node
  echo $a to $to_node
  openstack server migrate --shared-migration --live-migration --host $to_node --wait $a
  echo sleeping...
  sleep 3
  echo continuing...
done
