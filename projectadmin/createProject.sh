#!/bin/bash
set -e

. $(dirname $0)/../common.sh
. $(dirname $0)/functions.sh

prereq
need_admin

declare -A types
# Numbers are <instances> <cpu> <gb_RAM> <gb_cinder> <cinder_volumes> 
types[PRIV]="5 10 20 100 5"
types[STUDENT]="4 4 8 20 2"

types[THESIS]="16 16 32 50 10"

types[IMT2282]="1 2 4 20 1"
types[IMT2681]="3 3 6 20 2"
types[IMT3003]="15 15 30 200 10"
types[IMT3005]="25 25 50 200 10"
types[DCSG1005]="8 15 20 100 10"
types[DCSG2003]="15 15 30 200 10"
types[IIKG1001]="2 2 4 2 2"
types[TTM4135]="1 1 2 20 1"
types[TTM4133]="4 4 16 100 4"

while getopts u:n:d:e:slt:i:c:r:v:g: option; do
  case "${option}" in 
    d) projectDesc=${OPTARG} ;;
    n) projectName=${OPTARG} ;;
    e) expiry=${OPTARG} ;;
    s) service=1 ;;
    t) projectType=${OPTARG^^} ;;
    i) qinstances=${OPTARG} ;;
    c) qcpu=${OPTARG} ;;
    r) qmemory=${OPTARG} ;;
    v) qvol=${OPTARG} ;;
    l) listtypes=1 ;;
    g) [[ -z $groups ]] && groups="${OPTARG}" || groups="$groups,${OPTARG}" ;;
    u) [[ -z $users ]] && users="${OPTARG}" || users="$users,${OPTARG}" ;;
  esac
done

if [[ ! -z $listtypes ]]; then
  echo The following types of projects can be created:

  for ptype in $(echo ${!types[@]} | tr ' ' '\n' | sort); do
    read pi pc pr pg pv <<< ${types[$ptype]}
    echo "$ptype: $pi instances, $pc CPU's, ${pr}GB RAM, $pv (${pg}GB) volumes"
  done

  exit $EXIT_OK
fi

if [[ ! -z $qvol ]]; then
  if [[ $qvol =~ ^([0-9]+),([0-9]+)$ ]]; then 
    qvolumes=${BASH_REMATCH[1]}
    qgigabytes=${BASH_REMATCH[2]}
  else
    echo "-v is set incorrectly. It needs two numbers separated by a comma."
  fi
fi

if [[ -z $projectName ]] || [[ -z $projectDesc ]] || \
    ([[ -z $users ]] && [[ -z $groups ]]); then
  echo "This script creates a project and adds user(s) to the newly created"
  echo "project. The project is created wit quotas as defined by qouta"
  echo "templates."
  echo
  echo "Usage: $0 [ARGUMENTS]"
  echo ""
  echo "Mandatory arguments (arguments which are always required)"
  echo " -n <project_name>              : A project name"
  echo " -d <project_description>       : A project description"
  echo ""
  echo "Project membership - Add at least one user or group."
  echo " -u <username>  : The NTNU username of a user which should have access" 
  echo " -g <groupname> : The name of a NTNU LDAP group which should be added"
  echo "                :   to the project"
  echo ""
  echo "Quota-arguments (You need to set a type (-t) or all the other options):"
  echo " -t <project-type>        : What kind of project is it? It sets quotas"
  echo " -i <instances>           : The number of VM's the project might create"
  echo " -c <cpu-count>           : CPU-Quota for the project."
  echo " -r <memory>              : RAM-Quota - in gigabytes"
  echo " -v <volumes>,<gigabytes> : The number of volumes the project can have,"
  echo "                          :   and the total amount of space these can"
  echo "                          :   use"
  echo ""
  echo "Optional arguments:"
  echo " -e <expiry-date (dd.mm.yyyy)>  : Set deletion-date. If this is not"
  echo "                                :   supplied the expiry-date will be"
  echo "                                :   the end of the current semester"
  echo " -s                             : Create a service-user"
  echo " -l                             : List available project types"
  exit $EXIT_MISSINGARGS
fi

if [[ -z $projectType ]] && [[ -z $qcpu ]] && [[ -z $qmemory ]] && \
    [[ -z $qvolumes ]] &&  [[ -z $qgigabytes ]]; then  
  echo "You must either set a project type (-t) or manually"
  echo "define quotas (-i, -c, -m, -v and -g)"
  exit $EXIT_CONFIGERROR
fi

if [[ ! -z $projectType ]] && ([[ ! -z $qcpu ]] || [[ ! -z $qmemory ]] || \
    [[ ! -z $qvolumes ]] ||  [[ ! -z $qgigabytes ]]); then  
  echo "You cannot set project type (-t) at the same time as you manually"
  echo "define quotas (-i, -c, -m, -v and -g)"
  exit $EXIT_CONFIGERROR
fi

if [[ ! -z $projectType ]]; then
  read instances cpu ram cindergb cindervolumes <<< ${types[$projectType]}
else
  instances=$qinstances
  cpu=$qcpu
  ram=$qmemory
  cindergb=$qgigabytes
  cindervolumes=$qvolumes
fi

if [[ -z $expiry ]]; then
  if [[ $(date +%-m) -le 6 ]]; then
    expiry="30.06.$(date +%Y)"
  else
    expiry="31.12.$(date +%Y)"
  fi
fi

if [[ ! $expiry =~ ^[0-3][0-9]\.[0-1][0-9]\.20[0-9]{2}$ ]]; then
  echo "\"$expiry\" does not look like a date on the format dd.mm.yyyy"
  exit $EXIT_CONFIGERROR
fi

if openstack project show $projectName &> /dev/null; then
  echo "A project with the name \"$projectName\" already exist." 
else
  echo "Creating the project $projectName"
  openstack project create --description "$projectDesc" --domain NTNU $projectName
  echo "Setting project expiry to $expiry"
  openstack project set --property expiry=$expiry $projectName

  echo "Setting quotas ($instances instances, $cpu cores, $ram GB RAM"
  echo "  $cindervolumes volumes with $cindergb gigabytes totally)"
  openstack quota set $projectName --cores $cpu --instances $instances \
      --ram $(($ram * 1024))  --volumes $cindervolumes --gigabytes $cindergb
  # THis is not needed anymore as we have set these volume-types as non-public
  #echo "Setting the quota for Fast/VeryFast/Unlimited cinder-volumes to 0"
  #openstack quota set $projectName --volume-type Fast --volumes 0 || \
  #    echo "The volume-type Fast does not exist"
  #openstack quota set $projectName --volume-type VeryFast --volumes 0 || \
  #    echo "The volume-type VeryFast does not exist"
  #openstack quota set $projectName --volume-type Unlimited --volumes 0 || \
  #    echo "The volume-type Unlimited does not exist"
  echo "Project created"
fi

for username in $(echo $users | tr ',' ' '); do 
  noRoles=$(openstack role assignment list --project $projectName --user $username \
      --user-domain=NTNU -f csv  | wc -l)
  if [[ $noRoles -le 1 ]]; then
    echo "Adding $username to the project"
    openstack role add --project $projectName --user $username \
        --user-domain=NTNU _member_
    openstack role add --project $projectName --user $username \
        --user-domain=NTNU heat_stack_owner
    openstack role add --project $projectName --user $username \
        --user-domain=NTNU load-balancer_member
    openstack role add --project $projectName --user $username \
        --user-domain=NTNU creator
  else
    echo "$username is already present in the project"
  fi
done

for groupname in $(echo $groups | tr ',' ' '); do 
  noRoles=$(openstack role assignment list --project $projectName \
  --group $groupname --group-domain=NTNU -f csv | wc -l)
  if [[ $noRoles -le 1 ]]; then
    echo "Adding $groupname to the project"
    openstack role add --project $projectName --group $groupname \
        --group-domain=NTNU _member_
    openstack role add --project $projectName --group $groupname \
        --group-domain=NTNU heat_stack_owner
    openstack role add --project $projectName --group $groupname \
        --group-domain=NTNU load-balancer_member
    openstack role add --project $projectName --group $groupname \
        --group-domain=NTNU creator
  else
    echo "$groupname is already present in the project"
  fi
done

if [[ ! -z $service ]]; then
  create_serviceuser $projectName
fi

exit $EXIT_OK
