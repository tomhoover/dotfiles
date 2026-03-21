# shellcheck shell=bash

if command -v "$HOME/.opencode/bin/opencode" &>/dev/null; then
    export PATH="$HOME/.opencode/bin:$PATH"

    # too slow
    # if command -v ~/.opencode/bin/opencode &>/dev/null; then eval "$(~/.opencode/bin/opencode completion)"; fi
fi
