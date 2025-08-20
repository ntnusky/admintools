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

types[THESIS]="16 32 64 300 10"

types[DCSG1001]="1 2 4 1 1"
types[DCSG1001-TA]="4 8 8 4 4"
types[DCSG1005]="8 16 24 100 10"
types[DCSG2003]="20 30 50 200 10"
types[DCST1001]="2 4 16 1 1"
types[IIKG1001]="1 1 2 1 1"
types[IIKG1001-TA]="4 8 8 4 4"
types[IIKG1001-GROUP]="2 2 4 2 2"
types[IIKG1003]="2 4 4 0 0"
types[IDATA2900]="1 2 4 0 0"
types[IDATG2202]="1 2 4 20 1"
types[IDATA2502]="2 2 8 40 2"
types[IMT3003]="15 15 30 200 10"
types[IIKG3005]="25 25 50 200 10"
types[MACS490]="2 4 4 50 2"
types[PROG2005]="3 3 3 20 2"
types[PROG2052]="8 16 32 100 8"
types[TTK4854]="2 8 16 64 2"
types[TTM4133]="4 4 16 100 4"
types[TTM4135]="1 1 2 20 1"
types[TTM4175]="30 128 256 20 30"
types[TTM4195]="2 2 4 100 2"
types[TTM4536]="3 3 6 0 0"

while getopts u:n:d:e:slq:i:c:r:v:f:z:4g:p:t: option; do
  case "${option}" in 
    d) projectDesc=${OPTARG} ;;
    n) projectName=${OPTARG} ;;
    e) expiry=${OPTARG} ;;
    s) service=1 ;;
    q) projectType=${OPTARG^^} ;;
    i) qinstances=${OPTARG} ;;
    c) qcpu=${OPTARG} ;;
    r) qmemory=${OPTARG} ;;
    v) qvol=${OPTARG} ;;
    f) qip=${OPTARG} ;;
    4) v4pool=1 ;;
    z) zone=${OPTARG} ;;
    l) listtypes=1 ;;
    g) [[ -z $groups ]] && groups="${OPTARG}" || groups="$groups,${OPTARG}" ;;
    u) [[ -z $users ]] && users="${OPTARG}" || users="$users,${OPTARG}" ;;
    p) parentProject=${OPTARG} ;;
    t) topdesk=${OPTARG} ;;
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

if [[ -z $projectName ]] || [[ -z $projectDesc ]]; then
  echo "This script creates a project and adds user(s) to the newly created"
  echo "project. The project is created wit quotas as defined by qouta"
  echo "templates."
  echo
  echo "Usage: $0 [ARGUMENTS]"
  echo ""
  echo "Mandatory arguments (arguments which are always required)"
  echo " -n <project_name>        : A project name"
  echo " -d <project_description> : A project description"
  echo " -e <expiry (dd.mm.yyyy)> : Set deletion-date."
  echo ""
  echo "Project membership"
  echo " -u <username>  : The NTNU username of a user which should have access" 
  echo " -g <groupname> : The name of a NTNU LDAP group which should be added"
  echo "                :   to the project"
  echo ""
  echo "Quota-arguments (You need to set a type (-q) or all the other options):"
  echo " -q <project-type>        : What kind of project is it? It sets quotas"
  echo " -i <instances>           : The number of VM's the project might create"
  echo " -c <cpu-count>           : CPU-Quota for the project."
  echo " -r <memory>              : RAM-Quota - in gigabytes"
  echo " -v <volumes>,<gigabytes> : The number of volumes the project can have,"
  echo "                          :   and the total amount of space these can"
  echo "                          :   use"
  echo ""
  echo "For ACI-Openstack network-settings:"
  echo " -4                       : Give access to IPv4 subnet pool"
  echo " -z <zone>                : Firewall-zone for the project"
  echo ""
  echo "Optional arguments:"
  echo " -f <floating-ip's>       : Quota for Floating IPs."
  echo " -l                       : List available project types"
  echo " -p <project-name|id>     : The new project will be a child"
  echo "                          :    of the given project"
  echo " -s                       : Create a service-user"
  echo " -t <TopDesk case number> : Case number from TopDesk"
  exit $EXIT_MISSINGARGS
fi

if [[ $OS_REGION_NAME =~ ^TRD[12]$ ]]; then
  if [[ ! -z $zone && ! $zone =~ \
      ^(internal|exposed|restricted|management|research|infrastructure)$ ]]; then
    echo "The specified zone is invalid. It must be one of: "
    echo "  exposed, internal, restricted, management, research or infrastructure" 
    exit $EXIT_MISSINGARGS
  fi
  
  if [[ -z $qip ]] && [[ $zone == 'exposed' ]]; then
    floatingip=5
  elif [[ -z $qip ]]; then
    floatingip=50
  else
    floatingip=$qip
  fi
else
  if [[ ! -z $v4pool ]]; then
    echo "IPv4 subnet-pool is not relevant for this plattform."
    exit $EXIT_CONFIGERROR
  fi
  if [[ ! -z $zone ]]; then
    echo "Firewall-zone is not relevant for this plattform."
    exit $EXIT_CONFIGERROR
  fi

  if [[ -z $qip ]]; then
    floatingip=50
  else
    floatingip=$qip
  fi
fi

if [[ -z $projectType ]] && [[ -z $qcpu ]] && [[ -z $qmemory ]] && \
    [[ -z $qvolumes ]] &&  [[ -z $qgigabytes ]]; then  
  echo "You must either set a project type (-q) or manually"
  echo "define quotas (-i, -c, -r, and -v)"
  exit $EXIT_CONFIGERROR
fi

if [[ ! -z $projectType ]] && ([[ ! -z $qcpu ]] || [[ ! -z $qmemory ]] || \
    [[ ! -z $qvolumes ]] ||  [[ ! -z $qgigabytes ]]); then  
  echo "You cannot set project type (-q) at the same time as you manually"
  echo "define quotas (-i, -c, -r, and -v)"
  exit $EXIT_CONFIGERROR
fi

if [[ ! -z $projectType ]]; then
  if [[ ! -z ${types[$projectType]} ]]; then
    read instances cpu ram cindergb cindervolumes <<< ${types[$projectType]}
  else
    echo "The project type $projectType does not exist!"
    exit $EXIT_CONFIGERROR
  fi
else
  instances=$qinstances
  cpu=$qcpu
  ram=$qmemory
  cindergb=$qgigabytes
  cindervolumes=$qvolumes
fi

if [[ -z $expiry ]]; then
  echo "Expiry-date is missing."
  exit $EXIT_CONFIGERROR
fi

if [[ ! $expiry =~ ^[0-3][0-9]\.[0-1][0-9]\.20[0-9]{2}$ ]]; then
  echo "\"$expiry\" does not look like a date on the format dd.mm.yyyy"
  exit $EXIT_CONFIGERROR
fi

if [[ ! -z $parentProject ]]; then
  parent="--parent $parentProject"
else
  parent=""
fi

if [[ ! -z $topdesk ]] && [[ ! $topdesk =~ ^NTNU[0-9]+ ]]; then
  echo "\"$topdesk\" is not a valid TopDesk case number"
  exit $EXIT_CONFIGERROR
fi

if [[ $projectName =~ ^([^_]*)_.*$ ]]; then
  prefix=${BASH_REMATCH[1]}
else
  echo "Project-name need to include an '_' between its prefix and name."
  echo "  MH-INB_Prosjektnavn eller IT-Server_Prosjektnavn"
  exit $EXIT_CONFIGERROR
fi

if openstack project show $projectName &> /dev/null; then
  echo "A project with the name \"$projectName\" already exist." 
else
  echo "Creating the project $projectName"
  openstack project create --description "$projectDesc" --domain NTNU \
    --tag $prefix $parent $projectName
fi

echo "Creates DNS-zone for the project"
./createDesignateZone.sh $projectName

echo "Setting project expiry to $expiry"
openstack project set --property expiry=$expiry $projectName

if [[ ! -z $topdesk ]]; then
  echo "Adding TopDesk case number ($topdesk)"
  openstack project set --property topdesk=$topdesk $projectName
  echo "Project created"
fi

echo "Setting quotas:"
echo " - $instances instances, $cpu cores, $ram GB RAM"
echo " - $floatingip Floating IP's"
echo " - $cindervolumes volumes with $cindergb gigabytes totally"

# The RAM calculation is odd because bash doesn't understand floating point numbers,
# and bc will always print a decimal.. Dividing by 1 removes it.
openstack quota set $projectName --force \
  --cores $cpu --instances $instances --ram $(echo "${ram} * 1024 / 1" | bc) \
  --volumes $cindervolumes --gigabytes $cindergb \
  --floating-ips $floatingip --subnetpools 0 || echo "Quota-change failed"

for username in $(echo $users | tr ',' ' '); do 
  noRoles=$(openstack role assignment list --project $projectName --user $username \
      --user-domain=NTNU -f csv  | wc -l)
  if [[ $noRoles -le 1 ]]; then
    echo "Adding $username to the project"
    openstack role add --project $projectName --user $username \
        --user-domain=NTNU member
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
        --group-domain=NTNU member
  else
    echo "$groupname is already present in the project"
  fi
done

if [[ ! -z $zone ]]; then
  echo "Giving project access to the $zone zone"
  openstack network rbac create --type network --action access_as_external \
    --target-project "${projectName}" "ntnu-${zone}" 2> /dev/null || \
    echo " - Already granted"
  echo "Giving project access to the ntnu-${zone}-v6 subnet pool"
  openstack network rbac create --type subnetpool --action access_as_shared \
    --target-project "${projectName}" "ntnu-${zone}-v6" 2> /dev/null || \
    echo " - Already granted"
  echo "Tagging project with zone"
  openstack project set --tag "ZONE-${zone}" --tag "POOL-V6-${zone}" "${projectName}"
fi

if [[ ! -z $v4pool ]]; then
  echo "Giving project access to the ntnu-${zone}-v4 subnet pool"
  openstack network rbac create --type subnetpool --action access_as_shared \
    --target-project "${projectName}" "ntnu-${zone}-v4" 2> /dev/null || \
    echo " - Already granted"
  openstack project set --tag "POOL-V4-${zone}" "${projectName}"
fi

if [[ ! -z $service ]]; then
  create_serviceuser $projectName
fi

exit $EXIT_OK
