#!/bin/bash

if [ `uname` = Linux ] ; then
	sudo apt-get update && sudo apt-get install git mr
	if [ ! -r ~/.mrconfig ] ; then
		cd $HOME && mr -t -i bootstrap https://raw.githubusercontent.com/tomhoover/mr-castle/master/home/.mrconfig
	fi
fi

source "$HOME/.homesick/repos/homeshick/homeshick.sh"
homeshick link
echo ""
echo "logout and login to re-read configuration"
