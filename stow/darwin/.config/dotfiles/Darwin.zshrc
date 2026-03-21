[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_ZSHRC_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export DARWIN_ZSHRC_LOADED=1

# https://github.com/seebi/dircolors-solarized (so solarized colors are used when accessing machine with iTerm2/ssh)
#eval `dircolors $HOME/src/github.com/seebi/dircolors-solarized/dircolors.ansi-universal`
if [ -x /usr/bin/dircolors ]; then test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"; fi

# Solarized colorscheme for macOS `ls` environment variable:
# https://github.com/seebi/dircolors-solarized/issues/10
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD

# iTerm2
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_ZSHRC_ENDED" | tee -a /tmp/shell-init.txt
