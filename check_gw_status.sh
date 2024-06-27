#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 15-12-2023
# Description: Check Gateway status
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='1.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"
declare -r pluginctl_cmd='/usr/local/sbin/pluginctl'

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

if ! ping -q -c4 -i1.0 -W40 9.9.9.9 > /dev/null; then
  log "error" "Ping check to \"9.9.9.9\" unsuccessful"
  ${pluginctl_cmd} -r return_gateways_status | jq -c '.dpinger.[]' | while read gw; do
    log "info" "Check Gateway status for \"$(echo "${gw}" | jq -r '.name')\""
    log "info" "Gateway status: \"$(echo "${gw}" | jq -r '.status')\""
    echo "${gw}" |sed "s/{/{\"timestamp\":\"$(date +'%F %T')\",/" | jq -c >> check_gw_$(echo "${gw}" | jq -r '.name').jsonl
  done
else
  log "info" "Ping check to \"9.9.9.9\" successful"
fi

