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
    [[ $(id -u) == 0 ]]
}

_read() {
    local prompt="${1}"
    local default="${2:-}"

    _print_default_value() {
        [[ -n "${default}" ]] && echo " [${default}]"
    }

    local answer
    read -rp "$(echo -e "\n${BOLD}${PURPLE}${prompt}${RESET}$(_print_default_value) ")" answer

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

    local answer
    answer="$(_read "${prompt} ($(_cap_if_default "y")/$(_cap_if_default "n"))")"

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
    answer="$(_read "${prompt} (one of ${options// /, }):")"

    if [[ " ${options[*]} " = *" ${answer} "* ]]; then
        echo "${answer}"
    else
        _read_enum "${@}"
    fi
}
