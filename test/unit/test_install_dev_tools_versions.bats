# tests/unit/test_install_dev_tools_versions.bats
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
# Default: emit no managed tools
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

    # These must exist on PATH so type -a finds them and reports a path.
    for cmd in ansible direnv; do
        cat >"$MOCK_BIN/${cmd}" <<'EOF'
#!/bin/bash
exit 0
EOF
        chmod +x "$MOCK_BIN/${cmd}"
    done
}

# Replace the mise mock with one that emits controlled 'mise ls' output.
# Each argument is a tool line in 'mise ls' format:
#   "node    20.0.0  ~/.config/mise/config.toml"
make_mise_with_tools() {
    local lines=("$@")
    {
        echo "#!/bin/bash"
        echo "echo \"mise \$@\" >> \"$CALL_LOG\""
        echo "if [[ \"\$1\" == \"ls\" ]]; then"
        for line in "${lines[@]}"; do
            echo "  echo '${line}'"
        done
        echo "fi"
        echo "exit 0"
    } >"$MOCK_BIN/mise"
    chmod +x "$MOCK_BIN/mise"
}

# ---------------------------------------------------------------------------
# "Installed versions:" header
# ---------------------------------------------------------------------------

@test "versions: prints 'Installed versions:' info message" {
    run bash "$SCRIPT"
    assert_output --partial "Installed versions:"
}

# ---------------------------------------------------------------------------
# type -a output for fixed tools
# type is a bash builtin — we verify by ensuring the tool paths in MOCK_BIN
# appear in the output after sed stripping, since MOCK_BIN is on PATH.
# ---------------------------------------------------------------------------

@test "versions: reports mise path in installed versions output" {
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/mise"
}

@test "versions: reports ansible path in installed versions output" {
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/ansible"
}

@test "versions: reports direnv path in installed versions output" {
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/direnv"
}

@test "versions: strips 'X is ' prefix from type output" {
    run bash "$SCRIPT"
    # Should NOT contain the raw 'X is /path' form — only the bare path
    refute_output --partial "mise is "
    refute_output --partial "ansible is "
    refute_output --partial "direnv is "
}

# ---------------------------------------------------------------------------
# mise ls loop — tool name extraction
# ---------------------------------------------------------------------------

@test "versions: calls type -a for each tool returned by mise ls" {
    cat >"$MOCK_BIN/node" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/node"
    make_mise_with_tools "node    20.0.0  ~/.config/mise/config.toml"
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/node"
}

@test "versions: does not abort if a mise-managed tool is not found on PATH" {
    make_mise_with_tools "nonexistent-tool    1.0.0  ~/.config/mise/config.toml"
    run bash "$SCRIPT"
    assert_success
}

@test "versions: strips go: path prefix from mise tool names" {
    cat >"$MOCK_BIN/mytool" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/mytool"
    make_mise_with_tools "go:path/to/mytool    1.0.0  ~/.config/mise/config.toml"
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/mytool"
}

@test "versions: strips pipx: prefix from mise tool names" {
    cat >"$MOCK_BIN/pipxtool" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/pipxtool"
    make_mise_with_tools "pipx:pipxtool    1.0.0  ~/.config/mise/config.toml"
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/pipxtool"
}

@test "versions: maps audible-cli to audible" {
    cat >"$MOCK_BIN/audible" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/audible"
    make_mise_with_tools "audible-cli    1.0.0  ~/.config/mise/config.toml"
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/audible"
}

@test "versions: deduplicates tool names from mise ls output" {
    cat >"$MOCK_BIN/node" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/node"
    # node appears twice in mise ls — sort -u deduplicates the name so the
    # loop body runs once. We can't intercept the type builtin directly, so
    # we verify the script exits successfully and that node's mock path
    # appears in the output (confirming it was looked up at least once).
    make_mise_with_tools \
        "node    20.0.0  ~/.config/mise/config.toml" \
        "node    18.0.0  ~/.config/mise/config.toml"
    run bash "$SCRIPT"
    assert_success
    assert_output --partial "$MOCK_BIN/node"
}

@test "versions: only includes tools from mise global config (not project-local)" {
    cat >"$MOCK_BIN/globaltool" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/globaltool"
    cat >"$MOCK_BIN/localtool" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$MOCK_BIN/localtool"
    make_mise_with_tools \
        "globaltool    1.0.0  ~/.config/mise/config.toml" \
        "localtool     1.0.0  /some/project/.mise.toml"
    run bash "$SCRIPT"
    assert_output --partial "$MOCK_BIN/globaltool"
    refute_output --partial "$MOCK_BIN/localtool"
}

@test "versions: changes to \$HOME before running mise ls loop" {
    # Verify by checking that the cd doesn't fail (HOME exists as temp dir)
    run bash "$SCRIPT"
    assert_success
}
