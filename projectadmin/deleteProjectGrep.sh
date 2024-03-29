#!/bin/bash

set -e # Exit the script if any of the commands returns something else than 0

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq      # Check that the needed tools are installed
need_admin  # Check that the user is authenticated as admin

if [ $# -lt 1 ]; then
  echo "Usage: $0 <group_grep>"
  exit $EXIT_MISSINGARGS
fi

echo "The following project will be KEPT as they have the KEEP-tag set:"
for projectID in $(openstack project list -f value -c Name --tags KEEP | grep -E "$1" ); do
  projectName=$(openstack project show -f value -c name $projectID)
  echo "$projectName"
done

echo

echo "The following projects matched your pattern, and will be deleted:"
for projectID in $(openstack project list -f value -c Name --not-tags KEEP | grep -E "$1" ); do
  projectName=$(openstack project show -f value -c name $projectID)
  if [[ -z $2 || $2 != "--yes-i-know-what-i-am-about-to-do" ]]; then
    echo "Your pattern matched the project $projectName"
    dryRun=1
  else
    dryRun=0
    ./$(dirname $0)/deleteProject.sh $projectName
  fi
done


if [[ $dryRun -eq 1 ]]; then
  echo "To actually delete these projects, run the command:"
  echo "$0 \"$1\" --yes-i-know-what-i-am-about-to-do"
fi
