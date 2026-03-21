# shellcheck shell=bash disable=SC1090
[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: BASH_PROFILE_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export BASH_PROFILE_LOADED=1

[ -r ~/.profile ] && . ~/.profile

[ -r ~/.config/dotfiles/"$(uname)".bash_profile ] && . ~/.config/dotfiles/"$(uname)".bash_profile
[ -r ~/.config/dotfiles/"${MYHOST}".bash_profile ] && . ~/.config/dotfiles/"${MYHOST}".bash_profile

[ -r ~/.bashrc ] && . ~/.bashrc
