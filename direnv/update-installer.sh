#!/usr/bin/env sh

# set -e: exit script immediately upon error
# set -u: treat unset variables as an error
set -eu

cd "$(dirname "$0")"

curl -sfLo install.sh https://direnv.net/install.sh
