#!/bin/bash

. ../common.sh
need_admin

declare -A images

for a in $(openstack loadbalancer amphora list -f value -c id); do
  echo -n "Amphora $a "
  i=$(openstack loadbalancer amphora show $a -f value -c image_id)
  if [[ ! -v "images[$i]" ]]; then
    images[$i]=$(openstack image show $i -f value -c name)
  fi
  echo "is running ${images[$i]}".
done

