#!/usr/bin/env bash

PROVIDER=$1
VM=$2
CLASS=$3

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <PROVIDER UUID> <INSTANCE UUID> <RESOURCE CLASS NAME>"
  exit 1
fi

read -r -p "Will remove the allocation of resource '$CLASS' for VM '$VM' on RP '$PROVIDER'. OK? (y/N): " CONFIRM
if [[ "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "OK! Removing the allocation..."
  openstack resource provider allocation unset --provider $PROVIDER --resource-class $CLASS $VM
else
  echo "ABORTED!"
fi
