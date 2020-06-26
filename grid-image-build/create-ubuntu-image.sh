#!/bin/bash
orgimage=${1}
image='ubuntu-grid.qcow2'
rawimage='ubuntu-grid.raw'

echo "Copying image"
cp $orgimage $image
echo "Upgrading packages"
virt-customize -a $image --update
echo "Installing packages"
virt-customize -a $image --install build-essential,dkms
echo "Installing GRID-script"
virt-customize -a $image --copy-in check-grid-driver.sh:/opt/ --append-line '/etc/crontab:@reboot root bash /opt/check-grid-driver.sh'

echo "Converting to raw"
qemu-img convert -f qcow2 -O raw $image $rawimage
echo "Cleaning temporary files"
rm $image
