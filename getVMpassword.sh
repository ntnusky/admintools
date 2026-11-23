#!/usr/bin/env bash

VM=$1
SSHKEY=$2

OS_COMPUTE_API_VERSION=2.96 nova get-password $VM $SSHKEY
