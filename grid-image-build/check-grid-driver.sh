#!/bin/bash

# Fetches the Nvidia GRID driver from our local repo, either if the driver is 
# not present, or if there is a new version available

# This script requires the OS to have tools for building the driver installed.
# For CentOS:
# epel-release gcc dkms make kernel-devel cpp glibc-devel glibc-headers kernel-headers libmpc mpfr
# For Ubuntu:
# build-essential dkms libxml2-utils

baseurl='http://rpm.iik.ntnu.no/nvidia'
available_driver_version=$(curl -s ${baseurl}/grid-driver-version.txt)
driver_url="${baseurl}/grid-driver.run"
gridd_conf="${baseurl}/gridd.conf"

function removeNouveau() {
  sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& rd.driver.blacklist=nouveau nouveau.modeset=0/' /etc/default/grub
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& rd.driver.blacklist=nouveau nouveau.modeset=0/' /etc/default/grub
  echo ">>>> /etc/default/grub:"
  cat /etc/default/grub | grep nouveau
}

if [ $(which nvidia-smi) ]; then
  installed_driver_version=$(nvidia-smi -q -x | xmllint --xpath '/nvidia_smi_log/driver_version/text()' -)
else
  installed_driver_verison=''
fi

if [ "$installed_driver_version" != "$available_driver_version" ]; then
  echo "No driver found, or there is a new version available. Installing/upgrading"

  # Remove nouveau driver
  if grep -qo "rd.driver.blacklist=nouveau" /etc/default/grub
  then
    echo "Nothing to do for Nouveau driver"
  else
      rmmod nouveau
      removeNouveau
    if grep -qi ubuntu /etc/os-release; then
      echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf
      echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
      update-initramsfs -u
    elif grep -qi centos /etc/os-release; then
      echo "blacklist nouveau" | tee /lib/modprobe.d/blacklist-nouveau.conf
      mv /boot/initramfs-$(uname -r).img /boot/initramfs-$(uname -r).img.bkp
      dracut /boot/initramfs-$(uname -r).img $(uname -r)
    fi
  fi

  curl -s -O $driver_url
  sh grid-driver.run -s --dkms --no-cc-version-check

  if [ ! -d /etc/nvidia ]; then
    mkdir -p /etc/nvidia
  fi

  curl -s -o /etc/nvidia/gridd.conf $gridd_conf

  rm grid-driver.run

  reboot
else
  echo "Driver is up to date!"
fi

