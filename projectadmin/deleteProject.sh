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

echo "Checking which endpoints exist in ${OS_REGION_NAME}."

set +e
has_endpoint "magnum"
has_magnum=$?
has_endpoint "heat"
has_heat=$?
has_endpoint "nova"
has_nova=$?
has_endpoint "cinderv3"
has_cinder=$?
has_endpoint "glance"
has_glance=$?
has_endpoint "swift"
has_swift=$?
has_endpoint "neutron"
has_neutron=$?
set -e

echo "Starting to delete the project $projectName ($projectID)"

delete_users $projectID
add_user $projectID $OS_USERNAME
set_project $projectName $projectID

clean_magnum $has_magnum
clean_heat $has_heat
clean_nova $has_nova
clean_cinder $has_cinder
clean_glance $has_glance
clean_swift $has_swift
clean_octavia
clean_neutron $projectID $has_neutron

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

# FwaaS has been disabled
## Delete default FWaaS v2 resources. This is easiest to do with the admin context
#echo "Removing default ingress and egress policies from default firewall group"
#default_fwg_id=$(openstack firewall group list --long -f value -c ID -c Project | grep $projectID | cut -d' ' -f1)
#openstack firewall group set --disable --no-egress-firewall-policy --no-ingress-firewall-policy $default_fwg_id
#
#echo "Deleting all firewall policies"
#fw_policies=$(openstack firewall group policy list --long -f value -c ID -c Project | grep $projectID | cut -d' ' -f1)
#for fw_p in $fw_policies; do
#  openstack firewall group policy delete $fw_p
#done
#
#echo "Deleting all firewall rules"
#fw_rules=$(openstack firewall group rule list --long -f value -c ID -c Project | grep $projectID | cut -d' ' -f1)
#for fw_r in $fw_rules; do
#  openstack firewall group rule delete $fw_r
#done

# Delete default security group from project. This MUST be done with the admin tenant context
echo "Deleting default security group from project $projectName"
default_sg_id=$(openstack security group list -f value | grep $projectID | cut -d' ' -f1)
openstack security group delete $default_sg_id

echo "Deleting projects from heat domain"
for heatProject in $(openstack project list -f value -c Name --domain heat | grep $projectID); do
  openstack project delete --domain heat $heatProject
done

echo "Deleting the project $projectName"
openstack project delete $projectID

exit $EXIT_OK
