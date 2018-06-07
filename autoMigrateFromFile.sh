#!/bin/bash
id_file=$1
to_node=$2

while read id; do
  echo $id to $to_node
  openstack server migrate --block-migration --live $to_node --wait $id
  echo sleeping...
  sleep 3
  echo continuing...
done < ${id_file}
