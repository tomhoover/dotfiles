# tests/unit/test_backup_file.bats
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
}

# ---------------------------------------------------------------------------
# backup_file — moves file to dated backup directory
# ---------------------------------------------------------------------------

@test "backup_file moves file to dated backup dir" {
    touch "$HOME/.bashrc"
    run "$RUNNER" backup_file ".bashrc"
    assert_success
    assert [ ! -f "$HOME/.bashrc" ]
    assert [ -f "$HOME/.backup-$(date '+%Y%m%d')/.bashrc" ]
}

@test "backup_file creates parent dirs for nested files" {
    mkdir -p "$HOME/.config/ghostty"
    touch "$HOME/.config/ghostty/config"
    run "$RUNNER" backup_file ".config/ghostty/config"
    assert_success
    assert [ -f "$HOME/.backup-$(date '+%Y%m%d')/.config/ghostty/config" ]
}

@test "backup_file creates parent dirs for kitty config" {
    mkdir -p "$HOME/.config/kitty"
    touch "$HOME/.config/kitty/kitty.conf"
    run "$RUNNER" backup_file ".config/kitty/kitty.conf"
    assert_success
    assert [ -f "$HOME/.backup-$(date '+%Y%m%d')/.config/kitty/kitty.conf" ]
}

@test "backup_file creates parent dirs for starship config" {
    mkdir -p "$HOME/.config"
    touch "$HOME/.config/starship.toml"
    run "$RUNNER" backup_file ".config/starship.toml"
    assert_success
    assert [ -f "$HOME/.backup-$(date '+%Y%m%d')/.config/starship.toml" ]
}

# ---------------------------------------------------------------------------
# backup_file — fixups.sh
# ---------------------------------------------------------------------------

@test "backup_file appends nvim diff command to fixups.sh" {
    touch "$HOME/.bashrc"
    run "$RUNNER" backup_file ".bashrc"
    assert_success
    assert [ -f "$HOME/fixups.sh" ]
    run grep "nvim -d" "$HOME/fixups.sh"
    assert_success
}

@test "backup_file fixups.sh entry references backup path" {
    touch "$HOME/.bashrc"
    run "$RUNNER" backup_file ".bashrc"
    run grep ".backup-$(date '+%Y%m%d')" "$HOME/fixups.sh"
    assert_success
}

@test "backup_file fixups.sh entry references original path" {
    touch "$HOME/.bashrc"
    run "$RUNNER" backup_file ".bashrc"
    run grep ".bashrc" "$HOME/fixups.sh"
    assert_success
}

@test "backup_file appends multiple entries to fixups.sh" {
    touch "$HOME/.bashrc"
    touch "$HOME/.zshrc"
    run "$RUNNER" backup_file ".bashrc"
    run "$RUNNER" backup_file ".zshrc"
    run grep -c "nvim -d" "$HOME/fixups.sh"
    assert_output "2"
}

# ---------------------------------------------------------------------------
# backup_file — prints success message
# ---------------------------------------------------------------------------

@test "backup_file prints backing up message" {
    touch "$HOME/.bashrc"
    run "$RUNNER" backup_file ".bashrc"
    assert_output --partial "Backing up"
}

@test "backup_file prints filename in message" {
    touch "$HOME/.bashrc"
    run "$RUNNER" backup_file ".bashrc"
    assert_output --partial ".bashrc"
}

# ---------------------------------------------------------------------------
# backup_file — handles filenames with spaces
# ---------------------------------------------------------------------------

@test "backup_file handles filenames with spaces" {
    touch "$HOME/my file.txt"
    run "$RUNNER" backup_file "my file.txt"
    assert_success
    assert [ ! -f "$HOME/my file.txt" ]
    assert [ -f "$HOME/.backup-$(date '+%Y%m%d')/my file.txt" ]
}
