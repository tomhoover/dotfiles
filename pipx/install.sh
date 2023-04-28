#!/usr/bin/env bash

if [[ $(pyenv global) == "system" ]]; then
    echo "pyenv global is not set"
    echo "install desired python version: 'pyenv install 3.11.2'"
    echo "create global virtualenv: 'pyenv virtualenv 3.11.2 py311'"
    echo "set pyenv global: 'pyenv global 3.11.2 py311'"
    exit 1
else
    eval "$(pyenv init -)" && eval "$(pyenv virtualenv-init -)" && pyenv activate $(pyenv global | tail -1)

    pip list | grep pipx  >/dev/null 2>&1 || ( pip install pipx && pipx reinstall-all )

    command -v black      >/dev/null 2>&1 || pipx install black
    command -v flake8     >/dev/null 2>&1 || pipx install flake8
    command -v ipython    >/dev/null 2>&1 || pipx install ipython
    # command -v mypy     >/dev/null 2>&1 || pipx install mypy
    # command -v pipenv   >/dev/null 2>&1 || pipx install pipenv
    command -v pre-commit >/dev/null 2>&1 || pipx install pre-commit
    command -v pylint     >/dev/null 2>&1 || pipx install pylint
    command -v tmuxp      >/dev/null 2>&1 || pipx install tmuxp

    pyenv deactivate
fi
