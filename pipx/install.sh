#!/usr/bin/env bash

pip list | grep pipx  >/dev/null 2>&1 || ( pip install pipx && pipx reinstall-all )

command -v black      >/dev/null 2>&1 || pipx install black
command -v flake8     >/dev/null 2>&1 || pipx install flake8
command -v ipython    >/dev/null 2>&1 || pipx install ipython
command -v mypy       >/dev/null 2>&1 || pipx install mypy
# command -v pipenv   >/dev/null 2>&1 || pipx install pipenv
command -v pre-commit >/dev/null 2>&1 || pipx install pre-commit
command -v pylint     >/dev/null 2>&1 || pipx install pylint
command -v tmuxp      >/dev/null 2>&1 || pipx install tmuxp
