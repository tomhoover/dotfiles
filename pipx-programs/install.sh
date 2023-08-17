#!/usr/bin/env bash

command -v pipx       >/dev/null 2>&1 && pipx reinstall-all

# https://github.com/pypa/pipx/issues/20
command -v ansible    >/dev/null 2>&1 || pipx install --include-deps ansible
# If you need [community modules and plugins which are now part of collections](https://github.com/ansible-collections/overview#now-ansible-2-10-and-later), you can then inject them:
    # pipx inject ansible $module
    #   injected package $module into venv ansible
    #   done! ✨ 🌟 ✨
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep requests || pipx inject ansible requests
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep passlib  || pipx inject ansible passlib
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep netaddr  || pipx inject ansible netaddr

command -v black      >/dev/null 2>&1 || pipx install black
command -v flake8     >/dev/null 2>&1 || pipx install flake8
command -v ipython    >/dev/null 2>&1 || pipx install ipython
# command -v mypy     >/dev/null 2>&1 || pipx install mypy
# command -v pipenv   >/dev/null 2>&1 || pipx install pipenv
command -v pre-commit >/dev/null 2>&1 || pipx install pre-commit
command -v pylint     >/dev/null 2>&1 || pipx install pylint
command -v tmuxp      >/dev/null 2>&1 || pipx install tmuxp

#### pipx inject ansible molecule
command -v molecule   >/dev/null 2>&1 || pipx install molecule
#### pipx inject molecule molecule-docker
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/molecule/pipx_metadata.json | grep molecule-plugins || { pipx inject molecule molecule-plugins; pipx inject molecule 'molecule-plugins[docker]'; }
