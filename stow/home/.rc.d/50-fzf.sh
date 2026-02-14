# shellcheck shell=bash

if command -v fzf &>/dev/null; then
    if [[ -f /usr/share/fzf/completion.${SHEL} ]]; then
        # shellcheck disable=SC1090
        source /usr/share/fzf/completion."${SHEL}"
    fi
    if [[ -f /usr/share/fzf/key-bindings.${SHEL} ]]; then
        # shellcheck disable=SC1090
        source /usr/share/fzf/key-bindings."${SHEL}"
    fi
fi

# shellcheck disable=SC1090
isdarwin && [ -f ~/.config/dotfiles/fzf."${SHEL}" ] && source ~/.config/dotfiles/fzf."${SHEL}"
