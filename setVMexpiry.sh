#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq

instance=$1
expiry=$2

if [ $# -ne 2 ]; then
  echo "Usage: $0 <instance name|uuid> <expiry date (dd.mm.yyyy)>"
  exit $EXIT_MISSINGARGS
fi

if [[ ! $expiry =~ ^[0-3][0-9]\.[0-1][0-9]\.20[0-9]{2}$ ]]; then
  echo "\"$expiry\" does not look like a date on the format dd.mm.yyyy"
  exit $EXIT_CONFIGERROR
fi

if openstack server show $instance &> /dev/null; then
  openstack server set --property expire=$expiry $instance
  openstack server unset --tag notified_delete $instance &> /dev/null || true
  echo "The VM $instance now has the expiry date $expiry, and the notified_delete tag is removed"
else
  echo "The VM $instance does not exist"
  exit $EXIT_CONFIGERROR
fi
