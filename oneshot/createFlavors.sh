openstack flavor create --vcpus 1 --ram 256 --disk 5 \
  --property quota:disk_read_iops_sec='150' \
  --property quota:disk_write_iops_sec='150' t1.tiny

openstack flavor create --vcpus 1 --ram 512 --disk 5 \
  --property quota:disk_read_iops_sec='150' \
  --property quota:disk_write_iops_sec='150' t1.small

openstack flavor create --vcpus 1 --ram 768 --disk 10 \
  --property quota:disk_read_iops_sec='150' \
  --property quota:disk_write_iops_sec='150' t1.medium

openstack flavor create --vcpus 2 --ram 1024 --disk 10 \
  --property quota:disk_read_iops_sec='150' \
  --property quota:disk_write_iops_sec='150' t1.large

openstack flavor create --vcpus 2 --ram 1536 --disk 10 \
  --property quota:disk_read_iops_sec='150' \
  --property quota:disk_write_iops_sec='150' t1.xlarge

openstack flavor create --vcpus 1 --ram 2048 --disk 20 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' m1.tiny

openstack flavor create --vcpus 1 --ram 4096 --disk 30 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' m1.small

openstack flavor create --vcpus 2 --ram 8192 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' m1.medium

openstack flavor create --vcpus 4 --ram 16384 --disk 50 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' m1.large

openstack flavor create --vcpus 8 --ram 32768 --disk 50 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' m1.xlarge

openstack flavor create --vcpus 8 --ram 65536 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' r1.tiny

openstack flavor create --vcpus 12 --ram 98304 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' r1.small

openstack flavor create --vcpus 16 --ram 131072 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' r1.medium

openstack flavor create --vcpus 24 --ram 196608 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' r1.large

openstack flavor create --vcpus 32 --ram 262144 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' r1.xlarge

openstack flavor create --vcpus 8 --ram 16384 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' c1.tiny

openstack flavor create --vcpus 12 --ram 24576 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' c1.small

openstack flavor create --vcpus 16 --ram 32768 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' c1.medium

openstack flavor create --vcpus 24 --ram 49152 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' c1.large

openstack flavor create --vcpus 32 --ram 65536 --disk 40 \
  --property quota:disk_read_iops_sec='300' \
  --property quota:disk_write_iops_sec='300' c1.xlarge
