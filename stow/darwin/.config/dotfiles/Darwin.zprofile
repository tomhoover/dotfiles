[ "$DOTFILE_DEBUG" ] && echo "$PATH" >>/tmp/shell-init.txt
[ "$DOTFILE_DEBUG" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_ZPROFILE_LOADED" | tee -a /tmp/shell-init.txt
export DARWIN_ZPROFILE_LOADED=1

# MacPorts
export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
export MANPATH="/opt/local/share/man:$MANPATH"

[ -r /usr/local/bin/brew ] && eval "$(/usr/local/bin/brew shellenv zsh)"
[ -r /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv zsh)"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :

[ "$DOTFILE_DEBUG" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_ZPROFILE_ENDED" | tee -a /tmp/shell-init.txt
