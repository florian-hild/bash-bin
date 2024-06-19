#!/usr/bin/env bash

#-------------------------------------------------------------------------------
# Author     : Florian Hild
# Created    : 17-06-2024
# Description: Create OPNsense backup from config.xml
#-------------------------------------------------------------------------------

export LANG=C
declare -r __SCRIPT_VERSION__='1.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"
declare BACKUP_DAYS_KEEP=30

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
  -c, --config_path    Path to config file (Required)
  -e, --encrypt        Encrypt backup file
  -h, --help           Display this help and exit
  -v, --verbose        Print debugging messages
  -V, --version        Display version and exit

Examples:
  Create backup
  \$ ${0} --config_path /usr/local/etc/opnsense_fw_backup.env

  Create encrypted backup
  \$ ${0} --encrypt --config_path /usr/local/etc/opnsense_fw_backup.env

EOF
  exit ${exit_code}
}

# get_backup_file()
# Use curl to get opnsense backup xml file
get_backup_file() {
  local curl_cmd='/usr/bin/curl'
  curl_cmd+=' --silent --insecure'
  curl_cmd+=" --user ${BACKUP_API_KEY}:${BACKUP_API_SECRET}"
  curl_cmd+=" https://${BACKUP_API_HOST}:${BACKUP_API_PORT}/api/core/backup/download/this"

  local xz_cmd='/usr/bin/xz'

  if [[ -n "${encrypt// }" ]]; then
    local openssl_cmd='/usr/bin/openssl'
    openssl_cmd+=' enc -e -base64 -aes-256-cbc -pbkdf2 -md sha512 -iter 100000'
    openssl_cmd+=" -pass pass:${BACKUP_ENCRYPTION_PASS}"

    ${curl_cmd} | ${openssl_cmd} | ${xz_cmd} > "${BACKUP_DESTINATION_PATH}/opnsense-backup-$(date +'%F_%H-%M')_encrypted.xml.xz"
  else
    ${curl_cmd} | ${xz_cmd} > "${BACKUP_DESTINATION_PATH}/opnsense-backup-$(date +'%F_%H-%M').xml.xz"
  fi

  exit_code=${PIPESTATUS[0]}

  if [[ ${exit_code} -ne 0 ]]; then
    log fatal "Curl exit code: \"${exit_code}\""
    exit 1
  fi
}

purge_backup_files() {
  /usr/bin/find ${BACKUP_DESTINATION_PATH} -name "opnsense-backup-*.xml.xz" -type f -mtime +${BACKUP_DAYS_KEEP} -delete
}

# main()
# Start of script
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ ${@} == "-" ]] || [[ ${@} == "--" ]]; then
    echo "Syntax or usage error (1)" >&2
    echo
    help 128
  fi

  OPTS="$(getopt -o 'c:hevV' --long 'config_path:,help,encrypt,verbose,version' -n "${0}" -- "${@}")"
  if [[ "${?}" != "0" ]] ; then
    echo "Syntax or usage error (2)" >&2
    echo
    help 128
  fi
  eval set -- "$OPTS"

  while true; do
    case "${1}" in
    -c | --config_path)
      declare -r config_path="${2}"
      shift 2
      ;;
    -h | --help)
      help 0
      ;;
    -e | --encrypt)
      declare -r encrypt="1"
      shift
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

if [[ -z "${config_path// }" ]]; then
  log error "Path to config file required"
  echo
  help 128
fi

if [[ ! -r "${config_path}" ]]; then
  log fatal "Config file \"${config_path}\" not found or not readable"
  exit 1
else
  source ${config_path}
fi

if [[ -z "${BACKUP_API_HOST// }" ]]; then
  log error "Variable \"BACKUP_API_HOST\" not found in config file"
  exit 1
fi

if [[ -z "${BACKUP_API_PORT// }" ]]; then
  log error "Variable \"BACKUP_API_PORT\" not found in config file"
  exit 1
fi

if [[ -z "${BACKUP_API_KEY// }" ]]; then
  log error "Variable \"BACKUP_API_KEY\" not found in config file"
  exit 1
fi

if [[ -z "${BACKUP_API_SECRET// }" ]]; then
  log error "Variable \"BACKUP_API_SECRET\" not found in config file"
  exit 1
fi

if [[ -z "${BACKUP_DESTINATION_PATH// }" ]]; then
  log error "Variable \"BACKUP_DESTINATION_PATH\" not found in config file"
  exit 1
else
  if [[ ! -d "${BACKUP_DESTINATION_PATH}" ]]; then
    log error "Path \"${BACKUP_DESTINATION_PATH}\" not found"
    exit 1
  fi
fi

if [[ -n "${encrypt// }" ]] && [[ -z "${BACKUP_ENCRYPTION_PASS// }" ]]; then
  log error "Variable \"BACKUP_ENCRYPTION_PASS\" not found in config file"
  exit 1
fi

get_backup_file

exit

