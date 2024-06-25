#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 19-06-2024
# Description:
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='1.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"

# Load libraries
source ${BASH_LIB_DIR}/logger/lib
declare -r log_no_timestamp="true"

# help(exit_code)
# Print help message and exit
help() {
  local -r exit_code="${1:-0}"
  # Print help text
  cat << EOF
Usage:
  ${0} [options]

Options:
  -f, --file       Backup file (Required)
  -h, --help       Display this help and exit
  -v, --verbose    Print debugging messages
  -V, --version    Display version and exit

Examples:
  Create backup
  \$ ${0} --file /data/backups/opnsense/opnsense-backup-2024-06-19_23-04_encrypted.xml.xz

EOF
  exit ${exit_code}
}

decrypt_file() {
  while true; do
    read -p $'Enter password:\n' -r psw
      if [[ -n "${psw// }" ]]; then
        break
      fi
  done

  if [[ "${file_mime_type}" == "application/gzip" ]]; then
    gzip --decompress --stdout "${file}" | openssl enc -d -base64 -aes-256-cbc -pbkdf2 -md sha512 -iter 100000 -pass pass:${psw}
  elif [[ "${file_type}" =~ ^openssl ]]; then
    openssl enc -d -base64 -aes-256-cbc -pbkdf2 -md sha512 -iter 100000 -pass pass:${psw} -in "${file}"
  else
    echo "Error: File unknown"
  fi


}

# main()
# Start of script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ ${@} == "-" ]] || [[ ${@} == "--" ]]; then
    echo "Syntax or usage error (1)" >&2
    echo
    help 128
  fi

  OPTS="$(getopt -o 'f:hvV' --long 'file:,help,verbose,version' -n "${0}" -- "${@}")"
  if [[ "${?}" != "0" ]] ; then
    echo "Syntax or usage error (2)" >&2
    echo
    help 128
  fi
  eval set -- "$OPTS"

  while true; do
    case "${1}" in
    -f | --file)
      declare -r file="${2}"
      shift 2
      ;;
    -h | --help)
      help 0
      ;;
    -v | --verbose)
      declare -r verbose="1"
      set -xv  # Set xtrace and verbose mode.
      shift
      ;;
    -V | --version)
      echo "${__SCRIPT_VERSION__}"
      exit 0
      ;;
    -- )
      shift
      break
      ;;
    *)
      echo "Syntax or usage error (3)" >&2
      echo
      help 128
      ;;
    esac
  done
fi

if [[ -z "${file// }" ]]; then
  log error "Path to backup file is required"
  echo
  help 128
fi

if [[ ! -r "${file}" ]]; then
  log fatal "Backup file \"${file}\" not found or not readable"
  exit 1
else
  declare -r file_type="$(sed -e '/--- /d; /: /d; /^$/d;' ${file} | file --brief -)"
  declare -r file_mime_type="$(sed -e '/--- /d; /: /d; /^$/d;' ${file} | file --mime-type --brief -)"
fi

if [[ "${file_mime_type}" == "application/gzip" ]]; then
  if [[ "$(gzip --decompress --stdout ${file} | sed -e '/--- BEGIN/d; /--- END/d' | file --brief -)" =~ ^openssl ]]; then
    decrypt_file
  else
    zcat "${file}"
  fi
elif [[ "${file_type}" =~ ^openssl ]]; then
  decrypt_file
elif [[ "${file_mime_type}" == "text/plain" ]]; then
  cat "${file}"
else
  echo "Error: File format unknown"
fi

exit
