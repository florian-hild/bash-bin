#!/usr/bin/env bash

################################################################################
# Developer ......: F.Hild
# Created ........: 09.08.2023
# Description ....: Create backup with borgbackup
#
# The config is stored in borg_backup.env
################################################################################

export LANG=C

declare -r __SCRIPT_VERSION__='1.0'
declare -r BASH_LIB_DIR="/usr/local/bin/bash-lib"

# Defaults:
# This variables can be overitten in the env file
declare borg_logfile="${HOME}/local/log/borg_backup_$(hostname -s)_$(date +'%Y-%m').log"
declare BORG_EXCLUDE=''
declare BORG_PREFIX=''
declare BORG_PRUNE_KEEP_LAST='4'
declare BORG_PRUNE_KEEP_DAILY='0'
declare BORG_PRUNE_KEEP_WEEKLY='0'
declare BORG_PRUNE_KEEP_MONTHLY='3'
declare BORG_PRUNE_KEEP_YEARLY='3'

# Load libraries
source ${BASH_LIB_DIR}/logger/lib

# Help
#
help() {
  # Display Help
  echo "Usage:"
  echo "  ${0} [-ehpvV] [--env file] [--prune]"
  echo
  echo "Options:"
  printf "  %-18s %s\n" "-e, --env" "Set borg_backup.env (required)"
  printf "  %-18s %s\n" "-h, --help" "Display this help and exit"
  printf "  %-18s %s\n" "-p, --prune" "Prune borg backups"
  printf "  %-18s %s\n" "-v, --verbose" "Print debugging messages"
  printf "  %-18s %s\n" "-V, --version" "Display the version number and exit"
  echo
  echo "Examples:"
  echo "  Create backup"
  echo "  \$ ${0} --env borg_backup.env"
  echo
  echo "  Prune backups"
  echo "  \$ ${0} --env borg_backup.env --prune"
  exit 0
}

# Backup
#
borg_backup() {
  log "info" "Start backup script"

  log "info" "Run pre commands"
  run_pre

  log "info" "Start backup to ${BORG_REPO}"
  export BORG_PASSPHRASE
  borg create \
    --filter AME \
    --list \
    --stats \
    --compression zlib,5 \
    --exclude-caches \
    --exclude "${BORG_EXCLUDE}" \
    ${BORG_REPO}::${BORG_PREFIX:+${BORG_PREFIX}_}{hostname}_{now:%Y-%m-%d}_{now:%H:%M} \
    ${BORG_DIR_LIST}

  rc=$?

  # https://borgbackup.readthedocs.io/en/stable/usage/general.html#return-codes
  if [[ ${rc} -eq "1" ]]; then
    log "warn" "Return code: \"${rc}\""
  elif [[ ${rc} -eq "2" ]]; then
    log "error" "Return code: \"${rc}\""
  elif [[ ${rc} -gt "2" ]]; then
    log "fatal" "Return code: \"${rc}\""
  fi

  log "info" "Run post commands"
  run_post

  log "info" "End backup script"
}

# Prune
#
borg_prune() {
  log "info" "Start backup script (Prune)"

  log "info" "Start prune to ${BORG_REPO}"
  export BORG_PASSPHRASE
  borg prune \
    --list \
    --glob-archives "${BORG_PREFIX:+${BORG_PREFIX}_}{hostname}_" \
    --keep-last ${BORG_PRUNE_KEEP_LAST} \
    --keep-daily ${BORG_PRUNE_KEEP_DAILY} \
    --keep-weekly ${BORG_PRUNE_KEEP_WEEKLY} \
    --keep-monthly ${BORG_PRUNE_KEEP_MONTHLY} \
    --keep-yearly ${BORG_PRUNE_KEEP_YEARLY} \
    ${BORG_REPO}

  rc=$?

  # https://borgbackup.readthedocs.io/en/stable/usage/general.html#return-codes
  if [[ ${rc} -eq "1" ]]; then
    log "warn" "Return code: \"${rc}\""
  elif [[ ${rc} -eq "2" ]]; then
    log "error" "Return code: \"${rc}\""
  elif [[ ${rc} -gt "2" ]]; then
    log "fatal" "Return code: \"${rc}\""
  fi

  log "info" "End backup script (Prune)"
}

################################################################################
#                                    Start                                     #
################################################################################
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ ${#} -eq "0" ]] || [[ ${@} == "-" ]] || [[ ${@} == "--" ]]; then
    echo "Syntax or usage error"
    echo
    help
  fi

  OPTS="$(getopt -o "e:phvV" --long "help,env:,prune,verbose,version" -n "${0##*/}" -- "${@}")"
  if [[ "${?}" != "0" ]] ; then
    echo "Syntax or usage error" >&2
    echo "Unknown option: ${1}" >&2
    exit 2
  fi
  eval set -- "${OPTS}"

  while true; do
    case "${1}" in
    -h | --help)
      help
      ;;
    -e | --env)
      declare -r env_file="${2}"
      shift 2
      ;;
    -p | --prune)
      declare -r prune="1"
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
      echo "Syntax or usage error" >&2
      echo "Unknown option: ${1}" >&2
      exit 2
      ;;
    esac
  done
fi

if [[ -z "${env_file// }" ]]; then
  log "fatal" "Env file not specified."
  echo
  help
fi

if [[ ! -f "${env_file}" ]]; then
  log "fatal" "\"${env_file}\" file not found."
  exit 1
fi

# Source borg_backup.env file
source "${env_file}"

# Create path to logfile
mkdir -p ${borg_logfile%/*}

if [[ -z "${BORG_REPO// }" ]]; then
  log "fatal" "BORG_REPO not specified."
  exit 1
fi

if [[ -z "${BORG_PASSPHRASE// }" ]]; then
  log "fatal" "BORG_PASSPHRASE not specified."
  exit 1
fi

if [[ -z "${BORG_DIR_LIST// }" ]]; then
  log "fatal" "BORG_DIR_LIST not specified."
  exit 1
fi

exec > >(tee -a ${borg_logfile}) 2>&1

if [[ -z "${prune// }" ]]; then
  borg_backup
else
  borg_prune
fi

exit ${rc}
