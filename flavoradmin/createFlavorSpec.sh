#!/bin/bash

createFlavor() {
  echo '{'

  # Add basic properties
  echo "  \"Name\": \"$1\","
  echo "  \"CPU\": \"$2\","
  echo "  \"RAM\": \"$3\","
  echo "  \"Disk\": \"$4\","

  # Set CPU-configuration
  if [[ $2 -gt 1 && $(($2%2)) -eq 0 ]]; then
    echo -n "  \"hw:cpu_cores\": $(($2/2)), "
    echo "\"hw:cpu_sockets\": 2, \"hw:cpu_threads\": 1,"
  fi

  if [[ $5 -ne '-1' ]]; then
    # Define IOPS-limits
    echo "  \"quota:disk_read_iops_sec\": $5, \"quota:disk_write_iops_sec\": $5," 
  fi

  # Add general-purpose compute tag.
  echo "  \"aggregate_instance_extra_specs:node_type\": \"general\"," 

  # Allow using the RNG
  echo -n "  \"hw_rng:allowed\": true, \"hw_rng:rate_bytes\": 24, "
  echo "\"hw_rng:rate_period\": 5000,"

  # Set visibility
  echo "  \"visibility\": \"$6\""

  echo '},'
}

echo '['

# Generate t-series
createFlavor "t1.tiny"   1 256  40 150 public
createFlavor "t1.small"  1 512  40 150 public
createFlavor "t1.medium" 1 768  40 150 public
createFlavor "t1.large"  2 1024 40 150 public
createFlavor "t1.xlarge" 2 1536 40 150 public

# Generate m-series 
i=0
cores=(1 2 2 4 8)
for s in tiny small medium large xlarge; do
  if [[ $i -lt 2 ]]; then ram=$((${cores[$i]}*2048));
  else ram=$((${cores[$i]}*4096)); fi
  createFlavor "m1.${s}" ${cores[$i]} $ram 40 300 public
  createFlavor "m1.io1.${s}" ${cores[$i]} $ram 40 600 private
  createFlavor "m1.io2.${s}" ${cores[$i]} $ram 40 1200 private
  createFlavor "m1.ix.${s}" ${cores[$i]} $ram 40 -1 private
  ((i++))
done

# Generate l-series
i=0
cores=(12 16 20 24 32 64)
for s in tiny small medium large xlarge 2xlarge; do
  createFlavor "l1.${s}" ${cores[$i]} $((${cores[$i]}*4096)) 40 300 public
  createFlavor "l1.io1.${s}" ${cores[$i]} $((${cores[$i]}*4096)) 40 600 private
  createFlavor "l1.io2.${s}" ${cores[$i]} $((${cores[$i]}*4096)) 40 1200 private
  createFlavor "l1.ix.${s}" ${cores[$i]} $((${cores[$i]}*4096)) 40 -1 private
  ((i++))
done

# Generate c and r-series
i=0
cores=(8 12 16 24 32)
for s in tiny small medium large xlarge; do
  createFlavor "c1.${s}" ${cores[$i]} $((${cores[$i]}*2048)) 40 300 public
  createFlavor "c1.io1.${s}" ${cores[$i]} $((${cores[$i]}*2048)) 40 600 private
  createFlavor "c1.io2.${s}" ${cores[$i]} $((${cores[$i]}*2048)) 40 1200 private
  createFlavor "c1.ix.${s}" ${cores[$i]} $((${cores[$i]}*2048)) 40 -1 private
  createFlavor "r1.${s}" ${cores[$i]} $((${cores[$i]}*8192)) 40 300 public
  createFlavor "r1.io1.${s}" ${cores[$i]} $((${cores[$i]}*8192)) 40 600 private
  createFlavor "r1.io2.${s}" ${cores[$i]} $((${cores[$i]}*8192)) 40 1200 private
  createFlavor "r1.ix.${s}" ${cores[$i]} $((${cores[$i]}*8192)) 40 -1 private
  ((i++))
done

echo ']'
