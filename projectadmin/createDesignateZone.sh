#!/usr/bin/env bash

if [[ $# -lt 1 ]]; then
  echo "This script will create designate DNS zones for a specific project, and share it with the project."
  echo
  echo "Usage: $0 <project-id|project-name>"
  exit 1
fi

project="${1}"
projectId="$(openstack project show -f value -c id "$project")"
projectName="$(openstack project show -f value -c name "$project")"

if [[ -z $projectId ]]; then
  echo "No project with ID/name $project exists. Exiting"
  exit 1
fi

servicesId=$(openstack project show -f value -c id services)

# Find the project zone suffix
if [[ $OS_AUTH_URL == *"api.stack.it.ntnu.no"* ]]; then
  zoneSuffix="iaas.ntnu.no."
elif [[ $OS_AUTH_URL == *"api.pile.it.ntnu.no"* ]]; then
  zoneSuffix="iaas-test.ntnu.no."
else
  echo "Could not find the project zone name for this cloud environment. Exiting"
  exit 1
fi

# To lowercase, replace all underscores with dashes, remove everything except letters, numbers and dashes
zoneLabel="$(echo "$projectName" | tr '[:upper:]' '[:lower:]' | tr "_" "-" | tr -cd -- '-[:alnum:]')"
zoneName="$zoneLabel.$zoneSuffix"

zoneEmail="$(openstack zone show -f value -c email "$zoneSuffix" --sudo-project-id "$servicesId")"
if [[ -z $zoneEmail ]]; then
  echo "Could not find the email for zone $zoneSuffix. Does the zone exist? Exiting"
  exit 1
fi

echo "Creating zone $zoneName for project $projectName ($projectId)"

openstack zone create --email "$zoneEmail" "$zoneName" --sudo-project-id "$servicesId"

if [[ $? -ne 0 ]]; then
  echo "Failed to create zone $zoneName. Exiting"
  exit 1
fi

echo "Sharing zone $zoneName with project $projectName ($projectId)"

openstack zone share create "$zoneName" "$projectId" --sudo-project-id "$servicesId" > /dev/null

if [[ $? -ne 0 ]]; then
  echo "Failed to share zone $zoneName with project $projectName. Exiting"
  exit 1
fi

echo "Zone $zoneName created and shared with project $projectName ($projectId)."

