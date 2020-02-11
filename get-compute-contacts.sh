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
echo "Retrieving usernames affected" >&2
for project in $(echo  ${projects[@]} | tr ' ' '\n' | sort | uniq); do
  for user in $(openstack role assignment list --project $project --names --role _member_ --effective -f value -c User | grep NTNU | cut -f 1 -d '@'); do
    users=($user ${users[@]})
  done
  echo -n '#' >&2
done
echo >&2

echo "Retrieving emails" >&2
for user in $(echo  ${users[@]} | tr ' ' '\n' | sort | uniq); do
  openstack user show --domain NTNU $user -f value -c email
  echo -n '#' >&2
done
echo >&2

