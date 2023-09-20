#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

projectName="${1}"

if [ $# -ne 1 ]; then
  echo "This script will remove the KEEP tag from the given project,"
  echo "which will allow you to delete the project"
  echo ""
  echo "Usage $0: <project_name|project_id>"
  exit $EXIT_MISSINGARGS
fi

if openstack project show $projectName &> /dev/null; then
  openstack project set --remove-tag KEEP $projectName
  echo "The project $projectName has gotten its KEEP-tag removed, and will now be possible to delete via our scripts"
else
  echo "No project with the name $projectName exists"
  exit $EXIT_CONFIGERROR
fi
