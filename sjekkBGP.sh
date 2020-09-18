#!/bin/bash

for speaker in $(openstack bgp speaker list -f value -c Name); do
  echo "DR-Agents for $speaker"
  openstack bgp speaker show dragents $speaker
done

echo "Tilgjengelige DR-Agents":
openstack network agent list --sort-column Host --agent-type bgp \
                              -c ID -c Host -c Alive -c State -c Binary
