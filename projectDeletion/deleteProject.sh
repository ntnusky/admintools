#!/bin/bash
set -e # Exit the script if any of the commands returns something else than 0

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq      # Check that the needed tools are installed
need_admin  # Check that the user is authenticated as admin

if [ $# -lt 1 ]; then
  echo "Usage: $0 <project_name|project_id>"
  exit $EXIT_MISSINGARGS
fi

projectName=$(openstack project show $1 -f value -c name)
projectID=$(openstack project show $1 -f value -c id)
adminProjectID=$(openstack project show admin -f value -c id)

echo "Starting to delete the project $projectName ($projectID)"

delete_users $projectID $OS_USERNAME
add_user $projectID $OS_USERNAME
set_project $projectName $projectID

clean_heat
clean_nova
clean_glance
clean_cinder
clean_swift
clean_neutron $projectID

# Delete all security groups
echo "Deleting security groups"
default_group=$(openstack security group show -f value -c id default)
groups=$(openstack security group list | \
  grep -v $default_group | \
  egrep [0-9a-f]{8}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{4}\-[0-9a-f]{12} -o) \
  || groups=""
for group in $groups; do
  openstack security group delete $group
done

#delete_loadbalancers

set_project 'admin' $adminProjectID
remove_user $projectID $OS_USERNAME

# Delete default security group from project. This MUST be done with the admin tenant context
echo "Deleting default security group from project $projectName"
default_sg_id=$(openstack security group list -f value | grep $projectID | cut -d' ' -f1)
openstack security group delete $default_sg_id

echo "Deleting the project $projectName"
openstack project delete $projectID

exit $EXIT_OK
