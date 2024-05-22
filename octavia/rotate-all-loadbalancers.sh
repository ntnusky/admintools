#!/bin/bash

. ../common.sh
need_admin

echo "Rotating all load-balancers"
for lb in $(openstack loadbalancer list -f value -c id); do
  echo "Triggering failover of $lb"
  openstack loadbalancer failover $lb
done


