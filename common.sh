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
