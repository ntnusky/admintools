#!/bin/bash

set -e # Exit the script if any of the commands returns something else than 0

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq      # Check that the needed tools are installed
need_admin  # Check that the user is authenticated as admin

for projectID in $(openstack project list --long -f value | grep 'DELETABLE' | \
    awk '{ print $1 }'); do
  projectName=$(openstack project show $projectID | grep name | awk '{ print $4 }')
  if [[ $(openstack project show $projectID -f json | jq -c '.tags' | \
      grep -c DELETABLE) -ge 1 ]]; then
    if [[ -z $1 || $1 != "--yes-i-know-what-i-am-about-to-do" ]]; then
      echo "The project $projectName is marked for deletion"
      dryRun=1
    else
      dryRun=0
      ./$(dirname $0)/deleteProject.sh $projectName
    fi
  else
    echo "Project $projectName have 'DELETABLE' in its name or description,"
    echo "but the tag is not set"
  fi
done

if [[ $dryRun -eq 1 ]]; then
  echo "To actually delete these projects, run the command:"
  echo "$0 --yes-i-know-what-i-am-about-to-do"
fi
