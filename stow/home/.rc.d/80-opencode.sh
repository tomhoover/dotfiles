# shellcheck shell=bash

if command -v "$HOME/.opencode/bin/opencode" &>/dev/null; then
  export PATH="$HOME/.opencode/bin:$PATH"

  if [ "$SHEL" = "zsh" ]; then
    _bin="$HOME/.opencode/bin/opencode"
    _cache="${XDG_CACHE_HOME:-$HOME/.cache}/opencode/completion.zsh"
    if [[ ! -f "$_cache" || "$_bin" -nt "$_cache" ]]; then
      mkdir -p "${_cache%/*}"
      "$_bin" completion zsh >"$_cache"
    fi
    # shellcheck disable=SC1090
    source "$_cache"
    unset _bin _cache
  fi
fi
