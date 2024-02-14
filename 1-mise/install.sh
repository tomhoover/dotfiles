#!/bin/sh
set -eu

#region logging setup
if [ "${MISE_DEBUG-}" = "true" ] || [ "${MISE_DEBUG-}" = "1" ]; then
	debug() {
		echo "$@" >&2
	}
else
	debug() {
		:
	}
fi

if [ "${MISE_QUIET-}" = "1" ] || [ "${MISE_QUIET-}" = "true" ]; then
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
	musl=""
	if type ldd >/dev/null 2>/dev/null; then
		libc=$(ldd /bin/ls | grep 'musl' | head -1 | cut -d ' ' -f1)
		if [ -z "$libc" ]; then
			musl="-musl"
		fi
	fi
	arch="$(uname -m)"
	if [ "$arch" = x86_64 ]; then
		echo "x64$musl"
	elif [ "$arch" = aarch64 ] || [ "$arch" = arm64 ]; then
		echo "arm64$musl"
	elif [ "$arch" = armv6l ]; then
		echo "armv6$musl"
	elif [ "$arch" = armv7l ]; then
		echo "armv7$musl"
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
		error "mise install requires shasum or sha256sum but neither is installed. Aborting."
	fi
}

get_checksum() {
	os="$(get_os)"
	arch="$(get_arch)"

	checksum_linux_x86_64="f3d74747ea983d9c0cfe87aaf637fa7eaeacaa712aa2355fbfc5fa3f9fb458f2  ./mise-v2024.2.15-linux-x64.tar.gz"
	checksum_linux_x86_64_musl="29757c3aedd8bd2490ea427fd7e8c737c1926dcf8443cc1cbfa49310ab796622  ./mise-v2024.2.15-linux-x64-musl.tar.gz"
	checksum_linux_arm64="9ae2aad4f3e5b947b2a8f1625abe4278f52a80ad0e8039ef7733755103a366b9  ./mise-v2024.2.15-linux-arm64.tar.gz"
	checksum_linux_arm64_musl="7a9bc2444adc17c727c6144cc86888cd2117845022fc61da63b891181df52ec7  ./mise-v2024.2.15-linux-arm64-musl.tar.gz"
	checksum_linux_armv6="4ec6388327d5e91fd0affb77d505b302a19efef3f3ba0cd9f762d54c40d3460a  ./mise-v2024.2.15-linux-armv6.tar.gz"
	checksum_linux_armv6_musl="ad78919fea61e4f52a29bbbd910538c4e50cbffea21f3e3b6fcebc4c44feff77  ./mise-v2024.2.15-linux-armv6-musl.tar.gz"
	checksum_linux_armv7="a0890cad9ff368ed4628d63a07f519ec546f4b753884ddff351cd6d499a13d0c  ./mise-v2024.2.15-linux-armv7.tar.gz"
	checksum_linux_armv7_musl="88e731e9862d4f78f36b9e15ba6f4966472db5baa53c09085d974070a6c31ca6  ./mise-v2024.2.15-linux-armv7-musl.tar.gz"
	checksum_macos_x86_64="db7dbcf00dd9b01e7433313679358a1174eee1912be074d11fa319a06510079b  ./mise-v2024.2.15-macos-x64.tar.gz"
	checksum_macos_arm64="ee97973c7609b43c2b469c76942498feb22b00d41a1fd1b89add88790ba436f6  ./mise-v2024.2.15-macos-arm64.tar.gz"

	if [ "$os" = "linux" ]; then
		if [ "$arch" = "x64" ]; then
			echo "$checksum_linux_x86_64"
		elif [ "$arch" = "x64-musl" ]; then
			echo "$checksum_linux_x86_64_musl"
		elif [ "$arch" = "arm64" ]; then
			echo "$checksum_linux_arm64"
		elif [ "$arch" = "arm64-musl" ]; then
			echo "$checksum_linux_arm64_musl"
		elif [ "$arch" = "armv6" ]; then
			echo "$checksum_linux_armv6"
		elif [ "$arch" = "armv6-musl" ]; then
			echo "$checksum_linux_armv6_musl"
		elif [ "$arch" = "armv7" ]; then
			echo "$checksum_linux_armv7"
		elif [ "$arch" = "armv7-musl" ]; then
			echo "$checksum_linux_armv7_musl"
		else
			warn "no checksum for $os-$arch"
		fi
	elif [ "$os" = "macos" ]; then
		if [ "$arch" = "x64" ]; then
			echo "$checksum_macos_x86_64"
		elif [ "$arch" = "arm64" ]; then
			echo "$checksum_macos_arm64"
		else
			warn "no checksum for $os-$arch"
		fi
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

	info "mise: installing mise..."

	if command -v curl >/dev/null 2>&1; then
		debug ">" curl -#fLo "$file" "$url"
		curl -#fLo "$file" "$url"
	else
		if command -v wget >/dev/null 2>&1; then
			debug ">" wget -qO "$file" "$url"
			stderr=$(mktemp)
			wget -O "$file" "$url" >"$stderr" 2>&1 || error "wget failed: $(cat "$stderr")"
		else
			error "mise standalone install requires curl or wget but neither is installed. Aborting."
		fi
	fi

	echo "$file"
}

install_mise() {
	# download the tarball
	version="v2024.2.15"
	os="$(get_os)"
	arch="$(get_arch)"
	install_path="${MISE_INSTALL_PATH:-$HOME/.local/bin/mise}"
	install_dir="$(dirname "$install_path")"
	tarball_url="https://github.com/jdx/mise/releases/download/${version}/mise-${version}-${os}-${arch}.tar.gz"

	cache_file=$(download_file "$tarball_url")
	debug "mise-setup: tarball=$cache_file"

	debug "validating checksum"
	cd "$(dirname "$cache_file")" && get_checksum | "$(shasum_bin)" -c >/dev/null

	# extract tarball
	mkdir -p "$install_dir"
	rm -rf "$install_path"
	cd "$(mktemp -d)"
	tar -xzf "$cache_file"
	mv mise/bin/mise "$install_path"
	info "mise: installed successfully to $install_path"
}

after_finish_help() {
	case "${SHELL:-}" in
	*/zsh)
		info "mise: run the following to activate mise in your shell:"
		info "echo \"eval \\\"\\\$($install_path activate zsh)\\\"\" >> \"${ZDOTDIR-$HOME}/.zshrc\""
		info ""
		info "mise: this must be run in order to use mise in the terminal"
		info "mise: run \`mise doctor\` to verify this is setup correctly"
		;;
	*/bash)
		info "mise: run the following to activate mise in your shell:"
		info "echo \"eval \\\"\\\$($install_path activate bash)\\\"\" >> ~/.bashrc"
		info ""
		info "mise: this must be run in order to use mise in the terminal"
		info "mise: run \`mise doctor\` to verify this is setup correctly"
		;;
	*/fish)
		info "mise: run the following to activate mise in your shell:"
		info "echo \"$install_path activate fish | source\" >> ~/.config/fish/config.fish"
		info ""
		info "mise: this must be run in order to use mise in the terminal"
		info "mise: run \`mise doctor\` to verify this is setup correctly"
		;;
	*)
		info "mise: run \`$install_path --help\` to get started"
		;;
	esac
}

install_mise
after_finish_help
