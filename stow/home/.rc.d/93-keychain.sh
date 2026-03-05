# shellcheck shell=bash

# start ssh-agent & load key
command -v keychain >/dev/null 2>&1 && eval "$(keychain --quiet --ignore-missing --eval id_ed25519_"${MYHOST}" id_rsa_"${MYHOST}" github_rsa id_rsa)"

# keychain
# shellcheck disable=SC1090
[ -r "$HOME"/.keychain/"$(uname -n)"-sh ] && source "$HOME"/.keychain/"$(uname -n)"-sh
