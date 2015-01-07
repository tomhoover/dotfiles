#!/bin/sh

if [ `uname` == Linux ] ; then
	apt-get install git mr
	if [ ! -r ~/.mrconfig ] ; then
		mr bootstrap https://github.com/tomhoover/mr-castle/blob/master/home/.mrconfig
	fi
fi

source "$HOME/.homesick/repos/homeshick/homeshick.sh"
homeshick link
echo ""
echo "logout and login to re-read configuration"
