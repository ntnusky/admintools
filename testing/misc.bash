#!/bin/bash

MYDIR="$(dirname "$(realpath "$0")")"
. $MYDIR/testlib.bash

echo="echo [MISC]"

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

if [[ -e ~/.ssh/id_ed25519.pub ]]; then
  key="~/.ssh/id_ed25519.pub"
elif [[ -e ~/.ssh/id_rsa.pub ]]; then
  key="~/.ssh/id_rsa.pub"
else
  $echo "Could not find a SSH public key"
  exit 1
fi

if [[ ! -z $create ]]; then
  starttime=$(date +%s)
  $echo "Uploading your SSH public key"
  openstack keypair create --public-key $key openstackTest || \
      fail "$echo" "Could not upload public-key."
  $echo "Creating a security group, and adding rules for SSH and ICMP"
  openstack security group create openstackTest.group || \
      fail "$echo" "Could not upload create security-group."
  openstack security group rule create --remote-ip 0.0.0.0/0 --dst-port 22 \
      --protocol tcp --ingress openstackTest.group || \
      fail "$echo" "Could not create SSH rule."
  openstack security group rule create --remote-ip 0.0.0.0/0 \
      --protocol icmp --ingress openstackTest.group || \
      fail "$echo" "Could not create ICMP rule."
  endtime=$(date +%s)
  s=$((endtime-starttime))
  $echo "Finished uploading key and creating security-group in ${s} seconds"
fi

if [[ ! -z $delete ]]; then
  starttime=$(date +%s)
  $echo "Deleting the SSH key"
  openstack keypair delete openstackTest || \
      fail "$echo" "Could not delete public-key."
  $echo "Deleting the security-group"
  openstack security group delete openstackTest.group || \
      fail "$echo" "Could not delete security-group" 
  endtime=$(date +%s)
  s=$((endtime-starttime))
  $echo "Finished deleting key and security group in ${s} seconds"
fi

exit 0
