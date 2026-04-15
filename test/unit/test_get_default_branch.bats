# test/unit/test_get_default_branch.bats
# bats file_tags=fast
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

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

make_git_repo() {
  local repo_dir="$1"
  local branch="${2:-master}"
  mkdir -p "$repo_dir"
  git -C "$repo_dir" init -b "$branch" >/dev/null 2>&1
  git -C "$repo_dir" config user.email "test@test.com"
  git -C "$repo_dir" config user.name "Test"
  git -C "$repo_dir" commit --allow-empty -m "initial" >/dev/null 2>&1
}

# ---------------------------------------------------------------------------
# get_default_branch
# ---------------------------------------------------------------------------

@test "get_default_branch returns current branch name from a git repo" {
  make_git_repo "${BATS_TEST_TMPDIR}/myrepo" "main"
  run "$RUNNER" get_default_branch "${BATS_TEST_TMPDIR}/myrepo"
  assert_success
  assert_output "main"
}

@test "get_default_branch returns 'master' for a repo initialized with master" {
  make_git_repo "${BATS_TEST_TMPDIR}/myrepo" "master"
  run "$RUNNER" get_default_branch "${BATS_TEST_TMPDIR}/myrepo"
  assert_success
  assert_output "master"
}

@test "get_default_branch returns branch name for a non-default branch" {
  make_git_repo "${BATS_TEST_TMPDIR}/myrepo" "main"
  git -C "${BATS_TEST_TMPDIR}/myrepo" checkout -b "develop" >/dev/null 2>&1
  run "$RUNNER" get_default_branch "${BATS_TEST_TMPDIR}/myrepo"
  assert_success
  assert_output "develop"
}

@test "get_default_branch falls back to 'master' for a non-git directory" {
  mkdir -p "${BATS_TEST_TMPDIR}/not-a-repo"
  run "$RUNNER" get_default_branch "${BATS_TEST_TMPDIR}/not-a-repo"
  assert_success
  assert_output "master"
}

@test "get_default_branch falls back to 'master' for a nonexistent directory" {
  run "$RUNNER" get_default_branch "${BATS_TEST_TMPDIR}/does-not-exist"
  assert_success
  assert_output "master"
}

@test "get_default_branch defaults to '.' when no argument given" {
  make_git_repo "${BATS_TEST_TMPDIR}/myrepo" "trunk"
  run bash -c "cd '${BATS_TEST_TMPDIR}/myrepo' && '$RUNNER' get_default_branch"
  assert_success
  assert_output "trunk"
}
