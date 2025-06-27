#!/bin/bash

MYDIR="$(dirname "$(realpath "$0")")"
. $MYDIR/testlib.bash

echo="echo [GLANCE]"
image="https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
filename=$(mktemp)

openstack image list &> /dev/null
if [[ $? -ne 0 ]]; then
  $echo "You are not logged in to an openstack cloud."
  exit 1
fi

while [[ ! -z $1 ]]; do
  if [[ $1 == 'create' ]]; then
    create='x'
  fi
  
  if [[ $1 == 'delete' ]]; then
    delete='x'
  fi
  shift
done

if [[ ! -z $create ]]; then
  starttime=$(date +%s)
  $echo "Download image to test with from the web"
  wget $image -O $filename || fail "$echo" "Could not download image"
  endtime=$(date +%s)
  $echo "Finished downloading image in $((endtime-starttime)) seconds"
  
  starttime=$(date +%s)
  $echo "Converting image to raw"
  qemu-img convert -f qcow2 -O raw $filename "${filename}.raw" || fail "$echo" \
      "Could not convert image"
  endtime=$(date +%s)
  $echo "converted image in $((endtime-starttime)) seconds"

  starttime=$(date +%s)
  $echo "Uploading image to glance"
  openstack image create --container-format bare --disk-format raw \
    --file "${filename}.raw" openstackTest.image --progress || fail "$echo" "could not uplad image"
  endtime=$(date +%s)
  $echo "uploaded image in $((endtime-starttime)) seconds"

  $echo "Deleting image from local disk"
  rm $filename 
  rm "${filename}.raw" 
fi

if [[ ! -z $delete ]]; then
  starttime=$(date +%s)
  $echo "Deleting image in glance"
  openstack image delete openstackTest.image || \
      fail "$echo" "could not delete image from glance"
  endtime=$(date +%s)
  $echo "Deleted in $((endtime-starttime)) seconds"
fi

exit 0
