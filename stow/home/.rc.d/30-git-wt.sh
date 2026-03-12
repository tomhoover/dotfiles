# shellcheck shell=bash

if command -v git-wt &>/dev/null; then
    eval "$(git wt init "${SHEL}")"
    eval "$(git wt completion "${SHEL}")"
    if [ -f "$HOME/src/github.com/tomhoover/git-wt+claude/src/git-wt" ]; then
        ln -nsf "$HOME/src/github.com/tomhoover/git-wt+claude/src/git-wt" "$HOME/bin/git-wt"
    fi
fi
