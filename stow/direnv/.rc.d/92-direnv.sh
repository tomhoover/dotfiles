# shellcheck shell=bash

if command -v direnv &>/dev/null; then
  _bin="$(command -v direnv)"
  _cache="${XDG_CACHE_HOME:-$HOME/.cache}/direnv/hook.${SHEL}"
  if [[ ! -f "$_cache" || "$_bin" -nt "$_cache" ]]; then
    mkdir -p "${_cache%/*}"
    direnv hook "${SHEL}" >"$_cache"
  fi
  # shellcheck disable=SC1090
  source "$_cache"
  unset _bin _cache
fi
