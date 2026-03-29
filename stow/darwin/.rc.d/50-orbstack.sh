# shellcheck shell=bash

if [[ -f $HOME/.orbstack/shell/init.${SHEL} ]]; then
  # shellcheck disable=SC1090
  source "$HOME/.orbstack/shell/init.${SHEL}"
fi
