# shellcheck shell=bash

if command -v try &>/dev/null; then
  _bin="$(command -v try)"
  _cache="${XDG_CACHE_HOME:-$HOME/.cache}/try/init.${SHEL}"

  if [[ ! -f "$_cache" || "$_bin" -nt "$_cache" ]]; then
    mkdir -p "${_cache%/*}"
    try init ~/src/tries >"$_cache"
  fi
  # shellcheck disable=SC1090
  source "$_cache"
  unset _bin _cache
fi
