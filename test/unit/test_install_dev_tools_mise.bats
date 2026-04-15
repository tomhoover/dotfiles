# tests/unit/test_install_dev_tools_mise.bats
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

  export FAKE_REPO="${BATS_TEST_TMPDIR}/repo"
  mkdir -p "${FAKE_REPO}/script"
  cp "${REPO_ROOT}/script/install-dev-tools" "${FAKE_REPO}/script/install-dev-tools"
  chmod +x "${FAKE_REPO}/script/install-dev-tools"

  export SCRIPT="${FAKE_REPO}/script/install-dev-tools"

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
  # find — no installers
  cat >"$MOCK_BIN/find" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/find"

  cat >"$MOCK_BIN/sort" <<'EOF'
#!/bin/bash
cat
EOF
  chmod +x "$MOCK_BIN/sort"

  cat >"$MOCK_BIN/uv" <<EOF
#!/bin/bash
echo "uv \$@" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/uv"

  cat >"$MOCK_BIN/tput" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/tput"

  for cmd in ansible direnv; do
    cat >"$MOCK_BIN/${cmd}" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/${cmd}"
  done
}

make_mise() {
  local exit_code="${1:-0}"
  cat >"$MOCK_BIN/mise" <<EOF
#!/bin/bash
echo "mise \$@" >> "$CALL_LOG"
exit ${exit_code}
EOF
  chmod +x "$MOCK_BIN/mise"
}

mise_was_called_with() {
  grep -qF -- "mise $*" "$CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# mise install
# ---------------------------------------------------------------------------

@test "mise: calls 'mise install'" {
  make_mise 0
  run bash "$SCRIPT"
  assert_success
  run mise_was_called_with "install"
  assert_success
}

@test "mise: exits with error if 'mise install' fails" {
  make_mise 1
  run bash "$SCRIPT"
  assert_failure
}

@test "mise: calls mise install before uv tool install" {
  make_mise 0
  run bash "$SCRIPT"
  assert_success
  mise_line=$(grep -n "mise install" "$CALL_LOG" | head -1 | cut -d: -f1)
  uv_line=$(grep -n "^uv " "$CALL_LOG" | head -1 | cut -d: -f1)
  assert [ "$mise_line" -lt "$uv_line" ]
}
