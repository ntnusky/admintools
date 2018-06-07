#!/bin/bash

function usage() {
  echo
  echo "This script creates an instance in the MISC project, with useful metadata attached"
  echo "Only the default security group will be attached"
  echo
  echo "USAGE: ${0} -i <image-id> -f <flavor-id|flavor-name> -k <key-name> -n <instance-name> -t <global|internal> -e <expiredate (dd.mm.yyyy)> -o <owner> -m <contact-mail>"
  echo 
  exit 1
}

if [ $# -eq 0 ] || [ $1 == "--help" ]; then
  usage
fi

if [ -z $OS_PROJECT_NAME ] || [ $OS_PROJECT_NAME != "MISC" ]; then
  echo "You must source your OpenRC file for the MISC project before running this script. TNXBYE..."
  exit 1
fi

# ID for MISC-net
NTNUNET='f755ba0e-5b95-42c3-954a-137c43b53467'
GLOBALNET='e64530a7-3668-4aaa-845f-21f793e51afe'
SECGROUP='default'

while getopts i:f:k:n:t:e:o:m: option
do
  case "${option}" in
    i) IMAGE="${OPTARG}";;
    f) FLAVOR="${OPTARG}";;
    k) KEY="${OPTARG}";;
    n) NAME="${OPTARG}";;
    t) NETTYPE="${OPTARG}";;
    e) EXPIRE="${OPTARG}";;
    o) OWNER="${OPTARG}";;
    m) EMAIL="${OPTARG}";;
    *) exit 1
  esac
done
  
if [ -z "$IMAGE" ] || [ -z "$FLAVOR" ] || [ -z "$KEY" ] || [ -z "$NAME" ] || [ -z "$NETTYPE" ] || [ -z "$EXPIRE" ] || [ -z "$OWNER" ] || [ -z "$EMAIL" ]; then
  echo "One or more arguments missing"
  usage
fi

if [ "$NETTYPE" == "internal" ]; then
  NET="${NTNUNET}"
elif [ "$NETTYPE" == "global" ]; then
  NET="${GLOBALNET}"
else
  echo "Net type must be either 'global' or 'internal'"
  exit 1
fi

echo "Creating VM $NAME..."

openstack server create --image $IMAGE --flavor $FLAVOR --security-group "default" --key-name $KEY --nic net-id=$NET --property contact=$EMAIL --property expire=$EXPIRE --property owner="${OWNER}" $NAME --wait
