#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

projectName="${1}"

if [ $# -ne 1 ]; then
  echo "This script will set a tag named KEEP on the given project"
  echo "That tag will be respected by the deleteProjectGrep.sh and the deleteProject.sh scripts"
  echo ""
  echo "Usage $0: <project_name|project_id>"
  exit $EXIT_MISSINGARGS
fi

if openstack project show $projectName &> /dev/null; then
  openstack project set --tag KEEP $projectName
  echo "The project $projectName has gotten the KEEP-tag set, and will be protected from deletion"
else
  echo "No project with the name $projectName exists"
  exit $EXIT_CONFIGERROR
fi
