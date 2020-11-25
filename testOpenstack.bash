#!/bin/bash

echo="echo [TESTOPENSTACK]"

U="${OS_REGION_NAME}_${OS_PROJECT_NAME}"

while [[ ! -z $1 ]]; do
  if [[ $1 == 'create' ]]; then
    create='x'
  fi

  if [[ $1 == 'delete' ]]; then
    delete='x'
  fi
  shift
done

set -e

if [[ ! -z $create ]]; then
  if [[ ! -e .openstackTest.misc ]]; then
    $echo "Misc create"
    testing/misc.bash create
    touch .openstackTest.${U}.misc
  fi

  if [[ ! -e .openstackTest.glance ]]; then
    $echo "Glance create"
    testing/glance.bash create
    touch .openstackTest.${U}.glance
  fi

  if [[ ! -e .openstackTest.neutron ]]; then
    $echo "Neutron create"
    testing/neutron.bash create
    touch .openstackTest.${U}.neutron
  fi

  if [[ ! -e .openstackTest.nova ]]; then
    $echo "Nova create"
    testing/nova.bash create
    touch .openstackTest.${U}.nova
  fi

  if [[ ! -e .openstackTest.cinder ]]; then
    $echo "Cinder create"
    testing/cinder.bash create
    touch .openstackTest.${U}.cinder
  fi
fi

if [[ ! -z $delete ]]; then
  if [[ -e .openstackTest.${U}.cinder ]]; then
    $echo "Cinder delete"
    testing/cinder.bash delete
    rm .openstackTest.${U}.cinder
  fi
  
  if [[ -e .openstackTest.${U}.nova ]]; then
    $echo "Nova delete"
    testing/nova.bash delete
    rm .openstackTest.${U}.nova
  fi
  
  if [[ -e .openstackTest.${U}.neutron ]]; then
    $echo "Neutron delete"
    testing/neutron.bash delete
    rm .openstackTest.${U}.neutron
  fi
  
  if [[ -e .openstackTest.${U}.glance ]]; then
    $echo "Glance delete"
    testing/glance.bash delete
    rm .openstackTest.${U}.glance
  fi
  
  if [[ -e .openstackTest.${U}.misc ]]; then
    $echo "Misc delete"
    testing/misc.bash delete
    rm .openstackTest.${U}.misc
  fi
fi
