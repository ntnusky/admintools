#!/bin/bash

function usage() {
  echo "Usage: $0: <admin|service> <skylow|skyhigh>"
  exit 1
}

typ="${1}"
environment="${2}"

if [ $# -ne 2 ]; then
  usage
fi

if [ "$typ" != "admin" ] &&  [ "$typ" != "service" ]; then
  echo "[ERROR] type is wrong: $typ"
  usage
elif [ "$environment" != "skyhigh" ] && [ "$environment" != "skylow" ]; then
  echo "[ERROR] environment is wrong: $environment"
  usage
fi

curl -s "http://${typ}lb.${environment}.iik.ntnu.no:9000" | grep -oE "${typ}lb[[:digit:]]" | head -n1
