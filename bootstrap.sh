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

#add the following to crontab:
# @weekly comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) | grep -v ^linux-headers- > ~/.config/apt-mark/installed
if [ `uname` = Linux ] ; then
	sudo aptitude install $(cat ~/.config/apt-mark/installed)
	sudo apt-mark manual $(cat ~/.config/apt-mark/installed) 	# this line is probably not needed, but added for good measure
fi

echo ""
echo "logout and login to re-read configuration"
