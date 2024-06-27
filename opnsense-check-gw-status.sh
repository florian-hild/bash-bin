#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 15-12-2023
# Description: Check Gateway status
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='2.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"
declare -r pluginctl_cmd='/usr/local/sbin/pluginctl'
declare -r logfile_path="${HOME}/local/log"

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

if ! command -v jq &> /dev/null; then
  echo "Command jq could not be found"
  exit 1
fi

if [[ ! -d ${logfile_path} ]]; then
  mkdir -p ${logfile_path}
fi

${pluginctl_cmd} -r return_gateways_status | jq -c '.dpinger.[]' | while read gw; do
  gw_name="$(echo "${gw}" | jq -r '.name')"
  gw_status="$(echo "${gw}" | jq -r '.status' | sed 's/none/up/g')"
  log "info" "Gateway status \"${gw_status}\" for \"${gw_name}\""

  if [[ "${gw_status}" == "down" ]]; then
    echo "${gw}" | sed "s/{/{\"timestamp\":\"$(date +'%F %T')\",/" | jq -c | sed 's/none/up/g' >> ${logfile_path}/check_gw_${gw_name}.jsonl
  fi
done

