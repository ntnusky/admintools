#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

while getopts p:z:4 option; do
  case "${option}" in 
    4) v4pool=1 ;;
    p) project=${OPTARG} ;;
    z) zone=${OPTARG} ;;
  esac
done

if [[ -z $project ]] || [[ -z $zone ]] || [[ -z $v4pool ]]; then
  echo "This script assignes a networking-zone to a project."
  echo
  echo "Usage: $0 [ARGUMENTS]"
  echo ""
  echo "Mandatory arguments (arguments which are always required)"
  echo " -p <project_name> : A project name"
  echo " -z <Network zone> : A project description"
  echo " -4                : Also give access to NTNU IPv4-addresses" 
  exit $EXIT_MISSINGARGS
fi

if [[ $OS_REGION_NAME =~ ^TRD[12]$ ]]; then
  if [[ ! -z $zone && ! $zone =~ \
      ^(internal|exposed|restricted|management|research|infrastructure)$ ]]; then
    echo "The specified zone is invalid. It must be one of: "
    echo "  exposed, internal, restricted, management, research or infrastructure" 
    exit $EXIT_MISSINGARGS
  fi
else
  echo "Zones are not relevant in this region"
  exit $EXIT_CONFIGERROR
fi

echo "Giving project access to the $zone zone"
openstack network rbac create --type network --action access_as_external \
  --target-project "${project}" "ntnu-${zone}" 2> /dev/null || \
  echo " - Already granted"
echo "Giving project access to the ntnu-${zone}-v6 subnet pool"
openstack network rbac create --type subnetpool --action access_as_shared \
  --target-project "${project}" "ntnu-${zone}-v6" 2> /dev/null || \
  echo " - Already granted"
echo "Tagging project with zone"
openstack project set --tag "ZONE-${zone}" --tag "POOL-V6-${zone}" "${project}"

if [[ ! -z $v4pool ]]; then
  echo "Giving project access to the ntnu-${zone}-v4 subnet pool"
  openstack network rbac create --type subnetpool --action access_as_shared \
    --target-project "${project}" "ntnu-${zone}-v4" 2> /dev/null || \
    echo " - Already granted"
  openstack project set --tag "POOL-V4-${zone}" "${project}"
fi

exit $EXIT_OK
