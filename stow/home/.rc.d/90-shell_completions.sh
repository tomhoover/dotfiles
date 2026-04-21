# shellcheck shell=bash

_cache_completion() {
  # Usage: _cache_completion <bin> <cache-name> <gen-cmd...>
  local bin="$1" cache_name="$2"
  shift 2
  local cache_file="${XDG_CACHE_HOME:-$HOME/.cache}/completions/${cache_name}.${SHEL}"
  if [[ ! -f "$cache_file" || "$bin" -nt "$cache_file" ]]; then
    mkdir -p "${cache_file%/*}"
    "$@" >"$cache_file"
  fi
  # shellcheck disable=SC1090
  source "$cache_file"
}

# changed from 'mise install' to native pkg mgr due to issues with bat completion function:
# _arguments:comparguments:327: can only be called from completion function
# if command -v bat &>/dev/null; then
#   _cache_completion "$(command -v bat)" bat bat --completion "${SHEL}"
# fi

if command -v codex &>/dev/null; then
  _cache_completion "$(command -v codex)" codex codex completion "${SHEL}"
fi

if command -v fnox &>/dev/null; then
  _cache_completion "$(command -v fnox)" fnox fnox completion "${SHEL}"
fi

if command -v hk &>/dev/null; then
  _cache_completion "$(command -v hk)" hk hk completion "${SHEL}"
fi

if command -v register-python-argcomplete &>/dev/null && command -v pipx &>/dev/null; then
  _cache_completion "$(command -v pipx)" pipx register-python-argcomplete pipx
fi

if command -v ruff &>/dev/null; then
  _cache_completion "$(command -v ruff)" ruff ruff generate-shell-completion "${SHEL}"
fi

if command -v uv &>/dev/null; then
  _cache_completion "$(command -v uv)" uv uv generate-shell-completion "${SHEL}"
fi

if command -v uvx &>/dev/null; then
  _cache_completion "$(command -v uvx)" uvx uvx --generate-shell-completion "${SHEL}"
fi

unset -f _cache_completion
