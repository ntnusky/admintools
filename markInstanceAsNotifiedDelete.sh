#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

instance=$1

if openstack server show $instance &> /dev/null; then
  openstack server set --tag notified_delete $instance
  echo "Instance $instance now has the tag 'notified_delete' set"
else
  echo "Instance $instance does not exist"
  exit $EXIT_CONFIGERROR
fi
