# shellcheck shell=bash

echo "$PATH" >>/tmp/shell-init.txt
echo "$(date '+%Y-%m-%d %H:%M') :: BASHRC_LOADED" >>/tmp/shell-init.txt
export BASHRC_LOADED=1

# exit if non-interactive shell
[[ $- != *i* ]] && return

SHEL=bash
shopt -s extglob
for rc in ~/.rc.d/*.+(sh|bash); do
    echo "$rc"
    # shellcheck disable=SC1090
    [ -r "$rc" ] && [ -f "$rc" ] && source "$rc"
done
unset rc

MYHOST=$(uname -n | sed -e 's/\..*//') # alternative to $(hostname -s), as arch does not install 'hostname' by default

# shellcheck disable=SC1090
[ -r ~/.config/dotfiles/"$(uname)".bashrc ] && source ~/.config/dotfiles/"$(uname)".bashrc
# shellcheck disable=SC1090
[ -r ~/.config/dotfiles/"${MYHOST}".bashrc ] && source ~/.config/dotfiles/"${MYHOST}".bashrc

# ----------

# Increase Bash history size. Allow 32³ entries; the default is 500.
export HISTSIZE='32768'
export HISTFILESIZE="${HISTSIZE}"
# Omit duplicates and commands that begin with a space from history.
export HISTCONTROL='ignoreboth'

# https://github.com/seebi/dircolors-solarized (so solarized colors are used when accessing machine with iTerm2/ssh)
#eval $(dircolors $HOME/src/github.com/seebi/dircolors-solarized/dircolors.ansi-universal)
# shellcheck disable=SC2015
if [ -x /usr/bin/dircolors ]; then test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"; fi

# enable bash-completion to work with git aliases
# https://stackoverflow.com/questions/342969/how-do-i-get-bash-completion-to-work-with-aliases
#TODO
#__git_complete g __git_main
#TODO
# https://github.com/cykerway/complete-alias ??

# ----------

# Use starship prompt if available, otherwise liquidprompt
if command -v starship &>/dev/null; then
  # prevent empty line when opening terminal (https://github.com/starship/starship/issues/560)
  #   used in conjunction with 'add_newline = false' in ~/.config/starship.toml
  PROMPT_NEEDS_NEWLINE=false
  my_precmd() {
    if [[ "$PROMPT_NEEDS_NEWLINE" == true ]]; then
      echo
    fi
    PROMPT_NEEDS_NEWLINE=true
  }
  clear() {
    PROMPT_NEEDS_NEWLINE=false
    command clear
  }
  # export PROMPT_COMMAND=my_precmd
  # shellcheck disable=SC2034
  starship_precmd_user_func=my_precmd

  # shellcheck disable=SC2086
  eval "$(starship init ${SHEL})"
else
  # shellcheck disable=SC1090
  [ -f ~/.local/share/liquidprompt ] && source ~/.local/share/liquidprompt
fi
