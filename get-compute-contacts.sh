#!/bin/bash

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <compute-host>"
  exit 1
fi

host=$1
projects=()

echo "For each server, get the project ID" >&2
for server in $(openstack server list --all --host $host -f value -c ID); do
  project=$(openstack server show $server -f value -c project_id)
  projects=($project ${projects[@]})
  echo -n '#' >&2
done
echo >&2

users=()
groups=()
echo "Retrieving usernames and groups affected" >&2
for project in $(echo  ${projects[@]} | tr ' ' '\n' | sort | uniq); do
  for member in $(openstack role assignment list --project $project --names --role _member_ -f value -c User -c Group | grep NTNU | cut -f 1 -d '@'); do
    if [[ $member =~ _ ]]; then # A group will always contain an underscore. Usernames will never have one
      groups=($member ${groups[@]})
    else
      users=($member ${users[@]})
    fi
  done

  echo -n '#' >&2
done
echo >&2

echo "Fetching usernames from groups..."
for group in $(echo ${groups[@]} | tr ' ' '\n' | sort | uniq); do
  members="$(ldapsearch -LLL -x -H ldaps://at.ntnu.no -b "ou=Groups,dc=ntnu,dc=no"  cn="$group" memberUid | grep memberUid | awk '{print $2}' | tr '\n' ' ')"
  users=($members ${users[@]})
done

echo "Retrieving emails" >&2
for user in $(echo  ${users[@]} | tr ' ' '\n' | sort | uniq); do
  openstack user show --domain NTNU $user -f value -c email
  echo -n '' >&2
done
echo >&2
