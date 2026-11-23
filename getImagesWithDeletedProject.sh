#!/usr/bin/env bash

TOTAL_SIZE_WASTED=0

for image in $(openstack image list --all -f value -c ID); do
  image_data=$(openstack image show $image -f json -c name -c owner -c status -c visibility -c size)
  owner=$(echo "$image_data" | jq -r .owner)
  if ! openstack project show $owner &> /dev/null; then
    name=$(echo "$image_data" | jq -r .name)
    status=$(echo "$image_data" | jq -r .status)
    visibility=$(echo "$image_data" | jq -r .visibility)
    size=$(echo "$image_data" | jq -r .size)
    TOTAL_SIZE_WASTED=$(( TOTAL_SIZE_WASTED+=size ))
    size_mb=$(( size / 1024 / 1024 ))
    if [[ $size_mb -gt 1023 ]]; then
      print_size="$(( size / 1024 / 1024 / 1024)) GB"
    else
      print_size="$size_mb MB"
    fi
    echo "$name ($image) is owned by a deleted project | Size: $print_size | Status: $status | Visibility: $visibility"
    echo "VMs running this image:"; openstack server list --all --image $image -f value -c ID
    echo
  fi
done

echo "Total storage wasted: $(( TOTAL_SIZE_WASTED / 1024 / 1024 / 1024 )) GB"
