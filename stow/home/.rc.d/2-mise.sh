# shellcheck shell=bash

# ensure ~/.local/bin follows rbenv/pyenv/asdf/mise shims in $PATH (i.e. pipx installed packages are secondary to shims)
export PATH="$HOME/.local/bin:$PATH"

if command -v mise &>/dev/null; then eval "$(mise activate "${SHEL}")"; fi # this sets up interactive sessions
# export PATH=$HOME/.local/share/mise/shims:$PATH # add mise shims to PATH in .profile, instead of .bashrc and .zshrc:

# insert ~/bin into $PATH before rbenv/pyenv/asdf/mise shims
export PATH="$HOME/bin:$PATH"

if command -v mise &>/dev/null; then eval "$(mise completion "${SHEL}")"; fi

echo "$PATH" >/tmp/pathAfterMise.txt
