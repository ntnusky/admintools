#!/bin/bash

EXIT_OK=0
EXIT_CONFIGERROR=1
EXIT_MISSINGARGS=2
EXIT_DEPENDENCY=3
EXIT_FORBIDDEN=4
EXIT_ERROR=5

function prereq() {
  err=0
  if [ ! $(which openstack) ]; then
    echo "openstack command missing"
    err=$EXIT_DEPENDENCY
  fi
  if [ ! $(which jq) ]; then
    echo "jq command missing"
    err=$EXIT_DEPENDENCY
  fi
  if [ ! $(which heat)  ]; then
    echo "heat client missing"
    err=$EXIT_DEPENDENCY
  fi
  if [ ! $(which pwgen) ]; then
    echo "pwgen is missing"
    err=$EXIT_DEPENDENCY
  fi

  if [ $err -ne 0 ]; then
    exit $err
  fi
}

function need_admin {
  if [ ! -z $OS_TENANT_NAME ] && [ $OS_TENANT_NAME != 'admin' ]; then
    echo "Needs to be authenticated as admin!"
    exit $EXIT_FORBIDDEN
  fi
  
  if [ ! -z $OS_PROJECT_NAME ] && [ $OS_PROJECT_NAME != 'admin' ]; then
    echo "Needs to be authenticated as admin!"
    exit $EXIT_FORBIDDEN
  fi
  
  if [ -z $OS_TENANT_NAME ] && [ -z $OS_PROJECT_NAME ]; then
    echo "Needs to be authenticated for for openstack"
    exit $EXIT_DEPENDENCY
  fi
}

function add_user {
  local project=$1
  local user=$2

  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)
  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)

  if [ $(openstack role assignment list --project $projectid --user $userid \
        --role member | wc -l) -eq 1 ]; then
    echo Adding $user to $project as member
    openstack role add --project $projectid --user $userid member
  fi
}

function remove_user {
  local project=$1
  local user=$2

  local userid=$(openstack user show $user -f value -c id 2> /dev/null) || \
  local userid=$(openstack user show $user -f value -c id --domain=NTNU 2> /dev/null)
  local projectid=$(openstack project show $project -f value -c id 2> /dev/null) || \
  local projectid=$(openstack project show $project -f value -c id --domain=NTNU 2> /dev/null)

  unset even
  for roleinherit in $(openstack role assignment list --project $projectid \
        --user $userid -f value -c Role -c Inherited); do
    if [[ -z $even ]]; then
      role=$roleinherit
      even=1
      continue
    else
      inherit=$roleinherit
      unset even
    fi

    if [[ $inherit == "True" ]]; then
      extra="--inherited"
    else
      extra=""
    fi

    echo "Removing the role $role for the user $user from the project $project"
    openstack role remove --project $projectid --user $userid $role $extra
  done
}

function box() { local t="$1xxxx";local c="${2:-=}"; echo "${t//?/$c}"; echo "$c $1 $c"; echo "${t//?/$c}"; }
