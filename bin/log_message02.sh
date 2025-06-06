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
        INFO)       color=${TNS_INFO:-'\033[0;30m'} ;;
        WARN)       color=${TNS_WARN:-'\033[0;33m'} ;;
        ERROR)      color=${TNS_ERROR:-'\033[0;31m'} ;;
        SUCCESS)    color=${TNS_SUCCESS:-'\033[0;32m'} ;;
        DEBUG)      color=${TNS_DEBUG:-'\033[0;36m'} ;;
        *)          color=${NC:-'\033[0m'} ;;
    esac

    # Function to handle appending message with or without a newline
    append_log() {
        if [ "$newline" = true ]; then
            echo -e "$color$1$NC"
        else
            echo -n -e "$color$1$NC"
        fi
    }

    # Handling message based on log level and mode (VERBOSE, QUIET, DEBUG)
    if { [[ "${level^^}" == "DEBUG" ]] && [[ -n "${DEBUG}" ]]; } || 
       { [[ "${level^^}" != "DEBUG" ]] && { [[ -n "${VERBOSE}" ]] || { [[ -z "${QUIET}" ]] && [[ "${level^^}" != "INFO" ]] && [[ "${level^^}" != "SUCCESS" ]]; } || { [[ -n "${QUIET}" ]] && [[ "${level^^}" == "ERROR" ]]; } } }; then
        append_log "$message"
    fi
}

# Example Usage:
# LOGFILE="/path/to/yourlogfile.log"
# VERBOSE=1  # or QUIET=1 or DEBUG=1
# log_message -n "This is a test message." "INFO"
