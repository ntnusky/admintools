#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <project-name|id>"
  exit 1
fi

echo Projectinfo:
openstack project show $1

echo Members:
openstack role assignment list --project $1 --names \
  --sort-column User --sort-column Group

for region in $(openstack region lis -f value -c Region); do
  export OS_REGION_NAME=$region

  echo Servers in $region:
  openstack server list --sort-column Name --project $1
  
  echo Images in $region:
  openstack image list --sort-column Name --project $1
  
  echo Volumes in $region:
  openstack volume list --sort-column Name --project $1
done
