#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

inputFile="${1}"

if [ $# -ne 1 ]; then
  echo "This script will remove the KEEP tag on the given projects in the supplied text file"
  echo "The file is expected to have a projectname on each line"
  echo "The projects in the file will now be be possible to delete with our scripts"
  echo ""
  echo "Usage $0: <filename>"
  exit $EXIT_MISSINGARGS
fi

while read -r projectName; do
  ./removeKeepTag.sh $projectName
done < "$inputFile"
