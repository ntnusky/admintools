openstack flavor create --vcpus 12 --ram 49152 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' l1.tiny

openstack flavor create --vcpus 16 --ram 65536 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' l1.small

openstack flavor create --vcpus 20 --ram 81920 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' l1.medium

openstack flavor create --vcpus 24 --ram 98304 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' l1.large

openstack flavor create --vcpus 32 --ram 131072 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' l1.xlarge
