# shellcheck shell=bash

if command -v git-wt &>/dev/null; then
  _bin="$(command -v git-wt)"
  _cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/git-wt"

  _init_cache="$_cache_dir/init.${SHEL}"
  if [[ ! -f "$_init_cache" || "$_bin" -nt "$_init_cache" ]]; then
    mkdir -p "$_cache_dir"
    git wt init "${SHEL}" >"$_init_cache"
  fi
  # shellcheck disable=SC1090
  source "$_init_cache"

  _comp_cache="$_cache_dir/completion.${SHEL}"
  if [[ ! -f "$_comp_cache" || "$_bin" -nt "$_comp_cache" ]]; then
    git wt completion "${SHEL}" >"$_comp_cache"
  fi
  # shellcheck disable=SC1090
  source "$_comp_cache"

  unset _bin _cache_dir _init_cache _comp_cache
  # if [ -f "$HOME/src/github.com/tomhoover/git-wt+claude/src/git-wt" ]; then
  #     ln -sf "$HOME/src/github.com/tomhoover/git-wt+claude/src/git-wt" "$HOME/bin/git-wt"
  # fi
fi
