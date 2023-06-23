#!/usr/bin/env bash

exit

if [[ $(pyenv global) == "system" ]]; then
    echo "pyenv global is not set"
    echo "install desired python version: 'pyenv install 3.11.2'"
    echo "create global virtualenv: 'pyenv virtualenv 3.11.2 py311'"
    echo "set pyenv global: 'pyenv global 3.11.2 py311'"
    exit 1
else
    eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init -)" && pyenv activate "$(pyenv global | tail -1)"
    pip list | grep pipx >/dev/null 2>&1 || pip install pipx
    pyenv deactivate
fi
