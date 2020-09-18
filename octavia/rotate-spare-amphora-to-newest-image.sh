#!/bin/bash

. ../common.sh
need_admin

echo "Checking if an appropriate image exists"
no=$(openstack image list --tag amphora -f value -c ID | wc -l)

if [[ $no -ne '1' ]]; then
  echo "There is not exactlu one image with the tag amphora!"
  exit 2
fi

new=$(openstack image list --tag amphora -f value -c ID)

echo "Rotating the spare amphora"
for amphora in $(openstack loadbalancer amphora list \
                    -f value -c id --status READY); do
  current=$(openstack loadbalancer amphora show $amphora -f value -c image_id)
  if [[ $current != $new ]]; then
    echo " - Amphora $amphora needs an upgrade"
    openstack loadbalancer amphora failover $amphora
  else
    echo " - Amphora $amphora is already the correct version"
  fi
done
