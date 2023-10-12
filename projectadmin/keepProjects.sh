#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

inputFile="${1}"

if [ $# -ne 1 ]; then
  echo "This script will set a tag named KEEP on the given projects in the supplied text file"
  echo "The file is expected to have a projectname on each line"
  echo "That tag will be respected by the deleteProjectGrep.sh and the deleteProject.sh scripts"
  echo ""
  echo "Usage $0: <filename>"
  exit $EXIT_MISSINGARGS
fi

while read -r projectName; do
  ./keepProject.sh $projectName
done < "$inputFile"
