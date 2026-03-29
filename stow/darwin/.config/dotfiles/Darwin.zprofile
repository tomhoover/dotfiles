[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_ZPROFILE_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export DARWIN_ZPROFILE_LOADED=1

[ -r /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv zsh)"
[ -r /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_ZPROFILE_ENDED" | tee -a /tmp/shell-init.txt
