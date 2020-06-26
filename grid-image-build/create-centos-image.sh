#!/bin/bash
orgimage=${1}
image='centos-grid.qcow2'
rawimage='centos-grid.raw'

echo "Copying image"
cp $orgimage $image
echo "Upgrading packages"
virt-customize -a $image --update
echo "Installing epel-release"
virt-customize -a $image --install epel-release
echo "Installing packages"
virt-customize -a $image --install gcc,dkms,make,kernel-devel,cpp,glibc-devel,glibc-headers,kernel-headers,libmpc,mpfr
echo "Installing GRID-script"
virt-customize -a $image --copy-in check-grid-driver.sh:/opt/ --append-line '/etc/crontab:@reboot root bash /opt/check-grid-driver.sh'
echo "Re-labling selinux"
virt-customize -a $image --selinux-relabel

echo "Converting to raw"
qemu-img convert -f qcow2 -O raw $image $rawimage

echo "Cleaning temporary files"
rm $image
