# shellcheck shell=bash disable=SC1090
[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: ZPROFILE_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export ZPROFILE_LOADED=1

[ -r ~/.profile ] && emulate sh -c 'source ~/.profile'

[ -r ~/.config/dotfiles/"$(uname)".zprofile ] && . ~/.config/dotfiles/"$(uname)".zprofile
[ -r ~/.config/dotfiles/"${MYHOST}".zprofile ] && . ~/.config/dotfiles/"${MYHOST}".zprofile

[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: ZPROFILE_ENDED" | tee -a /tmp/shell-init.txt
