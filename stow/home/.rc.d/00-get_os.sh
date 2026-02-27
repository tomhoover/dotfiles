# shellcheck shell=sh

isdarwin() {
    [ "$(uname -s)" = "Darwin" ]
}

islinux() {
    [ "$(uname -s)" = "Linux" ]
}

isarch() {
    if islinux && [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        # shellcheck disable=SC2078
        [ "${ID}" = "arch" ] && return 0
    fi
    return 1
}

isdebian() {
    if islinux && [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        # shellcheck disable=SC2078
        [ "${ID}" = "debian" ] && return 0
    fi
    return 1
}

isfedora() {
    if islinux && [ -f /etc/os-release ]; then
        # shellcheck disable=SC1091
        . /etc/os-release
        # shellcheck disable=SC2078
        [ "${ID}" = "fedora" ] && return 0
    fi
    return 1
}

isomarchy() {
    isarch && grep -q '\[omarchy\]' /etc/pacman.conf
}

isfreebsd() {
    [ "$(uname -s)" = "FreeBSD" ]
}

isopenbsd() {
    [ "$(uname -s)" = "OpenBSD" ]
}

get_os() {
    if [ "$(uname -s)" = "Darwin" ]; then
        echo "darwin"
    elif [ "$(uname -s)" = "Linux" ]; then
        if [ -f /etc/os-release ]; then
            # shellcheck disable=SC1091
            . /etc/os-release
            if isarch && grep -q '\[omarchy\]' /etc/pacman.conf; then
                echo "omarchy"
            else
                echo "${ID}"
            fi
        else
            echo "linux"
        fi
    elif [ "$(uname -s)" = "FreeBSD" ]; then
        echo "freebsd"
    elif [ "$(uname -s)" = "OpenBSD" ]; then
        echo "openbsd"
    else
        echo "unknown-os"
    fi
}
