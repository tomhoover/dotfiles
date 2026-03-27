# AGENTS.md

## Overview

This is a dotfiles repository for bootstrapping and configuring a new system. The two primary scripts are:

- **`script/bootstrap`** — Installs required packages, clones private repos, stows dotfiles, and sets up services (tailscale, keychain, caps2esc). Supports macOS (via Homebrew), Arch, Debian, and Fedora.
- **`script/install-dev-tools`** — Installs development tools by discovering and running `install.sh` scripts in subdirectories, then uses `mise install` and `uv` for the rest.

Dotfiles are managed with [GNU Stow](https://www.gnu.org/software/stow/) from the `stow/` directory, targeting `~`. The bootstrap script dispatches stow packages based on OS, hostname, and shell. Arch-specific package installation logic resides in `script/arch`.

## Commands

### Setup (first time)

```bash
make deps          # Install bats, shellcheck, shfmt via mise, brew, or pacman
make bats-libs     # Clone bats helper libraries into test/libs/
make verify-deps   # Check that all required tools are installed
```

### Linting

```bash
make lint        # shellcheck on scripts only
make lint-tests  # shellcheck on .bats files
make lint-all    # both
```

### Formatting

```bash
make fmt         # shfmt scripts in place
make fmt-check   # check only (CI-safe)
make fmt-tests   # format .bats files in place
make fmt-all     # format scripts and .bats files
```

shfmt options: `-i 2 -ci -bn` (2-space indent, indent switch cases, binary ops start new line)

### Testing

```bash
make test                                   # all tests
make test-unit                              # unit tests only
make test-integ                             # integration tests only
make test-file FILE=test/unit/foo.bats      # single file
make test-filter FILTER='backup file'       # tests matching a pattern
make test-tap                               # all tests with TAP output (for CI)
```

### Combined

```bash
make check   # lint-all + fmt-check + test
make ci      # fmt-check + lint-all + test-tap
make fix     # fmt-all (format everything in place)
```

### Utilities

```bash
make clean         # Remove temp files and bats output artifacts
make list-tests    # List all test names without running them
```

## Test Architecture

Tests use [BATS](https://github.com/bats-core/bats-core) with three helper libraries in `test/libs/`: `bats-support`, `bats-assert`, `bats-file`.

**Structure:**

- `test/unit/` — unit tests for individual functions in the bootstrap scripts
- `test/integration/` — integration tests that exercise broader flows
- `test/helpers/mocks.bash` — shared helper loaded by all test files; sets `REPO_ROOT` and provides `stub_uname_*` functions for OS detection mocking

**Test pattern:** Tests source `script/bootstrap` via a runner script created in `setup()`, then call individual functions. OS detection is controlled by stubbing `uname` in `$BATS_TEST_TMPDIR/bin/` and exporting `OS_RELEASE` to point to a temp file.

**Key env vars used in tests:**

- `REPO_ROOT` — set by `mocks.bash`, points to repo root
- `OS_RELEASE` — overrides `/etc/os-release` path for `isarch()`/`isdebian()`/`isfedora()`
- `PACMAN_CONF` — overrides `/etc/pacman.conf` path for `isomarchy()`
- `MYHOST_OVERRIDE` — overrides `MYHOST` (hostname) for host-specific tests

## Script Conventions

Both scripts use the same logging helpers: `error()`, `warn()`, `info()`, `success()` with ANSI colors (suppressed when stdout is not a TTY).

OS detection functions in `script/bootstrap`: `isdarwin()`, `islinux()`, `isarch()`, `isdebian()`, `isfedora()`, `isomarchy()`, `iszsh()`, `isdev()`.

The scripts use `set -euo pipefail`. Fold markers (`#{{{` / `#}}}`) are used throughout for vim folding.

Tool versions for development are managed via `mise` (see `.mise.toml`): bats, shellcheck, shfmt, claude.
