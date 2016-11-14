#!/bin/sh

if [ "$(uname)" = Darwin ] ; then
    #echo "verify Xcode and git are installed"
    [ "$(xcode-select -p)"  ] || xcode-select --install
    [ "$(which brew)" ] || ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

    brew update || exit
    brew doctor || exit
    brew upgrade || exit
    brew install mr vcsh
fi

if [ "$(hostname -s)" = unraid ] ; then
    cd /usr/bin && ln -sf 'vim' 'vi'
    mkdir -p ~/src
    cd ~/src || exit
    if [ ! -d "vcsh/.git" ] ; then
        git clone https://github.com/RichiH/vcsh.git
        cd /usr/local/bin && ln -s ~/src/vcsh/vcsh
    fi
    cd ~/src || exit
    if [ ! -d "myrepos/.git" ] ; then
        git clone https://github.com/joeyh/myrepos.git
        cd /usr/local/bin && ln -s ~/src/myrepos/mr
    fi
elif [ "$(uname)" = Linux ] ; then
    sudo apt-get update && sudo apt-get install git mr vcsh
fi

if [ ! -d "$HOME/.spf13-vim-3" ] ; then
    cd && curl http://j.mp/spf13-vim3 -L -o - | sh
    mv ~/.vimrc.local ~/.vimrc.local.bak
else
    cd ~/.spf13-vim-3 || exit
    git pull
    vim +BundleInstall! +BundleClean +q
fi

#if [ ! -r ~/.mrconfig ] ; then
    #cd $HOME && mr -t -i bootstrap https://raw.githubusercontent.com/tomhoover/mr-castle/master/home/.mrconfig
#fi

/usr/local/bin/vcsh clone git@github.com:tomhoover/mr-vcsh.git mr
/usr/local/bin/mr up

#add the following to crontab:
# @weekly brew list > ~/.config/homebrew/brew.installed
# @weekly brew cask list > ~/.config/homebrew/cask.installed

if [ "$(uname)" = Darwin ] ; then
    brew install "$(cat ~/.config/homebrew/brew.installed)"
    brew cask install "$(cat ~/.config/homebrew/cask.installed)"
fi

#add the following to crontab:
# @weekly comm -23 <(apt-mark showmanual | sort -u) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort -u) | grep -v ^linux-headers- > ~/.config/apt/installed

if [ ! "$(hostname -s)" = unraid ] && [ "$(uname)" = Linux ] ; then
    sudo aptitude install "$(cat ~/.config/apt/installed)"
    # sudo apt-mark manual $(cat ~/.config/apt/installed) 	# this line is probably not needed, but added for good measure
fi

echo ""
echo "logout and login to re-read configuration"
