#!/usr/bin/env bash

#!/bin/bash

. $(dirname $0)/common.sh

prereq
need_admin

if [ $# -ne 1 ]; then
  echo "Usage: $0 <project[name|id]>"
  exit 1
fi

PROJECT=$1

TICKET=$(openstack project show -f value -c topdesk $PROJECT 2> /dev/null)
if [[ -n $TICKET ]]; then
  URL="https://hjelp.ntnu.no/tas/secure/incident?action=lookup&lookup=naam&lookupValue=$TICKET"
  gnome-www-browser "$URL"
else
  echo "No ticket number registered on this project"
  exit $EXIT_ERROR
fi
