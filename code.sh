#!/usr/bin/env sh

declare -A categories=(
	["rust"]="rust-lang.rust-analyzer tamasfe.even-better-toml serayuzgur.crates"
	["go"]="golang.go"
	["dev"]="usernamehw.errorlens"
	["misc"]="DotJoshJohnson.xml rangav.vscode-thunder-client"
	["java"]="redhat.java vscjava.vscode-java-test vscjava.vscode-java-dependency vscjava.vscode-maven vscjava.vscode-java-debug vscjava.vscode-java-pack"
	["spring"]="vmware.vscode-spring-boot vscjava.vscode-spring-boot-dashboard vscjava.vscode-spring-initializr vmware.vscode-boot-dev-pack"
)

if [ $# -eq 0 ]; then
	echo "no category provided"
	echo "available categories: ${!categories[@]}"
	exit
fi

declare -A dependencies=(
	["rust"]="rust-analyzer rustup"
	["go"]="go gopls"
	["java"]="jdk-openjdk openjdk-src openjdk-doc"
)

function install() {
    local EXT_ID=$1
    code --list-extensions | grep "$EXT_ID" >/dev/null 2>&1 && echo "skip $EXT_ID" && return
    echo "extension installation $EXT_ID"
    code --install-extension "$EXT_ID"
}

for arg in "$@"
do
	if [ ! "${categories[$arg]}" ]; then
		echo "unknwon category $arg"
		echo "available categories: ${!categories[@]}"
		exit
	fi
done

for arg in "$@"
do
	deps=${dependencies[$arg]}
	if [ -n "$deps" ]; then
		for dep in ${deps[@]}
		do
			pacman -Qi "$dep" >/dev/null 2>&1 || apps="$apps $dep"
		done
		if [ -n "$apps" ]; then
			sudo pacman --needed --noconfirm -S $apps
		fi
	fi

	extensions=${categories[$arg]}
	for ext in ${extensions[@]}
	do
		install "$ext"
	done
done
