# tests/unit/test_install_paru_customizepkg.bats
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export MOCK_BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$MOCK_BIN"

  export PARU_CALL_LOG="${BATS_TEST_TMPDIR}/paru.log"
  rm -f "$PARU_CALL_LOG"

  export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
  cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
"$@"
EOF
  chmod +x "$RUNNER"

  _stub_paru
}

teardown() {
  rm -f "$PARU_CALL_LOG"
  rm -f "$MOCK_BIN/paru"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_stub_paru() {
  cat >"$MOCK_BIN/paru" <<EOF
#!/bin/bash
echo "paru \$@" >> "$PARU_CALL_LOG"
exit 0
EOF
  chmod +x "$MOCK_BIN/paru"
}

paru_was_called_with() {
  grep -qF -- "$*" "$PARU_CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

@test "install_paru_customizepkg: does not fail when paru.conf is missing" {
  rm -rf "$HOME/.config/paru"
  rm -rf "$HOME/.cache/AUR/customizepkg-git"
  run "$RUNNER" install_paru_customizepkg
  assert_success
}

@test "install_paru_customizepkg: installs customizepkg-git via paru when missing" {
  rm -rf "$HOME/.cache/AUR/customizepkg-git"
  run "$RUNNER" install_paru_customizepkg
  assert_success
  run paru_was_called_with "paru -S customizepkg-git"
  assert_success
}

@test "install_paru_customizepkg: creates paru.conf when missing" {
  rm -rf "$HOME/.config/paru"
  run "$RUNNER" install_paru_customizepkg
  assert_success
  assert [ -f "$HOME/.config/paru/paru.conf" ]
}
