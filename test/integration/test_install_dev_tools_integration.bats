# tests/integration/test_install_dev_tools_integration.bats
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

  # Stub tput unconditionally — no terminal in test environment
  cat >"$MOCK_BIN/tput" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/tput"
}

teardown() {
  rm -f "$CALL_LOG"
  rm -rf "$FAKE_REPO"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_mise() {
  local exit_code="${1:-0}"
  shift
  local tools=("$@")
  # Write the shebang and static lines first using a quoted heredoc,
  # then append the dynamic ls output block and exit code.
  cat >"$MOCK_BIN/mise" <<SHEBANG
#!/bin/bash
SHEBANG
  cat >>"$MOCK_BIN/mise" <<EOF
echo "mise \$@" >> "${CALL_LOG}"
case "\$1" in
  ls)
EOF
  for tool in "${tools[@]}"; do
    echo "    echo '${tool}'" >>"$MOCK_BIN/mise"
  done
  cat >>"$MOCK_BIN/mise" <<EOF
    ;;
esac
exit ${exit_code}
EOF
  chmod +x "$MOCK_BIN/mise"
}

make_uv() {
  local exit_code="${1:-0}"
  cat >"$MOCK_BIN/uv" <<EOF
#!/bin/bash
echo "uv \$@" >> "$CALL_LOG"
exit ${exit_code}
EOF
  chmod +x "$MOCK_BIN/uv"
}

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

# Ensure a named binary exists in MOCK_BIN (so type -a finds it)
make_binary() {
  local name="$1"
  cat >"$MOCK_BIN/${name}" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$MOCK_BIN/${name}"
}

fn_order() {
  # Returns the line number of the first occurrence of a pattern in CALL_LOG
  grep -n "$1" "$CALL_LOG" | head -1 | cut -d: -f1
}

# ---------------------------------------------------------------------------
# Full run — all tools already present (no installers needed)
# ---------------------------------------------------------------------------

@test "integration: exits successfully with all tools mocked and present" {
  make_binary mise
  make_binary uv
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 0
  run bash "$SCRIPT"
  assert_success
}

# ---------------------------------------------------------------------------
# Full run — no tools present (fresh install path)
# ---------------------------------------------------------------------------

@test "integration: exits successfully with no tools present (fresh install path)" {
  # Use tool names that are guaranteed absent from any real PATH.
  # The find stub emits their installer paths; since the tools aren't on
  # PATH, the loop runs both installers.
  cat >"$MOCK_BIN/find" <<'EOF'
#!/bin/bash
echo "./1-faketool-a/install.sh"
echo "./2-faketool-b/install.sh"
EOF
  chmod +x "$MOCK_BIN/find"

  cat >"$MOCK_BIN/sort" <<'EOF'
#!/bin/bash
cat
EOF
  chmod +x "$MOCK_BIN/sort"

  mkdir -p "${FAKE_REPO}/1-faketool-a" "${FAKE_REPO}/2-faketool-b"
  cat >"${FAKE_REPO}/1-faketool-a/install.sh" <<EOF
#!/bin/bash
echo "installer:./1-faketool-a/install.sh" >> "${CALL_LOG}"
exit 0
EOF
  chmod +x "${FAKE_REPO}/1-faketool-a/install.sh"

  cat >"${FAKE_REPO}/2-faketool-b/install.sh" <<EOF
#!/bin/bash
echo "installer:./2-faketool-b/install.sh" >> "${CALL_LOG}"
exit 0
EOF
  chmod +x "${FAKE_REPO}/2-faketool-b/install.sh"

  make_mise 0
  make_uv 0
  make_binary ansible
  make_binary direnv

  run bash "$SCRIPT"
  assert_success
  run grep -qF "installer:./1-faketool-a/install.sh" "$CALL_LOG"
  assert_success
  run grep -qF "installer:./2-faketool-b/install.sh" "$CALL_LOG"
  assert_success
}

# ---------------------------------------------------------------------------
# Execution order
# ---------------------------------------------------------------------------

@test "integration: runs mise install after all individual installers" {
  make_binary ansible
  make_binary direnv
  make_installer "./mytool/install.sh" 0
  # mytool not on PATH — installer will run
  make_mise 0
  make_uv 0

  run bash "$SCRIPT"
  assert_success

  installer_line=$(fn_order "installer:./mytool/install.sh")
  mise_line=$(fn_order "mise install")
  assert [ "$installer_line" -lt "$mise_line" ]
}

@test "integration: runs uv tool install after mise install" {
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 0

  run bash "$SCRIPT"
  assert_success

  mise_line=$(fn_order "mise install")
  uv_line=$(fn_order "^uv tool install")
  assert [ "$mise_line" -lt "$uv_line" ]
}

@test "integration: runs installer loop before mise install and uv tool install" {
  make_binary ansible
  make_binary direnv
  make_installer "./alpha/install.sh" 0
  make_mise 0
  make_uv 0

  run bash "$SCRIPT"
  assert_success

  installer_line=$(fn_order "installer:./alpha/install.sh")
  mise_line=$(fn_order "mise install")
  uv_line=$(fn_order "^uv tool install")
  assert [ "$installer_line" -lt "$mise_line" ]
  assert [ "$installer_line" -lt "$uv_line" ]
}

# ---------------------------------------------------------------------------
# Full sequence on macOS-like environment
# ---------------------------------------------------------------------------

@test "integration: full sequence completes without error on macOS-like environment" {
  # Simulate macOS: uname returns Darwin, no os-release
  cat >"$MOCK_BIN/uname" <<'EOF'
#!/bin/bash
echo "Darwin"
EOF
  chmod +x "$MOCK_BIN/uname"

  make_binary mise
  make_binary uv
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 0

  run bash "$SCRIPT"
  assert_success
}

# ---------------------------------------------------------------------------
# Full sequence on Linux-like environment
# ---------------------------------------------------------------------------

@test "integration: full sequence completes without error on Linux-like environment" {
  cat >"$MOCK_BIN/uname" <<'EOF'
#!/bin/bash
echo "Linux"
EOF
  chmod +x "$MOCK_BIN/uname"

  make_binary mise
  make_binary uv
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 0

  run bash "$SCRIPT"
  assert_success
}

# ---------------------------------------------------------------------------
# Legacy warnings appear at end of full run
# ---------------------------------------------------------------------------

@test "integration: legacy warnings appear after installed versions output" {
  make_binary mise
  make_binary uv
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 0

  mkdir -p "$HOME/.pyenv/bin"
  cat >"$HOME/.pyenv/bin/pyenv" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$HOME/.pyenv/bin/pyenv"

  run bash "$SCRIPT"
  assert_success

  versions_pos=$(echo "$output" | grep -n "Installed versions" | head -1 | cut -d: -f1)
  pyenv_pos=$(echo "$output" | grep -n "Consider removing pyenv" | head -1 | cut -d: -f1)
  assert [ "$versions_pos" -lt "$pyenv_pos" ]
}

# ---------------------------------------------------------------------------
# Abort on failure propagates correctly
# ---------------------------------------------------------------------------

@test "integration: aborts and exits non-zero if installer fails" {
  make_installer "./badtool/install.sh" 1
  make_binary mise
  make_binary uv
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 0

  run bash "$SCRIPT"
  assert_failure
  # mise install should NOT have been called since we aborted earlier
  run grep -qF "mise install" "$CALL_LOG"
  assert_failure
}

@test "integration: aborts and exits non-zero if mise install fails" {
  make_binary ansible
  make_binary direnv
  make_mise 1
  make_uv 0

  run bash "$SCRIPT"
  assert_failure
  # uv should NOT have been called
  run grep -qF "uv tool install" "$CALL_LOG"
  assert_failure
}

@test "integration: aborts and exits non-zero if uv tool install fails" {
  make_binary ansible
  make_binary direnv
  make_mise 0
  make_uv 1

  run bash "$SCRIPT"
  assert_failure
}
