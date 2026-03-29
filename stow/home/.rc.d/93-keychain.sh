# shellcheck shell=bash

# Source existing keychain env immediately so SSH_AUTH_SOCK is available to
# subsequent rc.d files. The keychain invocation itself (which starts/verifies
# ssh-agent and loads keys) is deferred to after the first prompt.
# shellcheck disable=SC1090
[ -r "$HOME/.keychain/$(uname -n)-sh" ] && source "$HOME/.keychain/$(uname -n)-sh"

if command -v keychain >/dev/null 2>&1; then
  if [[ -n "${ZSH_VERSION:-}" ]] && [[ -o interactive ]]; then
    _keychain_deferred() {
      add-zle-hook-widget -d zle-line-init _keychain_deferred
      zle -D _keychain_deferred
      eval "$(keychain --quiet --ignore-missing --eval id_ed25519_"${MYHOST}" id_rsa_"${MYHOST}" github_rsa id_rsa)"
    }
    zle -N _keychain_deferred
    add-zle-hook-widget zle-line-init _keychain_deferred
  else
    eval "$(keychain --quiet --ignore-missing --eval id_ed25519_"${MYHOST}" id_rsa_"${MYHOST}" github_rsa id_rsa)"
  fi
fi
