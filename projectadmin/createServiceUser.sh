#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

if [[ -z $1 ]]; then
  echo "This script creates a service-user to a project. The user can also be"
  echo "configured to have access to all projects inheriting from the given"
  echo "project name"
  echo
  echo "Usage: $0 <projectID|projectName> [--inherit]"
  exit $EXIT_CONFIGERROR 
fi

if [[ $2 == '--inherit' ]]; then
  extra="--inherited"
else
  extra=""
fi

name=$(openstack project show $1 -f value -c name) || name=0
if [[ -z $name ]]; then
  echo "Could not fint the project $1"
  exit $EXIT_CONFIGERROR 
else
  create_serviceuser $name $extra
fi

exit $EXIT_OK
