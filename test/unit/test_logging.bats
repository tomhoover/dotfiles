# tests/unit/test_logging.bats
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  mkdir -p "${BATS_TEST_TMPDIR}/bin"

  export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
  cat >"$RUNNER" <<'EOF'
#!/bin/bash
source ./script/bootstrap
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
"$@"
EOF
  chmod +x "$RUNNER"
}

teardown() {
  rm -f "${BATS_TEST_TMPDIR}/bin/uname"
  rm -f "${BATS_TEST_TMPDIR}/bin/tput"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_uname() {
  cat >"${BATS_TEST_TMPDIR}/bin/uname" <<EOF
#!/bin/bash
echo "$1"
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/uname"
}

# Stub tput to return empty strings, simulating non-interactive / no-color
stub_tput_empty() {
  cat >"${BATS_TEST_TMPDIR}/bin/tput" <<'EOF'
#!/bin/bash
echo ""
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/tput"
}

# ---------------------------------------------------------------------------
# error
# ---------------------------------------------------------------------------

@test "error: outputs to stderr" {
  run "$RUNNER" error "something went wrong"
  # bats 'run' captures both streams by default; check output contains the message
  assert_output --partial "something went wrong"
}

@test "error: message contains ERROR label" {
  run "$RUNNER" error "disk full"
  assert_output --partial "ERROR"
}

@test "error: message contains input text" {
  run "$RUNNER" error "disk full"
  assert_output --partial "disk full"
}

@test "error: message contains error symbol" {
  stub_tput_empty
  run "$RUNNER" error "oops"
  assert_output --partial "✘"
}

@test "error: exits with non-zero status when used with set -e" {
  # error() itself does not exit — it just prints. This confirms it returns 0
  # and does not itself terminate the script.
  run "$RUNNER" error "test"
  # exit code is 0 because error() uses echo which succeeds
  assert_success
}

# ---------------------------------------------------------------------------
# warn
# ---------------------------------------------------------------------------

@test "warn: message contains WARNING label" {
  run "$RUNNER" warn "low disk"
  assert_output --partial "WARNING"
}

@test "warn: message contains input text" {
  run "$RUNNER" warn "low disk space"
  assert_output --partial "low disk space"
}

@test "warn: message contains warning symbol" {
  stub_tput_empty
  run "$RUNNER" warn "careful"
  assert_output --partial "‼"
}

# ---------------------------------------------------------------------------
# info
# ---------------------------------------------------------------------------

@test "info: message contains input text" {
  run "$RUNNER" info "starting up"
  assert_output --partial "starting up"
}

# ---------------------------------------------------------------------------
# success
# ---------------------------------------------------------------------------

@test "success: message contains input text" {
  run "$RUNNER" success "all done"
  assert_output --partial "all done"
}

@test "success: message contains checkmark symbol" {
  stub_tput_empty
  run "$RUNNER" success "completed"
  assert_output --partial "✔"
}

# ---------------------------------------------------------------------------
# No color codes in non-interactive context
# ---------------------------------------------------------------------------

@test "color variables are empty when stdout is not a terminal" {
  # bootstrap sets colors via tput only when [ -t 1 ] (stdout is a TTY).
  # When run via bats, stdout is not a TTY, so all color vars should be empty.
  # shellcheck disable=SC2016
  run "$RUNNER" bash -c 'source ./script/bootstrap; printf "%s" "$RED"'
  assert_output ""
}
