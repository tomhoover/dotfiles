# tests/unit/test_stow.bats
load '../helpers/mocks'

setup() {
    export HOME="${BATS_TEST_TMPDIR}/home"
    mkdir -p "$HOME"
    export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
    export BIN="${BATS_TEST_TMPDIR}/bin"
    mkdir -p "$BIN"
    # REPO_ROOT is set by mocks.bash at load time. MOCK_BIN must be set here
    # because BATS_TEST_TMPDIR is only available per-test, not at load time.
    export MOCK_BIN="${BATS_TEST_TMPDIR}/bin"

    export STOW_CALL_LOG="${BATS_TEST_TMPDIR}/stow.log"
    export BACKUP_LOG="${BATS_TEST_TMPDIR}/backup.log"
    rm -f "$STOW_CALL_LOG" "$BACKUP_LOG"

    export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
    cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
# Override BIN after bootstrap has set it so stow calls go through the mock.
BIN="${MOCK_BIN}"
# Mock backup_file to record calls without moving files.
backup_file() { echo "backup_file $1" >> "$BACKUP_LOG"; }
"$@"
EOF
    chmod +x "$RUNNER"
}

teardown() {
    rm -f "$BIN/stow" "$BIN/uname"
    rm -f "$STOW_CALL_LOG" "$BACKUP_LOG"
    rm -f "${BATS_TEST_TMPDIR}/etc/os-release"
    rm -f "${BATS_TEST_TMPDIR}/etc/pacman.conf"
    unset OS_RELEASE
    unset PACMAN_CONF
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_stow() {
    cat >"$BIN/stow" <<EOF
#!/bin/bash
echo "stow \$@" >> "$STOW_CALL_LOG"
exit 0
EOF
    chmod +x "$BIN/stow"
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

make_pacman_conf() {
    mkdir -p "${BATS_TEST_TMPDIR}/etc"
    echo "$1" >"${BATS_TEST_TMPDIR}/etc/pacman.conf"
    export PACMAN_CONF="${BATS_TEST_TMPDIR}/etc/pacman.conf"
}

stow_was_called_with() {
    grep -qF -- "$*" "$STOW_CALL_LOG" 2>/dev/null
}

stow_was_not_called_with() {
    ! grep -qF -- "$*" "$STOW_CALL_LOG" 2>/dev/null
}

backup_was_called_for() {
    grep -qF -- "backup_file $1" "$BACKUP_LOG" 2>/dev/null
}

backup_was_not_called_for() {
    ! grep -qF -- "backup_file $1" "$BACKUP_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# Pre-stow backup — real files (readable, non-symlink)
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs: backs up real .bashrc before stowing" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    touch "$HOME/.bashrc"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".bashrc"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up real .zshrc before stowing" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    touch "$HOME/.zshrc"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".zshrc"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up real .aliases before stowing" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    touch "$HOME/.aliases"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".aliases"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up real .profile before stowing" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    touch "$HOME/.profile"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".profile"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up real nested file .config/starship.toml" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    mkdir -p "$HOME/.config"
    touch "$HOME/.config/starship.toml"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".config/starship.toml"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up real nested file .config/ghostty/config" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    mkdir -p "$HOME/.config/ghostty"
    touch "$HOME/.config/ghostty/config"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".config/ghostty/config"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up real nested file .config/kitty/kitty.conf" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    mkdir -p "$HOME/.config/kitty"
    touch "$HOME/.config/kitty/kitty.conf"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".config/kitty/kitty.conf"
    assert_success
}

@test "stow_dotfiles_pkgs: backs up multiple conflicting dotfiles in one pass" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    touch "$HOME/.bashrc"
    touch "$HOME/.zshrc"
    touch "$HOME/.aliases"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".bashrc"
    assert_success
    run backup_was_called_for ".zshrc"
    assert_success
    run backup_was_called_for ".aliases"
    assert_success
}

# ---------------------------------------------------------------------------
# Pre-stow backup — symlinks are skipped
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs: skips .bashrc that is already a symlink" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    ln -s /dev/null "$HOME/.bashrc"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_not_called_for ".bashrc"
    assert_success
}

@test "stow_dotfiles_pkgs: skips .zshrc that is already a symlink" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    ln -s /dev/null "$HOME/.zshrc"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_not_called_for ".zshrc"
    assert_success
}

@test "stow_dotfiles_pkgs: skips files that do not exist" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert [ ! -f "$BACKUP_LOG" ] || [ ! -s "$BACKUP_LOG" ]
}

@test "stow_dotfiles_pkgs: backs up real file but skips symlink when both present" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    touch "$HOME/.bashrc"
    ln -s /dev/null "$HOME/.zshrc"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    run backup_was_called_for ".bashrc"
    assert_success
    run backup_was_not_called_for ".zshrc"
    assert_success
}

# ---------------------------------------------------------------------------
# Core stow call — always runs
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs: always calls stow for 'home' package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "home"
    assert_success
}

@test "stow_dotfiles_pkgs: always calls stow for 'tmux' package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "tmux"
    assert_success
}

@test "stow_dotfiles_pkgs: always calls stow for 'vim' package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "vim"
    assert_success
}

@test "stow_dotfiles_pkgs: always calls stow for 'vcsh' package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "vcsh"
    assert_success
}

@test "stow_dotfiles_pkgs: always calls stow for 'mr' package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "mr"
    assert_success
}

@test "stow_dotfiles_pkgs: always calls stow for 'starship' package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "starship"
    assert_success
}

@test "stow_dotfiles_pkgs: stow target is always \$HOME" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "-t ${HOME}"
    assert_success
}

@test "stow_dotfiles_pkgs: stow source dir is always ~/.dotfiles/stow" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "-d ${HOME}/.dotfiles/stow"
    assert_success
}

@test "stow_dotfiles_pkgs: passes -R flag to stow" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "-R"
    assert_success
}

@test "stow_dotfiles_pkgs: stow is called for MYHOST package" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "testhost"
    assert_success
}

# ---------------------------------------------------------------------------
# OS-conditional stow calls
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs: calls darwin stow only on macOS" {
    make_stow
    make_uname "Darwin"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "darwin"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call darwin stow on Linux" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "darwin"
    assert_success
}

@test "stow_dotfiles_pkgs: calls linux stow on Linux" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "linux"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call linux stow on macOS" {
    make_stow
    make_uname "Darwin"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "linux"
    assert_success
}

@test "stow_dotfiles_pkgs: calls arch stow on Arch Linux" {
    make_stow
    make_uname "Linux"
    make_os_release "arch"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "arch"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call arch stow on Debian" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "arch"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call arch stow on macOS" {
    make_stow
    make_uname "Darwin"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "arch"
    assert_success
}

@test "stow_dotfiles_pkgs: calls debian stow on Debian" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "debian"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call debian stow on Arch" {
    make_stow
    make_uname "Linux"
    make_os_release "arch"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "debian"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call debian stow on macOS" {
    make_stow
    make_uname "Darwin"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "debian"
    assert_success
}

@test "stow_dotfiles_pkgs: calls omarchy stow on Arch with omarchy in pacman.conf" {
    make_stow
    make_uname "Linux"
    make_os_release "arch"
    make_pacman_conf "[omarchy]"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "omarchy"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call omarchy stow on plain Arch" {
    make_stow
    make_uname "Linux"
    make_os_release "arch"
    make_pacman_conf "[core]"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "omarchy"
    assert_success
}

@test "stow_dotfiles_pkgs: calls zsh stow when SHELL is /bin/zsh" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env SHELL="/bin/zsh" MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "zsh"
    assert_success
}

@test "stow_dotfiles_pkgs: calls zsh stow when SHELL is /usr/bin/zsh" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env SHELL="/usr/bin/zsh" MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "zsh"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call zsh stow when SHELL is /bin/bash" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env SHELL="/bin/bash" MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "zsh"
    assert_success
}

# ---------------------------------------------------------------------------
# Host-conditional stow calls
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs: calls ansible, beets, and tmuxinator stow only on ariel" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="ariel" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "ansible"
    assert_success
    run stow_was_called_with "beets"
    assert_success
    run stow_was_called_with "tmuxinator"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call ansible stow on theophilus" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="theophilus" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "ansible"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call ansible stow on unknown host" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="someserver" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "ansible"
    assert_success
}

@test "stow_dotfiles_pkgs: calls i3 and x11 stow only on theophilus" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="theophilus" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "i3"
    assert_success
    run stow_was_called_with "x11"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call i3 stow on ariel" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="ariel" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "i3"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call i3 stow on unknown host" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="someserver" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "i3"
    assert_success
}

@test "stow_dotfiles_pkgs: calls ghostty, kitty, and nvim stow on ariel" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="ariel" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "ghostty"
    assert_success
    run stow_was_called_with "kitty"
    assert_success
    run stow_was_called_with "nvim"
    assert_success
}

@test "stow_dotfiles_pkgs: calls ghostty, kitty, and nvim stow on theophilus" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="theophilus" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_called_with "ghostty"
    assert_success
    run stow_was_called_with "kitty"
    assert_success
    run stow_was_called_with "nvim"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call nvim stow on non-dev host" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="someserver" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "nvim"
    assert_success
}

@test "stow_dotfiles_pkgs: does not call ghostty stow on non-dev host" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="someserver" "$RUNNER" stow_dotfiles_pkgs
    assert_success
    run stow_was_not_called_with "ghostty"
    assert_success
}

# ---------------------------------------------------------------------------
# Exit behavior
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs: succeeds when stow exits cleanly" {
    make_stow
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_success
}

@test "stow_dotfiles_pkgs: fails when stow exits with error" {
    cat >"$BIN/stow" <<'EOF'
#!/bin/bash
exit 1
EOF
    chmod +x "$BIN/stow"
    make_uname "Linux"
    make_os_release "debian"
    run env MYHOST_OVERRIDE="testhost" "$RUNNER" stow_dotfiles_pkgs
    assert_failure
}
