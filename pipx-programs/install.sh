#!/usr/bin/env bash

command -v pipx       >/dev/null 2>&1 && pipx reinstall-all

# https://github.com/pypa/pipx/issues/20
command -v ansible    >/dev/null 2>&1 || pipx install --include-deps ansible
# If you need [community modules and plugins which are now part of collections](https://github.com/ansible-collections/overview#now-ansible-2-10-and-later),
# you can then inject them:
    # pipx inject ansible $module
    #   injected package $module into venv ansible
    #   done! ✨ 🌟 ✨

command -v black      >/dev/null 2>&1 || pipx install black
command -v flake8     >/dev/null 2>&1 || pipx install flake8
command -v ipython    >/dev/null 2>&1 || pipx install ipython
# command -v mypy     >/dev/null 2>&1 || pipx install mypy
# command -v pipenv   >/dev/null 2>&1 || pipx install pipenv
command -v pre-commit >/dev/null 2>&1 || pipx install pre-commit
command -v pylint     >/dev/null 2>&1 || pipx install pylint
command -v tmuxp      >/dev/null 2>&1 || pipx install tmuxp
