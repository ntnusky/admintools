#!/bin/bash
orgimage=${1}
image='ubuntu-grid.qcow2'
rawimage='ubuntu-grid.raw'

if [ ! -f cuda.run ]; then
  echo "[ERROR] du mangler cuda.run i denne mappa"
  exit 1
fi

echo "Copying image"
cp $orgimage $image
echo "Upgrading packages"
virt-customize -a $image --update
echo "Installing packages"
virt-customize -a $image --install build-essential,dkms,libxml2-utils,libglvnd-core-dev,linux-generic-hwe-22.04
echo "Installing GRID-script"
virt-customize -a $image \
  --copy-in check-grid-driver.sh:/opt/ \
  --copy-in cuda.run:/opt/ \
  --copy-in cuda.sh:/etc/profile.d/ \
  --append-line '/etc/crontab:@reboot root bash /opt/check-grid-driver.sh'

echo "Converting to raw"
qemu-img convert -f qcow2 -O raw $image $rawimage
echo "Cleaning temporary files"
rm $image
