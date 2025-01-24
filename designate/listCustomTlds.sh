#!/usr/bin/env bash

openstack tld list --format json | jq -r '.[] | "\(.description) \(.name)"' | grep -v "Imported from publicsuffix.org" | awk '{ print $NF; }' | sort
