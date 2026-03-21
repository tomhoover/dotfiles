# shellcheck shell=bash

if command -v tmuxifier &>/dev/null; then
    export TMUXIFIER_LAYOUT_PATH="$HOME/.config/tmuxifier/layouts"
    _bin="$(command -v tmuxifier)"
    _cache="${XDG_CACHE_HOME:-$HOME/.cache}/tmuxifier/init.${SHEL}"
    if [[ ! -f "$_cache" || "$_bin" -nt "$_cache" ]]; then
        mkdir -p "${_cache%/*}"
        tmuxifier init - >"$_cache"
    fi
    # shellcheck disable=SC1090
    source "$_cache"
    unset _bin _cache
fi
