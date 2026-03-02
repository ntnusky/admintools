#!/usr/bin/env bash

for project in $(openstack project list -f value -c Name --domain NTNU --sort-column Name); do
  users=$(openstack role assignment list -f value -c User --project $project)

  if [[ -n $users ]]; then # Vi har brukere, da trenger vi ikke sjekke mer
    continue
  else
    groups=$(openstack role assignment list -f value -c Group --names --project $project | sed -r '/^\s*$/d')
    if [[ -z $groups ]]; then
      echo "$project: No users, no groups";
    else
      for group in "$groups"; do
        group=${group/"@NTNU"/""}
        groupMembers=$(~/bin/fetchGroupMembers.sh $group)
        if [[ -z $groupMembers ]]; then
          echo "$project: $group has access, but is empty"
        fi
      done
    fi
  fi
done
