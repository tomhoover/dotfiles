# shellcheck shell=bash

if command -v direnv &>/dev/null; then eval "$(direnv hook "${SHEL}")"; fi
