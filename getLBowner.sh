#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <lb-uuid|lb-name>"
  exit 1
fi
lb=$1
oscmd=$(which openstack)

if [[ "$lb" =~ ^lb- ]]; then
  lb="${lb#lb-}"              # Remove the "lb-" prefix if present
fi

lb_data=$($oscmd loadbalancer show -f json -c project_id -c name -c pools -c listeners "$lb")
project=$(echo "$lb_data" | jq -r '.project_id')
lb_name=$(echo "$lb_data" | jq -r '.name')
mapfile -t listener_ids < <(jq -r '.listeners[].id' <<< "$lb_data")
mapfile -t pool_ids < <(jq -r '.pools[].id' <<< "$lb_data")
projectname=$($oscmd project show -f value -c name "$project")

declare -A listeners

for l in "${listener_ids[@]}"; do
  listener_data=$($oscmd loadbalancer listener show -f json -c name -c protocol $l)
  listeners["$l,name"]=$(echo "$listener_data" | jq -r '.name')
  listeners["$l,protocol"]=$(echo "$listener_data" | jq -r '.protocol')
done

box "Info about LB: $lb ($lb_name)"
echo "Project: $projectname"
echo
echo "Listeners:"
for l in "${listener_ids[@]}"; do
  echo "${listeners["$l,name"]} ($l) - ${listeners["$l,protocol"]}"
done
echo
echo "Pools:"
for p in "${pool_ids[@]}"; do
  pool_name=$($oscmd loadbalancer pool show -f value -c name $p)
  echo -n "$pool_name | Members: "
  member_ids=$($oscmd loadbalancer member list -f value -c id $p | tr '\n' ' ')
  for m in $member_ids; do
    member_ip=$($oscmd loadbalancer member show -f value -c address $p $m)
    vm_data=$($oscmd server list --project $project -f json -c Name -c Networks -c ID | jq -r --arg ip "$member_ip" '.[] | select(any(.Networks[]; index($ip)))')
    vm_name=$(echo "$vm_data" | jq -r '.Name')
    vm_id=$(echo "$vm_data" | jq -r '.ID')
    echo -n "$vm_name ($vm_id) ($member_ip) - "
  done
  echo
done
echo

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
    if [[ $($oscmd group show -f value -c description --domain NTNU "$group" 2> /dev/null) ]]; then
      groupdesc="| Group description: $($oscmd group show -f value -c description --domain NTNU $group)"
    else
      groupdesc="| (No group description set)"
    fi
    echo "Group: $group $groupdesc"
  fi
done

