#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: get_seps_pwd.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2025.06.05
# Version....: v0.2.0
# Purpose....: Extract password for a given connect string from Oracle Wallet
# Notes......: Uses mkstore. Password must be entered only once.
# Reference..: https://github.com/oehrlis
# License....: Apache License Version 2.0
# ------------------------------------------------------------------------------
# Modified...:
# 2025.06.05 oehrli - initial version
# ------------------------------------------------------------------------------

# - Default Values -------------------------------------------------------------
SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
SCRIPT_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_BASE=$(dirname ${SCRIPT_BIN_DIR})
SCRIPT_ETC_DIR="${SCRIPT_BASE}/etc"
SCRIPT_LOG_DIR="${SCRIPT_BASE}/log"
SCRIPT_LOG="${SCRIPT_LOG_DIR}/${SCRIPT_NAME%.sh}_$(date +%Y%m%d_%H%M%S).log"
DEBUG=false
WALLET_DIR="${cdn:-${ORACLE_BASE}/network}/wallet"
WALLET_PASSWORD="${WALLET_PASSWORD:-}"
CONNECT_STRING=""
QUIET=false
# - EOF Default Values ---------------------------------------------------------

# - Functions ------------------------------------------------------------------

# Function...: Usage
# Purpose....: Display usage information and exit
# Usage......: Usage
# Parameters.: None
# Globals....: SCRIPT_NAME
# ------------------------------------------------------------------------------
function Usage {
    cat <<EOF

Usage: ${SCRIPT_NAME} -s <connect_string> [-q]

Options:
  -s <connect_string>   Required. The DB alias (TNS name) to match.
  -q                    Quiet mode. Output only the password.
  -h                    Show this help message.
EOF
    exit 1
}

# Function...: log_message
# Purpose....: Print and log a message with optional color and support for multiline strings
# Parameters.: $1 - Log level (INFO, DEBUG, ERROR)
#              $2 - Message text (can include newlines)
# Globals....: SCRIPT_LOG, DEBUG
# ------------------------------------------------------------------------------ 
function log_message {
    local level="$1"
    local message="$2"
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

# Function...: get_entry
# Purpose....: Get a specific entry from the Oracle Wallet using mkstore
#              This function retrieves the value of a specified key from the wallet.
#              It uses mkstore to view the entry and extracts the value using grep and awk.
#              If the entry does not exist, it returns an empty string.
# Usage......: get_entry <key>
# Parameters.: $key - The key to retrieve from the wallet (e.g., oracle.security.client.connect_string1)
# Globals....: WALLET_DIR, WALLET_PASSWORD
# Returns....: The value associated with the key, or an empty string if not found.
# Dependencies: mkstore, grep, awk
# ------------------------------------------------------------------------------ 
function get_entry {
    local key="$1"
    echo "$WALLET_PASSWORD" | mkstore -wrl "$WALLET_DIR" -viewEntry "$key" 2>/dev/null \
        | grep -i "$key" | awk -F '= ' '{print $2}'
}
# - EOF Functions --------------------------------------------------------------

# - Parse Parameters -----------------------------------------------------------
while getopts "s:qh" opt; do
    case "$opt" in
        s) CONNECT_STRING="$OPTARG" ;;
        q) QUIET=true ;;
        h|*) Usage ;;
    esac
done

# check if required parameters are set
[[ -z "$CONNECT_STRING" ]] && Usage

# Load password from encoded file if available
if [[ -f "$WALLET_DIR/.wallet_pwd" ]]; then
    WALLET_PASSWORD=$(base64 -d "$WALLET_DIR/.wallet_pwd")
fi

# Prompt for password if not yet loaded
if [[ -z "$WALLET_PASSWORD" ]]; then
    read -s -p "Enter wallet password: " WALLET_PASSWORD
    echo
fi

# Count how many connect string entries exist
COUNT=$(echo "$WALLET_PASSWORD" | mkstore -wrl "$WALLET_DIR" -list 2>/dev/null \
        | grep -c oracle.security.client.connect_string)
log_message DEBUG "Found $COUNT connect string entries in wallet."
# If no connect strings are found, exit with an error
if [[ $COUNT -eq 0 ]]; then
    log_message ERROR "No connect strings found in wallet."
    exit 1
fi
# - EOF Parse Parameters -------------------------------------------------------
# - Main Script Logic ----------------------------------------------------------
# Search for matching connect string
for i in $(seq 1 $COUNT); do
    ALIAS=$(get_entry oracle.security.client.connect_string$i)
    if [[ "${ALIAS,,}" == "${CONNECT_STRING,,}" ]]; then
        # If a match is found, retrieve the password
        log_message INFO "Found connect string '$CONNECT_STRING' in wallet."
        PASSWORD=$(get_entry oracle.security.client.password$i)
        if $QUIET; then
            # If in quiet mode, just output the password
            echo "$PASSWORD"
        else
            # If not in quiet mode, log the match
            log_message INFO "Match found for connect string '$CONNECT_STRING':"
            log_message INFO "  Password: $PASSWORD"
        fi
        exit 0
    fi
done

# - If we reach here, no match was found
log_message ERROR "Connect string '$CONNECT_STRING' not found in wallet."
exit 1
# - EOF ------------------------------------------------------------------------
