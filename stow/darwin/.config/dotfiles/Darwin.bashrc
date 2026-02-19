[ "$DOTFILE_DEBUG" ] && echo "$PATH" >>/tmp/shell-init.txt
[ "$DOTFILE_DEBUG" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_BASHRC_LOADED" | tee -a /tmp/shell-init.txt
export DARWIN_ZSHRC_LOADED=1

# Solarized colorscheme for macOS `ls` environment variable:
# https://github.com/seebi/dircolors-solarized/issues/10
export LSCOLORS=gxfxbEaEBxxEhEhBaDaCaD

[ "$DOTFILE_DEBUG" ] && echo "$(date '+%Y-%m-%d %H:%M') :: :: DARWIN_BASHRC_ENDED" | tee -a /tmp/shell-init.txt
