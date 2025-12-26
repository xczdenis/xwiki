#!/usr/bin/env bash

[ "${LOGGER_SH_GUARD:-}" ] && return
LOGGER_SH_GUARD=1

. ./scripts/colors.sh

get_color_for_log_level() {
    case $1 in
    info)
        printf "${color_info}"
        ;;
    debug)
        printf "${color_debug}"
        ;;
    success)
        printf "${color_success}"
        ;;
    error)
        printf "${color_error}"
        ;;
    warn)
        printf "${color_warn}"
        ;;
    white)
        ${color_white}
        ;;
    reset)
        printf "${color_reset}"
        ;;
    *)
        printf "${color_reset}"
        ;;
    esac
}

get_log_prefix() {
    case $1 in
    info)
        printf "INFO     "
        ;;
    debug)
        printf "DEBUG    "
        ;;
    success)
        printf "SUCCESS  "
        ;;
    error)
        printf "ERROR    "
        ;;
    warn)
        printf "WARN     "
        ;;
    *)
        printf ""
        ;;
    esac
}

get_msg_prefix() {
    case $1 in
    info)
        printf "INFO"
        ;;
    debug)
        printf "DEBUG"
        ;;
    success)
        printf "SUCCESS"
        ;;
    error)
        printf "ERROR"
        ;;
    warn)
        printf "WARNING"
        ;;
    *)
        printf ""
        ;;
    esac
}

log() {
    log_level=$1
    text=$2

    log_color=$(get_color_for_log_level "${log_level}")
    prefix=$(get_log_prefix "${log_level}")
    current_time=$(date +"%Y-%m-%d %H:%M:%S.%3N")

    echo "${color_success}${current_time} ${color_reset}| ${log_color}${prefix}${color_reset}| ${log_color}${text}${color_reset}"
}

msg() {
    log_level=$1
    text=$2

    log_color=$(get_color_for_log_level "${log_level}")
    color_reset=$(get_color_for_log_level "reset")
    prefix=$(get_msg_prefix "${log_level}")

    echo "${log_color}${prefix}: ${color_reset}${text}${color_reset}"
}

log_debug() {
    text=$1
    log "debug" "${text}"
}

log_info() {
    text=$1
    log "info" "${text}"
}

log_success() {
    text=$1
    log "success" "${text}"
}

log_error() {
    text=$1
    log "error" "${text}"
}

log_warn() {
    text=$1
    log "warn" "${text}"
}

log_header() {
    text=${1}

    echo ""
    echo "${color_primary}------------------------------------------------------${color_reset}"
    echo "${color_primary}$(date +"%Y-%m-%d %H:%M:%S.%3N") | ${text}${color_reset}"
    echo "${color_primary}------------------------------------------------------${color_reset}"
}

msg_debug() {
    text=$1
    msg "debug" "${text}"
}

msg_info() {
    text=$1
    msg "info" "${text}"
}

msg_success() {
    text=$1
    msg "success" "${text}"
}

msg_error() {
    text=$1
    msg "error" "${text}"
}

msg_warn() {
    text=$1
    msg "warn" "${text}"
}
