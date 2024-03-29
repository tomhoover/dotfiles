#!/usr/bin/env bash

# command -v pipx         >/dev/null 2>&1 && asdf global pipx latest && pipx reinstall-all

if [ "$(mise global pipx)" != "$(mise ls-remote pipx | tail -1)" ]; then
    # mise use -g pipx@latest && pipx reinstall-all
    mise global pipx@"$(mise ls-remote pipx | tail -1)" && mise install && pipx reinstall-all
fi

# https://github.com/pypa/pipx/issues/20
command -v ansible    >/dev/null 2>&1 || pipx install --include-deps ansible
# If you need [community modules and plugins which are now part of collections](https://github.com/ansible-collections/overview#now-ansible-2-10-and-later), you can then inject them:
    # pipx inject ansible $module
    #   injected package $module into venv ansible
    #   done! ✨ 🌟 ✨
# gron ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep 'json.injected_packages.requests' >/dev/null || pipx inject ansible requests
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep requests >/dev/null || pipx inject ansible requests
# gron ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep 'json.injected_packages.passlib' >/dev/null || pipx inject ansible passlib
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep passlib  >/dev/null || pipx inject ansible passlib
# gron ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep 'json.injected_packages.netaddr' >/dev/null || pipx inject ansible netaddr
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/ansible/pipx_metadata.json | grep netaddr  >/dev/null || pipx inject ansible netaddr

# https://github.com/mkb79/audible-cli
command -v audible      >/dev/null 2>&1 || pipx install audible-cli

command -v black        >/dev/null 2>&1 || pipx install black
command -v cookiecutter >/dev/null 2>&1 || pipx install cookiecutter
command -v flake8       >/dev/null 2>&1 || pipx install flake8
command -v isort        >/dev/null 2>&1 || pipx install isort
command -v ipython      >/dev/null 2>&1 || pipx install ipython
command -v pre-commit   >/dev/null 2>&1 || pipx install pre-commit
command -v pylint       >/dev/null 2>&1 || pipx install pylint
command -v tmuxp        >/dev/null 2>&1 || pipx install tmuxp
# command -v mypy         >/dev/null 2>&1 || pipx install mypy
# command -v pipenv       >/dev/null 2>&1 || pipx install pipenv

#### pipx inject ansible molecule
command -v molecule   >/dev/null 2>&1 || pipx install molecule
#### pipx inject molecule molecule-docker
# gron ~/.local/pipx/venvs/molecule/pipx_metadata.json | grep 'json.injected_packages\["molecule-plugins"\]' >/dev/null || { pipx inject molecule molecule-plugins; pipx inject molecule 'molecule-plugins[docker]'; }
jq -r '.injected_packages | keys' ~/.local/pipx/venvs/molecule/pipx_metadata.json | grep molecule-plugins >/dev/null || { pipx inject molecule molecule-plugins; pipx inject molecule 'molecule-plugins[docker]'; }
