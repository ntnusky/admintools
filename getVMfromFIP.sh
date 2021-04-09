#!/bin/bash
set -e

. $(dirname $0)/common.sh

prereq
need_admin

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <Floating IP address>"
  exit 1
fi

oscmd=$(which openstack)

fip="$1"

port_id=$($oscmd port list -f value -c ID --fixed-ip ip-address="$fip")
port_details=$($oscmd port show -f json -c device_owner -c device_id "$port_id")
device_owner=$(echo "$port_details" | jq -r '.device_owner')
device_id=$(echo "$port_details" | jq -r '.device_id')

box "Info om ressurs med IP: $fip"

if [ "$device_owner" == "network:router_gateway" ]; then
  router_details=$($oscmd router show -f json -c name -c project_id $device_id)
  router_name=$(echo $router_details | jq -r '.name')
  project_id=$(echo $router_details | jq -r '.project_id')
  project_name=$($oscmd project show -f value -c name "$project_id")

  box "User info about ROUTER: $device_id ($router_name)"
  echo "Project: $project_name"

  $oscmd role assignment list -f value -c User --project "$project_id" --names | grep 'NTNU' | uniq | while read -r line; do
    username=$(echo "$line" | cut -d'@' -f1)
    details=$($oscmd user show -f value -c id -c email --domain NTNU "$username")
    if [[ $details =~ @ ]]; then
      mail=$(echo $details | cut -d' ' -f1)
    # No email registered. Assume student with RESERVE_PUBLISH
    else
      mail="${username}@stud.ntnu.no [WARN] No e-mail registered in AD. Assumed student"
    fi
    echo "Username: $username | E-mail: $mail"
  done

elif [ "$device_owner" == "network:floatingip" ]; then
  vm_id=$($oscmd floating ip show -f value -c port_details "$fip" | grep -oE "device_id='\w{8}-\w{4}-\w{4}-\w{4}-\w{12}'" | cut -d'=' -f2 | tr -d "'")
  ./getVMowner.sh $vm_id
else
  echo "Dette var rare greier ($device_owner)"
fi
