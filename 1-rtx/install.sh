#!/bin/sh

# update script via:
#   mv install.sh install.sh.bak
#   curl https://rtx.pub/install.sh.sig | gpg --decrypt > install.sh

set -eu

#region logging setup
if [ "${RTX_DEBUG-}" = "true" ] || [ "${RTX_DEBUG-}" = "1" ]; then
	debug() {
		echo "$@" >&2
	}
else
	debug() {
		:
	}
fi

if [ "${RTX_QUIET-}" = "1" ] || [ "${RTX_QUIET-}" = "true" ]; then
	info() {
		:
	}
else
	info() {
		echo "$@" >&2
	}
fi

error() {
	echo "$@" >&2
	exit 1
}
#endregion

#region environment setup
get_os() {
	os="$(uname -s)"
	if [ "$os" = Darwin ]; then
		echo "macos"
	elif [ "$os" = Linux ]; then
		echo "linux"
	else
		error "unsupported OS: $os"
	fi
}

get_arch() {
	arch="$(uname -m)"
	if [ "$arch" = x86_64 ]; then
		echo "x64"
	elif [ "$arch" = aarch64 ] || [ "$arch" = arm64 ]; then
		echo "arm64"
	else
		error "unsupported architecture: $arch"
	fi
}

shasum_bin() {
  if command -v shasum >/dev/null 2>&1; then
    echo "shasum"
  elif command -v sha256sum >/dev/null 2>&1; then
    echo "sha256sum"
  else
    error "rtx install requires shasum or sha256sum but neither is installed. Aborting."
  fi
}

get_checksum() {
	os="$(get_os)"
	arch="$(get_arch)"

	checksum_linux_x86_64="51de71dddb0e541e861f8c79ff0e6eecbf9bd6dfe218582c02673aeb1a91e814  ./rtx-v2023.10.2-linux-x64.tar.gz"
	checksum_linux_arm64="1cd49c3e659912864a7e933e2218a74b0210f754cee330fcd4f260e75cb13b82  ./rtx-v2023.10.2-linux-arm64.tar.gz"
	checksum_macos_x86_64="a110d579276bce3e28e0eaa9b13a9b865956307cec3bed3c413a4a8778d21cda  ./rtx-v2023.10.2-macos-x64.tar.gz"
	checksum_macos_arm64="e4dac7a9caf6cc9950d6e15dde6da347881fd8d2bd9fd7f32502326ac0ae9b60  ./rtx-v2023.10.2-macos-arm64.tar.gz"

	if [ "$os" = "linux" ] && [ "$arch" = "x64" ]; then
		echo "$checksum_linux_x86_64"
	elif [ "$os" = "linux" ] && [ "$arch" = "arm64" ]; then
		echo "$checksum_linux_arm64"
	elif [ "$os" = "macos" ] && [ "$arch" = "x64" ]; then
		echo "$checksum_macos_x86_64"
	elif [ "$os" = "macos" ] && [ "$arch" = "arm64" ]; then
		echo "$checksum_macos_arm64"
	else
		warn "no checksum for $os-$arch"
	fi
}

#endregion

download_file() {
	url="$1"
	filename="$(basename "$url")"
	cache_dir="$(mktemp -d)"
	file="$cache_dir/$filename"

	info "rtx: installing rtx..."

	if command -v curl >/dev/null 2>&1; then
		debug ">" curl -fLlSso "$file" "$url"
		curl -fLlSso "$file" "$url"
	else
		if command -v wget >/dev/null 2>&1; then
			debug ">" wget -qO "$file" "$url"
			stderr=$(mktemp)
			wget -O "$file" "$url" >"$stderr" 2>&1 || error "wget failed: $(cat "$stderr")"
		else
			error "rtx standalone install requires curl or wget but neither is installed. Aborting."
		fi
	fi

	echo "$file"
}

install_rtx() {
	# download the tarball
	version="v2023.10.2"
	os="$(get_os)"
	arch="$(get_arch)"
	xdg_data_home="${XDG_DATA_HOME:-$HOME/.local/share}"
	install_path="${RTX_INSTALL_PATH:-$xdg_data_home/rtx/bin/rtx}"
	install_dir="$(dirname "$install_path")"
	tarball_url="https://github.com/jdx/rtx/releases/download/${version}/rtx-${version}-${os}-${arch}.tar.gz"

	cache_file=$(download_file "$tarball_url")
	debug "rtx-setup: tarball=$cache_file"

	debug "validating checksum"
	cd "$(dirname "$cache_file")" && get_checksum | "$(shasum_bin)" -c >/dev/null

	# extract tarball
	mkdir -p "$install_dir"
	rm -rf "$install_path"
	cd "$(mktemp -d)"
	tar -xzf "$cache_file"
	mv rtx/bin/rtx "$install_path"
	info "rtx: installed successfully to $install_path"
}

after_finish_help() {
	case "${SHELL:-}" in
	*/zsh)
		info "rtx: run the following to activate rtx in your shell:"
		info "echo \"eval \\\"\\\$($install_path activate zsh)\\\"\" >> ~/.zshrc"
		info ""
		info "rtx: this must be run in order to use rtx in the terminal"
		info "rtx: run \`rtx doctor\` to verify this is setup correctly"
		;;
	*/bash)
		info "rtx: run the following to activate rtx in your shell:"
		info "echo \"eval \\\"\\\$($install_path activate bash)\\\"\" >> ~/.bashrc"
		info ""
		info "rtx: this must be run in order to use rtx in the terminal"
		info "rtx: run \`rtx doctor\` to verify this is setup correctly"
		;;
	*/fish)
		info "rtx: run the following to activate rtx in your shell:"
		info "echo \"$install_path activate fish | source\" >> ~/.config/fish/config.fish"
		info ""
		info "rtx: this must be run in order to use rtx in the terminal"
		info "rtx: run \`rtx doctor\` to verify this is setup correctly"
		;;
	*)
		info "rtx: run \`$install_path --help\` to get started"
		;;
	esac
}

install_rtx
after_finish_help
