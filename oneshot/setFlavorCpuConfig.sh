#!/bin/sh

openstack flavor set --property hw:cpu_cores=2 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 m1.large
openstack flavor set --property hw:cpu_cores=4 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 m1.xlarge
openstack flavor set --property hw:cpu_cores=4 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 c1.tiny
openstack flavor set --property hw:cpu_cores=6 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 c1.small
openstack flavor set --property hw:cpu_cores=8 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 c1.medium
openstack flavor set --property hw:cpu_cores=12 --property  hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 c1.large
openstack flavor set --property hw:cpu_cores=16 --property  hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 c1.xlarge
openstack flavor set --property hw:cpu_cores=4 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 r1.tiny
openstack flavor set --property hw:cpu_cores=6 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 r1.small
openstack flavor set --property hw:cpu_cores=8 --property hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 r1.medium
openstack flavor set --property hw:cpu_cores=12 --property  hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 r1.large
openstack flavor set --property hw:cpu_cores=16 --property  hw:cpu_sockets=2 \
    --property hw:cpu_threads=1 r1.xlarge
