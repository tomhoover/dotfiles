#!/usr/bin/env bash

install_latest() {
    cd || return
    current=$(asdf current "$1" | awk '{ print $2 }')
    # latest=$(asdf list all "$1" | tail -1)
    latest=$(asdf latest "$1")
    if [ "$current" != "$latest" ]; then
        echo "$1 current version is: $current"
        echo "$1 latest version is: $latest"
        asdf install "$1" latest
        echo "### If desired, run: asdf global $1 latest"
        echo ""
    fi
}

# shellcheck disable=SC2015
command -v asdf >/dev/null 2>&1 && asdf update || { echo ""; echo "asdf not installed!"; echo ""; exit; }
asdf plugin update --all

echo ""

if ! asdf plugin list | grep -q direnv; then
    asdf plugin add direnv https://github.com/asdf-community/asdf-direnv.git
    asdf direnv setup --no-touch-rc-file --shell bash --version latest
    asdf direnv setup --no-touch-rc-file --shell zsh --version latest
else
    asdf plugin update direnv
    asdf direnv setup --no-touch-rc-file --shell bash --version latest
    asdf direnv setup --no-touch-rc-file --shell zsh --version latest
fi
install_latest direnv

if ! asdf plugin list | grep -q bats; then
    asdf plugin add bats https://github.com/timgluz/asdf-bats.git
fi
install_latest bats

if ! asdf plugin list | grep -q shfmt; then
    asdf plugin add shfmt https://github.com/luizm/asdf-shfmt.git
fi
install_latest shfmt

if ! asdf plugin list | grep -q python; then
    asdf plugin add python https://github.com/asdf-community/asdf-python.git
fi
install_latest python

# the following is required until shellcheck releases an M1/M2 binary (https://github.com/koalaman/shellcheck/issues/2714)
if [ "$(uname)" = Darwin ]; then
    brew tap tomhoover/shellcheck
    brew install shellcheck@0.8.0
else
    if ! asdf plugin list | grep -q shellcheck; then
        asdf plugin add shellcheck https://github.com/luizm/asdf-shellcheck.git
        asdf install shellcheck 0.8.0
        asdf global shellcheck 0.8.0
    fi
    install_latest shellcheck
fi
