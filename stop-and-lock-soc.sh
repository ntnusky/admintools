#!/usr/bin/env bash

set -e

. $(dirname $0)/common.sh

prereq
need_admin

function usage() {
  echo "Usage: $0 <vm uuid> [unlock]"
  exit $EXIT_MISSINGARG
}

if [[ $# -lt 1 ]] || [[ $2 -gt 2 ]] ; then
  usage
fi

VM=$1
message='VM has been shut down by request from NTNU SOC. Contact soc@ntnu.no for details'

if [[ $# -eq 1 ]]; then
  openstack server stop $VM && echo "Server $VM has been shut down"
  openstack server lock --reason "$message" $VM && echo "Server $VM has been locked"
  openstack server set --description "$message" $VM && echo "Set description from SOC"
elif [[ $# -eq 2 ]] && [[ $2 =~ ^unlock$ ]]; then
  openstack server unlock $VM && echo "Server $VM is now unlocked"
  openstack server start $VM && echo "Server $VM is now started"
  openstack server unset --description $VM && echo "Description is removed"
else
  usage
fi
