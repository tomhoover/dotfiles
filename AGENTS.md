# AGENTS.md — Dotfiles Bootstrap & Install-Dev-Tools

## Project Overview

Personal dotfiles repo with two main shell scripts (`script/bootstrap`,
`script/install-dev-tools`) managing system setup across macOS, Arch Linux,
Debian, and Fedora. Configuration files live under `stow/` and are deployed
via GNU Stow. The repo uses [bats-core](https://github.com/bats-core/bats-core)
for testing and shellcheck/shfmt for linting/formatting.

## Build / Lint / Test Commands

```bash
# --- Setup (first time) ---
make deps            # Install bats, shellcheck, shfmt via system package manager
make bats-libs       # Clone bats-support, bats-assert, bats-file into test/libs/

# --- Linting ---
make lint            # shellcheck on script/bootstrap and script/install-dev-tools
make lint-tests      # shellcheck on all .bats files
make lint-all        # Both of the above

# --- Formatting ---
make fmt             # shfmt -w on scripts (in place)
make fmt-tests       # shfmt -w on .bats files
make fmt-all         # Both of the above
make fmt-check       # Dry-run format check (CI-safe, no modifications)

# --- Testing ---
make test            # Run all tests (unit + integration); parallel if GNU parallel/rush found
make test-unit       # Unit tests only (test/unit/)
make test-integ      # Integration tests only (test/integration/)

# Run a single test FILE:
make test-file FILE=test/unit/test_backup_file.bats

# Run tests matching a name PATTERN:
make test-filter FILTER='backup file'

make test-tap        # TAP output (used in CI, always serial)
make list-tests      # List all test names without running them

# --- Combined workflows ---
make check           # lint-all + fmt-check + test
make ci              # fmt-check + lint-all + test-tap (mirrors GitHub Actions)
make fix             # fmt-all (auto-fix formatting)

# --- Utilities ---
make verify-deps     # Check all required tools are installed
make clean           # Remove temp files and bats output artifacts
```

### CI Pipeline

GitHub Actions runs on push/PR to `master` (see `.github/workflows/ci.yml`):
`make lint-all` -> `make fmt-check` -> `make test-tap`

## Code Style — Shell Scripts

### Formatting (enforced by shfmt)

- **Indent**: 2 spaces (no tabs in scripts; Makefile uses tabs per make rules)
- **Switch/case**: indent case bodies (`-ci`)
- **Binary operators**: `&&` and `||` start a new line (`-bn`)
- shfmt flags: `-i 2 -ci -bn`

### Linting (enforced by shellcheck)

- Severity: `--severity=warning`
- Shell dialect: `bash`
- External sources allowed: `--external-sources`
- Suppress specific warnings with inline `# shellcheck disable=SCxxxx` comments,
  always adding a rationale comment explaining why the disable is needed

### General Bash Conventions

- Shebang: `#!/usr/bin/env bash`
- Always `set -euo pipefail` at the top of executable scripts
- Quote all variable expansions: `"$var"`, `"${array[@]}"`
- Use `[[ ]]` for conditionals (bash-specific), `[ ]` for POSIX compat
- Prefer `$(command)` over backticks
- Use `local` for function-scoped variables
- Use `command -v` instead of `which` to check if a binary exists
- Functions use `name() { ... }` syntax (no `function` keyword)
- Fold markers `#{{{` and `#}}}` are used for editor folding — preserve them
- Vim modeline at end of scripts:
  `# vim: set tw=120 expandtab tabstop=2 shiftwidth=2 fdm=marker commentstring=#%s:`

### Naming Conventions

- **Functions**: `snake_case` (e.g., `backup_file`, `install_required_pkgs`,
  `clone_apt_vcsh`)
- **Local variables**: `snake_case` with `local` keyword
- **Environment/global variables**: `UPPER_SNAKE_CASE` (e.g., `MYHOST`,
  `STOW_DOTFILES`, `REPO_ROOT`)
- **Arrays**: `UPPER_SNAKE_CASE` with plural names (e.g., `COMMON_PKGS`,
  `ARCH_PKGS`)
- **Test files**: `test_<feature_name>.bats` in `test/unit/` or
  `test/integration/`

### Error Handling

- Use the logging helpers defined in the scripts:
  - `error "msg"` — prints to stderr with red `ERROR` prefix
  - `warn "msg"` — prints yellow `WARNING`
  - `info "msg"` — prints cyan informational message
  - `success "msg"` — prints green checkmark message
- Guard optional args: `local target="${1:-}"` then `[ -z "$target" ] && return 1`
- Fail loudly on critical errors: `exit <nonzero>` with a descriptive `error` call
- Use `|| true` for non-critical commands that may fail (e.g., OS-conditional stow)

### Testability

- OS-detection functions (`isdarwin`, `islinux`, `isarch`, `isdebian`,
  `isfedora`, `isomarchy`) read from overridable env vars (e.g., `$OS_RELEASE`,
  `$PACMAN_CONF`) so tests can inject fakes without touching the real filesystem.
- `script/bootstrap` returns early when sourced (`[[ "${BASH_SOURCE[0]}" != "${0}" ]] && return 0`)
  so tests can source individual functions.
- Hostname-dependent logic uses `MYHOST_OVERRIDE` in tests.

## Code Style — Python (minor role)

Enforced by ruff via pre-commit. Key rules enabled:

- Import sorting (`I`), `from __future__ import annotations` (`FA`)
- Prefer `pathlib` over `os.path` (`PTH`)
- Simplification rules (`SIM`), comprehension checks (`C4`)
- Return practices (`RET`), type-checking imports (`TC`)

## Test Patterns (bats)

### Structure

```text
test/
  helpers/mocks.bash   # Shared setup: loads bats-support/bats-assert, sets REPO_ROOT
  unit/                # Fast, isolated unit tests
  integration/         # End-to-end tests with mocked external tools
  libs/                # bats helper libraries (gitignored, installed via make bats-libs)
```

### Writing Tests

- Load shared helpers: `load '../helpers/mocks'`
- Every test file needs `setup()` and `teardown()` functions
- In `setup()`: set `HOME`, `PATH`, `MOCK_BIN` to temp dirs; create a `RUNNER`
  script that sources the script-under-test
- In `teardown()`: clean up stubs and temp files
- Use `run` + `assert_success` / `assert_failure` / `assert_output` from bats-assert
- Stub external commands by writing shell scripts to `${BATS_TEST_TMPDIR}/bin/`
- Group related tests with comment block headers (`# ------- section -------`)
- Test names: `@test "function_name: describes expected behavior" { ... }`

### Parallel Safety

Tests run in parallel across files when GNU parallel or rush is installed (via
`--jobs <nproc>`). All test files **must** remain parallel-safe:

- **Always** scope all side effects to `${BATS_TEST_TMPDIR}` — never write to
  fixed paths like `/tmp/somename` or a shared `$HOME`
- **Always** override `HOME` and `PATH` to point into `${BATS_TEST_TMPDIR}` in
  `setup()`; never mutate the real `HOME` or `PATH`
- **Always** write mock/stub binaries to `${BATS_TEST_TMPDIR}/bin/` — never a
  shared directory
- **Never** share state between test files via global files, fixed socket paths,
  or named pipes outside `${BATS_TEST_TMPDIR}`
- `make test-tap` (CI) is intentionally serial — parallel bats + TAP formatter
  produces interleaved output that breaks TAP consumers

### Test Runner Script Pattern

Tests use a `RUNNER` wrapper that sources the script-under-test and then
invokes a function by name:

```bash
export RUNNER="${BATS_TEST_TMPDIR}/runner.sh"
cat >"$RUNNER" <<'EOF'
#!/bin/bash
source "${REPO_ROOT}/script/bootstrap"
[[ -n "${MYHOST_OVERRIDE+x}" ]] && MYHOST="${MYHOST_OVERRIDE}"
"$@"
EOF
chmod +x "$RUNNER"
```

## Pre-commit Hooks

Configured in `.pre-commit-config.yaml` with `fail_fast: true`. Key hooks:

- shellcheck, shfmt (with `--apply-ignore`)
- ruff-check + ruff-format for Python
- `prevent-fixme`: blocks commits containing `# FIX`+`ME` comments
- Standard checks: trailing whitespace, end-of-file-fixer, mixed-line-ending,
  detect-private-key, detect-aws-credentials, check-merge-conflict

## Important Notes

- **Never commit `test/libs/`** — it is gitignored; recreate with `make bats-libs`
- **Never commit `.env` or `*.local.toml`** — gitignored
- Default branch is `master`
- The repo uses `mise` for tool version management (see `.mise.toml`)

## Behavioral guidelines to reduce common LLM coding mistakes

**Tradeoff:** These guidelines bias toward caution over speed. For trivial tasks, use judgment.

### 1. Think Before Coding

**Don't assume. Don't hide confusion. Surface tradeoffs.**

Before implementing:

- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.

### 2. Simplicity First

**Minimum code that solves the problem. Nothing speculative.**

- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.

Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes

**Touch only what you must. Clean up only your own mess.**

When editing existing code:

- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.

When your changes create orphans:

- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.

The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution

**Define success criteria. Loop until verified.**

Transform tasks into verifiable goals:

- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"

For multi-step tasks, state a brief plan:

```text
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```

Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---

**These guidelines are working if:** fewer unnecessary changes in diffs, fewer rewrites due to overcomplication, and clarifying questions come before implementation rather than after mistakes.
