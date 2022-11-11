RESET="\033[0m"
BOLD="\033[1m"
# shellcheck disable=SC2034
GREEN="\033[32m"
# shellcheck disable=SC2034
YELLOW="\033[33m"
# shellcheck disable=SC2034
BLUE="\033[34m"
PURPLE="\033[35m"

_log() {
    echo
    echo -e "${BOLD}${YELLOW}${1}${RESET}"
}

_available() {
    hash "${1}" > /dev/null 2>&1
}

_is_nixos() {
    [[ -f "/etc/NIXOS" ]]
}

_is_root() {
    local user_id
    user_id=$(id -u)
    [[ ${user_id} == 0 ]]
}

_read() {
    local prompt="${1}"
    local default="${2:-}"

    _print_default_value() {
        [[ -n "${default}" ]] && echo " [${default}]"
    }

    local answer
    local default_value
    # shellcheck disable=SC2311
    default_value="$(_print_default_value)"
    read -rp "$(echo -e "\n${BOLD}${PURPLE}${prompt}${RESET}${default_value} ")" answer

    local answer_filled="${answer:-"${default}"}"

    echo "${answer_filled}"
}

_read_boolean() {
    local prompt="${1}"
    local default="${2:-}"

    _cap_if_default() {
        local low="${1,,}"
        local cap="${1^^}"

        [[ "${default^^}" = "${cap}" ]] && echo "${cap}" || echo "${low}"
    }

    local yes
    # shellcheck disable=SC2311
    yes="$(_cap_if_default "y")"
    local no
    # shellcheck disable=SC2311
    no="$(_cap_if_default "n")"
    local answer
    # shellcheck disable=SC2311
    answer="$(_read "${prompt} (${yes}/${no})")"

    local answer_filled="${answer:-"${default}"}"

    if [[ "${answer_filled^^}" =~ (Y|N) ]]; then
        [[ "${answer_filled^^}" = "Y" ]]
    else
        _read_boolean "${@}"
    fi
}

_read_enum() {
    local prompt="${1}"
    local options="${*:2}"

    local answer
    # shellcheck disable=SC2311
    answer="$(_read "${prompt} (one of ${options// /, }):")"

    if [[ " ${options[*]} " = *" ${answer} "* ]]; then
        echo "${answer}"
    else
        _read_enum "${@}"
    fi
}
