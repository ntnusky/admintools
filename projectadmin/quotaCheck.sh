#!/bin/bash

set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

while getopts i:c:v:g:r:p: option; do
  case "${option}" in 
    i) instances=${OPTARG} ;;
    c) cores=${OPTARG} ;;
    r) ram=${OPTARG} ;;
    v) volumes=${OPTARG} ;;
    g) gigabytes=${OPTARG} ;;
    p) project=${OPTARG} ;;
  esac
done

if [[ -z $project ]]; then
  echo "Usage: $0 -p <project> [-c <cores>] [-r <GB RAM>]"
  echo
  echo "Parameters:"
  echo " -p <project>: Which project to check usage for"
  echo " -i <N>: Would a new quota with N instances be valid?"
  echo " -c <N>: Would a new quota with N CPUs be valid?"
  echo " -r <N>: Would a new quota with N GB RAM be valid?"
  echo " -v <N>: Would a new quota with N cinder volumes be valid?"
  echo " -g <N>: Would a new quota with N GB cinder be valid?"
  exit $EXIT_MISSINGARGS
fi

e=$EXIT_OK

. <(openstack limits show --project $project --absolute -f value | tr ' ' '=')

echo "Usage overview for $project:"
if [[ -z $instances || $totalInstancesUsed -le $instances ]]; then
  echo " - Instances: $totalInstancesUsed / $maxTotalInstances"
else
  echo " * Instances: $totalInstancesUsed / $maxTotalInstances"
  e=1
fi

if [[ -z $cores || $totalCoresUsed -le $cores ]]; then
  echo " - VCPUs:     $totalCoresUsed / $maxTotalCores"
else
  echo " * VCPUs:     $totalCoresUsed / $maxTotalCores"
  e=1
fi

if [[ -z $ram || $(($totalRAMUsed/1024)) -le $ram ]]; then
  echo " - RAM (GB):  $(($totalRAMUsed/1024)) / $(($maxTotalRAMSize/1024))"
else
  echo " * RAM (GB):  $(($totalRAMUsed/1024)) / $(($maxTotalRAMSize/1024))"
  e=1
fi

if [[ -z $volumes || $totalVolumesUsed -le $volumes ]]; then
  echo " - Volumes:   $totalVolumesUsed / $maxTotalVolumes"
else
  echo " * Volumes:   $totalVolumesUsed / $maxTotalVolumes"
  e=1
fi

if [[ -z $gigabytes || $totalGigabytesUsed -le $gigabytes ]]; then
  echo " - Volume GB: $totalGigabytesUsed / $maxTotalVolumeGigabytes"
else
  echo " * Volume GB: $totalGigabytesUsed / $maxTotalVolumeGigabytes"
  e=1
fi

exit $e
