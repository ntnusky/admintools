#!/bin/bash

set -e

for f in $(cat $1 | jq -c '.[]'); do
  NAME=$(echo $f | jq -re '.["Name"]')
  CPU=$(echo $f | jq -re '.["CPU"]')
  RAM=$(echo $f | jq -re '.["RAM"]')
  DISK=$(echo $f | jq -re '.["Disk"]')
  VISIBILITY=$(echo $f | jq -re '.["visibility"]')
  declare -A properties

  for key in $(echo $f | jq -r 'keys[]'); do
    if ! [[ "Name CPU RAM Disk visibility" =~ $key ]]; then
      properties[$key]=$(echo $f | jq -r ".[\"$key\"]")
    fi
  done

  new=0
  flavor=$(openstack flavor show -f json $NAME 2> /dev/null) || new=1

  props=""
  for key in ${!properties[@]}; do
    props+=" --property ${key}=${properties[$key]}"
  done

  case $VISIBILITY in
    public) 
      v="--public" 
      public='true'
      ;;
    private) 
      v="--private" 
      public='false'
      ;;
    *) 
      echo "Unknown visibility: $VISIBILITY"
      exit 1
      ;;
  esac

  if [[ $new -eq 1 ]]; then
    echo "Creating the flavor $NAME" 
    openstack flavor create \
      --vcpus $CPU --ram $RAM --disk $DISK $v $props \
      $NAME
  else
    echo "Updating the flavor $NAME"
    if [[ $(echo $flavor | jq '.["os-flavor-access:is_public"]') != $public ]]; then
      echo -n " - Flavor $NAME is not correctly set public/private. ("
      echo -n "$(echo $flavor | jq '.["os-flavor-access:is_public"]')"
      echo "instead of $public)"
    fi
    if [[ $(echo $flavor | jq '.["disk"]') -ne $DISK ]]; then
      echo -n " - Flavor $NAME does not have the disk correctly set. "
      echo "$(echo $flavor | jq '.["disk"]') instead of $DISK"
    fi
    if [[ $(echo $flavor | jq '.["vcpus"]') -ne $CPU ]]; then
      echo -n " - Flavor $NAME does not have CPU-count correctly set "
      echo "$(echo $flavor | jq '.["vcpus"]') instead of $CPU"
    fi
    if [[ $(echo $flavor | jq '.["ram"]') -ne $RAM ]]; then
      echo -n " - Flavor $NAME does not have the right amount for RAM "
      echo "$(echo $flavor | jq '.["ram"]') instead of $RAM"
    fi
    
    openstack flavor set $NAME --no-property $props
  fi
done
