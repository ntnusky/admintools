#!/bin/bash

function usage() {
  echo
  echo "This script iterates through HA-routers and ensures that they all are"
  echo "scheduled to a sufficient amount of L3-agents."
  echo
  echo "Usage: ${0} [-a agent1,agent2] [-h] [-i input-file.txt] [-r no_routers]"
  echo
  echo "Options:"
  echo " - a: A comma-separated list of l3-agents to schedule routers to. It"
  echo "      defaults to all active l3-agents if nothing is supplied."
  echo " - h: Display (this) help-text"
  echo " - i: An input-file of router-ID's to verify. If not supplied all"
  echo "      HA-routers will be checked."
  echo " - n: How many agents each HA-router should be scheduled to. Defaults"
  echo "      to 3 agents."
  echo 
  exit 1
}

NOAGENTS=3

while getopts a:hi:r: option
do
  case "${option}" in
    a) AGENTLIST="${OPTARG}";;
    h) HELP=1;;
    i) INPUT="${OPTARG}";;
    n) NOAGENTS="${OPTARG}";;
    *) exit 1
  esac
done

if [[ ! -z $HELP ]]; then
  usage
fi

# Create an assoc-array where the key is the agents hostnames, and the value is
# the agents ID. Only collect agents that is alive and enabled.
declare -A AGENTIDS
agentlist=$(openstack network agent list --agent-type l3 -f json)
for host in $(echo $agentlist | jq -r '.[].Host'); do
  alive=$(echo $agentlist | jq -r ".[] | select(.Host == \"${host}\").Alive")
  state=$(echo $agentlist | jq -r ".[] | select(.Host == \"${host}\").State")
  if [[ $alive == 'true' && $state == 'true' ]]; then
    ID=$(echo $agentlist | jq -r ".[] | select(.Host == \"${host}\").ID")
    AGENTIDS[$host]=$ID
  fi
done

# Create a list of agent hostnames. Either from the openstack-APIs or from a
# command-line argument.
if [[ -z $AGENTLIST ]]; then
  agentlist=$(openstack network agent list --agent-type l3 -f value -c Host)
else
  agentlist=$(echo $AGENTLIST | tr ',' ' ')
fi

# Make a list of agents and their current load. Filter the list through the
# AGENTIDS assoc-array to only collect active and valid agents.
declare -A CURRENTLOAD
AGENTS=()
for agent in ${agentlist}; do
  if [[ ! -z ${AGENTIDS[$agent]} ]]; then
    AGENTS+=($agent)
    CURRENTLOAD[$agent]=$(openstack router list --agent ${AGENTIDS[$agent]} \
        -f value -c ID | wc -l)
  fi
done

# Determine which routers should be verified.
if [[ -z $INPUT ]]; then
  routers=$(openstack router list -f json | jq -r '.[] | select(.HA == true) | .ID')
else
  if [[ ! -e $INPUT ]]; then
    echo ERROR: Could not read $INPUT
    exit 1
  fi
  routers=$(cat $INPUT)
fi

# Print a summary before starting
r=$(echo $routers | tr ' ' '\n' | wc -l)
echo "Starting to verify that ${r} routers are scheduled to at least $NOAGENTS"
echo "L3-agents each. For routers not shceduled to enough agents one of the"
echo "following agents is attempted for scheduling:"

for a in ${AGENTS[*]}; do
  echo " - $a (Currently has ${CURRENTLOAD[$a]} routers)"
done
echo

# Start iterating through the routers to verify that they are sufficiently
# scheduled one by one
for router in $routers; do
  current=$(openstack network agent list --router $router -f value -c Host)
  amount=$(echo $current | tr ' ' '\n' | wc -l)

  # If a router has fewer than the required number of agents.
  if [[ $amount -lt $NOAGENTS ]]; then
    echo $router needs more agents.

    # Loop N rounds to add the N missing agents
    for i in $(seq $amount $(($NOAGENTS - 1))); do
      # Determine which one of the available agents that is not currently
      # hosting this router that has the fewest running routers.
      unset lowest
      for a in ${AGENTS[*]}; do 
        if [[ $current =~ $a ]]; then
          continue
        fi

        if [[ -z $lowest ]]; then
          lowest=$a
        elif [[ ${CURRENTLOAD[$a]} -lt ${CURRENTLOAD[$lowest]} ]]; then
          lowest=$a
        fi
      done

      if [[ -z $lowest ]]; then
        echo " - It cannot get enough agents, as it is already present on"
        echo "   all available candidates"
        break
      fi

      ((CURRENTLOAD[$lowest] += 1))
      echo " - ADD to $lowest (Now running ${CURRENTLOAD[$lowest]} routers)"
      openstack network agent add router --l3 ${AGENTIDS[$lowest]} $router
      current=$(openstack network agent list --router $router -f value -c Host)
    done
  else
    echo -n '.'
  fi
done
