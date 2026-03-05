# tests/unit/test_install_dev_tools_legacy_warnings.bats
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
    # Clean up any legacy tool stubs created during tests
    rm -rf "$HOME/.pyenv" "$HOME/.asdf" "$HOME/.local/share/rtx" "$HOME/.local/bin/rtx"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_stub_externals() {
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

make_legacy_tool() {
    # Creates a fake executable at the given path under $HOME
    local rel_path="$1"
    local full_path="${HOME}/${rel_path}"
    mkdir -p "$(dirname "$full_path")"
    cat >"$full_path" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$full_path"
}

# ---------------------------------------------------------------------------
# pyenv binary warning
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about pyenv if ~/.pyenv/bin/pyenv exists" {
    make_legacy_tool ".pyenv/bin/pyenv"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing pyenv."
}

@test "legacy warnings: does not warn about pyenv if ~/.pyenv/bin/pyenv is absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing pyenv."
}

# ---------------------------------------------------------------------------
# asdf binary warning
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about asdf if ~/.asdf/bin/asdf exists" {
    make_legacy_tool ".asdf/bin/asdf"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing asdf."
}

@test "legacy warnings: does not warn about asdf if ~/.asdf/bin/asdf is absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing asdf."
}

# ---------------------------------------------------------------------------
# rtx link warning
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about rtx link if ~/.local/bin/rtx exists" {
    make_legacy_tool ".local/bin/rtx"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing rtx link in .local/bin."
}

@test "legacy warnings: does not warn about rtx link if ~/.local/bin/rtx is absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing rtx link in .local/bin."
}

# ---------------------------------------------------------------------------
# rtx binary warning
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about rtx if ~/.local/share/rtx/bin/rtx exists" {
    make_legacy_tool ".local/share/rtx/bin/rtx"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing rtx."
}

@test "legacy warnings: does not warn about rtx if ~/.local/share/rtx/bin/rtx is absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing rtx."
}

# ---------------------------------------------------------------------------
# ~/.pyenv* directory warnings
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about ~/.pyenv* directories if present" {
    mkdir -p "$HOME/.pyenv"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing the following ~/.pyenv* directory(s):"
}

@test "legacy warnings: does not warn about ~/.pyenv* directories if absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing the following ~/.pyenv* directory(s):"
}

@test "legacy warnings: lists all matching ~/.pyenv* directories in warning" {
    mkdir -p "$HOME/.pyenv"
    mkdir -p "$HOME/.pyenv-backup"
    run bash "$SCRIPT"
    assert_output --partial ".pyenv"
    assert_output --partial ".pyenv-backup"
}

# ---------------------------------------------------------------------------
# ~/.asdf* directory warnings
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about ~/.asdf* directories if present" {
    mkdir -p "$HOME/.asdf"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing the following ~/.asdf* directory(s):"
}

@test "legacy warnings: does not warn about ~/.asdf* directories if absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing the following ~/.asdf* directory(s):"
}

# ---------------------------------------------------------------------------
# ~/.local/share/rtx* directory warnings
# ---------------------------------------------------------------------------

@test "legacy warnings: warns about ~/.local/share/rtx* directories if present" {
    mkdir -p "$HOME/.local/share/rtx"
    run bash "$SCRIPT"
    assert_output --partial "Consider removing the following ~/.local/share/rtx* directory(s):"
}

@test "legacy warnings: does not warn about ~/.local/share/rtx* directories if absent" {
    run bash "$SCRIPT"
    refute_output --partial "Consider removing the following ~/.local/share/rtx* directory(s):"
}

# ---------------------------------------------------------------------------
# Output streams
# ---------------------------------------------------------------------------

@test "legacy warnings: warning messages are printed to stdout" {
    make_legacy_tool ".pyenv/bin/pyenv"
    # Capture stdout only — warning should appear there
    run bash -c "bash \"$SCRIPT\" 2>/dev/null"
    assert_output --partial "Consider removing pyenv."
}

@test "legacy warnings: error() messages are printed to stderr" {
    # Trigger an installer failure to produce an error() message.
    # Override the find stub to emit this specific installer path so the
    # loop actually runs it (the default find stub emits nothing).
    mkdir -p "${FAKE_REPO}/mytool"
    cat >"${FAKE_REPO}/mytool/install.sh" <<'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "${FAKE_REPO}/mytool/install.sh"
    cat >"$MOCK_BIN/find" <<EOF
#!/bin/bash
echo "./mytool/install.sh"
EOF
    chmod +x "$MOCK_BIN/find"
    # Capture stderr only — error should appear there, not on stdout
    run bash -c "bash \"$SCRIPT\" 2>&1 1>/dev/null"
    assert_output --partial "Failed to run mytool/install.sh"
}
