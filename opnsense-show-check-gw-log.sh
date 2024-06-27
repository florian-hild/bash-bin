#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 15-12-2023
# Description: Show Check Gateway status logfile
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='2.0'

if ! command -v jq &> /dev/null; then
  echo "Command jq could not be found"
  exit 1
fi

if [[ -z "${1// }" ]]; then
  echo "Usage:"
  echo "  $0 [jsonl-logfile]"
  exit 2
fi

if [[ -r ${1} ]]; then
  cat "${1}" | jq '.timestamp + " | Status: " + .status + " | Loss: " + .loss'
else
  echo "Error: File \"${1}\" not found or not readable"
  exit 1
fi
