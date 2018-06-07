#!/bin/bash

globalnet='0b537b33-d135-493a-bd97-3d5ce9e6dea6'
project="${1}"

neutron rbac-create --target-tenant $project --action access_as_external --type network $globalnet
