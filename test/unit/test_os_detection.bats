# tests/unit/test_os_detection.bats
load '../helpers/mocks'

setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"
    export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"

    export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
    cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
"$@"
EOF
    chmod +x "$RUNNER"
}

teardown() {
    rm -f "${BATS_TEST_TMPDIR}/bin/uname"
    rm -f "${BATS_TEST_TMPDIR}/etc/os-release"
    rm -f "${BATS_TEST_TMPDIR}/etc/pacman.conf"
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

make_os_release() {
    mkdir -p "${BATS_TEST_TMPDIR}/etc"
    echo "ID=$1" >"${BATS_TEST_TMPDIR}/etc/os-release"
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release"
}

make_pacman_conf() {
    mkdir -p "${BATS_TEST_TMPDIR}/etc"
    echo "$1" >"${BATS_TEST_TMPDIR}/etc/pacman.conf"
    export PACMAN_CONF="${BATS_TEST_TMPDIR}/etc/pacman.conf"
}

# ---------------------------------------------------------------------------
# isdarwin
# ---------------------------------------------------------------------------

@test "isdarwin returns true when uname is Darwin" {
    make_uname "Darwin"
    run "$RUNNER" isdarwin
    assert_success
}

@test "isdarwin returns false when uname is Linux" {
    make_uname "Linux"
    run "$RUNNER" isdarwin
    assert_failure
}

@test "isdarwin returns false when uname is unknown" {
    make_uname "UNKNOWNOS"
    run "$RUNNER" isdarwin
    assert_failure
}

# ---------------------------------------------------------------------------
# islinux
# ---------------------------------------------------------------------------

@test "islinux returns true when uname is Linux" {
    make_uname "Linux"
    run "$RUNNER" islinux
    assert_success
}

@test "islinux returns false when uname is Darwin" {
    make_uname "Darwin"
    run "$RUNNER" islinux
    assert_failure
}

@test "islinux returns false when uname is unknown" {
    make_uname "UNKNOWNOS"
    run "$RUNNER" islinux
    assert_failure
}

# ---------------------------------------------------------------------------
# isarch
# ---------------------------------------------------------------------------

@test "isarch returns true on Arch Linux" {
    make_uname "Linux"
    make_os_release "arch"
    run "$RUNNER" isarch
    assert_success
}

@test "isarch returns false on Debian" {
    make_uname "Linux"
    make_os_release "debian"
    run "$RUNNER" isarch
    assert_failure
}

@test "isarch returns false on Fedora" {
    make_uname "Linux"
    make_os_release "fedora"
    run "$RUNNER" isarch
    assert_failure
}

@test "isarch returns false on macOS" {
    make_uname "Darwin"
    run "$RUNNER" isarch
    assert_failure
}

@test "isarch returns false when os-release is missing" {
    make_uname "Linux"
    #shellcheck disable=SC2030
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
    run "$RUNNER" isarch
    assert_failure
}

# ---------------------------------------------------------------------------
# isdebian
# ---------------------------------------------------------------------------

@test "isdebian returns true on Debian" {
    make_uname "Linux"
    make_os_release "debian"
    run "$RUNNER" isdebian
    assert_success
}

@test "isdebian returns false on Arch" {
    make_uname "Linux"
    make_os_release "arch"
    run "$RUNNER" isdebian
    assert_failure
}

@test "isdebian returns false on Fedora" {
    make_uname "Linux"
    make_os_release "fedora"
    run "$RUNNER" isdebian
    assert_failure
}

@test "isdebian returns false on macOS" {
    make_uname "Darwin"
    run "$RUNNER" isdebian
    assert_failure
}

@test "isdebian returns false when os-release is missing" {
    make_uname "Linux"
    #shellcheck disable=SC2030,SC2031
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
    run "$RUNNER" isdebian
    assert_failure
}

# ---------------------------------------------------------------------------
# isfedora
# ---------------------------------------------------------------------------

@test "isfedora returns true on Fedora" {
    make_uname "Linux"
    make_os_release "fedora"
    run "$RUNNER" isfedora
    assert_success
}

@test "isfedora returns false on Arch" {
    make_uname "Linux"
    make_os_release "arch"
    run "$RUNNER" isfedora
    assert_failure
}

@test "isfedora returns false on Debian" {
    make_uname "Linux"
    make_os_release "debian"
    run "$RUNNER" isfedora
    assert_failure
}

@test "isfedora returns false on macOS" {
    make_uname "Darwin"
    run "$RUNNER" isfedora
    assert_failure
}

@test "isfedora returns false when os-release is missing" {
    make_uname "Linux"
    #shellcheck disable=SC2031
    export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
    run "$RUNNER" isfedora
    assert_failure
}

# ---------------------------------------------------------------------------
# isomarchy
# ---------------------------------------------------------------------------

@test "isomarchy returns true on Arch with omarchy in pacman.conf" {
    make_uname "Linux"
    make_os_release "arch"
    make_pacman_conf "[omarchy]"
    run "$RUNNER" isomarchy
    assert_success
}

@test "isomarchy returns false on Arch without omarchy in pacman.conf" {
    make_uname "Linux"
    make_os_release "arch"
    make_pacman_conf "[core]"
    run "$RUNNER" isomarchy
    assert_failure
}

@test "isomarchy returns false on Debian even with omarchy in pacman.conf" {
    make_uname "Linux"
    make_os_release "debian"
    make_pacman_conf "[omarchy]"
    run "$RUNNER" isomarchy
    assert_failure
}

@test "isomarchy returns false on macOS" {
    make_uname "Darwin"
    make_pacman_conf "[omarchy]"
    run "$RUNNER" isomarchy
    assert_failure
}

@test "isomarchy returns false when pacman.conf is missing" {
    make_uname "Linux"
    make_os_release "arch"
    export PACMAN_CONF="${BATS_TEST_TMPDIR}/etc/pacman.conf-missing"
    run "$RUNNER" isomarchy
    assert_failure
}

# ---------------------------------------------------------------------------
# iszsh
# ---------------------------------------------------------------------------

@test "iszsh returns true when SHELL is /bin/zsh" {
    run env SHELL="/bin/zsh" "$RUNNER" iszsh
    assert_success
}

@test "iszsh returns true when SHELL is /usr/bin/zsh" {
    run env SHELL="/usr/bin/zsh" "$RUNNER" iszsh
    assert_success
}

@test "iszsh returns false when SHELL is /bin/bash" {
    run env SHELL="/bin/bash" "$RUNNER" iszsh
    assert_failure
}

@test "iszsh returns false when SHELL is empty" {
    run env SHELL="" "$RUNNER" iszsh
    assert_failure
}

# ---------------------------------------------------------------------------
# isdev
# ---------------------------------------------------------------------------

@test "isdev returns true for hostname 'ariel'" {
    run env MYHOST_OVERRIDE="ariel" "$RUNNER" isdev
    assert_success
}

@test "isdev returns true for hostname 'theophilus'" {
    run env MYHOST_OVERRIDE="theophilus" "$RUNNER" isdev
    assert_success
}

@test "isdev returns false for unknown hostname" {
    run env MYHOST_OVERRIDE="someserver" "$RUNNER" isdev
    assert_failure
}

@test "isdev returns false for empty hostname" {
    run env MYHOST_OVERRIDE="" "$RUNNER" isdev
    assert_failure
}

@test "isdev returns false for partial match like 'ariel2'" {
    run env MYHOST_OVERRIDE="ariel2" "$RUNNER" isdev
    assert_failure
}

@test "isdev returns false for partial match like 'myariel'" {
    run env MYHOST_OVERRIDE="myariel" "$RUNNER" isdev
    assert_failure
}
