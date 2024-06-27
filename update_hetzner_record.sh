#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 15-12-2023
# Description: Update DNS Record with Hetzner API
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='2.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

source update_hetzner_record.env
# public_ip=$(ifconfig igb0 | grep -w 'inet' | cut -d' ' -f2)
# public_ip=$(curl ipinfo.io/ip)
current_public_ip=$(curl --silent --show-error https://ifconfig.me)

log "info" "Current public ip: \"${current_public_ip}\""
log "info" "   Last public ip: \"${last_public_ip}\""

if [[ "${current_public_ip}" != "${last_public_ip}" ]]; then
  printf "{\"timestamp\":\"$(date +'%F %T')\",\"current\":\"${current_public_ip}\",\"last\":\"${last_public_ip}\"}\n" >> update_hetzner_record.jsonl


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

  perl -pi -e "s/^last_public_ip=.*/last_public_ip=\"${current_public_ip}\"/g" update_hetzner_record.env
fi

exit
