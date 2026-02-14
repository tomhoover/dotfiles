# shellcheck shell=bash

if command -v zoxide &>/dev/null; then
    eval "$(zoxide init "${SHEL}")"
else
    # shellcheck disable=SC1090
    [ -r ~/.local/share/z.sh ] && source ~/.local/share/z.sh # rupa/z
fi
