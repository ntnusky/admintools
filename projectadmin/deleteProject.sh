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

checkKeep=$(openstack project show -f value -c tags $projectName)
if [[ $checkKeep =~ KEEP ]]; then
  echo "The project $projectName has the KEEP tag set, and will not be deleted!"
  echo "Exiting..."
  exit $EXIT_CONFIGERROR
fi

active=$(openstack project show $projectID -f value -c enabled)
if [[ $active =~ False ]]; then
  echo "Activating project as it need to be active to be deleted :P"
  openstack project set --enable $projectID
fi

echo "Starting to delete the project $projectName ($projectID)"
delete_users $projectID
add_user $projectID $OS_USERNAME

for region in $(openstack region list -f value -c Region); do
  echo "Deleting from the region $region"
  export OS_REGION_NAME=$region
  set_project $projectName $projectID
  
  clean_magnum
  clean_heat
  clean_nova
  clean_cinder
  clean_glance
  clean_swift
  clean_octavia
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
  
  set_project 'admin' $adminProjectID
  clean_neutron_rbac $projectID
  # Delete default security group from project. This MUST be done with the admin tenant context
  echo "Deleting default security group from project $projectName"
  default_sg_id=$(openstack security group list -f value | grep $projectID | cut -d' ' -f1)
  openstack security group delete $default_sg_id
done

remove_user $projectID $OS_USERNAME
  
echo "Deleting projects from heat domain"
for heatProject in $(openstack project list -f value -c Name --domain heat | grep $projectID); do
  openstack project delete --domain heat $heatProject
done

echo "Deleting the project $projectName"
openstack project delete $projectID

exit $EXIT_OK
