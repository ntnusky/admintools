#!/bin/bash

. $(dirname $0)/common.sh

prereq
need_admin

if [ $# -ne 1 ]; then
  echo "Usage: $0 <username>"
  exit 1
fi

username="$1"

openstack role assignment list --user "$username" --user-domain NTNU --names
