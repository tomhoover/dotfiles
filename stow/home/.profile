# shellcheck shell=sh disable=SC2034
[ "${DOTFILE_DEBUG:-}" ] && echo "$(date '+%Y-%m-%d %H:%M') :: PROFILE_LOADED" | tee -a /tmp/shell-init.txt
[ "${DOTFILE_DEBUG:-}" ] && echo "$PATH" >>/tmp/shell-init.txt
export PROFILE_LOADED=1

MYHOST=$(uname -n | sed -e 's/\..*//') # alternative to $(hostname -s), as arch does not install 'hostname' by default

# # start ssh-agent & load key
# command -v /usr/bin/keychain >/dev/null 2>&1 && eval "$(/usr/bin/keychain --quiet --ignore-missing --eval id_rsa_"${MYHOST}" github_rsa id_rsa)"
