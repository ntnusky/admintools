#!/bin/bash

. $(dirname $0)/common.sh

prereq
need_admin

if [ $# -ne 1 ]; then
  echo "Usage: $0 <project[name|id]>"
  exit 1
fi

project="$1"

openstack role assignment list --project "$project" --names
