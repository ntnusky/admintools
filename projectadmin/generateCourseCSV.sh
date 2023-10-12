#!/bin/bash

COURSE="$1"
SEMESTER="$2"

LDAP_URI="ldaps://at.ntnu.no"
LDAP_BASE="ou=groups,dc=ntnu,dc=no"

function usage() {
  echo "Usage: $0 <course-code> <semester>"
}

function getCourseMembers() {
  ldapsearch -LLL -H $LDAP_URI -D "" -b "$LDAP_BASE" cn="fs_${COURSE}_1" memberUid | grep -v '^dn:' | cut -d' ' -f2
}

if [ $# -ne 2 ]; then
  usage
  exit 1
fi

OUTFILE="${COURSE}_${SEMESTER}.csv"

echo "Genererer CSV for ${COURSE}_${SEMESTER}..."
for username in $(getCourseMembers) ; do
  echo "${COURSE}_${SEMESTER}_${username},${username}" >> $OUTFILE
done

if [ -e $OUTFILE ]; then
  echo "Ferdig. Genererte fila ${OUTFILE}"
else
  echo "Emnet ${COURSE} finnes ikke. Eventuelt er det ingen som tar det..."
  exit 1
fi
