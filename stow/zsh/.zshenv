# shellcheck shell=bash disable=SC1090

[ "$DOTFILE_DEBUG" ] && echo "$PATH" >>/tmp/shell-init.txt
[ "$DOTFILE_DEBUG" ] && echo "$(date '+%Y-%m-%d %H:%M') :: ZSHENV_LOADED" | tee -a /tmp/shell-init.txt
export ZSHENV_LOADED=1

# GRML_DISPLAY_BATTERY=1
export NOPATHHELPER=1

MYHOST=$(uname -n | sed -e 's/\..*//')     # alternative to $(hostname -s), as arch does not install 'hostname' by default

[ -r ~/.config/dotfiles/"$(uname)".zshenv ] && . ~/.config/dotfiles/"$(uname)".zshenv
[ -r ~/.config/dotfiles/"${MYHOST}".zshenv ] && . ~/.config/dotfiles/"${MYHOST}".zshenv
