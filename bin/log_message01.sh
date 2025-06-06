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
        INFO)       color=${TNS_INFO:-'\033[0;30m'} ;;      # Black for info messages
        WARN)       color=${TNS_WARN:-'\033[0;33m'} ;;      # Yellow for warning messages
        ERROR)      color=${TNS_ERROR:-'\033[0;31m'} ;;     # Red for error messages
        SUCCESS)    color=${TNS_SUCCESS:-'\033[0;32m'} ;;   # Green for info messages
        DEBUG)      color=${TNS_DEBUG:-'\033[0;36m'} ;;     # Blue for debug messages
        *)          color=${NC:-'\033[0m'} ;;               # No color/reset
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
    # If neither VERBOSE nor QUIET is set, send WARN to stderr and logfile
    elif [[ "${level^^}" == "WARN" ]]; then
        append_log "$message" | tee -a "${LOGFILE}"
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