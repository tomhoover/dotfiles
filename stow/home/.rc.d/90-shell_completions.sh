# shellcheck shell=bash

if command -v register-python-argcomplete &>/dev/null; then eval "$(register-python-argcomplete pipx)"; fi # enable pipx completion
if command -v ruff                        &>/dev/null; then eval "$(ruff generate-shell-completion "${SHEL}")"; fi
if command -v uv                          &>/dev/null; then eval "$(uv generate-shell-completion "${SHEL}")"; fi
if command -v uvx                         &>/dev/null; then eval "$(uvx --generate-shell-completion "${SHEL}")"; fi
