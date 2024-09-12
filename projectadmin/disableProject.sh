#!/bin/bash
set -e # Exit the script if any of the commands returns something else than 0

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq      # Check that the needed tools are installed
need_admin  # Check that the user is authenticated as admin

if [ $# -lt 1 ]; then
  echo "This script removes all users from a project and shuts off all VM's."
  echo "Use-case is to 'delete' a project before we actually delete machines."
  echo ""
  echo "Usage: $0 <project_name|project_id>"
  exit $EXIT_MISSINGARGS
fi

projectName=$(openstack project show $1 -f value -c name)
projectID=$(openstack project show $1 -f value -c id)
adminProjectID=$(openstack project show admin -f value -c id)

statusfile=$(mktemp)

echo "Starting to disable the project $projectName ($projectID)"

openstack project --disable $projectID
disable_nova $projectID $statusfile


echo "Uploading a statusfile to swift, so that the project can be reactivated"
openstack container show DeactivationLog &> /dev/null || \
  openstack container create DeactivationLog
openstack object create --name "${projectID}.log" DeactivationLog $statusfile
rm $statusfile

exit $EXIT_OK
