#!/bin/bash

if [ `uname` = Darwin ] ; then
	echo "verify Xcode and git are installed"
	[ `which brew` ] || ruby -e "$(curl -fsSL https://raw.github.com/Homebrew/homebrew/go/install)"
	brew update || exit
	brew doctor || exit
	brew upgrade || exit
	brew install mr
fi

if [ `uname` = Linux ] ; then
	sudo apt-get update && sudo apt-get install git mr
fi

if [ ! -r ~/.mrconfig ] ; then
	cd $HOME && mr -t -i bootstrap https://raw.githubusercontent.com/tomhoover/mr-castle/master/home/.mrconfig
fi

source "$HOME/.homesick/repos/homeshick/homeshick.sh"
homeshick link
echo ""
echo "logout and login to re-read configuration"
