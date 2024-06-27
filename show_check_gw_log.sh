#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 15-12-2023
# Description: Show Check Gateway status logfile
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='1.0'

if [[ -z "${1// }" ]]; then
  echo "Usage:"
  echo "  $0 [jsonl-logfile]"
  exit 2
fi

cat "${1}" | jq '.timestamp + " | Status: " + .status + " | Loss: " + .loss'

