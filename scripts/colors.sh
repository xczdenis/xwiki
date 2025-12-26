#!/usr/bin/env bash

[ "${COLORS_SH_GUARD:-}" ] && return
COLORS_SH_GUARD=1

show_colors() {
    for code in {30..37}; do
        printf "\033[0;${code}mColor code: 0;${code}\033[0m\n"  # Стандартные цвета
        printf "\033[1;${code}mColor code: 1;${code}\033[0m\n"  # Яркие цвета
    done
}

color_black=$(printf "\033[30m")
color_red=$(printf "\033[31m")
color_green=$(printf "\033[32m")
color_yellow=$(printf "\033[33m")
color_blue=$(printf "\033[34m")
color_purple=$(printf "\033[35m")
color_turquoise=$(printf "\033[36m")
color_white=$(printf "\033[37m")

color_black_bright=$(printf "\033[90m")
color_red_bright=$(printf "\033[91m")
color_green_bright=$(printf "\033[92m")
color_yellow_bright=$(printf "\033[93m")
color_blue_bright=$(printf "\033[94m")
color_purple_bright=$(printf "\033[95m")
color_turquoise_bright=$(printf "\033[96m")
color_white_bright=$(printf "\033[97m")

color_black_bright_2=$(printf "\033[1;30m")
color_red_bright_2=$(printf "\033[1;31m")
color_green_bright_2=$(printf "\033[1;32m")
color_yellow_bright_2=$(printf "\033[1;33m")
color_blue_bright_2=$(printf "\033[1;34m")
color_purple_bright_2=$(printf "\033[1;35m")
color_turquoise_bright_2=$(printf "\033[1;36m")
color_white_bright_2=$(printf "\033[1;37m")

bg_black=$(printf "\033[40m")
bg_red=$(printf "\033[41m")
bg_green=$(printf "\033[42m")
bg_yellow=$(printf "\033[43m")
bg_blue=$(printf "\033[44m")
bg_purple=$(printf "\033[45m")
bg_turquoise=$(printf "\033[46m")
bg_white=$(printf "\033[47m")

bg_black_bright=$(printf "\033[100m")
bg_red_bright=$(printf "\033[101m")
bg_green_bright=$(printf "\033[102m")
bg_yellow_bright=$(printf "\033[103m")
bg_blue_bright=$(printf "\033[104m")
bg_purple_bright=$(printf "\033[105m")
bg_turquoise_bright=$(printf "\033[106m")
bg_white_bright=$(printf "\033[107m")

bg_black_bright_2=$(printf "\033[1;40m")
bg_red_bright_2=$(printf "\033[1;41m")
bg_green_bright_2=$(printf "\033[1;42m")
bg_yellow_bright_2=$(printf "\033[1;43m")
bg_blue_bright_2=$(printf "\033[1;44m")
bg_purple_bright_2=$(printf "\033[1;45m")
bg_turquoise_bright_2=$(printf "\033[1;46m")
bg_white_bright_2=$(printf "\033[1;47m")

if [[ "$LOG_COLOR_TYPE" == "2" ]]; then
    color_info=${color_turquoise_bright_2}
    color_debug=${color_blue_bright_2}
    color_success=${color_green_bright_2}
    color_error=${color_red_bright_2}
    color_warn=${color_yellow_bright_2}
    color_primary=${color_white_bright_2}

    bg_info=${bg_turquoise_bright_2}
    bg_debug=${bg_blue_bright_2}
    bg_success=${bg_green_bright_2}
    bg_error=${bg_red_bright_2}
    bg_warn=${bg_yellow_bright_2}
    bg_primary=${bg_white_bright_2}
elif [[ "$LOG_COLOR_TYPE" == "1" ]]; then
    color_info=${color_turquoise_bright}
    color_debug=${color_blue_bright}
    color_success=${color_green_bright}
    color_error=${color_red_bright}
    color_warn=${color_yellow_bright}
    color_primary=${color_white_bright}

    bg_info=${bg_turquoise_bright}
    bg_debug=${bg_blue_bright}
    bg_success=${bg_green_bright}
    bg_error=${bg_red_bright}
    bg_warn=${bg_yellow_bright}
    bg_primary=${bg_white_bright}
else
    color_info=${color_turquoise}
    color_debug=${color_blue}
    color_success=${color_green}
    color_error=${color_red}
    color_warn=${color_yellow}
    color_primary=${color_white}

    bg_info=${bg_turquoise}
    bg_debug=${bg_blue}
    bg_success=${bg_green}
    bg_error=${bg_red}
    bg_warn=${bg_yellow}
    bg_primary=${bg_white}
fi

color_reset=$(printf "\033[0m")
