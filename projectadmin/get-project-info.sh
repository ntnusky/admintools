#!/bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <project-name|id>"
  exit 1
fi

echo Projectinfo:
openstack project show $1

echo Members:
openstack role assignment list --project $1 --names

echo Servers:
openstack server list --project $1

echo Images:
openstack image list --project $1

echo Volumes:
openstack volume list --project $1
