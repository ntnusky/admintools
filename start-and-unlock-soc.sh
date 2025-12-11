#! /bin/bash

if [[ -z $1 ]]; then
  echo "Usage: $0 <vm-UUID>"
  exit 1
fi

./stop-and-lock-soc.sh $1 unlock
