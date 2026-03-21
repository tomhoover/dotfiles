# shellcheck shell=bash

if command -v tmuxifier &>/dev/null; then
    export TMUXIFIER_LAYOUT_PATH="$HOME/.config/tmuxifier/layouts"
    eval "$(tmuxifier init -)"
fi
