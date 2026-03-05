# Makefile for bootstrap — lint, format, and test

SHELL        := /usr/bin/env bash
SCRIPT       := script/bootstrap
TEST_DIR     := test
UNIT_DIR     := $(TEST_DIR)/unit
INTEG_DIR    := $(TEST_DIR)/integration
LIBS_DIR     := $(TEST_DIR)/libs
HELPERS_DIR  := $(TEST_DIR)/helpers

# Tool paths — override via environment if needed
BATS         := bats
SHELLCHECK   := shellcheck
SHFMT        := shfmt

# shfmt formatting options — match common bash style
# -i 2  : indent with 2 spaces
# -ci   : indent switch cases
# -bn   : binary ops (&&, ||) start a new line
SHFMT_OPTS   := -i 2 -ci -bn

# bats options
BATS_OPTS    := --timing

# Colors
# RED          := \033[0;31m
# GREEN        := \033[0;32m
# YELLOW       := \033[0;33m
# CYAN         := \033[0;36m
# RESET        := \033[0m

RED          := $(shell tput setaf 1)
GREEN        := $(shell tput setaf 2)
YELLOW       := $(shell tput setaf 3)
# BLUE         := $(shell tput setaf 4)
# MAGENTA      := $(shell tput setaf 5)
CYAN         := $(shell tput setaf 6)
RESET        := $(shell tput sgr0)

.DEFAULT_GOAL := help

# ---------------------------------------------------------------------------
# Help
# ---------------------------------------------------------------------------

.PHONY: help
help:
	@echo ""
	@echo "  $(CYAN)Bootstrap script — development targets$(RESET)"
	@echo ""
	@echo "  $(GREEN)Setup$(RESET)"
	@echo "    make deps          Install bats, shellcheck, shfmt via package manager"
	@echo "    make bats-libs     Clone bats helper libraries into tests/libs/"
	@echo ""
	@echo "  $(GREEN)Linting$(RESET)"
	@echo "    make lint          Run shellcheck against bootstrap"
	@echo "    make lint-tests    Run shellcheck against all .bats files"
	@echo "    make lint-all      Run shellcheck against bootstrap and all tests"
	@echo ""
	@echo "  $(GREEN)Formatting$(RESET)"
	@echo "    make fmt           Format bootstrap in place with shfmt"
	@echo "    make fmt-check     Check formatting without modifying files (CI-safe)"
	@echo "    make fmt-tests     Format all .bats files in place"
	@echo "    make fmt-all       Format bootstrap and all .bats files"
	@echo ""
	@echo "  $(GREEN)Testing$(RESET)"
	@echo "    make test          Run all tests (unit + integration)"
	@echo "    make test-unit     Run unit tests only"
	@echo "    make test-integ    Run integration tests only"
	@echo "    make test-file     Run a single test file  (FILE=tests/unit/foo.bats)"
	@echo "    make test-tap      Run all tests with TAP output (for CI)"
	@echo "    make test-filter   Run tests matching a pattern (FILTER='backup file')"
	@echo ""
	@echo "  $(GREEN)Combined$(RESET)"
	@echo "    make check         lint-all + fmt-check + test"
	@echo "    make ci            fmt-check + lint-all + test-tap"
	@echo "    make fix           fmt-all (format everything in place)"
	@echo ""
	@echo "  $(GREEN)Utilities$(RESET)"
	@echo "    make clean         Remove temp files and bats output artifacts"
	@echo "    make list-tests    List all test names without running them"
	@echo "    make verify-deps   Check that all required tools are installed"
	@echo ""

# ---------------------------------------------------------------------------
# Dependency installation
# ---------------------------------------------------------------------------

.PHONY: deps
deps: verify-tools-for-deps
	@echo "$(CYAN) Installing dependencies...$(RESET)"
	@if command -v mise >/dev/null 2>&1; then \
		echo "$(CYAN) Using mise...$(RESET)"; \
		mise use bats shellcheck shfmt; \
	elif command -v brew >/dev/null 2>&1; then \
		echo "$(CYAN) Using Homebrew...$(RESET)"; \
		brew install bats-core shellcheck shfmt; \
	elif command -v pacman >/dev/null 2>&1; then \
		echo "$(CYAN) Using pacman...$(RESET)"; \
		sudo pacman -S --noconfirm --needed shellcheck shfmt; \
		sudo pacman -S --noconfirm --needed bats || $(MAKE) bats-from-source; \
	elif command -v apt-get >/dev/null 2>&1; then \
		echo "$(CYAN) Using apt-get...$(RESET)"; \
		sudo apt-get update && sudo apt-get install -y shellcheck shfmt; \
		$(MAKE) bats-from-source; \
	elif command -v dnf >/dev/null 2>&1; then \
		echo "$(CYAN) Using dnf...$(RESET)"; \
		sudo dnf install -y shellcheck shfmt; \
		$(MAKE) bats-from-source; \
	else \
		echo "$(RED)✘ No supported package manager found. Install manually:$(RESET)"; \
		echo "    bats:       https://github.com/bats-core/bats-core"; \
		echo "    shellcheck: https://github.com/koalaman/shellcheck"; \
		echo "    shfmt:      https://github.com/mvdan/sh"; \
		exit 1; \
	fi
	@$(MAKE) bats-libs
	@echo "$(GREEN)✔ Dependencies installed$(RESET)"

.PHONY: bats-from-source
bats-from-source:
	@echo "$(CYAN) Installing bats-core from source...$(RESET)"
	@tmpdir=$$(mktemp -d) && \
		git clone https://github.com/bats-core/bats-core.git "$$tmpdir/bats-core" && \
		cd "$$tmpdir/bats-core" && sudo ./install.sh /usr/local && \
		rm -rf "$$tmpdir"
	@echo "$(GREEN)✔ bats-core installed$(RESET)"

.PHONY: bats-libs
bats-libs:
	@echo "$(CYAN) Installing bats helper libraries...$(RESET)"
	@mkdir -p $(LIBS_DIR)
	@for lib in bats-support bats-assert bats-file; do \
		if [ ! -d "$(LIBS_DIR)/$$lib" ]; then \
			echo "$(CYAN)   Cloning $$lib...$(RESET)"; \
			git clone "https://github.com/bats-core/$$lib.git" "$(LIBS_DIR)/$$lib"; \
		else \
			echo "$(YELLOW)   $$lib already present, pulling latest...$(RESET)"; \
			git -C "$(LIBS_DIR)/$$lib" pull --rebase --autostash; \
		fi \
	done
	@echo "$(GREEN)✔ bats libraries ready$(RESET)"

# ---------------------------------------------------------------------------
# Dependency verification
# ---------------------------------------------------------------------------

.PHONY: verify-deps
verify-deps:
	@echo "$(CYAN) Checking required tools...$(RESET)"
	@missing=0; \
	for tool in $(BATS) $(SHELLCHECK) $(SHFMT); do \
		if command -v "$$tool" >/dev/null 2>&1; then \
			version=$$($$tool --version 2>&1 | head -1); \
			echo "  $(GREEN)✔$(RESET) $$tool  ($$version)"; \
		else \
			echo "  $(RED)✘$(RESET) $$tool  (not found)"; \
			missing=1; \
		fi; \
	done; \
	for lib in bats-support bats-assert bats-file; do \
		if [ -d "$(LIBS_DIR)/$$lib" ]; then \
			echo "  $(GREEN)✔$(RESET) $$lib"; \
		else \
			echo "  $(RED)✘$(RESET) $$lib  (run: make bats-libs)"; \
			missing=1; \
		fi; \
	done; \
	[ "$$missing" -eq 0 ] || { echo "$(RED)✘ Some dependencies are missing. Run: make deps$(RESET)"; exit 1; }
	@echo "$(GREEN)✔ All dependencies present$(RESET)"

.PHONY: verify-tools-for-deps
verify-tools-for-deps:
	@for tool in git curl; do \
		command -v "$$tool" >/dev/null 2>&1 || { \
			echo "$(RED)✘ '$$tool' is required to install dependencies$(RESET)"; \
			exit 1; \
		}; \
	done

# ---------------------------------------------------------------------------
# Linting
# ---------------------------------------------------------------------------

.PHONY: lint
lint:
	@echo "$(CYAN) shellcheck $(SCRIPT)...$(RESET)"
	@$(SHELLCHECK) \
		--severity=warning \
		--shell=bash \
		--external-sources \
		$(SCRIPT) \
	&& echo "$(GREEN)✔ shellcheck passed$(RESET)" \
	|| { echo "$(RED)✘ shellcheck failed$(RESET)"; exit 1; }

.PHONY: lint-tests
lint-tests:
	@echo "$(CYAN) shellcheck tests...$(RESET)"
	@find $(TEST_DIR) -path $(LIBS_DIR) -prune -o -name '*.bats' -print | sort | while read -r f; do \
		echo "  checking $$f"; \
		$(SHELLCHECK) \
			--severity=warning \
			--shell=bash \
			--external-sources \
			"$$f" || exit 1; \
	done \
	&& echo "$(GREEN)✔ shellcheck tests passed$(RESET)" \
	|| { echo "$(RED)✘ shellcheck tests failed$(RESET)"; exit 1; }

.PHONY: lint-all
lint-all: lint lint-tests
	@echo "$(GREEN)✔ All lint checks passed$(RESET)"

# ---------------------------------------------------------------------------
# Formatting
# ---------------------------------------------------------------------------

.PHONY: fmt
fmt:
	@echo "$(CYAN) shfmt $(SCRIPT) (in place)...$(RESET)"
	@$(SHFMT) -w $(SHFMT_OPTS) $(SCRIPT) \
	&& echo "$(GREEN)✔ $(SCRIPT) formatted$(RESET)" \
	|| { echo "$(RED)✘ shfmt failed$(RESET)"; exit 1; }

.PHONY: fmt-check
fmt-check:
	@echo "$(CYAN) shfmt check (no modifications)...$(RESET)"
	@$(SHFMT) -d $(SHFMT_OPTS) $(SCRIPT) \
	&& echo "$(GREEN)✔ $(SCRIPT) formatting OK$(RESET)" \
	|| { \
		echo "$(RED)✘ $(SCRIPT) has formatting issues. Run: make fmt$(RESET)"; \
		exit 1; \
	}

.PHONY: fmt-tests
fmt-tests:
	@echo "$(CYAN) shfmt tests (in place)...$(RESET)"
	@find $(TEST_DIR) -name '*.bats' | sort | while read -r f; do \
		echo "  formatting $$f"; \
		$(SHFMT) -w $(SHFMT_OPTS) "$$f" || exit 1; \
	done \
	&& echo "$(GREEN)✔ Test files formatted$(RESET)" \
	|| { echo "$(RED)✘ shfmt failed on test files$(RESET)"; exit 1; }

.PHONY: fmt-all
fmt-all: fmt fmt-tests
	@echo "$(GREEN)✔ All files formatted$(RESET)"

# ---------------------------------------------------------------------------
# Testing
# ---------------------------------------------------------------------------

.PHONY: test
test:
	@echo "$(CYAN) Running all tests...$(RESET)"
	@$(BATS) $(BATS_OPTS) $(UNIT_DIR) $(INTEG_DIR) \
	&& echo "$(GREEN)✔ All tests passed$(RESET)" \
	|| { echo "$(RED)✘ Tests failed$(RESET)"; exit 1; }

.PHONY: test-unit
test-unit:
	@echo "$(CYAN) Running unit tests...$(RESET)"
	@$(BATS) $(BATS_OPTS) $(UNIT_DIR) \
	&& echo "$(GREEN)✔ Unit tests passed$(RESET)" \
	|| { echo "$(RED)✘ Unit tests failed$(RESET)"; exit 1; }

.PHONY: test-integ
test-integ:
	@echo "$(CYAN) Running integration tests...$(RESET)"
	@$(BATS) $(BATS_OPTS) $(INTEG_DIR) \
	&& echo "$(GREEN)✔ Integration tests passed$(RESET)" \
	|| { echo "$(RED)✘ Integration tests failed$(RESET)"; exit 1; }

.PHONY: test-file
test-file:
	@[ -n "$(FILE)" ] || { \
		echo "$(RED)✘ Specify a file: make test-file FILE=tests/unit/test_backup_file.bats$(RESET)"; \
		exit 1; \
	}
	@echo "$(CYAN) Running $(FILE)...$(RESET)"
	@$(BATS) $(BATS_OPTS) $(FILE) \
	&& echo "$(GREEN)✔ $(FILE) passed$(RESET)" \
	|| { echo "$(RED)✘ $(FILE) failed$(RESET)"; exit 1; }

.PHONY: test-tap
test-tap:
	@echo "$(CYAN) Running all tests (TAP output)...$(RESET)"
	@$(BATS) --formatter tap $(UNIT_DIR) $(INTEG_DIR)

.PHONY: test-filter
test-filter:
	@[ -n "$(FILTER)" ] || { \
		echo "$(RED)✘ Specify a filter: make test-filter FILTER='backup file'$(RESET)"; \
		exit 1; \
	}
	@echo "$(CYAN) Running tests matching: $(FILTER)...$(RESET)"
	@$(BATS) $(BATS_OPTS) --filter "$(FILTER)" $(UNIT_DIR) $(INTEG_DIR) \
	&& echo "$(GREEN)✔ Filtered tests passed$(RESET)" \
	|| { echo "$(RED)✘ Filtered tests failed$(RESET)"; exit 1; }

# ---------------------------------------------------------------------------
# Combined workflows
# ---------------------------------------------------------------------------

.PHONY: check
check: lint-all fmt-check test
	@echo "$(GREEN)✔ All checks passed$(RESET)"

.PHONY: ci
ci: fmt-check lint-all test-tap

.PHONY: fix
fix: fmt-all
	@echo "$(GREEN)✔ All files formatted$(RESET)"

# ---------------------------------------------------------------------------
# Utilities
# ---------------------------------------------------------------------------

.PHONY: list-tests
list-tests:
	@echo "$(CYAN) Listing all tests...$(RESET)"
	@$(BATS) --list $(UNIT_DIR) $(INTEG_DIR)

.PHONY: clean
clean:
	@echo "$(CYAN) Cleaning up...$(RESET)"
	@find . -name '*.bats_run' -delete
	@find . -name 'bats-*-timestamp' -delete
	@rm -rf /tmp/bats-*
	@echo "$(GREEN)✔ Clean$(RESET)"
