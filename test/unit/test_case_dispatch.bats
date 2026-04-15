# tests/unit/test_case_dispatch.bats
# bats file_tags=fast
load '../helpers/mocks'

setup() {
  export HOME="${BATS_TEST_TMPDIR}/home"
  mkdir -p "$HOME"
  export PATH="${BATS_TEST_TMPDIR}/bin:$PATH"
  export BIN="${BATS_TEST_TMPDIR}/bin"
  mkdir -p "$BIN"

  export CALL_LOG="${BATS_TEST_TMPDIR}/call.log"
  rm -f "$CALL_LOG"

  # Copy bootstrap and inject stubs before the BASH_SOURCE guard so they
  # override real functions before the case dispatch block executes.
  export BOOTSTRAP="${BATS_TEST_TMPDIR}/bootstrap_test.sh"
  cp "${REPO_ROOT}/script/bootstrap" "$BOOTSTRAP"
  _stub_all_functions
}

teardown() {
  rm -f "$CALL_LOG" "$BOOTSTRAP" "${BOOTSTRAP}.tmp"
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_stub_all_functions() {
  # Build the full stub block. CALL_LOG must expand now (unquoted in the
  # outer heredoc) so the path is baked into the stub definitions.
  local stubs
  stubs="
clone_dotfiles_repo()        { echo 'clone_dotfiles_repo'        >> \"${CALL_LOG}\"; }
install_required_pkgs()      { echo 'install_required_pkgs'      >> \"${CALL_LOG}\"; }
check_installed_commands()   { echo 'check_installed_commands'   >> \"${CALL_LOG}\"; }
setup_etckeeper()            { echo 'setup_etckeeper'            >> \"${CALL_LOG}\"; }
stow_dotfiles_pkgs()         { echo 'stow_dotfiles_pkgs'         >> \"${CALL_LOG}\"; }
clone_private_repos()        { echo 'clone_private_repos'        >> \"${CALL_LOG}\"; }
install_remaining_pkgs()     { echo 'install_remaining_pkgs'     >> \"${CALL_LOG}\"; }
create_ssh_key()             { echo 'create_ssh_key'             >> \"${CALL_LOG}\"; }
setup_keychain()             { echo 'setup_keychain'             >> \"${CALL_LOG}\"; }
setup_tailscale()            { echo 'setup_tailscale'            >> \"${CALL_LOG}\"; }
set_private_repos_tracking() { echo 'set_private_repos_tracking' >> \"${CALL_LOG}\"; }
install_caps2esc()           { echo 'install_caps2esc'           >> \"${CALL_LOG}\"; }
clone_apt_vcsh()             { echo 'clone_apt_vcsh'             >> \"${CALL_LOG}\"; }
isdarwin()  { return 1; }
islinux()   { return 1; }
isarch()    { return 1; }
isdebian()  { return 1; }
isfedora()  { return 1; }
isomarchy() { return 1; }
iszsh()     { return 1; }
isdev()     { return 1; }
sudo() { :; }
"

  # Find the line number of the BASH_SOURCE guard — stubs go just before it
  # so they are defined before the case dispatch block that follows the guard.
  local guard_line
  guard_line=$(grep -n 'BASH_SOURCE' "$BOOTSTRAP" | tail -1 | cut -d: -f1)

  {
    head -n "$((guard_line - 1))" "$BOOTSTRAP"
    echo "$stubs"
    tail -n "+${guard_line}" "$BOOTSTRAP"
  } >"${BOOTSTRAP}.tmp" && mv "${BOOTSTRAP}.tmp" "$BOOTSTRAP"
  chmod +x "$BOOTSTRAP"
}

_inject_override() {
  # Splice override function definitions before the BASH_SOURCE guard so they
  # take effect during the main execution sequence, not after it.
  local guard_line
  guard_line=$(grep -n 'BASH_SOURCE' "$BOOTSTRAP" | tail -1 | cut -d: -f1)
  {
    head -n "$((guard_line - 1))" "$BOOTSTRAP"
    echo "$1"
    tail -n "+${guard_line}" "$BOOTSTRAP"
  } >"${BOOTSTRAP}.tmp" && mv "${BOOTSTRAP}.tmp" "$BOOTSTRAP"
  chmod +x "$BOOTSTRAP"
}

fn_was_called() {
  grep -qF -- "$1" "$CALL_LOG" 2>/dev/null
}

fn_was_not_called() {
  ! grep -qF -- "$1" "$CALL_LOG" 2>/dev/null
}

call_order() {
  # Returns success if $1 appears before $2 in the call log
  local line1 line2
  line1=$(grep -nF -- "$1" "$CALL_LOG" 2>/dev/null | head -1 | cut -d: -f1)
  line2=$(grep -nF -- "$2" "$CALL_LOG" 2>/dev/null | head -1 | cut -d: -f1)
  [[ -n "$line1" && -n "$line2" && "$line1" -lt "$line2" ]]
}

# ---------------------------------------------------------------------------
# No argument — full bootstrap sequence
# ---------------------------------------------------------------------------

@test "no arg: exits successfully" {
  run bash "$BOOTSTRAP"
  assert_success
}

@test "no arg: calls clone_dotfiles_repo" {
  bash "$BOOTSTRAP"
  run fn_was_called "clone_dotfiles_repo"
  assert_success
}

@test "no arg: calls install_required_pkgs" {
  bash "$BOOTSTRAP"
  run fn_was_called "install_required_pkgs"
  assert_success
}

@test "no arg: calls check_installed_commands" {
  bash "$BOOTSTRAP"
  run fn_was_called "check_installed_commands"
  assert_success
}

@test "no arg: calls stow_dotfiles_pkgs" {
  bash "$BOOTSTRAP"
  run fn_was_called "stow_dotfiles_pkgs"
  assert_success
}

@test "no arg: calls clone_private_repos" {
  bash "$BOOTSTRAP"
  run fn_was_called "clone_private_repos"
  assert_success
}

@test "no arg: calls install_remaining_pkgs" {
  bash "$BOOTSTRAP"
  run fn_was_called "install_remaining_pkgs"
  assert_success
}

@test "no arg: calls create_ssh_key" {
  bash "$BOOTSTRAP"
  run fn_was_called "create_ssh_key"
  assert_success
}

@test "no arg: calls setup_keychain" {
  bash "$BOOTSTRAP"
  run fn_was_called "setup_keychain"
  assert_success
}

@test "no arg: calls setup_tailscale" {
  bash "$BOOTSTRAP"
  run fn_was_called "setup_tailscale"
  assert_success
}

@test "no arg: calls set_private_repos_tracking" {
  bash "$BOOTSTRAP"
  run fn_was_called "set_private_repos_tracking"
  assert_success
}

# ---------------------------------------------------------------------------
# No argument — call ordering
# ---------------------------------------------------------------------------

@test "no arg: clone_dotfiles_repo is called before install_required_pkgs" {
  bash "$BOOTSTRAP"
  run call_order "clone_dotfiles_repo" "install_required_pkgs"
  assert_success
}

@test "no arg: install_required_pkgs is called before check_installed_commands" {
  bash "$BOOTSTRAP"
  run call_order "install_required_pkgs" "check_installed_commands"
  assert_success
}

@test "no arg: check_installed_commands is called before stow_dotfiles_pkgs" {
  bash "$BOOTSTRAP"
  run call_order "check_installed_commands" "stow_dotfiles_pkgs"
  assert_success
}

@test "no arg: stow_dotfiles_pkgs is called before clone_private_repos" {
  bash "$BOOTSTRAP"
  run call_order "stow_dotfiles_pkgs" "clone_private_repos"
  assert_success
}

@test "no arg: clone_private_repos is called before install_remaining_pkgs" {
  bash "$BOOTSTRAP"
  run call_order "clone_private_repos" "install_remaining_pkgs"
  assert_success
}

@test "no arg: install_remaining_pkgs is called before create_ssh_key" {
  bash "$BOOTSTRAP"
  run call_order "install_remaining_pkgs" "create_ssh_key"
  assert_success
}

@test "no arg: create_ssh_key is called before setup_keychain" {
  bash "$BOOTSTRAP"
  run call_order "create_ssh_key" "setup_keychain"
  assert_success
}

@test "no arg: setup_keychain is called before setup_tailscale" {
  bash "$BOOTSTRAP"
  run call_order "setup_keychain" "setup_tailscale"
  assert_success
}

@test "no arg: setup_tailscale is called before set_private_repos_tracking" {
  bash "$BOOTSTRAP"
  run call_order "setup_tailscale" "set_private_repos_tracking"
  assert_success
}

# ---------------------------------------------------------------------------
# No argument — platform-conditional calls
# ---------------------------------------------------------------------------

@test "no arg: does not call setup_etckeeper on macOS" {
  _inject_override 'isdarwin() { return 0; }'
  bash "$BOOTSTRAP"
  run fn_was_not_called "setup_etckeeper"
  assert_success
}

@test "no arg: calls setup_etckeeper on Linux" {
  _inject_override $'isdarwin() { return 1; }\nislinux() { return 0; }'
  bash "$BOOTSTRAP"
  run fn_was_called "setup_etckeeper"
  assert_success
}

@test "no arg: calls install_caps2esc on Arch" {
  _inject_override 'isarch() { return 0; }'
  bash "$BOOTSTRAP"
  run fn_was_called "install_caps2esc"
  assert_success
}

@test "no arg: does not call install_caps2esc on Debian" {
  _inject_override $'isarch() { return 1; }\nisdebian() { return 0; }'
  bash "$BOOTSTRAP"
  run fn_was_not_called "install_caps2esc"
  assert_success
}

@test "no arg: does not call install_caps2esc on macOS" {
  _inject_override $'isdarwin() { return 0; }\nisarch() { return 1; }'
  bash "$BOOTSTRAP"
  run fn_was_not_called "install_caps2esc"
  assert_success
}

@test "no arg: calls clone_apt_vcsh on Debian" {
  _inject_override 'isdebian() { return 0; }'
  bash "$BOOTSTRAP"
  run fn_was_called "clone_apt_vcsh"
  assert_success
}

@test "no arg: does not call clone_apt_vcsh on Arch" {
  _inject_override $'isarch() { return 0; }\nisdebian() { return 1; }'
  bash "$BOOTSTRAP"
  run fn_was_not_called "clone_apt_vcsh"
  assert_success
}

@test "no arg: does not call clone_apt_vcsh on macOS" {
  _inject_override $'isdarwin() { return 0; }\nisdebian() { return 1; }'
  bash "$BOOTSTRAP"
  run fn_was_not_called "clone_apt_vcsh"
  assert_success
}

# ---------------------------------------------------------------------------
# 'update' argument
# ---------------------------------------------------------------------------

@test "update: exits successfully" {
  run bash "$BOOTSTRAP" update
  assert_success
}

@test "update: calls clone_dotfiles_repo" {
  bash "$BOOTSTRAP" update
  run fn_was_called "clone_dotfiles_repo"
  assert_success
}

@test "update: calls stow_dotfiles_pkgs" {
  bash "$BOOTSTRAP" update
  run fn_was_called "stow_dotfiles_pkgs"
  assert_success
}

@test "update: calls clone_dotfiles_repo before stow_dotfiles_pkgs" {
  bash "$BOOTSTRAP" update
  run call_order "clone_dotfiles_repo" "stow_dotfiles_pkgs"
  assert_success
}

@test "update: does not call install_required_pkgs" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "install_required_pkgs"
  assert_success
}

@test "update: does not call clone_private_repos" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "clone_private_repos"
  assert_success
}

@test "update: does not call install_remaining_pkgs" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "install_remaining_pkgs"
  assert_success
}

@test "update: does not call create_ssh_key" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "create_ssh_key"
  assert_success
}

@test "update: does not call setup_tailscale" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "setup_tailscale"
  assert_success
}

@test "update: does not call setup_keychain" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "setup_keychain"
  assert_success
}

@test "update: does not call setup_etckeeper" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "setup_etckeeper"
  assert_success
}

@test "update: does not call install_caps2esc" {
  bash "$BOOTSTRAP" update
  run fn_was_not_called "install_caps2esc"
  assert_success
}

# ---------------------------------------------------------------------------
# 'clone_dotfiles_repo' argument
# ---------------------------------------------------------------------------

@test "clone_dotfiles_repo arg: exits successfully" {
  run bash "$BOOTSTRAP" clone_dotfiles_repo
  assert_success
}

@test "clone_dotfiles_repo arg: calls clone_dotfiles_repo" {
  bash "$BOOTSTRAP" clone_dotfiles_repo
  run fn_was_called "clone_dotfiles_repo"
  assert_success
}

@test "clone_dotfiles_repo arg: does not call stow_dotfiles_pkgs" {
  bash "$BOOTSTRAP" clone_dotfiles_repo
  run fn_was_not_called "stow_dotfiles_pkgs"
  assert_success
}

@test "clone_dotfiles_repo arg: does not call install_required_pkgs" {
  bash "$BOOTSTRAP" clone_dotfiles_repo
  run fn_was_not_called "install_required_pkgs"
  assert_success
}

@test "clone_dotfiles_repo arg: does not call setup_tailscale" {
  bash "$BOOTSTRAP" clone_dotfiles_repo
  run fn_was_not_called "setup_tailscale"
  assert_success
}

# ---------------------------------------------------------------------------
# 'stow_dotfiles_pkgs' argument
# ---------------------------------------------------------------------------

@test "stow_dotfiles_pkgs arg: exits successfully" {
  run bash "$BOOTSTRAP" stow_dotfiles_pkgs
  assert_success
}

@test "stow_dotfiles_pkgs arg: calls stow_dotfiles_pkgs" {
  bash "$BOOTSTRAP" stow_dotfiles_pkgs
  run fn_was_called "stow_dotfiles_pkgs"
  assert_success
}

@test "stow_dotfiles_pkgs arg: does not call clone_dotfiles_repo" {
  bash "$BOOTSTRAP" stow_dotfiles_pkgs
  run fn_was_not_called "clone_dotfiles_repo"
  assert_success
}

@test "stow_dotfiles_pkgs arg: does not call install_required_pkgs" {
  bash "$BOOTSTRAP" stow_dotfiles_pkgs
  run fn_was_not_called "install_required_pkgs"
  assert_success
}

@test "stow_dotfiles_pkgs arg: does not call setup_tailscale" {
  bash "$BOOTSTRAP" stow_dotfiles_pkgs
  run fn_was_not_called "setup_tailscale"
  assert_success
}

@test "stow_dotfiles_pkgs arg: does not call create_ssh_key" {
  bash "$BOOTSTRAP" stow_dotfiles_pkgs
  run fn_was_not_called "create_ssh_key"
  assert_success
}

# ---------------------------------------------------------------------------
# Unknown argument — exits with code 9
# ---------------------------------------------------------------------------

@test "unknown arg: exits with code 9" {
  run bash "$BOOTSTRAP" totally_invalid_arg
  assert_failure
  assert [ "$status" -eq 9 ]
}

@test "unknown arg: exits with code 9 for another unknown arg" {
  run bash "$BOOTSTRAP" bad_arg
  assert_failure
  assert [ "$status" -eq 9 ]
}

@test "unknown arg: prints error message containing the unknown arg" {
  run bash "$BOOTSTRAP" bad_arg
  assert_output --partial "bad_arg"
}

@test "unknown arg: error message is printed to stderr" {
  # Run capturing stderr into output, stdout discarded — error must appear
  run bash -c 'bash "'"$BOOTSTRAP"'" bad_arg 2>&1 1>/dev/null'
  assert_output --partial "bad_arg"
}

@test "unknown arg: does not call any bootstrap functions" {
  bash "$BOOTSTRAP" bad_arg || true
  run fn_was_not_called "clone_dotfiles_repo"
  assert_success
  run fn_was_not_called "stow_dotfiles_pkgs"
  assert_success
  run fn_was_not_called "install_required_pkgs"
  assert_success
  run fn_was_not_called "setup_tailscale"
  assert_success
}

@test "unknown arg: exits with code 9 for arg that is a substring of valid arg" {
  run bash "$BOOTSTRAP" clone
  assert_failure
  assert [ "$status" -eq 9 ]
}

@test "unknown arg: exits with code 9 for arg that is a superstring of valid arg" {
  run bash "$BOOTSTRAP" clone_dotfiles_repo_extra
  assert_failure
  assert [ "$status" -eq 9 ]
}

@test "unknown arg: exits with code 9 for numeric arg" {
  run bash "$BOOTSTRAP" 42
  assert_failure
  assert [ "$status" -eq 9 ]
}

@test "unknown arg: exits with code 9 for empty string arg" {
  run bash "$BOOTSTRAP" ""
  assert_failure
  assert [ "$status" -eq 9 ]
}
