# tests/unit/test_install_dev_tools_installer_loop.bats
# bats file_tags=fast
bats_require_minimum_version 1.5.0
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

  # Stub non-loop externals so they don't interfere.
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
  cat >"$MOCK_BIN/mise" <<EOF
#!/bin/bash
echo "mise \$@" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/mise"

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

# Make a fake installer at a given path inside FAKE_REPO.
# Usage: make_installer ./1-mise/install.sh [exit_code]
make_installer() {
  local rel_path="$1" exit_code="${2:-0}"
  local full_path="${FAKE_REPO}/${rel_path#./}"
  mkdir -p "$(dirname "$full_path")"
  cat >"$full_path" <<EOF
#!/bin/bash
echo "installer:${rel_path}" >> "$CALL_LOG"
exit ${exit_code}
EOF
  chmod +x "$full_path"
}

installer_was_called() {
  grep -qF -- "installer:$1" "$CALL_LOG" 2>/dev/null
}

installer_was_not_called() {
  ! grep -qF -- "installer:$1" "$CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Program already on PATH — skip
# ---------------------------------------------------------------------------

@test "installer loop: skips installer if program is already on PATH" {
  make_installer "./mise/install.sh"
  # mise mock is already in MOCK_BIN, so it's on PATH
  run bash "$SCRIPT"
  assert_success
  run installer_was_not_called "./mise/install.sh"
  assert_success
}

# ---------------------------------------------------------------------------
# Program not on PATH — run installer
# ---------------------------------------------------------------------------

@test "installer loop: runs installer if program is not on PATH" {
  make_installer "./mytool/install.sh"
  # mytool is not in MOCK_BIN
  run bash "$SCRIPT"
  assert_success
  run installer_was_called "./mytool/install.sh"
  assert_success
}

@test "installer loop: prints 'Installing <program>...' before running installer" {
  make_installer "./mytool/install.sh"
  run bash "$SCRIPT"
  assert_output --partial "Installing mytool..."
}

@test "installer loop: does not print installing message when program already present" {
  make_installer "./mise/install.sh"
  run bash "$SCRIPT"
  refute_output --partial "Installing mise..."
}

# ---------------------------------------------------------------------------
# Program name extraction
# ---------------------------------------------------------------------------

@test "installer loop: extracts program name from path with numeric prefix (./1-mise/install.sh → mise)" {
  rm -f "$MOCK_BIN/mise"
  make_installer "./1-mise/install.sh"
  run -127 env PATH="$MOCK_BIN:/usr/bin:/bin" bash "$SCRIPT"
  assert_output --partial "Installing mise..."
}

@test "installer loop: extracts program name from path without numeric prefix (./direnv/install.sh → direnv)" {
  rm -f "$MOCK_BIN/direnv"
  make_installer "./direnv/install.sh"
  run env PATH="$MOCK_BIN:/usr/bin:/bin" bash "$SCRIPT"
  assert_output --partial "Installing direnv..."
}

@test "installer loop: extracts program name from path with multi-digit prefix (./10-foo/install.sh → foo)" {
  make_installer "./10-foo/install.sh"
  run bash "$SCRIPT"
  assert_output --partial "Installing foo..."
}

# ---------------------------------------------------------------------------
# direnv special case — bin_path env var
# ---------------------------------------------------------------------------

@test "installer loop: passes bin_path=~/.local/bin to direnv installer" {
  rm -f "$MOCK_BIN/direnv"
  mkdir -p "${FAKE_REPO}/direnv"
  cat >"${FAKE_REPO}/direnv/install.sh" <<EOF
#!/bin/bash
echo "bin_path=\${bin_path}" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "${FAKE_REPO}/direnv/install.sh"
  run env PATH="$MOCK_BIN:/usr/bin:/bin" bash "$SCRIPT"
  run grep -q "bin_path=.*local/bin" "$CALL_LOG"
  assert_success
}

@test "installer loop: does not pass bin_path to non-direnv installer" {
  mkdir -p "${FAKE_REPO}/mytool"
  cat >"${FAKE_REPO}/mytool/install.sh" <<EOF
#!/bin/bash
echo "bin_path=\${bin_path:-UNSET}" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "${FAKE_REPO}/mytool/install.sh"
  run bash "$SCRIPT"
  run grep -qF "bin_path=UNSET" "$CALL_LOG"
  assert_success
}

# ---------------------------------------------------------------------------
# Failure handling
# ---------------------------------------------------------------------------

@test "installer loop: exits with code 1 if non-direnv installer fails" {
  make_installer "./mytool/install.sh" 1
  run bash "$SCRIPT"
  assert_failure
  assert [ "$status" -eq 1 ]
}

@test "installer loop: exits with code 1 if direnv installer fails" {
  rm -f "$MOCK_BIN/direnv"
  make_installer "./direnv/install.sh" 1
  run env PATH="$MOCK_BIN:/usr/bin:/bin" bash "$SCRIPT"
  assert_failure
  assert [ "$status" -eq 1 ]
}

@test "installer loop: prints error message identifying failed installer" {
  make_installer "./mytool/install.sh" 1
  run bash "$SCRIPT"
  assert_output --partial "Failed to run mytool/install.sh"
}

# ---------------------------------------------------------------------------
# Ordering and depth
# ---------------------------------------------------------------------------

@test "installer loop: runs installers in sorted order" {
  make_installer "./2-bravo/install.sh"
  make_installer "./1-alpha/install.sh"
  run bash "$SCRIPT"
  assert_success
  alpha_line=$(grep -n "installer:./1-alpha" "$CALL_LOG" | cut -d: -f1)
  bravo_line=$(grep -n "installer:./2-bravo" "$CALL_LOG" | cut -d: -f1)
  assert [ "$alpha_line" -lt "$bravo_line" ]
}

@test "installer loop: finds installers at maxdepth 2 only" {
  make_installer "./mytool/install.sh"
  run bash "$SCRIPT"
  run installer_was_called "./mytool/install.sh"
  assert_success
}

@test "installer loop: does not find install.sh nested deeper than maxdepth 2" {
  mkdir -p "${FAKE_REPO}/a/b/c"
  cat >"${FAKE_REPO}/a/b/c/install.sh" <<EOF
#!/bin/bash
echo "deep-installer" >> "$CALL_LOG"
exit 0
EOF
  chmod +x "${FAKE_REPO}/a/b/c/install.sh"
  run bash "$SCRIPT"
  run grep -qF "deep-installer" "$CALL_LOG"
  # Should NOT have been called
  assert_failure
}

@test "installer loop: processes multiple installers in one pass" {
  make_installer "./alpha/install.sh"
  make_installer "./bravo/install.sh"
  run bash "$SCRIPT"
  assert_success
  run installer_was_called "./alpha/install.sh"
  assert_success
  run installer_was_called "./bravo/install.sh"
  assert_success
}

@test "installer loop: skips all installers if all programs already present" {
  # mise and uv are both in MOCK_BIN
  make_installer "./mise/install.sh"
  make_installer "./uv/install.sh"
  run bash "$SCRIPT"
  assert_success
  run installer_was_not_called "./mise/install.sh"
  assert_success
  run installer_was_not_called "./uv/install.sh"
  assert_success
}
