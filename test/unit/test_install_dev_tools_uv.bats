# tests/unit/test_install_dev_tools_uv.bats
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

make_uv() {
    local exit_code="${1:-0}"
    cat >"$MOCK_BIN/uv" <<EOF
#!/bin/bash
echo "uv \$@" >> "$CALL_LOG"
exit ${exit_code}
EOF
    chmod +x "$MOCK_BIN/uv"
}

uv_was_called_with() {
    grep -qF -- "$*" "$CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# uv tool install
# ---------------------------------------------------------------------------

@test "uv: calls 'uv tool install'" {
    make_uv 0
    run bash "$SCRIPT"
    assert_success
    run uv_was_called_with "uv tool install"
    assert_success
}

@test "uv: passes --with requests" {
    make_uv 0
    run bash "$SCRIPT"
    assert_success
    run uv_was_called_with "--with requests"
    assert_success
}

@test "uv: passes --with passlib" {
    make_uv 0
    run bash "$SCRIPT"
    assert_success
    run uv_was_called_with "--with passlib"
    assert_success
}

@test "uv: passes --with netaddr" {
    make_uv 0
    run bash "$SCRIPT"
    assert_success
    run uv_was_called_with "--with netaddr"
    assert_success
}

@test "uv: passes --with-executables-from ansible-core,ansible-lint" {
    make_uv 0
    run bash "$SCRIPT"
    assert_success
    run uv_was_called_with "--with-executables-from ansible-core,ansible-lint"
    assert_success
}

@test "uv: passes ansible as the final argument" {
    make_uv 0
    run bash "$SCRIPT"
    assert_success
    # The full uv invocation should end with 'ansible'
    run grep -qE "^uv .* ansible$" "$CALL_LOG"
    assert_success
}

@test "uv: exits with error if 'uv tool install' fails" {
    make_uv 1
    run bash "$SCRIPT"
    assert_failure
}
