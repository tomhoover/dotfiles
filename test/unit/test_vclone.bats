# tests/unit/test_vclone.bats
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

    export VCSH_CALL_LOG="${BATS_TEST_TMPDIR}/vcsh.log"
    rm -f "$VCSH_CALL_LOG"

    export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
    cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
# Override BIN after bootstrap has set it so vcsh/git calls go through mocks.
BIN="${MOCK_BIN}"
"$@"
EOF
    chmod +x "$RUNNER"
}

teardown() {
    rm -f "$BIN/vcsh"
    rm -f "$VCSH_CALL_LOG" "${VCSH_CALL_LOG}.pull_count"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_vcsh() {
    local clone_exit=0 pull_exit=0 checkout_exit=0 config_exit=0

    for arg in "$@"; do
        case "$arg" in
        clone=*) clone_exit="${arg#*=}" ;;
        pull=*) pull_exit="${arg#*=}" ;;
        checkout=*) checkout_exit="${arg#*=}" ;;
        config=*) config_exit="${arg#*=}" ;;
        esac
    done

    cat >"$BIN/vcsh" <<EOF
#!/bin/bash
echo "vcsh \$@" >> "$VCSH_CALL_LOG"
subcmd="\$1"
[[ "\$1" != "clone" && "\$1" != "config" ]] && subcmd="\$2"
case "\$subcmd" in
  clone)    exit ${clone_exit}    ;;
  pull)
    # Use a counter file to distinguish first pull (exits pull_exit)
    # from subsequent pulls (exits 0) so the post-checkout pull succeeds.
    _pull_count_file="${VCSH_CALL_LOG}.pull_count"
    _n=\$(cat "\$_pull_count_file" 2>/dev/null || echo 0)
    _n=\$((_n + 1))
    echo "\$_n" > "\$_pull_count_file"
    [ "\$_n" -eq 1 ] && exit ${pull_exit} || exit 0
    ;;
  checkout)
    # Emit a whitespace-prefixed line so the grep '^\s+' pipeline in
    # github_vclone's backup path doesn't exit 1 under set -o pipefail.
    echo "  conflict-file"
    exit ${checkout_exit}
    ;;
  config)   exit ${config_exit}   ;;
  *)        exit 0                ;;
esac
EOF
    chmod +x "$BIN/vcsh"
}

vcsh_was_called_with() {
    grep -qF -- "$*" "$VCSH_CALL_LOG" 2>/dev/null
}

vcsh_was_not_called_with() {
    ! grep -qF -- "$*" "$VCSH_CALL_LOG" 2>/dev/null
}

# ---------------------------------------------------------------------------
# github_vclone — clone succeeds
# ---------------------------------------------------------------------------

@test "github_vclone: succeeds on first clone" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "dotfiles"
    assert_success
}

@test "github_vclone: prints success message on first clone" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "dotfiles"
    assert_output --partial "successfully cloned"
}

@test "github_vclone: clones from correct GitHub URL" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "dotfiles"
    run vcsh_was_called_with "clone https://github.com/tomhoover/dotfiles-vcsh.git dotfiles"
    assert_success
}

@test "github_vclone: sets core.bare to false after successful clone" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "dotfiles"
    run vcsh_was_called_with "config set core.bare false"
    assert_success
}

@test "github_vclone: uses \$1 not \$REPO in config commands after clone" {
    make_vcsh clone=0
    unset REPO
    run "$RUNNER" github_vclone "dotfiles"
    run vcsh_was_not_called_with "vcsh  config"
    assert_success
}

# ---------------------------------------------------------------------------
# github_vclone — clone fails, pull succeeds
# ---------------------------------------------------------------------------

@test "github_vclone: falls back to pull when clone fails" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" github_vclone "dotfiles"
    assert_success
}

@test "github_vclone: prints 'updated via pull' message on pull fallback" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" github_vclone "dotfiles"
    assert_output --partial "successfully updated via pull"
}

@test "github_vclone: pull uses correct repo name" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" github_vclone "dotfiles"
    run vcsh_was_called_with "dotfiles pull"
    assert_success
}

# ---------------------------------------------------------------------------
# github_vclone — clone fails, pull fails, checkout succeeds
# ---------------------------------------------------------------------------

@test "github_vclone: attempts checkout when clone and pull both fail" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" github_vclone "dotfiles"
    run vcsh_was_called_with "dotfiles checkout master"
    assert_success
}

@test "github_vclone: prints error message when conflicting files found" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" github_vclone "dotfiles"
    assert_output --partial "Conflicting files found"
}

@test "github_vclone: pulls after successful checkout and backup" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" github_vclone "dotfiles"
    run vcsh_was_called_with "dotfiles pull"
    assert_success
}

@test "github_vclone: prints cloned-after-backup success message" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" github_vclone "dotfiles"
    assert_output --partial "successfully cloned after backup"
}

# ---------------------------------------------------------------------------
# github_vclone — all operations fail
# ---------------------------------------------------------------------------

@test "github_vclone: returns failure when clone, pull, and checkout all fail" {
    make_vcsh clone=1 pull=1 checkout=1
    run "$RUNNER" github_vclone "dotfiles"
    assert_failure
}

# ---------------------------------------------------------------------------
# github_vclone — repo name variations
# ---------------------------------------------------------------------------

@test "github_vclone: works with repo name 'apt'" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "apt"
    assert_success
    run vcsh_was_called_with "clone https://github.com/tomhoover/apt-vcsh.git apt"
    assert_success
}

@test "github_vclone: works with repo name 'private'" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "private"
    assert_success
    run vcsh_was_called_with "clone https://github.com/tomhoover/private-vcsh.git private"
    assert_success
}

@test "github_vclone: constructs URL correctly for any repo name" {
    make_vcsh clone=0
    run "$RUNNER" github_vclone "myrepo"
    run vcsh_was_called_with "clone https://github.com/tomhoover/myrepo-vcsh.git myrepo"
    assert_success
}

# ---------------------------------------------------------------------------
# gitolite_vclone — clone succeeds
# ---------------------------------------------------------------------------

@test "gitolite_vclone: succeeds on first clone" {
    make_vcsh clone=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    assert_success
}

@test "gitolite_vclone: clones from correct gitolite URL" {
    make_vcsh clone=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    run vcsh_was_called_with "clone gitolite:dotfiles-vcsh.git dotfiles"
    assert_success
}

@test "gitolite_vclone: prints success message on first clone" {
    make_vcsh clone=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    assert_output --partial "successfully cloned"
}

@test "gitolite_vclone: sets core.bare to false after successful clone" {
    make_vcsh clone=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    run vcsh_was_called_with "config set core.bare false"
    assert_success
}

@test "gitolite_vclone: uses \$1 not \$REPO in config commands" {
    make_vcsh clone=0
    unset REPO
    run "$RUNNER" gitolite_vclone "dotfiles"
    run vcsh_was_not_called_with "vcsh  config"
    assert_success
}

# ---------------------------------------------------------------------------
# gitolite_vclone — clone fails, pull succeeds
# ---------------------------------------------------------------------------

@test "gitolite_vclone: falls back to pull when clone fails" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    assert_success
}

@test "gitolite_vclone: prints 'updated via pull' on pull fallback" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    assert_output --partial "successfully updated via pull"
}

# ---------------------------------------------------------------------------
# gitolite_vclone — clone fails, pull fails, checkout succeeds
# ---------------------------------------------------------------------------

@test "gitolite_vclone: attempts checkout when clone and pull both fail" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    run vcsh_was_called_with "dotfiles checkout master"
    assert_success
}

@test "gitolite_vclone: prints error on conflicting files" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" gitolite_vclone "dotfiles"
    assert_output --partial "Conflicting files found"
}

# ---------------------------------------------------------------------------
# gitolite_vclone — URL construction
# ---------------------------------------------------------------------------

@test "gitolite_vclone: constructs URL correctly for any repo name" {
    make_vcsh clone=0
    run "$RUNNER" gitolite_vclone "private"
    run vcsh_was_called_with "clone gitolite:private-vcsh.git private"
    assert_success
}

# ---------------------------------------------------------------------------
# localhost_vclone — clone succeeds
# ---------------------------------------------------------------------------

@test "localhost_vclone: succeeds on first clone" {
    make_vcsh clone=0
    run "$RUNNER" localhost_vclone "dotfiles"
    assert_success
}

@test "localhost_vclone: clones from correct local path" {
    make_vcsh clone=0
    run "$RUNNER" localhost_vclone "dotfiles"
    run vcsh_was_called_with "clone ${HOME}/git/dotfiles-vcsh.git dotfiles"
    assert_success
}

@test "localhost_vclone: prints success message on first clone" {
    make_vcsh clone=0
    run "$RUNNER" localhost_vclone "dotfiles"
    assert_output --partial "successfully cloned"
}

@test "localhost_vclone: sets core.bare to false after successful clone" {
    make_vcsh clone=0
    run "$RUNNER" localhost_vclone "dotfiles"
    run vcsh_was_called_with "config set core.bare false"
    assert_success
}

@test "localhost_vclone: uses \$1 not \$REPO in config commands" {
    make_vcsh clone=0
    unset REPO
    run "$RUNNER" localhost_vclone "dotfiles"
    run vcsh_was_not_called_with "vcsh  config"
    assert_success
}

# ---------------------------------------------------------------------------
# localhost_vclone — clone fails, pull succeeds
# ---------------------------------------------------------------------------

@test "localhost_vclone: falls back to pull when clone fails" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" localhost_vclone "dotfiles"
    assert_success
}

@test "localhost_vclone: prints 'updated via pull' on pull fallback" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" localhost_vclone "dotfiles"
    assert_output --partial "successfully updated via pull"
}

@test "localhost_vclone: pull uses correct repo name" {
    make_vcsh clone=1 pull=0
    run "$RUNNER" localhost_vclone "dotfiles"
    run vcsh_was_called_with "dotfiles pull"
    assert_success
}

# ---------------------------------------------------------------------------
# localhost_vclone — clone fails, pull fails, checkout succeeds
# ---------------------------------------------------------------------------

@test "localhost_vclone: attempts checkout when clone and pull both fail" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" localhost_vclone "dotfiles"
    run vcsh_was_called_with "dotfiles checkout master"
    assert_success
}

@test "localhost_vclone: prints error on conflicting files" {
    make_vcsh clone=1 pull=1 checkout=0
    run "$RUNNER" localhost_vclone "dotfiles"
    assert_output --partial "Conflicting files found"
}

@test "localhost_vclone: returns failure when clone, pull, and checkout all fail" {
    make_vcsh clone=1 pull=1 checkout=1
    run "$RUNNER" localhost_vclone "dotfiles"
    assert_failure
}

# ---------------------------------------------------------------------------
# localhost_vclone — local path respects $HOME
# ---------------------------------------------------------------------------

@test "localhost_vclone: constructs URL correctly for any repo name" {
    make_vcsh clone=0
    run "$RUNNER" localhost_vclone "ssh"
    run vcsh_was_called_with "clone ${HOME}/git/ssh-vcsh.git ssh"
    assert_success
}
