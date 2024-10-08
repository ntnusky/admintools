#!/bin/bash
if [ $# -lt 1 ]; then
  echo "Usage: $0 <CSV-file formatted for createProject.sh>"
  echo "CSV-file should be PROJECT,user1,user2,...,userN"

  exit 1
fi

CSVFILE=$1
RED_BOLD="\e[1;31m"
GREEN_BOLD="\e[1;32m"
CLEAR="\e[0m"

if [ ! -e ldap_creds.txt ]; then
  echo -e "${RED_BOLD}Did not find LDAP credentials, usernames will not be verified! ${CLEAR}" >&2
  exit 0
fi

# Fila må inneholde:
# LDAP_BIND="<bind-dn>"
# LDAP_Pw="<password>"
. ldap_creds.txt


function ldap_lookup() {
  ldapsearch -H ldaps://at.ntnu.no -D "$LDAP_BIND" -w "$LDAP_PW" -b "ou=people,dc=ntnu,dc=no" "uid=$1" $2
}

STATUS=0
while IFS='' read -r line || [[ -n "$line" ]]; do
  project=$(echo $line | cut -d ',' -f 1)
  users=$(echo $line | cut -d ',' -f 2-)

  for u in $(echo $users | tr ',' ' '); do
    res=$(ldap_lookup $u uid | grep numEntries)
    if [ -z "$res" ]; then
      echo -e "${RED_BOLD}Invalid user ${CLEAR}$u in project $project" >&2
      STATUS=1
    else
      echo -e "${GREEN_BOLD}Valid user ${CLEAR}$u in project $project"
    fi
  done
done < $CSVFILE

exit $STATUS
