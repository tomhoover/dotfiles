# shellcheck shell=bash

if command -v try &>/dev/null; then
  if [ "${SHEL}" = "zsh" ]; then
    functions | grep -q '^try () {' || eval "$(try init ~/src/tries)"
  elif [ "${SHEL}" = "bash" ]; then
    [[ $(type -t try) == function ]] || eval "$(try init ~/src/tries)"
  fi
fi
