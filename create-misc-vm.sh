#!/bin/bash

function usage() {
  echo
  echo "This script creates an instance in the MISC project, with useful "
  echo "metadata attached. Only the default security group will be attached"
  echo
  echo -n "USAGE: ${0} -i <image-id> -f <flavor-id|flavor-name> -k <key-name> "
  echo -n "-n <instance-name> -t <global|internal> -e <expiredate (dd.mm.yyyy)> "
  echo "-o <owner> -m <contact-mail> [-v <size-of-boot-volume>] [-s TOPdesk-saksnummer] [-c cloud-config-file]"
  echo 
  exit 1
}

function printTopDeskMessage() {
  case_number=$1
  username=$2
  floating_ip=$3

  echo
  echo "============="
  echo "TOPDESK-TEKST"
  echo "============="
  echo "Lim dette inn i topdesksaken $case_number. Bruk språket som passer <3"
  echo "Lenke: https://hjelp.ntnu.no/tas/secure/incident?action=lookup&lookup=naam&lookupValue=$case_number"
  echo
  cat << EOF
Hei!

VMen din er klar til bruk, og du kan logge inn via ssh til $username@$floating_ip, med det nøkkelparet du har sendt oss. Brukeren din har passordløs sudo, slik at du kan installere alt du trenger på egenhånd. Det betyr også at vår support stort sett begrenser seg til reinstall dersom du skulle finne på å ødelegge noe.

######

Hi!

Your VM is now ready for use. Login with ssh to $username@$floating_ip with the keypair you have provided us. Your user has passwordless sudo, and you can install whatever you want. This also means that our support is limited to a reinstall in the case that you break anything.
EOF
}

if [ $# -eq 0 ] || [ $1 == "--help" ]; then
  usage
fi

if [ -z $OS_PROJECT_NAME ] || [ $OS_PROJECT_NAME != "MISC" ]; then
  echo "You must source your OpenRC file for the MISC project."
  exit 1
fi

# ID for MISC-net
NTNUNET='f755ba0e-5b95-42c3-954a-137c43b53467'
GLOBALNET='e64530a7-3668-4aaa-845f-21f793e51afe'
SECGROUP='default'

while getopts i:f:k:n:t:e:o:m:v:s:c: option
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
    v) VOLUMESIZE="${OPTARG}";;
    s) TOPDESK="${OPTARG}";;
    c) CONFIG="${OPTARG}";;
    *) exit 1
  esac
done
  
if [ -z "$IMAGE" ] || [ -z "$FLAVOR" ] || [ -z "$KEY" ] || [ -z "$NAME" ] || \
    [ -z "$NETTYPE" ] || [ -z "$EXPIRE" ] || [ -z "$OWNER" ] || [ -z "$EMAIL" ]
    then
  echo "One or more arguments missing"
  usage
fi

if [ "$NETTYPE" == "internal" ]; then
  NET="${NTNUNET}"
  FIP=$(openstack floating ip create -f value -c floating_ip_address ntnu-internal)
elif [ "$NETTYPE" == "global" ]; then
  NET="${GLOBALNET}"
  FIP=$(openstack floating ip create -f value -c floating_ip_address ntnu-global)
else
  echo "Net type must be either 'global' or 'internal'"
  exit 1
fi

if [ -z $VOLUMESIZE ]; then
  volume=""
else
  volume="--boot-from-volume $VOLUMESIZE"
fi

if [ -z $TOPDESK ]; then
  topdesk=""
else
  topdesk="--property topdesk=$TOPDESK"
fi

if [ -z $CONFIG ]; then
  config=""
else
  config="--user-data $CONFIG"
fi

echo "Creating VM $NAME..."

openstack server create --image $IMAGE --flavor $FLAVOR \
        --security-group "default" --key-name $KEY --nic net-id=$NET \
        $volume \
        --property contact=$EMAIL --property expire=$EXPIRE \
        --property owner="${OWNER}" $topdesk $config $NAME --wait

openstack server add floating ip $NAME $FIP

if [ -n "${volume}" ]; then
  echo "Marking root volume as 'delete on termination'"
  volume_id=$(openstack server show -f json -c volumes_attached $NAME | jq -r .volumes_attached[0].id)
  openstack server volume update --delete-on-termination $NAME $volume_id
fi

if [ -n "${config}" ]; then
  # Drar ut brukernavn fra cloud-init-data
  NAME=$(grep 'name:' $CONFIG | cut -d':' -f2 | tr -d ' ')
else
  NAME='##BRUKERNAVN##'
fi

# Print tekst til TopDesk
printTopDeskMessage $TOPDESK $NAME $FIP
