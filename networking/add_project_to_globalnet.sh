#!/bin/bash

project="${1}"

globalnet=$(openstack network show ntnu-global -f value -c id)
openstack network rbac create --target-project $project \
    --target-project-domain NTNU --type network --action access_as_external \
    $globalnet
