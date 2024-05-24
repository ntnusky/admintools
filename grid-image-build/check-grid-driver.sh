#!/bin/bash

# Fetches the Nvidia GRID driver from our local repo, either if the driver is 
# not present, or if there is a new version available

# This script requires the OS to have tools for building the driver installed.
# For Ubuntu:
# build-essential dkms libxml2-utils

baseurl='http://rpm.iik.ntnu.no/nvidia'
available_driver_version=$(curl -s ${baseurl}/grid-driver-version.txt)
driver_url="${baseurl}/grid-driver.deb"
gridd_conf="${baseurl}/gridd.conf"
gridd_token="${baseurl}/gridd.tok"
cuda_installer="/opt/cuda.run"
logfile="/var/log/grid-install.log"

function log() {
  echo "[$(date '+%F %T')] - $1" >> $logfile
}

function removeNouveau() {
  sed -i 's/GRUB_CMDLINE_LINUX="[^"]*/& rd.driver.blacklist=nouveau nouveau.modeset=0/' /etc/default/grub
  sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="[^"]*/& rd.driver.blacklist=nouveau nouveau.modeset=0/' /etc/default/grub
  echo ">>>> /etc/default/grub:"
  cat /etc/default/grub | grep nouveau
}

function installCuda() {
  log "Installing CUDA"
  sh $cuda_installer --silent --toolkit --samples
  rm $cuda_installer

  for patch in $(ls /opt/cuda_patch*); do
    log "Installing CUDA patches"
    /opt/$patch --silent --toolkit --samples
    rm $patch
  done
  log "CUDA installed"
}

# First of all: Do we even have a Nvidia device available?
if [ -z "$(lspci | grep -i nvidia)" ]; then
  log "No Nvidia device detected. Exiting"
  exit 0
fi

# Check if the Nvidia driver has failed for some reason
if [ $(which nvidia-smi) ] && ! nvidia-smi > /dev/null; then
  log "Nvidia driver is broken, and manual troubleshooting is needed. Exiting"
  exit 1
fi

if [ $(which nvidia-smi) ]; then
  installed_driver_version=$(nvidia-smi -q -x | xmllint --xpath '/nvidia_smi_log/driver_version/text()' -)
else
  installed_driver_version=''
fi

if [ "$installed_driver_version" != "$available_driver_version" ]; then
  log "No driver found, or there is a new version available. Installing/upgrading"
  log "Installing driver version $available_driver_version. Old version was: '$installed_driver_version'"

  # Remove nouveau driver
  if grep -qo "rd.driver.blacklist=nouveau" /etc/default/grub; then
    log "Nothing to do for Nouveau driver"
  else
    log "Removing Nouveau driver"
    rmmod nouveau
    removeNouveau
    echo blacklist nouveau > /etc/modprobe.d/blacklist-nvidia-nouveau.conf
    echo options nouveau modeset=0 >> /etc/modprobe.d/blacklist-nvidia-nouveau.conf
    update-initramfs -u
  fi

  log "Fetching driver from repo"
  curl -s -O $driver_url
  log "Installing driver"
  apt -y -o Dpkg::Options::="--force-confold" install ./grid-driver.deb
  res=$?

  if [ ! -d /etc/nvidia ]; then
    log "Creating /etc/nvidia"
    mkdir -p /etc/nvidia
  fi

  if [ ! -d /etc/nvidia/ClientConfigToken ]; then
    log "Creating /etc/nvidia/ClientConfigToken"
    mkdir -p /etc/nvidia/ClientConfigToken
  fi

  log "Fetching configuration from repo"
  curl -s -o /etc/nvidia/gridd.conf $gridd_conf
  curl -s -o /etc/nvidia/ClientConfigToken/gridd.tok $gridd_token

  rm grid-driver.deb

  if [ ! -e /usr/local/cuda ]; then
    installCuda
  fi

  if [ $res -eq 0 ]; then
    log "Driver install successful. Rebooting"
    reboot
  else
    log "Installation of Nvidia-driver failed. Check log-files"
    exit 1
  fi
else
  log "Driver is up to date!"
fi
