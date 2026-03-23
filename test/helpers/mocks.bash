# tests/helpers/mocks.bash — shared across all test files
load '../libs/bats-support/load'
load '../libs/bats-assert/load'

# ---------------------------------------------------------------------------
# Repo root — resolved at load time using BATS_TEST_DIRNAME, which bats sets
# to the directory containing the test file. Both test/unit/ and
# test/integration/ are two levels below the repo root.
# MOCK_BIN is NOT set here because BATS_TEST_TMPDIR is not available at
# load time — set it in each test file's setup() instead.
# ---------------------------------------------------------------------------
export REPO_ROOT
REPO_ROOT="$(cd "${BATS_TEST_DIRNAME}/../.." && pwd)"

# ---------------------------------------------------------------------------
# uname stubs
# ---------------------------------------------------------------------------

stub_uname_darwin() {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  cat >"${BATS_TEST_TMPDIR}/bin/uname" <<'EOF'
#!/bin/bash
echo "Darwin"
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/uname"
}

stub_uname_linux() {
  mkdir -p "${BATS_TEST_TMPDIR}/bin"
  cat >"${BATS_TEST_TMPDIR}/bin/uname" <<'EOF'
#!/bin/bash
echo "Linux"
EOF
  chmod +x "${BATS_TEST_TMPDIR}/bin/uname"
}

stub_uname_arch() {
  stub_uname_linux
  mkdir -p "${BATS_TEST_TMPDIR}/etc"
  echo "ID=arch" >"${BATS_TEST_TMPDIR}/etc/os-release"
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release"
}

stub_uname_debian() {
  stub_uname_linux
  mkdir -p "${BATS_TEST_TMPDIR}/etc"
  printf 'ID=debian\nVERSION_CODENAME=bookworm\n' >"${BATS_TEST_TMPDIR}/etc/os-release"
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release"
}

stub_uname_fedora() {
  stub_uname_linux
  mkdir -p "${BATS_TEST_TMPDIR}/etc"
  echo "ID=fedora" >"${BATS_TEST_TMPDIR}/etc/os-release"
  export OS_RELEASE="${BATS_TEST_TMPDIR}/etc/os-release"
}
