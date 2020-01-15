#!/bin/sh

openstack flavor set --property hw:cpu_cores=6 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 l1.tiny
openstack flavor set --property hw:cpu_cores=8 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 l1.small
openstack flavor set --property hw:cpu_cores=10 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 l1.medium
openstack flavor set --property hw:cpu_cores=12 --property  hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 l1.large
openstack flavor set --property hw:cpu_cores=16 --property  hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 l1.xlarge
