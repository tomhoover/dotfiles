# shellcheck shell=bash

# ensure ~/.local/bin follows rbenv/pyenv/asdf/mise shims in $PATH (i.e. pipx installed packages are secondary to shims)
export PATH="$HOME/.local/bin:$PATH"

if command -v mise &>/dev/null; then
  _mise_bin="$(command -v mise)"
  _mise_cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/mise"

  _mise_activate_cache="$_mise_cache_dir/activate.${SHEL}"
  if [[ ! -f "$_mise_activate_cache" || "$_mise_bin" -nt "$_mise_activate_cache" ]]; then
    mkdir -p "$_mise_cache_dir"
    mise activate "${SHEL}" >"$_mise_activate_cache"
  fi
  # shellcheck disable=SC1090
  source "$_mise_activate_cache"

  # In zsh, move _mise_hook from precmd (every prompt) to chpwd (directory change only)
  if [[ -n "${ZSH_VERSION:-}" ]]; then
    precmd_functions=("${precmd_functions[@]/_mise_hook/}")
    chpwd_functions+=(_mise_hook)
  fi

  _mise_comp_cache="$_mise_cache_dir/completion.${SHEL}"
  if [[ ! -f "$_mise_comp_cache" || "$_mise_bin" -nt "$_mise_comp_cache" ]]; then
    mise completion "${SHEL}" >"$_mise_comp_cache"
  fi
  # shellcheck disable=SC1090
  source "$_mise_comp_cache"

  unset _mise_bin _mise_cache_dir _mise_activate_cache _mise_comp_cache
fi

# export PATH=$HOME/.local/share/mise/shims:$PATH # add mise shims to PATH in .profile, instead of .bashrc and .zshrc:

# insert ~/bin into $PATH before rbenv/pyenv/asdf/mise shims
export PATH="$HOME/bin:$PATH"

[ "${DOTFILE_DEBUG:-}" ] && echo "pathAfterMise:" >>/tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
