# tests/integration/test_install_pkgs.bats
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$BIN"
  # REPO_ROOT is set by mocks.bash at load time (BATS_TEST_DIRNAME is
  # available then). MOCK_BIN must be set here because BATS_TEST_TMPDIR
  # is only available per-test, not at load time.
  export MOCK_BIN="${BATS_TEST_TMPDIR}/bin"

  export BREW_CALL_LOG="${BATS_TEST_TMPDIR}/brew.log"
  export PACMAN_CALL_LOG="${BATS_TEST_TMPDIR}/pacman.log"
  export APT_CALL_LOG="${BATS_TEST_TMPDIR}/apt.log"
  export DNF_CALL_LOG="${BATS_TEST_TMPDIR}/dnf.log"
  export CURL_CALL_LOG="${BATS_TEST_TMPDIR}/curl.log"
  rm -f "$BREW_CALL_LOG" "$PACMAN_CALL_LOG" "$APT_CALL_LOG" "$DNF_CALL_LOG" "$CURL_CALL_LOG"

  export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
  cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
# Override BIN after bootstrap has set it so all package manager calls
# go through mocks rather than real binaries on the host system.
BIN="${MOCK_BIN}"
# Stub AUR functions so they do not attempt real AUR operations.
install_paru_customizepkg() { :; }
install_AUR_pkg() { :; }
"$@"
EOF
  chmod +x "$RUNNER"

  # Place a sudo passthrough in PATH so 'sudo pacman', 'sudo apt-get' etc.
  # invoke mock binaries rather than real system tools.
  cat >"$BIN/sudo" <<'EOF'
#!/bin/bash
exec "$@"
EOF
  chmod +x "$BIN/sudo"
}

teardown() {
  rm -f "$BIN/uname" "$BIN/brew" "$BIN/pacman" "$BIN/apt-get" "$BIN/dnf" "$BIN/sudo" "$BIN/systemctl" "$BIN/curl" "$BIN/tee"
  rm -f "$BREW_CALL_LOG" "$PACMAN_CALL_LOG" "$APT_CALL_LOG" "$DNF_CALL_LOG" "$CURL_CALL_LOG"
  rm -f "${BATS_TEST_TMPDIR}/etc/os-release"
  unset OS_RELEASE
  unset PACMAN_CONF
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
  cat >"$BIN/systemctl" <<'EOF'
#!/bin/bash
exit 0
EOF
  chmod +x "$BIN/systemctl"
}

make_apt() {
  cat >"$BIN/apt-get" <<EOF
#!/bin/bash
echo "apt-get \$@" >> "$APT_CALL_LOG"
exit 0
EOF
  chmod +x "$BIN/apt-get"
  cat >"$BIN/curl" <<EOF
#!/bin/bash
echo "curl \$@" >> "$CURL_CALL_LOG"
exit 0
EOF
  chmod +x "$BIN/curl"
  cat >"$BIN/tee" <<'EOF'
#!/bin/bash
cat >/dev/null
exit 0
EOF
  chmod +x "$BIN/tee"
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

curl_was_called_with() {
  grep -qF -- "$*" "$CURL_CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# macOS — brew
# ---------------------------------------------------------------------------

@test "install_remaining_pkgs calls brew on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run brew_was_called_with "brew install"
  assert_success
}

@test "install_remaining_pkgs passes common pkgs to brew on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run brew_was_called_with "ghostty"
  assert_success
  run brew_was_called_with "neovim"
  assert_success
  run brew_was_called_with "tmux"
  assert_success
}

@test "install_remaining_pkgs passes darwin pkgs to brew on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run brew_was_called_with "brave-browser"
  assert_success
  run brew_was_called_with "tailscale-app"
  assert_success
}

@test "install_remaining_pkgs does not pass arch pkgs to brew on macOS" {
  stub_uname_darwin
  make_brew
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run brew_was_called_with "base-devel"
  assert_failure
}

@test "install_remaining_pkgs calls brew install p4v on ariel" {
  stub_uname_darwin
  make_brew
  run env MYHOST_OVERRIDE="ariel" "$RUNNER" install_remaining_pkgs
  assert_success
  run brew_was_called_with "p4v"
  assert_success
}

@test "install_remaining_pkgs does not call brew install p4v on non-ariel host" {
  stub_uname_darwin
  make_brew
  run env MYHOST_OVERRIDE="somehost" "$RUNNER" install_remaining_pkgs
  assert_success
  run brew_was_called_with "p4v"
  assert_failure
}

# ---------------------------------------------------------------------------
# Arch Linux — pacman
# ---------------------------------------------------------------------------

@test "install_remaining_pkgs calls pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run pacman_was_called_with "pacman"
  assert_success
}

@test "install_remaining_pkgs passes -S --noconfirm --needed to pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run pacman_was_called_with "-S --noconfirm --needed"
  assert_success
}

@test "install_remaining_pkgs passes common pkgs to pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run pacman_was_called_with "ghostty"
  assert_success
  run pacman_was_called_with "neovim"
  assert_success
  run pacman_was_called_with "tmux"
  assert_success
}

@test "install_remaining_pkgs passes arch pkgs to pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run pacman_was_called_with "base-devel"
  assert_success
  run pacman_was_called_with "zsh"
  assert_success
}

@test "install_remaining_pkgs does not pass darwin pkgs to pacman on Arch" {
  stub_uname_arch
  make_pacman
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run pacman_was_called_with "brave-browser"
  assert_failure
  run pacman_was_called_with "tailscale-app"
  assert_failure
}

# ---------------------------------------------------------------------------
# Debian — apt-get
# ---------------------------------------------------------------------------

@test "install_remaining_pkgs calls apt-get on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run apt_was_called_with "apt-get"
  assert_success
}

@test "install_remaining_pkgs calls apt-get update on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run apt_was_called_with "apt-get update"
  assert_success
}

@test "install_remaining_pkgs calls apt-get --yes install on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run apt_was_called_with "apt-get --yes install"
  assert_success
}

@test "install_remaining_pkgs passes common pkgs to apt-get on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run apt_was_called_with "ghostty"
  assert_success
  run apt_was_called_with "neovim"
  assert_success
}

@test "install_remaining_pkgs passes debian pkgs to apt-get on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run apt_was_called_with "tailscale"
  assert_success
  run apt_was_called_with "zsh"
  assert_success
}

@test "install_remaining_pkgs does not pass darwin pkgs to apt-get on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run apt_was_called_with "brave-browser"
  assert_failure
}

@test "install_remaining_pkgs fetches tailscale gpg key using distro codename on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run curl_was_called_with "pkgs.tailscale.com/stable/debian/bookworm.noarmor.gpg"
  assert_success
}

@test "install_remaining_pkgs fetches tailscale keyring list using distro codename on Debian" {
  stub_uname_debian
  make_apt
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run curl_was_called_with "pkgs.tailscale.com/stable/debian/bookworm.tailscale-keyring.list"
  assert_success
}

# ---------------------------------------------------------------------------
# Fedora — dnf
# ---------------------------------------------------------------------------

@test "install_remaining_pkgs calls dnf on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run dnf_was_called_with "dnf"
  assert_success
}

@test "install_remaining_pkgs passes common pkgs to dnf on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run dnf_was_called_with "ghostty"
  assert_success
  run dnf_was_called_with "neovim"
  assert_success
}

@test "install_remaining_pkgs passes fedora pkgs to dnf on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run dnf_was_called_with "tailscale"
  assert_success
  run dnf_was_called_with "zsh"
  assert_success
}

@test "install_remaining_pkgs does not pass darwin pkgs to dnf on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run dnf_was_called_with "brave-browser"
  assert_failure
}

@test "install_remaining_pkgs adds tailscale repo via dnf config-manager on Fedora" {
  stub_uname_fedora
  make_dnf
  run "$RUNNER" install_remaining_pkgs
  assert_success
  run dnf_was_called_with "config-manager --add-repo"
  assert_success
  run dnf_was_called_with "pkgs.tailscale.com/stable/fedora/tailscale.repo"
  assert_success
}

# ---------------------------------------------------------------------------
# Unknown OS
# ---------------------------------------------------------------------------

@test "install_remaining_pkgs exits with code 2 on unknown OS" {
  cat >"$BIN/uname" <<'EOF'
#!/bin/bash
echo "UNKNOWNOS"
EOF
  chmod +x "$BIN/uname"
  # shellcheck disable=SC2030
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
  run "$RUNNER" install_remaining_pkgs
  assert_failure
  assert [ "$status" -eq 2 ]
}

@test "install_remaining_pkgs prints error message on unknown OS" {
  cat >"$BIN/uname" <<'EOF'
#!/bin/bash
echo "UNKNOWNOS"
EOF
  chmod +x "$BIN/uname"
  # shellcheck disable=SC2031
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release-missing"
  run "$RUNNER" install_remaining_pkgs
  assert_output --partial "Unknown OS"
}
