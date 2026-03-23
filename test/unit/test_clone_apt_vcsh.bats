# tests/unit/test_clone_apt_vcsh.bats
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export MOCK_BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$MOCK_BIN"

  export APT_CALL_LOG="${BATS_TEST_TMPDIR}/apt.log"
  rm -f "$APT_CALL_LOG"

  export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
  cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
# avoid touching real repos in tests
github_vclone() { :; }
"$@"
EOF
  chmod +x "$RUNNER"

  _stub_apt_tools
  _stub_sudo
}

teardown() {
  rm -f "$APT_CALL_LOG"
  rm -f "$MOCK_BIN/apt-get" "$MOCK_BIN/apt-mark" "$MOCK_BIN/sudo" "$MOCK_BIN/uname"
  rm -f "${BATS_TEST_TMPDIR}/etc/os-release"
  unset OS_RELEASE
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_stub_apt_tools() {
  cat >"$MOCK_BIN/apt-get" <<EOF
#!/bin/bash
echo "apt-get \$@" >> "$APT_CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/apt-get"

  cat >"$MOCK_BIN/apt-mark" <<EOF
#!/bin/bash
echo "apt-mark \$@" >> "$APT_CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/apt-mark"
}

_stub_sudo() {
  cat >"$MOCK_BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
  chmod +x "$MOCK_BIN/sudo"
}

make_uname() {
  cat >"$MOCK_BIN/uname" <<EOF
#!/bin/bash
echo "$1"
EOF
  chmod +x "$MOCK_BIN/uname"
}

make_os_release() {
  mkdir -p "${BATS_TEST_TMPDIR}/etc"
  echo "ID=$1" >"${BATS_TEST_TMPDIR}/etc/os-release"
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release"
}

apt_was_called_with() {
  grep -qF -- "$*" "$APT_CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "clone_apt_vcsh: warns and skips when ~/.config/apt/installed is missing" {
  make_uname "Linux"
  make_os_release "debian"
  rm -f "$HOME/.config/apt/installed"
  run "$RUNNER" clone_apt_vcsh
  assert_success
  assert_output --partial "skipping apt package restore"
  run apt_was_called_with "apt-get update"
  assert_failure
}

@test "clone_apt_vcsh: installs listed packages when ~/.config/apt/installed exists" {
  make_uname "Linux"
  make_os_release "debian"
  mkdir -p "$HOME/.config/apt"
  printf "curl\nripgrep\n" >"$HOME/.config/apt/installed"
  run "$RUNNER" clone_apt_vcsh
  assert_success
  run apt_was_called_with "apt-get update"
  assert_success
  run apt_was_called_with "apt-get --yes install curl ripgrep"
  assert_success
  run apt_was_called_with "apt-mark manual curl ripgrep"
  assert_success
}
