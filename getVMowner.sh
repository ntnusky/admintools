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

vm_data=$($oscmd server show -f json -c project_id -c properties -c name -c user_id "$vm")
project=$(echo "$vm_data" | jq -r '.project_id')
properties=$(echo "$vm_data" | jq -r '.properties')
vm_name=$(echo "$vm_data" | jq -r '.name' )
user=$(echo "$vm_data" | jq -r '.user_id' )
projectname=$($oscmd project show -f value -c name "$project")
if [ $($oscmd user show -f value -c name "$user" 2> /dev/null ) ]; then
  creator=$($oscmd user show -f value -c name "$user")
else
  creator="$user (user does not exist)"
fi

box "User info about VM: $vm ($vm_name)"
echo "Project: $projectname"
echo "User that created the VM: $creator"

if [ "$properties" != "{}" ]; then
  echo "VM custom properties: $properties"
else
  box "Current project members"
  $oscmd role assignment list -f csv -c User -c  Group --project "$project" --names | tr -d '"' | grep '@NTNU' | uniq | while read -r line; do
    username=$(echo "$line" | cut -d',' -f1 | cut -d'@' -f1)
    group=$(echo "$line" | cut -d',' -f2 | cut -d '@' -f1)

    if [ -n "$username" ]; then
      userdetails=$($oscmd user show -f value -c id -c email --domain NTNU "$username")
      id=$(echo $userdetails | cut -d' ' -f2)
      if [[ $userdetails =~ @ ]]; then
        mail=$(echo $userdetails | cut -d' ' -f1)
      # No email registered. Assume student with RESERVE_PUBLISH
      else
        mail="${username}@stud.ntnu.no [WARN] No e-mail registered in AD. Assumed student"
      fi
      echo "Username: $username | E-mail: $mail"
    fi

    if [ -n "$group" ]; then
      if [ $($oscmd group show -f value -c description --domain NTNU "$group" 2> /dev/null) ]; then
        groupdesc="| Group description: $($oscmd group show -f value -c description --domain NTNU "$group")"
      else
        groupdesc="| (No group description set)"
      fi
      echo "Group: $group $groupdesc"
    fi
  done
fi
