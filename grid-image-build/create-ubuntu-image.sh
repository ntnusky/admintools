#!/bin/bash
orgimage=${1}
image='ubuntu-grid.qcow2'
rawimage='ubuntu-grid.raw'

echo "Copying image"
cp $orgimage $image
echo "Adding deb-file for CUDA repo"
virt-customize -a $image --run-command 'wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.1-1_all.deb -O /tmp/cuda-keyring.deb'
virt-customize -a $image --run-command 'dpkg -i /tmp/cuda-keyring.deb'
echo "Upgrading packages"
virt-customize -a $image --update
echo "Installing packages"
virt-customize -a $image --install build-essential,dkms,libxml2-utils,libglvnd-core-dev,cuda-toolkit-12-2,libcudnn8,libcudnn8-dev
echo "Setting correct timezone"
virt-customize -a $image --timezone Europe/Oslo
echo "Installing GRID-script"
virt-customize -a $image \
  --copy-in check-grid-driver.sh:/opt/ \
  --copy-in cuda.sh:/etc/profile.d/ \
  --append-line '/etc/crontab:@reboot root bash /opt/check-grid-driver.sh'

echo "Converting to raw"
qemu-img convert -f qcow2 -O raw $image $rawimage
echo "Cleaning temporary files"
rm $image
