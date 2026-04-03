# shellcheck shell=bash

# ensure mise is on the path
export PATH=$HOME/.local/bin:$PATH

# Full mise activation (hook-env) is deferred to after the first prompt via zle-line-init.
if command -v mise &>/dev/null; then
  _mise_bin="$(command -v mise)"
  _mise_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

  # eval "$(mise activate "${SHEL}")"
  _mise_activate_cache="$_mise_cache_dir/activate.${SHEL}"
  if [[ ! -f "$_mise_activate_cache" || "$_mise_bin" -nt "$_mise_activate_cache" ]]; then
    mkdir -p "$_mise_cache_dir"
    mise activate "${SHEL}" >"$_mise_activate_cache"
  fi

  # eval "$(mise completion "${SHEL}")"
  _mise_comp_cache="$_mise_cache_dir/completion.${SHEL}"
  if [[ ! -f "$_mise_comp_cache" || "$_mise_bin" -nt "$_mise_comp_cache" ]]; then
    mkdir -p "$_mise_cache_dir"
    mise completion "${SHEL}" >"$_mise_comp_cache"
  fi

  if [[ -n "${ZSH_VERSION:-}" ]] && [[ -o interactive ]]; then
    _mise_deferred_activate() {
      add-zle-hook-widget -d zle-line-init _mise_deferred_activate
      zle -D _mise_deferred_activate
      # shellcheck disable=SC1090
      source "$_mise_activate_cache"
      # shellcheck disable=SC1090
      source "$_mise_comp_cache"
      # Move _mise_hook from precmd (every prompt) to chpwd (directory change only)
      # precmd_functions=("${precmd_functions[@]/_mise_hook/}")
      # chpwd_functions+=(_mise_hook)
      # the above *_functions edits were replaced by the addition of the setting
      # 'hook_env.chpwd_only = true' in mise's configuration file, which
      # prevents the hook from running on every prompt and instead only
      # runs it when the directory changes.
      unset _mise_activate_cache _mise_comp_cache

      # insert ~/bin into $PATH before everything else
      # export PATH="$HOME/bin:$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
      # source "$HOME/.rc.d/99-after.sh
    }
    zle -N _mise_deferred_activate
    add-zle-hook-widget zle-line-init _mise_deferred_activate
  else
    # bash or non-interactive: activate immediately
    # shellcheck disable=SC1090
    source "$_mise_activate_cache"
    # shellcheck disable=SC1090
    source "$_mise_comp_cache"
    unset _mise_activate_cache _mise_comp_cache
  fi

  unset _mise_bin _mise_cache_dir
fi

[ "${DOTFILE_DEBUG:-}" ] && echo "pathAfterMise:" >>/tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
