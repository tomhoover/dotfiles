# tests/integration/test_tailscale.bats
load '../helpers/mocks'

setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"
    export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
    export BIN="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "$BIN"

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
    rm -f "$HOME/.SECRETS" "$HOME/TAILSCALE_KEY"
    rm -f "${BATS_TEST_TMPDIR}/bin/uname"
    rm -f "${BATS_TEST_TMPDIR}/etc/os-release"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

mock_systemctl() {
    cat >"$BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
    chmod +x "$BIN/sudo"
    cat >"$BIN/systemctl" <<'EOF'
#!/bin/bash
exit 0
EOF
    chmod +x "$BIN/systemctl"
}

mock_tailscale_already_up() {
    cat >"$BIN/tailscale" <<'EOF'
#!/bin/bash
[[ "$1" == "status" ]] && exit 0
EOF
    chmod +x "$BIN/tailscale"
}

make_uname() {
    cat >"$BIN/uname" <<EOF
#!/bin/bash
echo "$1"
EOF
    chmod +x "$BIN/uname"
}

make_os_release() {
    mkdir -p "${BATS_TEST_TMPDIR}/etc"
    echo "ID=$1" >"${BATS_TEST_TMPDIR}/etc/os-release"
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release"
}

# ---------------------------------------------------------------------------
# Key loading
# ---------------------------------------------------------------------------

@test "setup_tailscale sources .SECRETS if present" {
    echo 'export TAILSCALE_KEY=tskey-secret-123' >"$HOME/.SECRETS"
    make_uname "Linux"
    make_os_release "arch"
    mock_systemctl
    mock_tailscale_already_up
    run "$RUNNER" setup_tailscale
    assert_success
}

@test "setup_tailscale sources TAILSCALE_KEY file if present" {
    echo 'export TAILSCALE_KEY=tskey-file-456' >"$HOME/TAILSCALE_KEY"
    make_uname "Linux"
    make_os_release "arch"
    mock_systemctl
    mock_tailscale_already_up
    run "$RUNNER" setup_tailscale
    assert_success
}

@test "setup_tailscale proceeds without error if neither secrets file exists" {
    make_uname "Linux"
    make_os_release "arch"
    mock_systemctl
    mock_tailscale_already_up
    run "$RUNNER" setup_tailscale
    assert_success
}

@test "setup_tailscale does not crash with unbound variable when not connected and no secrets file" {
    make_uname "Linux"
    make_os_release "arch"
    mock_systemctl
    cat >"$BIN/tailscale" <<'EOF'
#!/bin/bash
[[ "$1" == "status" ]] && exit 1
echo "tailscale called with: $@"
exit 0
EOF
    chmod +x "$BIN/tailscale"
    run "$RUNNER" setup_tailscale
    refute_output --partial "unbound variable"
    assert_success
}

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------

@test "setup_tailscale calls 'open Tailscale.app' on macOS" {
    make_uname "Darwin"
    cat >"$BIN/open" <<'EOF'
#!/bin/bash
echo "open called with: $@"
exit 0
EOF
    chmod +x "$BIN/open"
    run "$RUNNER" setup_tailscale
    assert_output --partial "open called with: /Applications/Tailscale.app"
}

# ---------------------------------------------------------------------------
# Arch Linux
# ---------------------------------------------------------------------------

@test "setup_tailscale enables and starts tailscaled on Arch" {
    make_uname "Linux"
    make_os_release "arch"
    local systemctl_log="${BATS_TEST_TMPDIR}/systemctl.log"
    cat >"$BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
    chmod +x "$BIN/sudo"
    cat >"$BIN/systemctl" <<EOF
#!/bin/bash
echo "\$@" >> "$systemctl_log"
exit 0
EOF
    chmod +x "$BIN/systemctl"
    mock_tailscale_already_up
    run "$RUNNER" setup_tailscale
    run grep "enable --now tailscaled" "$systemctl_log"
    assert_success
}

@test "setup_tailscale skips 'tailscale up' on Arch if already connected" {
    make_uname "Linux"
    make_os_release "arch"
    mock_systemctl
    cat >"$BIN/tailscale" <<'EOF'
#!/bin/bash
[[ "$1" == "status" ]] && exit 0
EOF
    chmod +x "$BIN/tailscale"
    run "$RUNNER" setup_tailscale
    refute_output --partial "tailscale up"
}

@test "setup_tailscale runs 'tailscale up --auth-key' on Arch if not connected" {
    make_uname "Linux"
    make_os_release "arch"
    mock_systemctl
    echo 'TAILSCALE_KEY=tskey-arch-789' >"$HOME/.SECRETS"
    cat >"$BIN/tailscale" <<'EOF'
#!/bin/bash
[[ "$1" == "status" ]] && exit 1
echo "tailscale called with: $@"
exit 0
EOF
    chmod +x "$BIN/tailscale"
    run "$RUNNER" setup_tailscale
    assert_output --partial "--auth-key=tskey-arch-789"
}

# ---------------------------------------------------------------------------
# Debian / Fedora
# ---------------------------------------------------------------------------

@test "setup_tailscale prints TODO on Debian" {
    make_uname "Linux"
    make_os_release "debian"
    mock_tailscale_already_up
    cat >"$BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
    chmod +x "$BIN/sudo"
    run "$RUNNER" setup_tailscale
    assert_output --partial "TODO"
}

@test "setup_tailscale prints TODO on Fedora" {
    make_uname "Linux"
    make_os_release "fedora"
    mock_tailscale_already_up
    cat >"$BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
    chmod +x "$BIN/sudo"
    run "$RUNNER" setup_tailscale
    assert_output --partial "TODO"
}

# ---------------------------------------------------------------------------
# Unknown OS
# ---------------------------------------------------------------------------

@test "setup_tailscale exits with code 10 on unknown OS" {
    make_uname "UNKNOWNOS"
    # shellcheck disable=SC2030
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
    run "$RUNNER" setup_tailscale
    assert_failure
    assert [ "$status" -eq 10 ]
}

@test "setup_tailscale prints error message on unknown OS" {
    make_uname "UNKNOWNOS"
    # shellcheck disable=SC2031
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
    run "$RUNNER" setup_tailscale
    assert_output --partial "Unknown OS"
}
