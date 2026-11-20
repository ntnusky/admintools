#!/usr/bin/env bash

all_instances=()

echo "Fetching all instances from the gpu-providers..."
for provider in $(openstack resource provider list --sort-column name -f value -c uuid -c name | grep -E 'gpu.*_0000:' | awk '{print $1}'); do
  for i in $(openstack resource provider show --allocations $provider -f json -c allocations | jq -r '.allocations | keys[]'); do
    if ! [[ "${all_instances[*]}" =~ "$i" ]]; then
      all_instances+=( $i )
    fi
  done
done

echo "Checking the allocations for all instances..."
for instance in ${all_instances[@]}; do
  allocations=$(openstack resource provider allocation show -f json $instance)
  gpu_allocations=$(echo "$allocations" | jq '[.[] | select(any(.resources | keys[]; startswith("CUSTOM_")))] | length')
  if [[ $gpu_allocations -ge 2 ]]; then
    echo "$instance has more than one PCI allocation in placement"
    echo "$allocations"
  else
    echo "$instance has $gpu_allocations PCI allocation in placement - that's fine!"
  fi
done

