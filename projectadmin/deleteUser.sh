#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

if [[ $# -lt 2 ]]; then
  echo "This script removes a user from a project."
  echo
  echo "Usage: $0 <projectID|projectName> <userID|userName>"
  exit $EXIT_CONFIGERROR 
fi

projectid=$(openstack project show $1 -f value -c id 2> /dev/null) || \
projectid=$(openstack project show $1 -f value -c id --domain=NTNU 2> /dev/null) || \
unset projectid

userid=$(openstack user show $2 -f value -c id 2> /dev/null) || \
userid=$(openstack user show $2 -f value -c id --domain=NTNU 2> /dev/null) || \
unset userid

if [[ -z $userid ]]; then
  echo "Could not find the user $2"
  exit $EXIT_CONFIGERROR
fi
if [[ -z $projectid ]]; then
  echo "Could not find the project $1"
  exit $EXIT_CONFIGERROR
fi

remove_user $projectid $userid
delete_user $userid


exit $EXIT_OK
