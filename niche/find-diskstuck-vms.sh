#!/bin/bash

for id in $(openstack server list --all --status ACTIVE -f value -c ID)
do
  hung=$(openstack console log show $id 2> /dev/null | \
      grep '/proc/sys/kernel/hung_task_timeout_secs" disables this message' -c)
  if [[ $hung -ne 0 ]]; then
    echo $id
  fi
done
