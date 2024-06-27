#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 15-12-2023
# Description: Update DNS Record with Hetzner API
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='3.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"
declare -r logfile_path="${HOME}/local/log"

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

if [[ ! -d ${logfile_path} ]]; then
  mkdir -p ${logfile_path}
fi

if [[ -z "${1// }" ]]; then
  echo "Usage:"
  echo "  $0 [path to env file]"
  exit 2
fi

if [[ -r ${1} ]]; then
  source ${1}
else
  log "error" "File \"${1}\" not found or not readable"
  exit 1
fi

# public_ip=$(ifconfig igb0 | grep -w 'inet' | cut -d' ' -f2)
current_public_ip=$(curl --silent --show-error https://ifconfig.me/ip)

log "info" "Current public ip: \"${current_public_ip}\""
log "info" "   Last public ip: \"${last_public_ip}\""

if [[ "${current_public_ip}" != "${last_public_ip}" ]]; then
  printf "{\"timestamp\":\"$(date +'%F %T')\",\"current\":\"${current_public_ip}\",\"last\":\"${last_public_ip}\"}\n" >> ${logfile_path}/update_hetzner_record.jsonl


  for record in "${record_ids[@]}"; do
    record_name=$(echo $record|cut -d',' -f1)
    record_id=$(echo $record|cut -d',' -f2)

    curl -X "PUT" "https://dns.hetzner.com/api/v1/records/{${record_id}}" \
      -H 'Content-Type: application/json' \
      -H "Auth-API-Token: ${api_token}" \
      -d $'{
        "value": "'${current_public_ip}'",
        "ttl": 900,
        "type": "A",
        "name": "'${record_name}'",
        "zone_id": "'${zone_id}'"
      }'
  done

  # Replace last_public_ip value in env file
  perl -pi -e "s/^last_public_ip=.*/last_public_ip=\"${current_public_ip}\"/g" ${1}
fi

exit
