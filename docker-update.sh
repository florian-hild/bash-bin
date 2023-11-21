#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 21-12-2022
# Description: Update docker containers from docker-compose file
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='3.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

# Help
#
help() {
  # Display Help
  echo "Usage:"
  echo "  ${0} {docker compose file}"
  echo
  echo "Examples:"
  echo "  Update all container from docker-compose file"
  echo "  \$ ${0} docker-compose.yml"
  exit ${1:-0}
}

declare -r compose_file="${1:-"docker-compose.yml"}"

if [[ ! -f ${compose_file} ]]; then
  echo "fatal: File \"${compose_file}\" not found"
  echo
  help 1
fi

readarray -t containers < <(/bin/grep -w "^\s*container_name:" ${compose_file} | awk '{print $2}')
for container in "${containers[@]}"; do
  log "info" "Start update container: ${container}"
  current_image="$(docker inspect --format '{{ index .Image }}' ${container} | cut -c8-19)"
  current_version="$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' ${container})"
  log "debug" "Current container image: ${current_image}"
  log "debug" "Current container version: ${current_version}"

  docker-compose -f ${compose_file} pull
  new_image=$(docker image ls mbentley/omada-controller | awk 'NR==2 {print $3}')
  if [[ "${new_image}" != "${current_image}" ]]; then
    docker-compose -f ${compose_file} build --no-cache
    docker-compose -f ${compose_file} up \
      --force-recreate \
      --detach \
      --remove-orphans
    new_version="$(docker inspect --format '{{ index .Config.Labels "org.opencontainers.image.version"}}' ${container})"
    log "debug" "New container image: ${new_image}"
    log "debug" "New container version: ${new_version}"

    history_log="$(dirname "$(realpath -s "${compose_file}")")/update_history_${container%%;*}_log.jsonl"
    log "info" "Image version has changed"
    log "debug" "Write in log file: \"${history_log}\""
    echo "{\"timestamp\": \"$(date +'%F %H:%M:%S')\", \"version\": \"${new_version}\", \"image\": \"${new_image}\"}" >> ${history_log}
  fi

  log "info" "Finised update container: ${container}"
done

exit
