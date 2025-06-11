#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: sync_from_peers.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.06.11
# Version....: v1.0.0
# Purpose....: Sync a file or folder from a remote peer to local, then to other peers
# Notes......: Reads optional configuration from environment, etc/ folder or CLI.
#              Requires ssh and rsync. Designed to run from any of the peers.
# Reference..: https://github.com/oehrlis
# License....: Apache License Version 2.0
# ------------------------------------------------------------------------------
# Modified...:
# 2025.06.11s oehrli - initial version based on sync_to_peers.sh
# ------------------------------------------------------------------------------

# - Customization --------------------------------------------------------------
PEER_HOSTS_DEFAULT=()
SSH_USER_DEFAULT="oracle"
SSH_PORT_DEFAULT="22"
RSYNC_OPTS="-az"
DRYRUN=false
VERBOSE=false
DEBUG=false
DELETE=false
QUIET=false
REMOTE_BASE=""
CONFIG_FILE=""
LOADED_CONFIG=""
SYNC_SUCCESS=()
SYNC_FAILURE=()
# - EOF Customization ----------------------------------------------------------

# - Default Values -------------------------------------------------------------
SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
SCRIPT_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_BASE=$(dirname ${SCRIPT_BIN_DIR})
SCRIPT_ETC_DIR="${SCRIPT_BASE}/etc"
SCRIPT_CONF="${SCRIPT_ETC_DIR}/${SCRIPT_NAME%.sh}.conf"
SCRIPT_LOG_DIR="${SCRIPT_BASE}/log"
SCRIPT_LOG="${SCRIPT_LOG_DIR}/${SCRIPT_NAME%.sh}_$(date +%Y%m%d_%H%M%S).log"
# - EOF Default Values ---------------------------------------------------------

# - Load Configuration ---------------------------------------------------------
if [[ -f "$SCRIPT_CONF" ]]; then
    source "$SCRIPT_CONF"
    LOADED_CONFIG+="$SCRIPT_CONF,"
fi
if [[ -n "$ETC_BASE" && -d "$ETC_BASE" && -f "$ETC_BASE/${SCRIPT_NAME%.sh}.conf" ]]; then
    source "$ETC_BASE/${SCRIPT_NAME%.sh}.conf"
    LOADED_CONFIG+="$ETC_BASE/${SCRIPT_NAME%.sh}.conf,"
fi
if [[ -n "$CONFIG_FILE" && -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    LOADED_CONFIG+="$CONFIG_FILE,"
fi
LOADED_CONFIG="${LOADED_CONFIG%,}"

# Use env vars or fall back to defaults
SSH_USER="${SSH_USER:-$SSH_USER_DEFAULT}"
SSH_PORT="${SSH_PORT:-$SSH_PORT_DEFAULT}"
PEER_HOSTS=(${PEER_HOSTS[@]:-${PEER_HOSTS_DEFAULT[@]}})
# - EOF Configuration Load -----------------------------------------------------

# - Functions ------------------------------------------------------------------
function Usage {
    cat << EOF

Usage: ${SCRIPT_NAME} -p <remote_peer> [-nvdDq] [-H "host1 host2"] [-r <remote_base>] [-c <config_file>] <file-or-folder-to-sync>

Options:
  -p <remote_peer>      Required. Hostname of peer to sync from.
  -n                    Dry run (simulate rsync)
  -v                    Enable verbose output
  -d                    Enable debug mode
  -D                    Delete remote files not present locally (rsync --delete)
  -q                    Quiet mode (suppress non-error output)
  -H                    Space-separated list of peer hosts (overrides default or env list)
  -r <remote_base>      Optional base path on remote (default: same as local path)
  -c <config_file>      Optional config file
  -h                    Show this help message

Defaults:
  SSH_USER........: ${SSH_USER}
  SSH_PORT........: ${SSH_PORT}
  PEER_HOSTS......: ${PEER_HOSTS[*]}
  RSYNC_OPTS......: ${RSYNC_OPTS}
  SCRIPT_CONF.....: ${LOADED_CONFIG}
  
Examples:
  ${SCRIPT_NAME} -p db01 -v $ORACLE_BASE/network/admin/tnsnames.ora
  ${SCRIPT_NAME} -p db01 -D -H "db02" -r /tmp/config /etc/yum.repos.d/
EOF
    exit 1
}

function log_message {
    local level="$1"
    local message="$2"
    [[ "$QUIET" == true && "$level" != "ERROR" ]] && return
    [[ "$level" == "DEBUG" && "$DEBUG" != true ]] && return

    local plain_message="[$level] $message"

    case "$level" in
        INFO) echo -e "\e[32m[INFO]\e[0m $message" ;;
        DEBUG) echo -e "\e[34m[DEBUG]\e[0m $message" ;;
        ERROR) echo -e "\e[31m[ERROR]\e[0m $message" ;;
        *) echo "$message" ;;
    esac

    [[ -n "$SCRIPT_LOG" ]] && echo "$plain_message" >> "$SCRIPT_LOG"
}
# - EOF Functions --------------------------------------------------------------

# - Parse Parameters -----------------------------------------------------------
while getopts ":p:nvdDqH:r:c:h" opt; do
    case "$opt" in
        p) REMOTE_PEER="$OPTARG" ;;
        n) DRYRUN=true ; RSYNC_OPTS+=" --dry-run" ;;
        v) VERBOSE=true ; RSYNC_OPTS+=" -v" ;;
        d) DEBUG=true ;;
        D) DELETE=true ; RSYNC_OPTS+=" --delete" ;;
        q) QUIET=true ;;
        H) IFS=' ' read -r -a PEER_HOSTS <<< "$OPTARG" ;;
        r) REMOTE_BASE="$OPTARG" ;;
        c) CONFIG_FILE="$OPTARG" ; [[ -f "$CONFIG_FILE" ]] && source "$CONFIG_FILE" ;;
        h|*) Usage ;;
    esac
done
shift $((OPTIND -1))

SOURCE="$1"
[[ -z "$SOURCE" || -z "$REMOTE_PEER" ]] && Usage

# check PEER_HOSTS
if [[ ${#PEER_HOSTS[@]} -eq 0 ]]; then
    log_message ERROR "PEER_HOSTS is empty. Please check configuration or parameters."
    exit 1
fi

ABS_SOURCE=$(realpath "$SOURCE")

if [[ -d "$ABS_SOURCE" ]]; then
    RSYNC_TARGET="${ABS_SOURCE%/}/"
else
    RSYNC_TARGET="$ABS_SOURCE"
fi

THIS_HOST=$(hostname -s)
REMOTE_PATH="$REMOTE_BASE"
[[ -z "$REMOTE_PATH" ]] && REMOTE_PATH="$ABS_SOURCE"

log_message INFO "Syncing from $REMOTE_PEER:$REMOTE_PATH to local: $THIS_HOST:$RSYNC_TARGET"
rsync $RSYNC_OPTS -e "ssh -p ${SSH_PORT}" "${SSH_USER}@${REMOTE_PEER}:${REMOTE_PATH}" "$RSYNC_TARGET"
if [[ $? -ne 0 ]]; then
    log_message ERROR "Initial sync from $REMOTE_PEER failed"
    exit 2
else
    log_message INFO "Initial sync from $REMOTE_PEER succeeded"
fi

# Sync from local to other peers (excluding REMOTE_PEER and THIS_HOST)
for HOST in "${PEER_HOSTS[@]}"; do
    if [[ "$HOST" == "$THIS_HOST" || "$HOST" == "$REMOTE_PEER" ]]; then
        log_message DEBUG "Skipping $HOST"
        continue
    fi

    log_message INFO "Syncing to $HOST:$RSYNC_TARGET ..."
    rsync $RSYNC_OPTS -e "ssh -p ${SSH_PORT}" "$RSYNC_TARGET" "${SSH_USER}@${HOST}:${RSYNC_TARGET}"
    if [[ $? -ne 0 ]]; then
        log_message ERROR "Failed to sync to $HOST"
        SYNC_FAILURE+=("$HOST")
    else
        log_message INFO "Sync to $HOST completed"
        SYNC_SUCCESS+=("$HOST")
    fi

done

# Summary ---------------------------------------------------------------------
if [[ "$VERBOSE" == true && "$QUIET" != true ]]; then
    log_message INFO "--- Sync Summary ---"
    log_message INFO "Source : $REMOTE_PEER"
    log_message INFO "Local  : $THIS_HOST"
    log_message INFO "Targets: ${SYNC_SUCCESS[*]}"
    log_message INFO "Failed : ${SYNC_FAILURE[*]}"
fi
# - EOF ------------------------------------------------------------------------
