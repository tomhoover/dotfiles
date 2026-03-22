# shellcheck shell=bash

if command -v fzf &>/dev/null; then
    # fzf
    # export FZF_DEFAULT_OPTS='-m --height 40% --layout=reverse --border'
    # export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
    export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --color=fg:#f8f8f2,bg:#282a36,hl:#bd93f9 --color=fg+:#f8f8f2,bg+:#44475a,hl+:#bd93f9 --color=info:#ffb86c,prompt:#50fa7b,pointer:#ff79c6 --color=marker:#ff79c6,spinner:#ffb86c,header:#6272a4'

    if [[ -f /usr/share/fzf/completion.${SHEL} ]]; then
        # shellcheck disable=SC1090
        source /usr/share/fzf/completion."${SHEL}"
    fi
    if [[ -f /usr/share/fzf/key-bindings.${SHEL} ]]; then
        # shellcheck disable=SC1090
        source /usr/share/fzf/key-bindings."${SHEL}"
    fi
    # shellcheck disable=SC1090
    isdarwin && [ -f ~/.config/dotfiles/fzf."${SHEL}" ] && source ~/.config/dotfiles/fzf."${SHEL}"
fi
