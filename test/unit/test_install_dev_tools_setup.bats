# tests/unit/test_install_dev_tools_setup.bats
# bats file_tags=fast
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export MOCK_BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$MOCK_BIN"

  export CALL_LOG="${BATS_TEST_TMPDIR}/call.log"
  rm -f "$CALL_LOG"

  # Fake repo root: the script does cd "$(dirname "$0")"/.. so we place the
  # script at fake_repo/script/install-dev-tools and run from fake_repo.
  export FAKE_REPO="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${FAKE_REPO}/script"
  cp "${REPO_ROOT}/script/install-dev-tools" "${FAKE_REPO}/script/install-dev-tools"
  chmod +x "${FAKE_REPO}/script/install-dev-tools"

  export SCRIPT="${FAKE_REPO}/script/install-dev-tools"

  # Stub all external tools so the script can reach the setup block and exit.
  _stub_externals
}

teardown() {
  rm -f "$CALL_LOG"
  rm -rf "$FAKE_REPO"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_stub_externals() {
  # find — emit nothing so the installer loop is a no-op
  cat >"$MOCK_BIN/find" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/find"

  # sort — pass-through
  cat >"$MOCK_BIN/sort" <<'EOF'
#!/bin/bash
cat
EOF
  chmod +x "$MOCK_BIN/sort"

  # mise
  cat >"$MOCK_BIN/mise" <<EOF
#!/bin/bash
echo "mise \$@" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mise"

  # uv
  cat >"$MOCK_BIN/uv" <<EOF
#!/bin/bash
echo "uv \$@" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/uv"

  # tput — suppress color codes
  cat >"$MOCK_BIN/tput" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/tput"

  # ansible / direnv — present so type -a finds them
  for cmd in ansible direnv; do
    cat >"$MOCK_BIN/${cmd}" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/${cmd}"
  done
}

# ---------------------------------------------------------------------------
# Directory creation
# ---------------------------------------------------------------------------

@test "setup block: creates \$HOME/.local/bin if it does not exist" {
  rm -rf "$HOME/.local"
  run bash "$SCRIPT"
  assert [ -d "$HOME/.local/bin" ]
}

@test "setup block: does not fail if \$HOME/.local/bin already exists" {
  mkdir -p "$HOME/.local/bin"
  run bash "$SCRIPT"
  assert_success
}

# ---------------------------------------------------------------------------
# Permissions
# ---------------------------------------------------------------------------

@test "setup block: sets \$HOME/.local permissions to 700" {
  run bash "$SCRIPT"
  perms=$(stat -f "%OLp" "$HOME/.local" 2>/dev/null) || perms=$(stat -c "%a" "$HOME/.local")
  assert [ "$perms" = "700" ]
}

@test "setup block: sets \$HOME/.local/bin permissions to 755" {
  run bash "$SCRIPT"
  perms=$(stat -f "%OLp" "$HOME/.local/bin" 2>/dev/null) || perms=$(stat -c "%a" "$HOME/.local/bin")
  assert [ "$perms" = "755" ]
}

# ---------------------------------------------------------------------------
# Info message
# ---------------------------------------------------------------------------

@test "setup block: prints 'Installing development tools...' info message" {
  run bash "$SCRIPT"
  assert_output --partial "Installing development tools..."
}
