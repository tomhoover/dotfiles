# test/unit/test_install_required_pkgs.bats
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$BIN"
  export MOCK_BIN="${BATS_TEST_TMPDIR}/bin"

  export BREW_CALL_LOG="${BATS_TEST_TMPDIR}/brew.log"
  export PACMAN_CALL_LOG="${BATS_TEST_TMPDIR}/pacman.log"
  export APT_CALL_LOG="${BATS_TEST_TMPDIR}/apt.log"
  export DNF_CALL_LOG="${BATS_TEST_TMPDIR}/dnf.log"
  export SED_CALL_LOG="${BATS_TEST_TMPDIR}/sed.log"
  rm -f "$BREW_CALL_LOG" "$PACMAN_CALL_LOG" "$APT_CALL_LOG" "$DNF_CALL_LOG" "$SED_CALL_LOG"

  export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
  cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
BIN="${MOCK_BIN}"
"$@"
EOF
  chmod +x "$RUNNER"

  # Place a sudo passthrough in PATH
  cat >"$BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
  chmod +x "$BIN/sudo"
}

teardown() {
  rm -f "$BIN/uname" "$BIN/brew" "$BIN/pacman" "$BIN/apt-get" "$BIN/dnf" "$BIN/sudo" "$BIN/sed"
  rm -f "$BREW_CALL_LOG" "$PACMAN_CALL_LOG" "$APT_CALL_LOG" "$DNF_CALL_LOG" "$SED_CALL_LOG"
  rm -f "${BATS_TEST_TMPDIR}/etc/os-release"
  unset OS_RELEASE
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_brew() {
  cat >"$BIN/brew" <<EOF
#!/bin/bash
echo "brew \$@" >> "$BREW_CALL_LOG"
exit 0
EOF
  chmod +x "$BIN/brew"
}

make_pacman() {
  cat >"$BIN/pacman" <<EOF
#!/bin/bash
echo "pacman \$@" >> "$PACMAN_CALL_LOG"
exit 0
EOF
  chmod +x "$BIN/pacman"
  # Quoted heredoc: $@ and $SED_CALL_LOG expand at runtime (not write time).
  # Stdin is drained when piped to prevent SIGPIPE; bootstrap sources
  # `uname -n | sed ...` to assign MYHOST, so the stub must consume stdin.
  cat >"$BIN/sed" <<'STUB'
#!/bin/bash
[[ -p /dev/stdin ]] && cat > /dev/null
echo "sed $@" >> "$SED_CALL_LOG"
exit 0
STUB
  chmod +x "$BIN/sed"
}

make_apt() {
  cat >"$BIN/apt-get" <<EOF
#!/bin/bash
echo "apt-get \$@" >> "$APT_CALL_LOG"
exit 0
EOF
  chmod +x "$BIN/apt-get"
}

make_dnf() {
  cat >"$BIN/dnf" <<EOF
#!/bin/bash
echo "dnf \$@" >> "$DNF_CALL_LOG"
exit 0
EOF
  chmod +x "$BIN/dnf"
}

brew_was_called_with() {
  grep -qF -- "$*" "$BREW_CALL_LOG" 2>/dev/null
}

pacman_was_called_with() {
  grep -qF -- "$*" "$PACMAN_CALL_LOG" 2>/dev/null
}

apt_was_called_with() {
  grep -qF -- "$*" "$APT_CALL_LOG" 2>/dev/null
}

dnf_was_called_with() {
  grep -qF -- "$*" "$DNF_CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# macOS — brew
# ---------------------------------------------------------------------------

@test "install_required_pkgs calls brew doctor on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_required_pkgs
  assert_success
  run brew_was_called_with "brew doctor"
  assert_success
}

@test "install_required_pkgs calls brew install on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_required_pkgs
  assert_success
  run brew_was_called_with "brew install"
  assert_success
}

@test "install_required_pkgs installs bash and zsh-completions on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_required_pkgs
  assert_success
  run brew_was_called_with "bash"
  assert_success
  run brew_was_called_with "bash-completion@2"
  assert_success
  run brew_was_called_with "zsh-completions"
  assert_success
}

@test "install_required_pkgs passes required pkgs to brew on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_required_pkgs
  assert_success
  run brew_was_called_with "curl"
  assert_success
  run brew_was_called_with "git"
  assert_success
  run brew_was_called_with "stow"
  assert_success
  run brew_was_called_with "vcsh"
  assert_success
}

@test "install_required_pkgs calls brew completions link on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_required_pkgs
  assert_success
  run brew_was_called_with "brew completions link"
  assert_success
}

# ---------------------------------------------------------------------------
# Arch Linux — pacman
# ---------------------------------------------------------------------------

@test "install_required_pkgs calls pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_required_pkgs
  assert_success
  run pacman_was_called_with "pacman"
  assert_success
}

@test "install_required_pkgs passes -Syu --noconfirm --needed to pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_required_pkgs
  assert_success
  run pacman_was_called_with "-Syu --noconfirm --needed"
  assert_success
}

@test "install_required_pkgs passes required pkgs to pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_required_pkgs
  assert_success
  run pacman_was_called_with "curl"
  assert_success
  run pacman_was_called_with "git"
  assert_success
  run pacman_was_called_with "stow"
  assert_success
  run pacman_was_called_with "vcsh"
  assert_success
}

@test "install_required_pkgs installs etckeeper on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_required_pkgs
  assert_success
  run pacman_was_called_with "etckeeper"
  assert_success
}

@test "install_required_pkgs enables Color in pacman.conf on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_required_pkgs
  assert_success
  grep -qF "s/^#Color" "$SED_CALL_LOG"
}

@test "install_required_pkgs enables ParallelDownloads in pacman.conf on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_required_pkgs
  assert_success
  grep -qF "s/^#ParallelDownloads" "$SED_CALL_LOG"
}

# ---------------------------------------------------------------------------
# Debian — apt-get
# ---------------------------------------------------------------------------

@test "install_required_pkgs calls apt-get on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_required_pkgs
  assert_success
  run apt_was_called_with "apt-get"
  assert_success
}

@test "install_required_pkgs calls apt-get update on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_required_pkgs
  assert_success
  run apt_was_called_with "apt-get update"
  assert_success
}

@test "install_required_pkgs calls apt-get --yes install on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_required_pkgs
  assert_success
  run apt_was_called_with "apt-get --yes install"
  assert_success
}

@test "install_required_pkgs passes required pkgs to apt-get on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_required_pkgs
  assert_success
  run apt_was_called_with "curl"
  assert_success
  run apt_was_called_with "git"
  assert_success
  run apt_was_called_with "stow"
  assert_success
  run apt_was_called_with "vcsh"
  assert_success
}

@test "install_required_pkgs installs etckeeper on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_required_pkgs
  assert_success
  run apt_was_called_with "etckeeper"
  assert_success
}

# ---------------------------------------------------------------------------
# Fedora — dnf
# ---------------------------------------------------------------------------

@test "install_required_pkgs calls dnf on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_required_pkgs
  assert_success
  run dnf_was_called_with "dnf"
  assert_success
}

@test "install_required_pkgs passes required pkgs to dnf on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_required_pkgs
  assert_success
  run dnf_was_called_with "curl"
  assert_success
  run dnf_was_called_with "git"
  assert_success
  run dnf_was_called_with "stow"
  assert_success
  run dnf_was_called_with "vcsh"
  assert_success
}

@test "install_required_pkgs installs etckeeper on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_required_pkgs
  assert_success
  run dnf_was_called_with "etckeeper"
  assert_success
}

# ---------------------------------------------------------------------------
# Unknown OS
# ---------------------------------------------------------------------------

@test "install_required_pkgs exits with code 5 on unknown OS" {
  cat >"$BIN/uname" <<'EOF'
#!/bin/bash
echo "UNKNOWNOS"
EOF
  chmod +x "$BIN/uname"
  # shellcheck disable=SC2030
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
  run "$RUNNER" install_required_pkgs
  assert_failure
  assert [ "$status" -eq 5 ]
}

@test "install_required_pkgs prints error message on unknown OS" {
  cat >"$BIN/uname" <<'EOF'
#!/bin/bash
echo "UNKNOWNOS"
EOF
  chmod +x "$BIN/uname"
  # shellcheck disable=SC2031
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
  run "$RUNNER" install_required_pkgs
  assert_output --partial "Unknown OS"
}
