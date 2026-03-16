# shellcheck shell=bash

if command -v tmuxifier &>/dev/null; then
    eval "$(tmuxifier init -)"
fi
