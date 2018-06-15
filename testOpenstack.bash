#!/bin/bash

echo="echo [TESTOPENSTACK]"

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
  $echo "Misc create"
  testing/misc.bash create
  touch .openstackTest.misc

  $echo "Glance create"
  testing/glance.bash create
  touch .openstackTest.glance

  $echo "Neutron create"
  testing/neutron.bash create
  touch .openstackTest.neutron

  $echo "Nova create"
  testing/nova.bash create
  touch .openstackTest.nova

  $echo "Cinder create"
  testing/cinder.bash create
  touch .openstackTest.cinder
fi

if [[ ! -z $delete ]]; then
  if [[ -e .openstackTest.cinder ]]; then
    $echo "Cinder delete"
    testing/cinder.bash delete
    rm .openstackTest.cinder
  fi
  
  if [[ -e .openstackTest.nova ]]; then
    $echo "Nova delete"
    testing/nova.bash delete
    rm .openstackTest.nova
  fi
  
  if [[ -e .openstackTest.neutron ]]; then
    $echo "Neutron delete"
    testing/neutron.bash delete
    rm .openstackTest.neutron
  fi
  
  if [[ -e .openstackTest.glance ]]; then
    $echo "Glance delete"
    testing/glance.bash delete
    rm .openstackTest.glance
  fi
  
  if [[ -e .openstackTest.misc ]]; then
    $echo "Misc delete"
    testing/misc.bash delete
    rm .openstackTest.misc
  fi
fi
