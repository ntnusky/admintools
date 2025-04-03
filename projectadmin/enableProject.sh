#!/bin/bash
set -e # Exit the script if any of the commands returns something else than 0

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq      # Check that the needed tools are installed
need_admin  # Check that the user is authenticated as admin

if [ $# -lt 1 ]; then
  echo "This script re-enables a project by re-starting the VM's (that were"
  echo "running when the project was disabled) and re-adds the users."
  echo ""
  echo "Usage: $0 <project_name|project_id>"
  exit $EXIT_MISSINGARGS
fi

projectName=$(openstack project show $1 -f value -c name)
projectID=$(openstack project show $1 -f value -c id)
adminProjectID=$(openstack project show admin -f value -c id)

if openstack object save DeactivationLog "${projectID}.log"; then
  echo "Starting to re-enable the project $projectName ($projectID)"

  for line in $(cat "${projectID}.log"); do
    [[ $line =~ ^([A-Z]+):(.*)$ ]]

    case ${BASH_REMATCH[1]} in 
      VM)
        echo Enable VM ${BASH_REMATCH[2]}
        openstack server start ${BASH_REMATCH[2]} 
        ;;
#      USER)
#        userAndRole=$(echo ${BASH_REMATCH[2]} | sed s/,/\ /)
#        openstack role add --project $projectID --user $userAndRole
#        echo Add USER ${BASH_REMATCH[2]}
#        ;;
#      GROUP)
#        groupAndRole=$(echo ${BASH_REMATCH[2]} | sed s/,/\ /)
#        openstack role add --project $projectID --group $groupAndRole
#        echo Add GROUP ${BASH_REMATCH[2]}
#        ;;
      *)
        echo Unknown key ${BASH_REMATCH[1]}
    esac
  done
  openstack project set --enable $projectID 
  rm ${projectID}.log
  openstack object delete DeactivationLog "${projectID}.log"

  echo "The project is re-enabled"
else
  echo "Could not find logfile with a project-id $projectID."
fi

exit $EXIT_OK
