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

function gpuMessage() {
  username=$1
  floating_ip=$2
  cat << EOF
Hei!

Din GPU-vm er nå klar for bruk, og du kan logge inn via ssh til $username@$floating_ip med det nøkkelparet du har oppgitt. Din bruker er satt opp med passordløs sudo, slik at du kan installere alt du trenger på egenhånd. Siden du har sudo, betyr det at vår support stort sett begrenser seg til reinstall dersom du skulle finne på å ødelegge noe.

Nvidia-driver og CUDA er forhåndsinstallert. Det er viktig at du ikke endrer på eller oppgraderer driveren, da oppsettet er avhengig av nettopp denne versjonen for å fungere. Ønsker du en annen CUDA-versjon, er det mulig i gitte tilfeller. Dokumentasjon for dette finner du i lenken under.

Noen nyttige tips kan leses her: https://www.ntnu.no/wiki/display/skyhigh/Using+GPU+instances

Lykke til med arbeidet :-)

#####

Hi!

Your GPU VM is now ready for use, and you can login via ssh to $username@$floating_ip using the keypair you've provided. Your user is configured with passwordless sudo, so that you can install whatever you need yourself. Since you have sudo, our support will be limited to a reinstall in case you break something.

Nvidia driver and CUDA is pre-installed. It is very important that you don't change or upgrade the driver, since our setup requires exactly this version in order to function correctly. If you need a different CUDA version, that is possible in some given scenarios. Documentation for howto to do this can be found through the link below.

Some tips can be found here: https://www.ntnu.no/wiki/display/skyhigh/Using+GPU+instances

Good luck with you work :-)
EOF
}

function genericMessage() {
  username=$1
  floating_ip=$2

  cat << EOF
Hei!

VMen din er klar til bruk, og du kan logge inn via ssh til $username@$floating_ip, med det nøkkelparet du har sendt oss. Brukeren din har passordløs sudo, slik at du kan installere alt du trenger på egenhånd. Det betyr også at vår support stort sett begrenser seg til reinstall dersom du skulle finne på å ødelegge noe.


######

Hi!

Your VM is now ready for use. Login with ssh to $username@$floating_ip with the keypair you have provided us. Your user has passwordless sudo, and you can install whatever you want. This also means that our support is limited to a reinstall in the case that you break anything.
EOF
}

function printTopDeskMessage() {
  case_number=$1
  username=$2
  floating_ip=$3
  flavor=$4

  echo
  echo "============="
  echo "TOPDESK-TEKST"
  echo "============="
  echo "Lim dette inn i topdesksaken $case_number. Bruk språket som passer <3"
  echo "Lenke: https://hjelp.ntnu.no/tas/secure/incident?action=lookup&lookup=naam&lookupValue=$case_number"
  echo
  if isGPUflavor $flavor; then
    gpuMessage $username $floating_ip
  else
    genericMessage $username $floating_ip
  fi
}

function isGPUflavor() {
  flavor_id=$1

  # After Antelope, you get an access violation error for trying to list access_project_ids on a non-public flavor. Sending errors to devnull then.. =)
  props=$(openstack flavor show $flavor_id -f value -c properties 2> /dev/null)
  if [[ "$props" =~ VGPU ]]; then
    return 0
  else
    return 1
  fi
}

if [ $# -eq 0 ] || [ $1 == "--help" ]; then
  usage
fi

if [ -z $OS_PROJECT_NAME ] || [ $OS_PROJECT_NAME != "MISC" ]; then
  echo "You must source your OpenRC file for the MISC project."
  exit 1
fi

# IDs for MISC-net
declare -A networks
networks[SkyHiGh-internal]='f755ba0e-5b95-42c3-954a-137c43b53467'
networks[SkyHiGh-global]='e64530a7-3668-4aaa-845f-21f793e51afe'
networks[NTNU-IT-internal]='630212d4-764d-479a-8364-52e22e4d1e24'
networks[NTNU-IT-global]='367d094e-a80a-49f2-a84b-34493ab50cbd'
networks[TRD1-internal]='edb06423-a29d-49fe-9dc2-392a218081a6'
networks[TRD1-global]='1b466310-96a2-40c5-bf83-00a47d944138'

declare -A domains
domains[SkyHiGh]='vm.iik.ntnu.no'
domains[TRD1]='misc.iaas.ntnu.no'

NTNUNET=${networks["${OS_REGION_NAME}-internal"]}
GLOBALNET=${networks["${OS_REGION_NAME}-global"]}
SECGROUP='default'

if [ -z $NTNUNET ]; then
  echo "Could not find any networks for your Openstack region, $OS_REGION_NAME"
  exit 1
fi

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

if [[ ! $EXPIRE =~ ^[0-3][0-9]\.[0-1][0-9]\.20[0-9]{2}$ ]]; then
  echo "\"$EXPIRE\" does not look like a date on the format dd.mm.yyyy"
  exit 1
fi

if [ "$NETTYPE" == "internal" ]; then
  NET="${NTNUNET}"
  FIP=$(openstack floating ip create -f value -c floating_ip_address ntnu-internal)
elif [ "$NETTYPE" == "global" ]; then
  if [ "$OS_REGION_NAME" == "TRD1" ]; then
    extnet="ntnu-exposed"
  else
    extnet="ntnu-global"
  fi
  NET="${GLOBALNET}"
  FIP=$(openstack floating ip create -f value -c floating_ip_address $extnet)
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
  USERNAME=$(grep 'name:' $CONFIG | cut -d':' -f2 | tr -d ' ')
else
  USERNAME='##BRUKERNAVN##'
fi

# Print tekst til TopDesk
if [ -n ${domains[$OS_REGION_NAME]} ]; then
  FIP="${NAME}.${domains[$OS_REGION_NAME]}"
fi
printTopDeskMessage $TOPDESK $USERNAME $FIP $FLAVOR
