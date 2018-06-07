#!/bin/bash

for net in $(cat v6-prefixes.txt); do
  openstack security group rule create --src-ip "$net" --dst-port 22 --ethertype IPv6 --protocol tcp linux
  openstack security group rule create --src-ip "$net" --dst-port 80 --ethertype IPv6 --protocol tcp web
  openstack security group rule create --src-ip "$net" --dst-port 443 --ethertype IPv6 --protocol tcp web
  openstack security group rule create --src-ip "$net" --dst-port 3389 --ethertype IPv6 --protocol tcp windows
done
