# bootstrap a new system

- Copy desired private repos (gnupg ssh private-vcsh) from IRONKEY to ~/git/

- Recommended: Clone the repo locally, then run the bootstrap script:

  ```bash
  git clone https://github.com/tomhoover/dotfiles.git ~/.dotfiles
  ~/.dotfiles/script/bootstrap
  ```

- Alternative (`curl | bash`) — less transparent, skips version control:

  ```bash
  curl https://raw.githubusercontent.com/tomhoover/dotfiles/master/script/bootstrap | bash
  ```

  ⚠️ **Caution**: Review scripts before running them with `curl | bash`. Prefer
  cloning locally to inspect code and track versions via git.

---

## Development

### Prerequisites

Install development dependencies (bats, shellcheck, shfmt) and test helper
libraries:

```bash
make deps          # installs tools via mise, brew, pacman, apt, or dnf
make verify-deps   # confirm everything is in place
```

### Testing and Linting

| Command              | Description                                          |
| -------------------- | ---------------------------------------------------- |
| `make check`         | Run all checks: lint, format verification, and tests |
| `make test`          | Run all tests (unit + integration)                   |
| `make test-unit`     | Run unit tests only                                  |
| `make test-integ`    | Run integration tests only                           |
| `make lint-all`      | Shellcheck all scripts and test files                |
| `make fmt-check`     | Verify formatting without modifying files            |
| `make fmt-all`       | Auto-format all scripts and test files in place      |
| `make list-tests`    | List all test names without running them             |

Run `make` with no arguments to see the full list of targets.

### Pre-commit Hooks

This repo uses [pre-commit](https://pre-commit.com/) to enforce shellcheck,
shfmt, and other checks before each commit. To set it up:

```bash
pip install pre-commit   # or: brew install pre-commit
pre-commit install --install-hooks
```

Hooks run automatically on `git commit`. To run all hooks manually:

```bash
pre-commit run --all-files
```

### How to Contribute

1. Create a feature branch from `master`.
2. Make your changes, keeping scripts self-contained in `script/`.
3. Add or update tests in `test/unit/` or `test/integration/` as appropriate.
4. Run `make check` to ensure lint, formatting, and tests all pass.
5. Commit using a conventional commit message (e.g., `feat:`, `fix:`,
   `refactor:`, `docs:`).

### Stow Directory Layout

Dotfiles live in `stow/` and are deployed to `~` via
[GNU Stow](https://www.gnu.org/software/stow/). Packages are organized by
tool, OS, or hostname:

| Package pattern       | Example                 | Stowed when            |
| --------------------- | ----------------------- | ---------------------- |
| Tool-specific         | `git/`, `tmux/`         | Always                 |
| OS-specific           | `darwin/`, `linux/`     | Matching OS detected   |
| Host-specific         | `ariel/`, `theophilus/` | Matching hostname      |
| Shell-specific        | `zsh/`                  | `$SHELL` is zsh        |

Some files (e.g., `.editorconfig`) appear in multiple packages. These are
**not** duplicates -- EditorConfig uses directory-level inheritance, so child
files intentionally override the root `~/.editorconfig` for their subtree.
