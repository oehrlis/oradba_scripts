#!/bin/bash
# ------------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructure and Security, 5630 Muri, Switzerland
# ------------------------------------------------------------------------------
# Name.......: config_krb5_tns.sh
# Author.....: Stefan Oehrli (oes) stefan.oehrli@oradba.ch
# Editor.....: Stefan Oehrli
# Date.......: 2023.11.08
# Version....: v0.1.0
# Purpose....: This script configures SQLNet for Kerberos authentication in Oracle
#              environments. It facilitates the setup of Kerberos authentication by
#              managing keytab files, krb5 configurations, and sqlnet.ora entries.
# Notes......: This script assumes the presence of required Kerberos utilities and
#              Oracle environment variables.
# Reference..: Documentation for Oracle Database Security 19c
# License....: Licensed under the Apache License, Version 2.0 (the "License");
#              you may not use this file except in compliance with the License.
#              You may obtain a copy of the License at
#              http://www.apache.org/licenses/LICENSE-2.0
#              Unless required by applicable law or agreed to in writing, software
#              distributed under the License is distributed on an "AS IS" BASIS,
#              WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#              See the License for the specific language governing permissions and
#              limitations under the License.
# ------------------------------------------------------------------------------
# - Customization --------------------------------------------------------------
# Customization section: Define default values and environment variables
DEFAULT_DIT_BASE="dc=trivadislabs,dc=com"       # Directory Tree Base (DIT) distinguished name (DN)
DEFAULT_DOMAIN_NAME="trivadislabs.com"          # Generic domain name
DEFAULT_KRB5_CONF_FILE=""                       # Default value for the source krb5.conf file
DEFAULT_KRB5_CRYPTO="aes256-cts-hmac-sha1-96"   # Default kerberos crypto for the keytab file
DEFAULT_KRB5_KEYTAB_FILE=""                     # Default value for the keytab file
DEFAULT_KRB5_REALM="TRIVADISLABS.COM"           # KDC / AD Realm
DEFAULT_PDC_NAME="ad.trivadislabs.com"          # Generic PDC Name used
DEFAULT_SQLNET_ORA_FILE=""                      # Default value for the source sqlnet.ora file
DEFAULT_UX_DOMAIN_NAME="trivadislabs.com"       # Domain Name used for Linux / Unix servers

# default values also read from environment
ORADBA_VERBOSE=${ORADBA_VERBOSE:-"FALSE"}       # Set verbose mode based on environment or default value
ORADBA_DEBUG=${ORADBA_DEBUG:-"FALSE"}           # Set debug mode based on environment or default value
ORADBA_QUIET=${ORADBA_QUIET:-"FALSE"}           # Set quiet mode based on environment or default value
# - End of Customization -------------------------------------------------------

# - Customization of configuration files template ------------------------------
# Template for sqlnet.ora configuration file
SQLNET_ORA_CONTENT=$(cat <<EOF
# - KERBEROS5 Settings --------------------------------------------------------
SQLNET.AUTHENTICATION_SERVICES=(BEQ,KERBEROS5PRE,KERBEROS5)
SQLNET.AUTHENTICATION_KERBEROS5_SERVICE = oracle
SQLNET.FALLBACK_AUTHENTICATION = TRUE
SQLNET.KERBEROS5_KEYTAB = $TNS_ADMIN/krb5.keytab
SQLNET.KERBEROS5_CONF = $TNS_ADMIN/krb5.conf
SQLNET.KERBEROS5_CONF_MIT=TRUE
# - EOF KERBEROS5 -------------------------------------------------------------
EOF
)

# Template for kerberos configuration file krb5.conf
KRB5_CONF_CONTENT=$(cat <<'EOF'
# -----------------------------------------------------------------------------
# OraDBA - Oracle Database Infrastructur and Security, 5630 Muri, Switzerland
# -----------------------------------------------------------------------------
# Name.......: krb5.conf
# Author.....: Stefan Oehrli (oes) stefan.oehrli@trivadis.com
# Editor.....: Stefan Oehrli
# Date.......: 2021.09.28
# Revision...: --
# Purpose....: Oracle Kerberos Configuration File
# Notes......: --
# Reference..: Oracle Database Security 19c
# -----------------------------------------------------------------------------
[libdefaults]
forwardable = true
default_realm = $ORADBA_KRB5_REALM
 
[realms]
  $ORADBA_KRB5_REALM = {
    kdc = $ORADBA_PDC_NAME
  }
 
[domain_realm]
.$ORADBA_UX_DOMAIN_NAME = $ORADBA_KRB5_REALM
$ORADBA_UX_DOMAIN_NAME = $ORADBA_KRB5_REALM
.$ORADBA_DOMAIN_NAME = $ORADBA_KRB5_REALM
$ORADBA_DOMAIN_NAME = $ORADBA_KRB5_REALM
.$CURRENT_DOMAIN_NAME = $ORADBA_KRB5_REALM
$CURRENT_DOMAIN_NAME = $ORADBA_KRB5_REALM
# -----------------------------------------------------------------------------
EOF
)
# - End of Customization of configuration files --------------------------------

# - Default Values -------------------------------------------------------------
# source genric environment variables and functions
SCRIPT_NAME=$(basename ${BASH_SOURCE[0]})
SCRIPT_CONF="$(basename $SCRIPT_NAME .sh).conf"
SCRIPT_BIN_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
SCRIPT_BASE=$(dirname ${SCRIPT_BIN_DIR})
DATE_STAMP=$(date '+%Y%m%d')
VERSION=v0.1.0
VERBOSE=''                  # enable verbose mode
QUIET=''                    # enable quiet mode
DEBUG=''                    # enable debug mode
KEEP=''                     # Flag to keep temporary files
TOOLS="ldapsearch kvno ktutil oklist okinit"    # List of default tools to check
VARIABLES="TNS_ADMIN"                           # List of default variable to check
padding='....................................'
COMMENT="FALSE"

# Define color codes for various log levels
ORADBA_SUCCESS='\033[0;32m'    # Green for success messages
ORADBA_WARN='\033[0;33m'       # Yellow for warning messages
ORADBA_ERROR='\033[0;31m'      # Red for error messages
ORADBA_INFO='\033[0;30m'       # Black for info messages
ORADBA_DEBUG='\033[0;34m'      # Blue for debug messages
NC='\033[0m'                   # No color/reset

# define logfile and logging
export LOG_BASE=${LOG_BASE:-"${SCRIPT_BIN_DIR}"} # Use script directory as default logbase
TEMPFILE="$LOG_BASE/$(basename $SCRIPT_NAME .sh)_$$.tmp"
TIMESTAMP=$(date "+%Y.%m.%d_%H%M%S")
readonly LOGFILE="$LOG_BASE/$(basename $SCRIPT_NAME .sh)_$TIMESTAMP.log"
# - EOF Default Values ---------------------------------------------------------

# - Functions ------------------------------------------------------------------
# ------------------------------------------------------------------------------
# Function...: Usage
# Purpose....: Print usage and help
# ------------------------------------------------------------------------------
function Usage {
    cat << EOF

Usage: ${SCRIPT_NAME} [OPTIONS]

Script to configure SQLNet for Kerberos.

Options:
    -h                  Display this help message.
    -v                  Enable verbose mode.
    -q                  Enable quiet mode.
    -d                  Enable debug mode.
    -k                  Keep stuff and do not remove temp and password files.
    -C                  Comment out sqlnet.ora kerberos entries
    -f <CONFIG>         Specify a custom configuration file.
    -K <KEYTAB_FILE>    Specify the Kerberos keytab file.
    -s <SQLNET_ORA>     Specify the sqlnet.ora template file.
    -k <KRB5_CONF>      Specify the krb5.conf template file.
    -D <KRB5_USER>      Specify the Kerberos principal name.
    -w <KRB5_PASSWORD>  Specify the Kerberos password.
    -j <PWD_FILE>       Specify the Kerberos password file.
    -R <KRB_REALM>      Specify the Kerberos realm.
    -P <PDC_NAME>       Specify the Primary Domain Controller name.
    -X <UX_DOMAIN>      Specify the Unix domain name.
    -N <DOMAIN_NAME>    Specify the generic domain name.
    Logfile : ${LOGFILE}

    The script needs different information for the configuration of Kerberos.
    The required information like user name, password etc., can be specified in
    the following ways:

    Variant 1: Setting the values via commandline parameter
    Variant 2: Setting the corresponding environment variables
    Variant 3: Setting of the corresponding environment variables in a
               configuration file respectively in $SCRIPT_BIN_DIR/$SCRIPT_CONF
    Variant 4: Adjusting the values in this script, in the customization section.

    The following variables are available for configuraton:

    Variable Name               Mandatory Description
    --------------------------- --------- ---------------------------------------------
    ORADBA_KRB5_USER            yes       Kerberos service user name (default $DEFAULT_KRB5_REALM)
    ORADBA_KRB5_PASSWORD        no        Password for Kerberos service user account.
                                          Password file is prefered. If not available is requested
    ORADBA_KRB5_PASSWORD_FILE   yes       Base64 encoded file with the Kerberos
                                          service user account password
    ORADBA_KRB5_REALM           yes       Name of the Kerberos Realm / KDC (default $DEFAULT_KRB5_REALM)
    ORADBA_PDC_NAME             yes       Name of the Active Directory PDC (default $DEFAULT_PDC_NAME)    
    ORADBA_UX_DOMAIN_NAME       yes       Name of the Unix domain name (default $DEFAULT_UX_DOMAIN_NAME)        
    ORADBA_DOMAIN_NAME          no        Name of the common domain name (default $DEFAULT_DOMAIN_NAME)
    ORADBA_KRB5_KEYTAB_FILE     no        Kerberos Keytab file (default $(hostname -s).$CURRENT_DOMAIN_NAME.keytab")
    ORADBA_KRB5_CONF_FILE       no        Specific krb5.conf configuration file
                                          to be used for Kerberos. The default
                                          behavior is to use the embedded file.
    ORADBA_SQLNET_ORA_FILE      no        Specific sqlnet.ora configuration file
                                          to be used for Kerberos. The default
                                          behavior is to update the existing
                                          sqlnet.ora.
EOF
    exit 0
}

# ------------------------------------------------------------------------------
# Function...: command_exists
# Purpose....: check if a command exists. 
# ------------------------------------------------------------------------------
function command_exists () {
    command -v $1 >/dev/null 2>&1;
}

# ------------------------------------------------------------------------------
# Function:     log_message
# Purpose:      Log messages with optional levels and newline control.
# Usage:        log_message [-n] [LOG_LEVEL] "message"
# Options:
#   -n          Omit newline at message end.
# Arguments:
#   LOG_LEVEL   One of INFO, WARN, ERROR, SUCCESS, DEBUG (default: INFO).
# Environment:
#   LOGFILE     Required. File for logging messages.
#   VERBOSE     If set, echoes to both stdout and log file.
#   QUIET       If set, echoes only to log file.
#   DEBUG       If set, logs DEBUG messages to stdout and file.
# Examples:
#   log_message -n INFO "Process started"
#   log_message ERROR "Error occurred"
#   log_message DEBUG "Debug info"
# Notes:
#   LOGFILE must be set. LOG_LEVEL is case-insensitive.
# Returns:      0 on success, non-zero on error.
# ------------------------------------------------------------------------------
function log_message() {
    local newline=true      # Local variable for newline flag
    local message           # Local variable for message
    local level="INFO"      # Local variable for log level
    local color             # Local variable for color
    local OPTIND flag       # Local variable for options parsed by getopts

    # Parse options: if the first argument is '-n', do not append newline.
    while getopts ":n" flag; do
        case "$flag" in
            n) newline=false ;;
            *) ;;
        esac
    done
    shift $((OPTIND-1))

    # Check if the next argument is a log level
    if [[ "$1" =~ ^(INFO|WARN|ERROR|SUCCESS|DEBUG)$ ]]; then
        level=$1
        shift
    fi

    # Remaining arguments are the message
    message="$*"

    # Assign the color code based on the level
    case "${level^^}" in
        INFO)       color=${ORADBA_INFO :-'\033[0;30m'} ;;      # Black for info messages
        WARN)       color=${ORADBA_WARN:-'\033[0;33m'} ;;      # Yellow for warning messages
        ERROR)      color=${ORADBA_ERROR:-'\033[0;31m'} ;;     # Red for error messages
        SUCCESS)    color=${ORADBA_SUCCESS:-'\033[0;32m'} ;;   # Green for info messages
        DEBUG)      color=${ORADBA_DEBUG:-'\033[0;36m'} ;;     # Blue for debug messages
        *)          color=${NC:-'\033[0m'} ;;                  # No color/reset
    esac

    # Function to handle appending message with or without a newline
    append_log() {
        if [ "$newline" = true ]; then
            echo -e "$color$1$NC"
        else
            echo -n -e "$color$1$NC"
        fi
    }

    # Check if LOGFILE variable is set or not empty
    if [ -z "${LOGFILE}" ]; then
        echo "Error: LOGFILE is not set." >&2
        return 1
    fi

    # If neither VERBOSE nor QUIET is set, send ERROR to stderr and logfile
    if [[ "${level^^}" == "ERROR" ]]; then
        append_log "$message" >&2 | tee -a "${LOGFILE}"
    elif [[ "${level^^}" == "WARN" && ! -n "${QUIET}" ]]; then
        append_log "$message" >&2 | tee -a "${LOGFILE}"
    # Handle DEBUG level when DEBUG variable is set
    elif [[ "${level^^}" == "DEBUG" && -n "${DEBUG}" ]]; then
        append_log "$message" | tee -a "${LOGFILE}"
    # If VERBOSE is set, echo to both stdout and logfile DEBUG message will be skipped
    elif  [[ "${level^^}" != "DEBUG" && -n "${VERBOSE}" ]]; then
        append_log "$message" | tee -a "${LOGFILE}"
    # If QUIET is set, echo only to logfile. DEBUG message will be skipped
    elif [[ "${level^^}" != "DEBUG" && -n "${QUIET}" ]]; then
        append_log "$message" >> "${LOGFILE}"
    # If neither VERBOSE nor QUIET is set, default to only logfile. DEBUG message will be skipped
    elif [[ "${level^^}" != "DEBUG" ]]; then
        append_log "$message" >> "${LOGFILE}"
    fi
}

# ------------------------------------------------------------------------------
# Function...: exit_with_status
# Purpose....: Gracefully exits the script with an optional error code and message.
# Usage......: exit_with_status [ERROR_CODE [ERROR_VALUE]]
# Arguments..: ERROR_CODE  Exit status (default 0).
#              ERROR_VALUE Context for the error (e.g., filename or command).
# Env........: ORADBA_SUCCESS, ORADBA_ERROR for message formatting.
#              SCRIPT_NAME for the script's name in messages.
#              TEMPFILE, TNSPING_TEMPFILE for cleanup.
# Notes......: Set message format vars and SCRIPT_NAME. Un/comment cleanup as
#              needed. Exits with ERROR_CODE or 0 by default. Ensure ORADBA_SUCCESS
#              and ORADBA_ERROR are set.
# Examples...: clean_quit                      # exit cleanly
#              clean_quit 1                    # exit with generic error
#              clean_quit 2 "bad input"        # exit with custom message
# ------------------------------------------------------------------------------
function exit_with_status() {
    # define default values for function arguments
    error=${1:-"0"}
    error_value=${2:-""}

    case ${error} in
        0)  log_message SUCCESS "SUCCESS : Successfully finish ${SCRIPT_NAME}" ;;
        1)  log_message ERROR "ERROR: Exit Code ${error}. Wrong amount of arguments. See usage for correct one." >&2;;
        2)  log_message ERROR "ERROR: Exit Code ${error}. Wrong arguments (${error_value}). See usage for correct one." >&2;;
        3)  log_message ERROR "ERROR: Exit Code ${error}. Missing mandatory argument (${error_value}). See usage ..." >&2;;
        5)  log_message ERROR "ERROR: Exit Code ${error}. Variable ${error_value} not defined ..." >&2;;
        10) log_message ERROR "ERROR: Exit Code ${error}. Command ${error_value} isn't installed/available on this system..." >&2;;
        20) log_message ERROR "ERROR: Exit Code ${error}. File ${error_value} already exists..." >&2;;
        21) log_message ERROR "ERROR: Exit Code ${error}. Directory ${error_value} is not writeable..." >&2;;
        22) log_message ERROR "ERROR: Exit Code ${error}. Can not read file ${error_value} ..." >&2;;
        23) log_message ERROR "ERROR: Exit Code ${error}. Can not write file ${error_value} ..." >&2;;
        25) log_message ERROR "ERROR: Exit Code ${error}. Can not read file password file ${error_value} ..." >&2;;
        26) log_message ERROR "ERROR: Exit Code ${error}. Can not write tempfile file ${error_value} ..." >&2;;
        33) log_message ERROR "ERROR: Exit Code ${error}. Error running ${error_value} ..." >&2;;
        50) log_message ERROR "ERROR: Exit Code ${error}. Missing mandatory values ${error_value} ..." >&2;;
        90) log_message ERROR "ERROR: Exit Code ${error}. Received signal SIGINT / Interrupt / CTRL-C ..." >&2;;
        91) log_message ERROR "ERROR: Exit Code ${error}. Received signal TERM to terminate the script ..." >&2;;
        92) log_message ERROR "ERROR: Exit Code ${error}. Received signal ..." >&2;;
        99) log_message INFO "INFO : Just wanna say hallo." ;;
        ?)  log_message ERROR "ERROR: Exit Code ${1}. Unknown Error.";;
    esac

   cleanup_temp_files # Call to the cleanup function
    exit ${error}
}

# ------------------------------------------------------------------------------
# Function...: cleanup_temp_files
# Purpose....: clean up tempfiles 
# ------------------------------------------------------------------------------
cleanup_temp_files() {
    if [ -z "${KEEP}" ]; then
        if [ -n "$TEMPFILE" ]; then
            log_message DEBUG "DEBUG: Clean up tempfile $TEMPFILE"
            [[ -f "$TEMPFILE" ]] && rm "$TEMPFILE"
        else
            log_message DEBUG "DEBUG: Nothing to clean up"
        fi
        if [ -n "$ORADBA_KRB5_PASSWORD_FILE" ]; then
            log_message DEBUG "DEBUG: Clean up password file $ORADBA_KRB5_PASSWORD_FILE"
            [[ -f "$ORADBA_KRB5_PASSWORD_FILE" ]] && rm "$ORADBA_KRB5_PASSWORD_FILE"
        else
            log_message DEBUG "DEBUG: Nothing to clean up"
        fi
    else
        log_message DEBUG "DEBUG: Keep enabled, do not remove any thing"
    fi
}
# - EOF Functions --------------------------------------------------------------
# - Initialization -------------------------------------------------------------
# Define a bunch of bash option see 
# https://www.gnu.org/software/bash/manual/html_node/The-Set-Builtin.html
set -o nounset                      # stop script after 1st cmd failed
set -o errexit                      # exit when 1st unset variable found
set -o pipefail                     # pipefail exit after 1st piped commands failed

# initialize logfile
touch $LOGFILE 2>/dev/null
exec &> >(tee -a "$LOGFILE")        # Open standard out at `$LOG_FILE` for write.  
exec 2>&1                           # Forward standard error STDERR to STDOUT

# set the default value for the internal VERBOSE, DEBUG and QUIET variables
[[ "${ORADBA_VERBOSE^^}" == "TRUE" ]]  && VERBOSE=1
[[ "${ORADBA_DEBUG^^}" == "TRUE" ]]    && DEBUG=1  && VERBOSE=1
[[ "${ORADBA_QUIET^^}" == "TRUE" ]]    && QUIET=1  && VERBOSE=''

CURRENT_DOMAIN_NAME=$(hostname -f|sed 's/^[^\.]*\.//')

# usage and getopts
while getopts "hvqdlkf:K:s:k:D:w:j:R:P:X:CN:" arg; do
    case $arg in
        v) VERBOSE=1;;
        k) KEEP=1;;
        d) DEBUG=1 && VERBOSE=1;;
        q) QUIET=1 && VERBOSE='' && DEBUG='' ;;
        f) CLI_CUSTOM_CONF_FILE="${OPTARG}";;
        K) CLI_KRB5_KEYTAB_FILE="${OPTARG}";;
        s) CLI_SQLNET_ORA_FILE="${OPTARG}";;
        k) CLI_KRB5_CONF_FILE="${OPTARG}";;
        D) CLI_KRB5_USER="${OPTARG}";;
        w) CLI_KRB5_PASSWORD="${OPTARG}";;
        j) CLI_KRB5_PASSWORD_FILE="${OPTARG}";;
        R) CLI_KRB5_REALM="${OPTARG}";;
        P) CLI_PDC_NAME="${OPTARG}";;
        X) CLI_UX_DOMAIN_NAME="${OPTARG}";;
        N) CLI_DOMAIN_NAME="${OPTARG}";;
        C) COMMENT="TRUE";;
        h) Usage 0;;
        ?) Usage 2 "$*";;
    esac
done

# forware STDOUT to logfile in QUIET mode
if [[ -n "${QUIET}" ]]; then
    exec >> "$LOGFILE"
fi

log_message SUCCESS "INFO : Start ${SCRIPT_NAME} on host $(hostname) at $(date)"
log_message INFO "INFO : Check prerequisites ------------------------------------------------"
# check the list of mandatory variables if they are set
for i in ${VARIABLES} ; do
    log_message -n DEBUG $(printf "INFO : Check if variable %s is set .....%s" "$i" "${padding:${#i}}")
    if [ -n "${!i}" ] && [ -d "${!i}" ] ; then 
        log_message DEBUG OK
    else
        log_message DEBUG NOK
        exit_with_status 5 $i
    fi
done

# check the list of mandatory tools if they are available
for i in ${TOOLS}; do
    log_message -n DEBUG $(printf "INFO : Check if command %s is available %s" "${i}" "${padding:${#i}}")
    if ! command_exists ${i}; then
        log_message DEBUG NOK
        exit_with_status 10 ${i}
    else
        log_message DEBUG OK
    fi
done

# load config if a config file is defined
CUSTOM_CONF_FILE=${CLI_CUSTOM_CONF_FILE:-"$SCRIPT_BIN_DIR/$SCRIPT_CONF"}
if [ -f "$CUSTOM_CONF_FILE" ]; then
    log_message INFO "INFO : source config file $CUSTOM_CONF_FILE"
    . $CUSTOM_CONF_FILE
else
    log_message INFO "INFO : no config file sourced"
fi

# Sets the VARIABLE to the value of VARIABLE if set, otherwise to commandline
# variable, or defaults to an empty / defined string if neither is set.
ORADBA_KRB5_USER=${ORADBA_KRB5_USER:-${CLI_KRB5_USER:-""}}
ORADBA_KRB5_PASSWORD=${ORADBA_KRB5_PASSWORD:-${CLI_KRB5_PASSWORD:-""}}
ORADBA_KRB5_PASSWORD_FILE=${ORADBA_KRB5_PASSWORD_FILE:-${CLI_KRB5_PASSWORD_FILE:-""}}
ORADBA_KRB5_REALM=${ORADBA_KRB5_REALM:-${CLI_KRB5_REALM:-"${DEFAULT_KRB5_REALM}"}}
ORADBA_PDC_NAME=${ORADBA_PDC_NAME:-${CLI_PDC_NAME:-"${DEFAULT_PDC_NAME}"}}
ORADBA_UX_DOMAIN_NAME=${ORADBA_UX_DOMAIN_NAME:-${CLI_UX_DOMAIN_NAME:-"${DEFAULT_UX_DOMAIN_NAME}"}}
ORADBA_DOMAIN_NAME=${ORADBA_DOMAIN_NAME:-${CLI_DOMAIN_NAME:-"${DEFAULT_DOMAIN_NAME}"}}
ORADBA_KRB5_KEYTAB_FILE=${ORADBA_KRB5_KEYTAB_FILE:-${CLI_KRB5_KEYTAB_FILE:-"$(hostname -s).$CURRENT_DOMAIN_NAME.keytab"}}
ORADBA_SQLNET_ORA_FILE=${ORADBA_SQLNET_ORA_FILE:-${CLI_SQLNET_ORA_FILE:-""}}
ORADBA_KRB5_CONF_FILE=${ORADBA_KRB5_CONF_FILE:-${CLI_KRB5_CONF_FILE:-""}}

# define default value for the KRB5 user name
if [ -z $ORADBA_KRB5_USER ]; then
    log_message INFO "INFO : Use hostname $(hostname -s) as kerberos service user"
    ORADBA_KRB5_USER=$(hostname -s)
fi

# Check if the ORADBA_KRB5_PASSWORD_FILE environment variable is set
if [ -n "${ORADBA_KRB5_PASSWORD_FILE}" ]; then 
    # Check if the specified password file exists and is readable
    if [ -f "${ORADBA_KRB5_PASSWORD_FILE}" ] ; then
        log_message DEBUG "DEBUG: Password file ${ORADBA_KRB5_PASSWORD_FILE} defined and readable"
    else
        # Log an error and exit if the password file is not readable
        log_message ERROR "ERR  : Password file ${ORADBA_KRB5_PASSWORD_FILE} not readable"
        exit_with_status 22 ${ORADBA_KRB5_PASSWORD_FILE}
    fi
# Check if a default password file exists in the script's bin directory
elif [ -f "$SCRIPT_BIN_DIR/.${ORADBA_KRB5_USER}.pwd" ] ; then
    log_message INFO "INFO : Fallback to password file $SCRIPT_BIN_DIR/.${ORADBA_KRB5_USER}.pwd"
    ORADBA_KRB5_PASSWORD_FILE="$SCRIPT_BIN_DIR/.${ORADBA_KRB5_USER}.pwd"
# Check if a default password file exists in the TNS_ADMIN directory
elif [ -f "$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd" ] ; then
    log_message INFO "INFO : Fallback to password file $TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
    ORADBA_KRB5_PASSWORD_FILE="$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
# Check if ORADBA_KRB5_PASSWORD is set and use it to create a password file
elif [ -n "${ORADBA_KRB5_PASSWORD}" ]; then
    log_message INFO "INFO : Use the command-line password and store it in $TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd as base64-encoded text."
    echo ${ORADBA_KRB5_PASSWORD} | base64 > "$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
    chmod 600 "$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
# If ORADBA_KRB5_PASSWORD is not set and QUIET mode is not active, prompt the user for the password
elif [[ -z "${ORADBA_KRB5_PASSWORD}" && -z "${QUIET}" ]]; then
    log_message DEBUG "DEBUG: Request password interactively"
    echo -n Kerberos Principal Name Password: 
    read -s ORADBA_KRB5_PASSWORD
    echo
    echo ${ORADBA_KRB5_PASSWORD} | base64 > "$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
    chmod 600 "$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
    ORADBA_KRB5_PASSWORD_FILE="$TNS_ADMIN/.${ORADBA_KRB5_USER}.pwd"
    # If neither a password nor a password file is set, log an error and exit
else
    log_message ERROR "ERR : Missing credential for Kerberos service principal"
    exit_with_status 50 "Kerberos credentials"
fi

log_message DEBUG "DEBUG: Current variables and settings ------------------------------------"
log_message DEBUG "DEBUG: SCRIPT_NAME               : $SCRIPT_NAME"
log_message DEBUG "DEBUG: SCRIPT_CONF               : $SCRIPT_CONF"
log_message DEBUG "DEBUG: SCRIPT_BIN_DIR            : $SCRIPT_BIN_DIR"
log_message DEBUG "DEBUG: SCRIPT_BASE               : $SCRIPT_BASE"
log_message DEBUG "DEBUG: VERBOSE                   : $VERBOSE"
log_message DEBUG "DEBUG: QUIET                     : $QUIET"
log_message DEBUG "DEBUG: DEBUG                     : $DEBUG" 
log_message DEBUG "DEBUG: TOOLS                     : $TOOLS" 
log_message DEBUG "DEBUG: VARIABLES                 : $VARIABLES" 
log_message DEBUG "DEBUG: TNS_ADMIN                 : $TNS_ADMIN"
log_message DEBUG "DEBUG: ORADBA_DOMAIN_NAME        : $ORADBA_DOMAIN_NAME"
log_message DEBUG "DEBUG: ORADBA_KRB5_CONF_FILE     : $ORADBA_KRB5_CONF_FILE"
log_message DEBUG "DEBUG: ORADBA_KRB5_KEYTAB_FILE   : $ORADBA_KRB5_KEYTAB_FILE"
log_message DEBUG "DEBUG: ORADBA_KRB5_PASSWORD      : $ORADBA_KRB5_PASSWORD"
log_message DEBUG "DEBUG: ORADBA_KRB5_PASSWORD_FILE : $ORADBA_KRB5_PASSWORD_FILE"
log_message DEBUG "DEBUG: ORADBA_KRB5_REALM         : $ORADBA_KRB5_REALM"
log_message DEBUG "DEBUG: ORADBA_KRB5_USER          : $ORADBA_KRB5_USER"
log_message DEBUG "DEBUG: ORADBA_PDC_NAME           : $ORADBA_PDC_NAME"
log_message DEBUG "DEBUG: ORADBA_SQLNET_ORA_FILE    : $ORADBA_SQLNET_ORA_FILE"
log_message DEBUG "DEBUG: ORADBA_UX_DOMAIN_NAME     : $ORADBA_UX_DOMAIN_NAME"

# example log modes
# log_message         "     : A message with no mode specified" 
# log_message INFO    "INFO : A message in level INFO     Modes Q=>$QUIET, V=>$VERBOSE, D=>$DEBUG"
# log_message WARN    "WARN : A message in level WARN     Modes Q=>$QUIET, V=>$VERBOSE, D=>$DEBUG"
# log_message ERROR   "ERR  : A message in level ERROR    Modes Q=>$QUIET, V=>$VERBOSE, D=>$DEBUG"
# log_message SUCCESS "SUCC : A message in level SUCCESS  Modes Q=>$QUIET, V=>$VERBOSE, D=>$DEBUG"
# log_message DEBUG   "DEBUG: A message in level DEBUG    Modes Q=>$QUIET, V=>$VERBOSE, D=>$DEBUG"

log_message INFO "INFO : Start configuring --------------------------------------------------"

log_message INFO "INFO : Update sqlnet.ora --------------------------------------------------"
# Update sqlnet.ora
if [ -z "$ORADBA_SQLNET_ORA_FILE" ]; then
    log_message INFO "INFO : Use embedded sqlnet configuration to update new sqlnet.ora file"
    if [ -f "$TNS_ADMIN/sqlnet.ora" ]; then
        log_message INFO "INFO : save existing sqlnet.ora file as sqlnet.ora.${DATE_STAMP}"
        cp "$TNS_ADMIN/sqlnet.ora" "$TNS_ADMIN/sqlnet.ora.${DATE_STAMP}"
        log_message INFO "INFO : remove KRB5 config in sqlnet.ora file"
        sed -i '/AUTHENTICATION/d' $TNS_ADMIN/sqlnet.ora
        sed -i '/KERBEROS5/d' $TNS_ADMIN/sqlnet.ora

        log_message INFO "INFO : update sqlnet.ora file"
        if [ "${COMMENT^^}" == "TRUE" ]; then
            echo "$SQLNET_ORA_CONTENT"|sed 's/^SQLNET/#&/' >>$TNS_ADMIN/sqlnet.ora
        else
            echo "$SQLNET_ORA_CONTENT" >>$TNS_ADMIN/sqlnet.ora
        fi
    else
        log_message ERROR "ERR : Could not find an sqlnet.ora ($TNS_ADMIN/sqlnet.ora)"
        log_message ERROR "ERR : Please create sqlnet.ora manually"
        exit_with_status 22 $TNS_ADMIN/sqlnet.ora
    fi
elif [ -f "$ORADBA_SQLNET_ORA_FILE" ]; then
    log_message INFO "INFO : Copy sqlnet.ora from $ORADBA_SQLNET_ORA_FILE"
    cp -v $ORADBA_SQLNET_ORA_FILE $TNS_ADMIN/sqlnet.ora
else
    log_message ERROR "ERR : Can not find / access sqlnet.ora in $ORADBA_SQLNET_ORA_FILE"
    exit_with_status 22 $ORADBA_SQLNET_ORA_FILE
fi

log_message INFO "INFO : Create krb5.conf  --------------------------------------------------"
# if exist make a copy of the existing krb5.conf file
if [ -f "$TNS_ADMIN/krb5.conf" ]; then
    log_message INFO "INFO : save existing krb5.conf file as krb5.conf.${DATE_STAMP}"
    cp "$TNS_ADMIN/krb5.conf" "$TNS_ADMIN/krb5.conf.${DATE_STAMP}"
fi

# create a new krb5.conf
if [ -z "$ORADBA_KRB5_CONF_FILE" ]; then
    log_message INFO "INFO : Use embedded krb5.conf to create new krb5.conf file"
    eval "echo \"$KRB5_CONF_CONTENT\"" |awk '/^#/ {print; next} !seen[$0]++' >$TNS_ADMIN/krb5.conf
elif [ -f "$ORADBA_KRB5_CONF_FILE" ]; then
    log_message INFO "INFO : Copy krb5.conf from $ORADBA_KRB5_CONF_FILE"
    cp -v $ORADBA_KRB5_CONF_FILE $TNS_ADMIN/krb5.conf
else
    log_message ERROR "ERR : Can not find / access krb5.conf in $ORADBA_KRB5_CONF_FILE"
    exit_with_status 22 $ORADBA_KRB5_CONF_FILE
fi

log_message INFO "INFO : Get krb5 information -----------------------------------------------"

log_message INFO  "INFO : Create TGT for user ${ORADBA_KRB5_USER}@${ORADBA_KRB5_REALM}"
okinit ${ORADBA_KRB5_USER}@${ORADBA_KRB5_REALM} < <(base64 --decode ${ORADBA_KRB5_PASSWORD_FILE}) 2>&1
KRB5_CACHE=$(oklist 2>/dev/null|grep -i "Ticket cache"|cut -d: -f3) # get KRB5 cache file from oklist
log_message INFO  "INFO : Get kvno for user ${ORADBA_KRB5_USER}@${ORADBA_KRB5_REALM}"
export KRB5_CONFIG="$TNS_ADMIN/krb5.conf"                             # set an alternative krb5.conf file for kvno
KVNO=$(kvno -c $KRB5_CACHE ${ORADBA_KRB5_USER}@${ORADBA_KRB5_REALM}|cut -d' ' -f4)

log_message INFO "INFO : Create keytab ------------------------------------------------------"
# if exist make a copy of the existing krb5.conf file
if [ -f "$TNS_ADMIN/krb5.keytab" ]; then
    log_message INFO "INFO : save existing krb5.keytab file as krb5.keytab.${DATE_STAMP}"
    mv "$TNS_ADMIN/krb5.keytab" "$TNS_ADMIN/krb5.keytab.${DATE_STAMP}"
fi

# copy keytab file
if [ -f "$SCRIPT_BIN_DIR/$ORADBA_KRB5_KEYTAB_FILE" ]; then
    log_message INFO  "INFO : Copy keytab file from $SCRIPT_BIN_DIR/$ORADBA_KRB5_KEYTAB_FILE"
    cp -v "$SCRIPT_BIN_DIR/$ORADBA_KRB5_KEYTAB_FILE" "$TNS_ADMIN/krb5.keytab"
elif [ -f "$TNS_ADMIN/$ORADBA_KRB5_KEYTAB_FILE" ]; then
    log_message INFO  "INFO : Copy keytab file from $TNS_ADMIN/$ORADBA_KRB5_KEYTAB_FILE"
    cp -v "$TNS_ADMIN/$ORADBA_KRB5_KEYTAB_FILE" "$TNS_ADMIN/krb5.keytab"
elif [ -f "$ORADBA_KRB5_KEYTAB_FILE" ]; then
    log_message INFO  "INFO : Copy keytab file from $ORADBA_KRB5_KEYTAB_FILE"
    cp -v "$ORADBA_KRB5_KEYTAB_FILE" "$TNS_ADMIN/krb5.keytab"
fi

log_message INFO  "INFO : Create keytab file ${ORADBA_KRB5_USER}@${ORADBA_KRB5_REALM}"
log_message DEBUG "DEBUG: $TNS_ADMIN/krb5.keytab"
ktutil <<EOF
addent -password -p oracle/$(hostname -f)@${ORADBA_KRB5_REALM} -k ${KVNO} -e aes256-cts-hmac-sha1-96
$(cat ${ORADBA_KRB5_PASSWORD_FILE}|base64 --decode)
wkt $TNS_ADMIN/krb5.keytab
q
EOF

log_message INFO  "INFO : List current keytab file"
oklist -e -k $TNS_ADMIN/krb5.keytab 2>&1

log_message INFO  "INFO : Clean ticket cache using okdstry"
okdstry 2>&1

log_message INFO "INFO : --------------------------------------------------------------------"
log_message INFO "INFO : Kerberos OS configuration finished."
log_message INFO "      it is recommended to restart the listener and databases"
log_message INFO "      to make sure new SQLNet configuration is used."
log_message INFO ""
exit_with_status 0
# --- EOF ---------------------------------------------------------------------