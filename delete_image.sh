#!/bin/bash

id=${1}

openstack image set --unprotected $id
openstack image delete $id
