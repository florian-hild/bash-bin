#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 21-11-2023
# Description: Show docker update history log
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='1.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

# Help
#
help() {
  # Display Help
  echo "Usage:"
  echo "  ${0} {update history JSON file}"
  echo
  echo "Examples:"
  echo "  Show logs from JSON file"
  echo "  \$ ${0} update_history_pihole_log.jsonl"
  exit ${1:-0}
}

declare -r log_file="${1:-"update_history_*_log.jsonl"}"

if [ ! -f ${log_file} ]; then
  echo "fatal: File \"${log_file}\" not found"
  echo
  help 1
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "fatal: Command \"jq\" not found"
  exit 1
fi

tail -5 ${log_file} | jq -r '.timestamp + ";" + .version + ";" + .image' | (
  printf "+-----------------------------------------------------+\n"
  printf "| %-19s | %-14s | %-12s |\n" "Timestamp" "Version" "Image"
  printf "+-----------------------------------------------------+\n"
  while IFS=';' read -r ts ver img; do
    printf "| %-19s | %-14s | %-12s |\n" "${ts}" "${ver}" "${img}"
  done
  printf "+-----------------------------------------------------+\n"
)

exit
