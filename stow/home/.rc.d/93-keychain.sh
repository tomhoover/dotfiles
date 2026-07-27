# shellcheck shell=bash

# Source existing keychain env immediately so SSH_AUTH_SOCK is available to
# subsequent rc.d files. Then start/verify ssh-agent and load keys.
# shellcheck disable=SC1090
[ -r "$HOME/.keychain/$(uname -n)-sh" ] && source "$HOME/.keychain/$(uname -n)-sh"

if command -v keychain >/dev/null 2>&1; then
  eval "$(keychain --quiet --ignore-missing --eval id_ed25519_"${MYHOST}" id_rsa_"${MYHOST}" github_rsa id_rsa)"
fi
