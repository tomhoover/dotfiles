# shellcheck shell=bash

if command -v zoxide &>/dev/null; then
  _bin="$(command -v zoxide)"
  _cache="${XDG_CACHE_HOME:-$HOME/.cache}/zoxide/init.${SHEL}"
  if [[ ! -f "$_cache" || "$_bin" -nt "$_cache" ]]; then
    mkdir -p "${_cache%/*}"
    zoxide init "${SHEL}" >"$_cache"
  fi
  # shellcheck disable=SC1090
  source "$_cache"
  unset _bin _cache
else
  # shellcheck disable=SC1090
  [ -r ~/.local/share/z.sh ] && source ~/.local/share/z.sh # rupa/z
fi
