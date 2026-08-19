#!/bin/bash

if [[ $# -ne 3 ]]; then
  echo "Usage: $0 <hostname> <rack-number> <rack-position>" 
  exit 1
fi

hostname=$1
rack=$2
position=$(printf %02d $3)

declare -A VLAN_MAPPING
VLAN_MAPPING[compute]="300,303,2000-2999"
VLAN_MAPPING[gpu]="300,303,2000-2999"
VLAN_MAPPING[infra]="300,303"
VLAN_MAPPING[neutronnet]="300,307,317,2000-2999"
VLAN_MAPPING[storage]="300,303"

for key in "${!VLAN_MAPPING[@]}"; do
  if [[ $hostname =~ $key ]]; then
    vlan_mapping=${VLAN_MAPPING[$key]}
  fi
done

if [[ -z $vlan_mapping ]]; then
  echo "Cannot identify VLANS for the host $hostname"
  exit 2
fi

echo "! For tor${rack}-a":
echo "!"
echo "interface port-channel${rack}${position}"
echo "  description Host: ${hostname}"
echo "  switchport mode trunk"
echo "  switchport trunk native vlan 300"
echo "  switchport trunk allowed vlan ${vlan_mapping}"
echo "  spanning-tree port type edge trunk"
echo "  mtu 9216"
echo "  no lacp suspend-individual"
echo "  vpc ${rack}${position}"
echo "interface Ethernet1/${position}"
echo "  description Host: ${hostname}"
echo "  switchport mode trunk"
echo "  switchport trunk native vlan 300"
echo "  switchport trunk allowed vlan ${vlan_mapping}"
echo "  spanning-tree port type edge trunk"
echo "  mtu 9216"
echo "  channel-group ${rack}${position} mode passive"
echo "  no shutdown"
echo "!"
echo "! For tor${rack}-b":
echo "!"
echo "interface port-channel${rack}${position}"
echo "  description Host: ${hostname}"
echo "  switchport mode trunk"
echo "  switchport trunk native vlan 300"
echo "  switchport trunk allowed vlan ${vlan_mapping}"
echo "  spanning-tree port type edge trunk"
echo "  mtu 9216"
echo "  vpc ${rack}${position}"
echo "interface Ethernet1/${position}"
echo "  description Host: ${hostname}"
echo "  switchport mode trunk"
echo "  switchport trunk native vlan 300"
echo "  switchport trunk allowed vlan ${vlan_mapping}"
echo "  spanning-tree port type edge trunk"
echo "  mtu 9216"
echo "  channel-group ${rack}${position} mode passive"
echo "  no shutdown"
