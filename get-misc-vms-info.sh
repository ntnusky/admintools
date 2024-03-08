#!/bin/bash

. $(dirname $0)/common.sh

prereq

function usage() {
  echo
  echo "Get the key info from the VMs in the MISC-project "
  echo "with an expiry date of the given year."
  echo
  echo "USAGE: ${0} <YYYY>"
  echo
}

if [ "${OS_PROJECT_NAME}" != "MISC" ] && [ "${OS_PROJECT_NAME}" != "admin" ]; then
  echo "ERROR: You either need to be authenticated in the MISC or the admin project"
  exit $EXIT_CONFIGERROR
fi

if [ $# -ne 1 ]; then
  usage
  exit $EXIT_MISSINGARGS
fi

YEAR="$1"
TODAY=$(date +%Y%m%d)
NOW=$(date +%H%M%S)
OUTFILE="MISC-$YEAR-${TODAY}_${NOW}.csv"

if [ "${OS_PROJECT_NAME}" == "admin" ]; then
  project="--project MISC"
else
  project=""
fi

while read vm; do
  vm_name=$(echo $vm | cut -d',' -f1 | tr -d '"')
  vm_props="$(echo $vm | cut -d',' -f2- | tr -d '"' | tr "'" '"')"

  expire=$(echo $vm_props | jq -r .expire)
  if [[ "${vm_props}" =~ topdesk ]]; then
    contact=$(echo $vm_props | jq -r .topdesk)
  else
    contact=$(echo $vm_props | jq -r .contact)
  fi

  echo "Found VM: $vm_name | expiry: $expire | contact: $contact"
  echo "\"$vm_name\",\"$contact\",\"$expire\"" >> $OUTFILE
done < <(openstack server list -f csv -c Name -c Properties $project | grep $YEAR)

echo "Created CSV file $OUTFILE - ready to paste into excel <3"
