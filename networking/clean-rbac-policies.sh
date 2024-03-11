#!/bin/bash

set -e

. $(dirname $0)/../common.sh

need_admin

for i in $(openstack network rbac list -f value -c ID); do
  targetProject="$(openstack network rbac show -f value -c target_project_id $i)"
  if [ "${targetProject}" == '*' ] ; then
    echo "Wildcard RBAC. Keeping it"
  elif openstack project show $targetProject &> /dev/null; then
    echo "$targetProject exists. Keeping the policy"
  else
    echo "$targetProject does not exist. Deleting the RBAC policy"
    openstack network rbac delete $i
  fi
done
