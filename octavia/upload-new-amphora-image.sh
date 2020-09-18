#!/bin/bash
set -e

. ../common.sh
need_admin

newimage=$1

project=$(openstack project show services -f value -c id)
title=$(basename $newimage .raw)
oldImageID=$(openstack image list -f value -c ID --tag amphora)

echo "Uploading image to glance:"
openstack image create --file $newimage --private --project $project \
                       --tag amphora $title

echo "Removing amphora-tag from old image"
openstack image unset --tag amphora $oldImageID
