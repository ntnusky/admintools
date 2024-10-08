#!/bin/bash

if [[ -z $4 ]]; then
  echo "Usage: $0 <prefix> <instruction-set> <cpushares> public|private"
  echo
  echo "Prefix are usually one of:"
  echo " - gN for general purpose"
  echo " - pN for prioritized"
  echo " - sN for schavenger"
  echo
  echo "Instruction-set can be:"
  echo " - HW_CPU_X86_AESNI (gen1)"
  echo " - HW_CPU_X86_AVX (gen2)"
  echo " - HW_CPU_X86_AVX2 (gen3)"
  echo " - HW_CPU_X86_AVX512F (gen4)"
  echo " - HW_CPU_X86_AVX512VAES (gen5)"
  # Den her skulle virkelig ha vært noe AMX-flagg; for det er jo det vi vil ha.
  # Men dette virker som en work-around.
  echo " - HW_CPU_X86_AVX512IFMA (gen6)"
  echo
  echo "CPU Shares defines priority:"
  echo " - 1 for low priority"
  echo " - 8 for normal priority"
  echo " - 24 for high priority"
  exit 1
fi

prefix=$1
instructionSet=$2
cpushares=$3
visibility=$4
last=0

createFlavor() {
  echo '{'

  # Add basic properties
  echo "  \"Name\": \"$1\","
  echo "  \"CPU\": \"$2\","
  echo "  \"RAM\": \"$(($3*1024))\","
  echo "  \"Disk\": \"$4\","

  if [[ $cpushares -ne 0 ]]; then
    shares=$(($5*$2))
    echo "  \"quota:cpu_shares\": \"$shares\","
  fi

  # Set CPU-configuration
  if [[ $2 -gt 1 && $(($2%2)) -eq 0 ]]; then
    echo -n "  \"hw:cpu_cores\": $(($2/2)), "
    echo "\"hw:cpu_sockets\": 2, \"hw:cpu_threads\": 1,"
  fi

  # Add general-purpose compute tag.
  echo "  \"aggregate_instance_extra_specs:node_type\": \"general\"," 

  # Allow using the RNG
  echo -n "  \"hw_rng:allowed\": true, \"hw_rng:rate_bytes\": 24, "
  echo "\"hw_rng:rate_period\": 5000,"
  
  # Set the relevant traits to select correct instruction-sets.
  echo "  \"trait:$6\": \"required\","

  # Set visibility
  echo "  \"visibility\": \"$7\""

  if [[ $last -eq 0 ]]; then
    echo '},'
  else
    echo '}'
  fi
}

# Disk size and IOPS
disk="40"

echo '['

createFlavor "$prefix.1c1r" 1 1 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.1c2r" 1 2 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.1c3r" 1 3 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.1c4r" 1 4 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.2c1r" 2 1 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.2c2r" 2 2 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.2c3r" 2 3 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.2c4r" 2 4 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.2c6r" 2 6 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.2c8r" 2 8 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.4c2r" 4 2 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.4c3r" 4 3 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.4c4r" 4 4 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.4c8r" 4 8 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.4c16r" 4 16 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.4c32r" 4 32 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.4c64r" 4 64 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.6c4r" 6 4 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.6c8r" 6 8 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.6c16r" 6 16 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.6c32r" 6 32 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.6c64r" 6 64 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.8c16r" 8 16 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.8c32r" 8 32 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.8c64r" 8 64 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.12c24r" 12 24 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.12c48r" 12 48 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.12c96r" 12 96 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.16c32r" 16 32 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.16c64r" 16 64 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.16c128r" 16 128 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.20c40r" 20 40 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.20c80r" 20 80 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.20c160r" 20 160 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.24c48r" 24 48 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.24c96r" 24 96 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.24c192r" 24 192 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.32c64r" 32 64 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.32c128r" 32 128 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.32c256r" 32 256 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.64c64r" 64 64 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.64c128r" 64 128 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.64c256r" 64 256 $disk $cpushares $instructionSet $visibility

createFlavor "$prefix.72c64r" 72 64 $disk $cpushares $instructionSet $visibility
createFlavor "$prefix.72c128r" 72 128 $disk $cpushares $instructionSet $visibility
last=1
createFlavor "$prefix.72c256r" 72 256 $disk $cpushares $instructionSet $visibility


# Some larger flavors which only fits on our R650s
#createFlavor "$prefix.96c64r" 96 64 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.96c128r" 96 128 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.96c256r" 96 256 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.96c384r" 96 384 $disk $cpushares $instructionSet $visibility
#
#createFlavor "$prefix.112c16r" 112 16 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.112c32r" 112 32 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.112c64r" 112 64 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.112c128r" 112 128 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.112c256r" 112 256 $disk $cpushares $instructionSet $visibility
#createFlavor "$prefix.112c384r" 112 384 $disk $cpushares $instructionSet $visibility

echo ']'
