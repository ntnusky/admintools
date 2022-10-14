#!/bin/bash

. $(dirname $0)/common.sh

prereq
need_admin

if [ $# -ne 1 ]; then
  echo "Usage: $0 <group>"
  exit 1
fi

groupname="$1"

openstack role assignment list --group "$groupname" --group-domain "NTNU" --names
