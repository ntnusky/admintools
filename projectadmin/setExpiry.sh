#!/bin/bash

set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

project=$1
expiry=$2

if [ $# -ne 2 ]; then
  echo "Usage: $0 <project name|uuid> <expiry date (dd.mm.yyyy)>"
  exit $EXIT_MISSINGARGS
fi

if [[ ! $expiry =~ ^[0-3][0-9]\.[0-1][0-9]\.20[0-9]{2}$ ]]; then
  echo "\"$expiry\" does not look like a date on the format dd.mm.yyyy"
  exit $EXIT_CONFIGERROR
fi

if openstack project show $project &> /dev/null; then
  openstack project set --property expiry=$expiry $project
  openstack project set --remove-tag notified_delete $project
  echo "$project now has the expiry date $expiry, and the notified_delete tag is removed"
else
  echo "Project $project does not exist"
  exit $EXIT_CONFIGERROR
fi
