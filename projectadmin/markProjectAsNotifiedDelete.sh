#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <project-id|project-name> "
  exit 1
fi

project=$1

if openstack project show $project &> /dev/null; then
  openstack project set --tag notified_delete $project
  echo "Project $project now has the tag 'notified_delete' set"
else
  echo "Project $project does not exist"
  exit $EXIT_CONFIGERROR
fi
