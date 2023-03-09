#!/bin/bash
set -e

# A script which iterates through all stopped instances, and lists these
# machines events. Useful to see when the machine last was touched.

. $(dirname $0)/common.sh

prereq
need_admin

# Remove events from these user-ID's
ignored="(dd8518705f86391273c5cae2e9c5002d2d8e65d5cd19e7ea89e047f00ccd3731|78f914a17c827029484a5063ee07c4c86bea958f7fe05a8a8c0665bfd61e4241)"

for server in $(openstack server list --all --status SHUTOFF -f value -c ID); do
  openstack server show $server -f value -c name -c flavor -c image
  openstack server event list $server --long | grep -vE $ignored
done
