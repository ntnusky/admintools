#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <vm-uuid|vm-name>"
  exit 1
fi

vm=$1
oscmd=$(which openstack)

vm_data=$($oscmd server show -f json -c project_id -c properties -c name "$vm")
project=$(echo "$vm_data" | jq -r '.project_id')
properties=$(echo "$vm_data" | jq -r '.properties')
vm_name=$(echo "$vm_data" | jq -r '.name' )
projectname=$($oscmd project show -f value -c name "$project")

box "User info about VM: $vm ($vm_name)"
echo "Project: $projectname"

if [ -n "$properties" ]; then
  echo "$properties"
else
  $oscmd role assignment list -f value -c User --project "$project" --names | uniq | while read -r line; do
    username=$(echo "$line" | cut -d'@' -f1)
    details=$($oscmd user show -f value -c id -c email --domain NTNU "$username")
    if [[ $mail =~ @ ]]; then
      mail=$(echo $details | cut -d' ' -f1)
    # No email registered. Assume student with RESERVE_PUBLISH
    else
      mail="${username}@stud.ntnu.no [WARN] No e-mail registered in AD. Assumed student"
    fi
    echo "Username: $username | E-mail: $mail"
  done
fi
