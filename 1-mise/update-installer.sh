#!/usr/bin/env sh

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
set -eu

cd "$(dirname "$0")"

# gpg --keyserver hkps://keyserver.ubuntu.com --recv-keys 0x7413A06D
curl https://mise.jdx.dev/install.sh.sig | gpg --decrypt > install.sh
# ensure the above is signed with the mise release key
# sh ./install.sh
