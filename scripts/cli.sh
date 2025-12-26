#!/usr/bin/env bash

# Prefix for exported CLI environment variables
_CLI_ARG_PREFIX="CLI_ARG_"

# Colors for pretty output
_cli_color_reset=$(printf "\033[0m")
_cli_color_green=$(printf "\033[1;32m")
_cli_color_blue=$(printf "\033[1;34m")
_cli_color_red=$(printf "\033[1;31m")
_cli_color_yellow=$(printf "\033[1;33m")

# --- storage (arrays only, no associative arrays) ---

# Commands: parallel arrays
#   CMD_NAMES[i]  = command name
#   CMD_HELP[i]   = help text
declare -a CMD_NAMES=()
declare -a CMD_HELP=()

# Global flags: parallel arrays
#   GFLAG_NAMES[i] = name
#   GFLAG_DEF[i]   = default value
#   GFLAG_HELP[i]  = help text
#   GFLAG_VAL[i]   = current value
declare -a GFLAG_NAMES=()
declare -a GFLAG_DEF=()
declare -a GFLAG_HELP=()
declare -a GFLAG_VAL=()

# Command flags: parallel arrays
#   CFLAG_CMDS[i]  = command name
#   CFLAG_NAMES[i] = flag name
#   CFLAG_DEF[i]   = default value
#   CFLAG_HELP[i]  = help text
#   CFLAG_VAL[i]   = current value
declare -a CFLAG_CMDS=()
declare -a CFLAG_NAMES=()
declare -a CFLAG_DEF=()
declare -a CFLAG_HELP=()
declare -a CFLAG_VAL=()

# ---------- helpers ----------

# Convert string to upper-case using POSIX tools (works on old bash)
_cli_to_upper() {
    printf '%s' "$1" | tr '[:lower:]' '[:upper:]'
}

# Find index of a global flag by name; prints index or -1
_cli_gflag_index() {
    local name="$1"
    local i
    for i in "${!GFLAG_NAMES[@]}"; do
        if [[ "${GFLAG_NAMES[$i]}" == "$name" ]]; then
            printf '%s' "$i"
            return 0
        fi
    done
    printf '%s' -1
    return 1
}

# Find index of a command flag by command+name; prints index or -1
_cli_cflag_index() {
    local cmd="$1"
    local name="$2"
    local i
    for i in "${!CFLAG_CMDS[@]}"; do
        if [[ "${CFLAG_CMDS[$i]}" == "$cmd" && "${CFLAG_NAMES[$i]}" == "$name" ]]; then
            printf '%s' "$i"
            return 0
        fi
    done
    printf '%s' -1
    return 1
}

# ---------- API ----------

# add_arg name default help
# Registers a global flag and exports its default value as an env var.
add_arg() {
    local name="$1"
    local def="$2"
    local help="$3"
    local upper

    GFLAG_NAMES+=( "$name" )
    GFLAG_DEF+=( "$def" )
    GFLAG_HELP+=( "$help" )
    GFLAG_VAL+=( "$def" )

    upper=$(_cli_to_upper "$name")
    export "${_CLI_ARG_PREFIX}${upper}"="$def"
}

# add_cmd name help
# Registers a command.
add_cmd() {
    local name="$1"
    local help="$2"

    CMD_NAMES+=( "$name" )
    CMD_HELP+=( "$help" )
}

# add_cmd_arg cmd flag default help
# Registers a flag for a specific command.
add_cmd_arg() {
    local cmd="$1"
    local flag="$2"
    local def="$3"
    local help="$4"

    CFLAG_CMDS+=( "$cmd" )
    CFLAG_NAMES+=( "$flag" )
    CFLAG_DEF+=( "$def" )
    CFLAG_HELP+=( "$help" )
    CFLAG_VAL+=( "$def" )
}

# cli_run "$@"
# Main entry point; must be called as the last line of the user script.
cli_run() {
    local cmd=""
    local -a rem=()
    local commands_exist=${#CMD_NAMES[@]}
    local token key val idx upper

    # Full argv parsing
    while [[ $# -gt 0 ]]; do
        token="$1"
        shift
        case "$token" in
            -h|--help)
                if [[ -z "$cmd" && $commands_exist -eq 0 ]]; then
                    _print_global_help
                    return
                elif [[ -z "$cmd" ]]; then
                    _print_help
                    return
                else
                    _print_cmd_help "$cmd"
                    return
                fi
                ;;
            --*)
                # Long flag: --name or --name=value
                key="${token%%=*}"
                key="${key#--}"
                if [[ "$token" == *"="* ]]; then
                    val="${token#*=}"
                else
                    val=true
                fi

                # First try command-specific flag (if we already know the command)
                if [[ -n "$cmd" ]]; then
                    idx=$(_cli_cflag_index "$cmd" "$key")
                    if [[ "$idx" != "-1" ]]; then
                        CFLAG_VAL[$idx]="$val"
                        upper=$(_cli_to_upper "$key")
                        export "${_CLI_ARG_PREFIX}${upper}"="$val"
                        continue
                    fi
                fi

                # Then try global flag
                idx=$(_cli_gflag_index "$key")
                if [[ "$idx" != "-1" ]]; then
                    GFLAG_VAL[$idx]="$val"
                    upper=$(_cli_to_upper "$key")
                    export "${_CLI_ARG_PREFIX}${upper}"="$val"
                else
                    # Unknown flag -> positional
                    rem+=( "$token" )
                fi
                ;;
            *)
                # First non-flag might be a command name
                if [[ -z "$cmd" ]]; then
                    local i
                    for i in "${!CMD_NAMES[@]}"; do
                        if [[ "${CMD_NAMES[$i]}" == "$token" ]]; then
                            cmd="$token"
                            break
                        fi
                    done
                    if [[ -n "$cmd" ]]; then
                        continue
                    fi
                fi
                rem+=( "$token" )
                ;;
        esac
    done

    # Dispatch
    if [[ -n "$cmd" ]]; then
        "$cmd" "${rem[@]}"
        return
    fi

    # Fallback to main() if defined
    if command -v main >/dev/null 2>&1; then
        main "${rem[@]}"
        return
    fi

    # Error: no command and no main()
    echo "${_cli_color_red}Error:${_cli_color_reset} unknown command"
    echo
    _print_short_help
}

# ---------- help printing ----------

_print_help() {
    _print_short_help

    # Commands section
    if ((${#CMD_NAMES[@]} > 0)); then
        local cmd_width=0
        local i
        for i in "${!CMD_NAMES[@]}"; do
            ((${#CMD_NAMES[$i]} > cmd_width)) && cmd_width=${#CMD_NAMES[$i]}
        done
        cmd_width=$((cmd_width + 2))

        echo "${_cli_color_green}Commands:${_cli_color_reset}"
        for i in "${!CMD_NAMES[@]}"; do
            printf "  %s%-*s%s %s\n" \
                "${_cli_color_blue}" \
                "$cmd_width" "${CMD_NAMES[$i]}" \
                "${_cli_color_reset}" \
                "${CMD_HELP[$i]}"
        done
    fi

    # Global flags section
    if ((${#GFLAG_NAMES[@]} > 0)); then
        local g_width=0
        local i
        for i in "${!GFLAG_NAMES[@]}"; do
            ((${#GFLAG_NAMES[$i]} > g_width)) && g_width=${#GFLAG_NAMES[$i]}
        done
        g_width=$((g_width + 4))  # account for leading "--"

        echo
        echo "${_cli_color_green}Global flags:${_cli_color_reset}"
        for i in "${!GFLAG_NAMES[@]}"; do
            printf "  %s%-*s%s %s (default: '%s')\n" \
                "${_cli_color_blue}" \
                "$g_width" "--${GFLAG_NAMES[$i]}" \
                "${_cli_color_reset}" \
                "${GFLAG_HELP[$i]}" \
                "${GFLAG_DEF[$i]}"
        done
    fi
}

_print_cmd_help() {
    local cmd="$1"
    local i

    echo "${_cli_color_green}Usage: ${_cli_color_blue}$(basename "$0") $cmd [--flag=value] [args]${_cli_color_reset}"
    echo

    # Find command help text
    local desc=""
    for i in "${!CMD_NAMES[@]}"; do
        if [[ "${CMD_NAMES[$i]}" == "$cmd" ]]; then
            desc="${CMD_HELP[$i]}"
            break
        fi
    done
    echo "${_cli_color_yellow}$cmd${_cli_color_reset} - $desc"

    # Command-specific flags
    local f_width=0
    for i in "${!CFLAG_CMDS[@]}"; do
        if [[ "${CFLAG_CMDS[$i]}" == "$cmd" ]]; then
            ((${#CFLAG_NAMES[$i]} > f_width)) && f_width=${#CFLAG_NAMES[$i]}
        fi
    done
    f_width=$((f_width + 4))  # for "--"

    local have_flags=0
    for i in "${!CFLAG_CMDS[@]}"; do
        if [[ "${CFLAG_CMDS[$i]}" == "$cmd" ]]; then
            have_flags=1
            break
        fi
    done

    if [[ $have_flags -eq 1 ]]; then
        echo
        echo "${_cli_color_green}Flags:${_cli_color_reset}"
        for i in "${!CFLAG_CMDS[@]}"; do
            if [[ "${CFLAG_CMDS[$i]}" != "$cmd" ]]; then
                continue
            fi
            printf "  %s%-*s%s %s (default: '%s')\n" \
                "${_cli_color_blue}" \
                "$f_width" "--${CFLAG_NAMES[$i]}" \
                "${_cli_color_reset}" \
                "${CFLAG_HELP[$i]}" \
                "${CFLAG_DEF[$i]}"
        done
    fi

    # Global flags also apply
    if ((${#GFLAG_NAMES[@]} > 0)); then
        local g_width=0
        for i in "${!GFLAG_NAMES[@]}"; do
            ((${#GFLAG_NAMES[$i]} > g_width)) && g_width=${#GFLAG_NAMES[$i]}
        done
        g_width=$((g_width + 4))

        echo
        echo "${_cli_color_green}Global flags:${_cli_color_reset}"
        for i in "${!GFLAG_NAMES[@]}"; do
            printf "  %s%-*s%s %s (default: '%s')\n" \
                "${_cli_color_blue}" \
                "$g_width" "--${GFLAG_NAMES[$i]}" \
                "${_cli_color_reset}" \
                "${GFLAG_HELP[$i]}" \
                "${GFLAG_DEF[$i]}"
        done
    fi
}

_print_global_help() {
    echo "${_cli_color_green}Usage: ${_cli_color_blue}$(basename "$0") [--flag=value] [--help]${_cli_color_reset}"
    echo

    if ((${#GFLAG_NAMES[@]} > 0)); then
        local width=0
        local i
        for i in "${!GFLAG_NAMES[@]}"; do
            ((${#GFLAG_NAMES[$i]} > width)) && width=${#GFLAG_NAMES[$i]}
        done
        width=$((width + 4))

        echo "${_cli_color_green}Flags:${_cli_color_reset}"
        for i in "${!GFLAG_NAMES[@]}"; do
            printf "  %s%-*s%s %s (default: '%s')\n" \
                "${_cli_color_blue}" \
                "$width" "--${GFLAG_NAMES[$i]}" \
                "${_cli_color_reset}" \
                "${GFLAG_HELP[$i]}" \
                "${GFLAG_DEF[$i]}"
        done
    fi
}

_print_short_help() {
    echo "${_cli_color_green}Usage: ${_cli_color_blue}$(basename "$0") <command> [--flag=value] [--help]${_cli_color_reset}"
    echo
    echo "For more information, try '${_cli_color_blue}--help${_cli_color_reset}'."
    echo
}
