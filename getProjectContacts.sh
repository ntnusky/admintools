#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <projectID|projectName>"
  exit 1
fi

oscmd=$(which openstack)

project=$1
projectname=$($oscmd project show -f value -c name "$project")

echo "Project: $projectname"

$oscmd role assignment list -f csv -c User -c  Group --project "$project" --names | tr -d '"' | grep 'NTNU' | uniq | while read -r line; do
  username=$(echo "$line" | cut -d',' -f1 | cut -d'@' -f1)
  group=$(echo "$line" | cut -d',' -f2 | cut -d '@' -f1)

  if [ -n "$username" ]; then
    userdetails=$($oscmd user show -f value -c id -c email --domain NTNU "$username")
    if [[ $userdetails =~ @ ]]; then
      mail=$(echo $userdetails | cut -d' ' -f1)
    # No email registered. Assume student with RESERVE_PUBLISH
    else
      mail="${username}@stud.ntnu.no [WARN] No e-mail registered in AD. Assumed student"
    fi
    echo "Username: $username | E-mail: $mail"
  fi

  if [ -n "$group" ]; then
    groupdesc=$($oscmd group show -f value -c description --domain NTNU "$group")
    echo "Group: $group | Group description: $groupdesc"
  fi
done
