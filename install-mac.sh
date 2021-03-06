#!/usr/bin/env bash

#Config
GITHUB_USER="lantrix"
SUBLIME_SYNC_DIR="$HOME/Dropbox/syncdata/Sublime/User"
SUBLIME_USER_DIR="$HOME/Library/Application Support/Sublime Text 3/Packages/User"
ISTAT_PREF_FILE="$HOME/Library/Preferences/com.bjango.istatmenus5.extras.plist"
ISTAT_CONFIG_URI="https://www.dropbox.com/s/sanitized/com.bjango.istatmenus5.extras.plist?dl=1"
ITERM2_PREF_FILE="$HOME/Library/Preferences/com.googlecode.iterm2.plist"
ITERM2_CONFIG_URI="https://www.dropbox.com/s/393p4o2bwbrvf9g/com.googlecode.iterm2.plist?dl=1"
VMWARE_PREF_FILE="$HOME/Library/Preferences/VMware Fusion/preferences"
VMWARE_CONFIG_URI="https://www.dropbox.com/s/kp055mivqdfxlxz/preferences?dl=1"
VAGRANT_LICENCE_URI="https://www.dropbox.com/s/sanitized/license.lic?dl=1"
RUBY_VERSION="2.2"

function execute_after_confirm {
	read -p "$1 ($2) ? [y/n] " -n 1 -r
	echo
	if [[ $REPLY =~ ^[Yy]$ ]]
	then
		shift
		for var in "$@"
		do
			echo $var
			eval $var
			return_code=$?
			if [[ $return_code != 0 ]] ; then
				exit $return_code
			fi
		done
	fi
}

for dir in "/usr/local /usr/local/bin /usr/local/include /usr/local/lib /usr/local/share"; do
	sudo chgrp admin $dir
	sudo chmod g+w $dir
done

execute_after_confirm \
	'Generate SSH keys' \
	"ssh-keygen -t rsa -C \"`uname -n`\"" \
	'pbcopy < ~/.ssh/id_rsa.pub  ##### Copied key to clipboard #####'

execute_after_confirm \
	'Install Homebrew' \
	'ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"' \
	'brew doctor'

ALL_THE_THINGS_BREW=\
'git'\
' git-flow-avh'\
' jq'\
' gpg'\
' wget'\
' node'\
' macvim --env-std --with-override-system-vim'\
' tree'

execute_after_confirm \
	'Install useful brew packages' \
	"brew install $ALL_THE_THINGS_BREW" \

#Fix node perms if needed
if [[ `ls -l /usr/local/share/systemtap | awk '{print $3}'` -ne $USER ]]
then
	sudo chown -R $USER /usr/local
fi
brew link --overwrite node

execute_after_confirm \
	'Install Brew Cask & Versions' \
	'brew install caskroom/cask/brew-cask' \
	'brew update && brew upgrade brew-cask && brew cleanup && brew cask cleanup' \
	'brew tap caskroom/versions' \
	'brew tap caskroom/fonts'

ALL_THE_THINGS_CASK=\
'sublime-text3'\
' appzapper'\
' dropbox'\
' 1password'\
' google-chrome'\
' slack'\
' intellij-idea-ce'\
' istat-menus'\
' spotify'\
' flux'\
' beyond-compare'\
' sourcetree'\
' vmware-fusion7'\
' iterm2'\
' font-source-code-pro'\
' functionflip'\
' chefdk'\
' vagrant'\
' charles'\
' remote-desktop-manager'\
' tigervnc-viewer'\
' tunnelblick'\
' visual-studio-code'

CHROME_CASK_DIR="/opt/homebrew-cask/Caskroom/google-chrome/latest/Google\ Chrome.app"
#The Mac App Store version of 1Password won't work with a Homebrew-Cask-linked Google Chrome. To bypass this limitation we move Chrome to Applications
execute_after_confirm \
	'Install useful cask packages' \
	"brew cask install $ALL_THE_THINGS_CASK" \
	"if [[ -d $CHROME_CASK_DIR ]]; then mv $CHROME_CASK_DIR /Applications/ ; fi"

execute_after_confirm \
	"Install RVM" \
	"#curl -sSL https://get.rvm.io | bash -s stable" \
	"curl -sSL https://rvm.io/mpapis.asc | gpg --import -" \
	"\\curl -sSL https://get.rvm.io | bash -s stable" \
	"source $HOME/.rvm/scripts/rvm" \
	"rvm install $RUBY_VERSION" \
	"rvm --default use $RUBY_VERSION"

execute_after_confirm \
	"Install Homesick" \
	'gem install homesick' \
	'homesick clone lantrix/dotfiles' \
	'homesick symlink dotfiles' \
	'homesick clone lantrix/dotfiles-vim' \
	'homesick symlink dotfiles-vim' \
	'homesick clone lantrix/powerline-config' \
	'homesick symlink powerline-config' \
	'vim +PluginInstall +qall'

execute_after_confirm \
	"Install GO" \
	"mkdir $HOME/Go" \
	"mkdir -p $HOME/Go/src/github.com/$GITHUB_USER" \
	"export GOPATH=$HOME/Go" \
	"export GOROOT=/usr/local/opt/go/libexec" \
	"export PATH=$PATH:$GOPATH/bin" \
	"export PATH=$PATH:$GOROOT/bin" \
	"brew install go"

#Sublime Sync Setting
if [[ -d /opt/homebrew-cask/Caskroom/sublime-text3 ]]
then
	if [[ ! -L $SUBLIME_USER_DIR ]]; then
		echo "Installing Package Control"
		curl --progress-bar -L -o $HOME/Library/Application\ Support/Sublime\ Text\ 3/Installed\ Packages/Package\ Control.sublime-package https://packagecontrol.io/Package%20Control.sublime-package

		echo "Setup Sublime Text 3 Userdata Sync"
		open -a "Sublime Text"
		sleep 2
		kill -9 `ps -ef |grep Sublime |egrep -v 'grep|plugin' | awk '{print $2}'`
		read -p "Press [Enter] key after dropbox configured to sync Sublime user data to $SUBLIME_SYNC_DIR"
		if [[ -d $SUBLIME_SYNC_DIR && -d $SUBLIME_USER_DIR ]]
		then
			rm -r "$SUBLIME_USER_DIR" && ln -s $SUBLIME_SYNC_DIR "$SUBLIME_USER_DIR"
		else
			echo Skipping Sublime Sync Setup - required dirs missing
		fi
	else
		echo Skipping Sublime Sync Setup - already in place
	fi
fi

#iStat Config
if [[ -d /opt/homebrew-cask/Caskroom/istat-menus ]]
then
	echo "Setup iStat Menus config"
	if [[ ! -f $ISTAT_PREF_FILE ]]
	then
		curl --progress-bar -L -o ${ISTAT_PREF_FILE} ${ISTAT_CONFIG_URI}
	else
		echo Existing iStat prefs left alone at $ISTAT_PREF_FILE
	fi
fi

#iStat Config
if [[ -d /opt/homebrew-cask/Caskroom/istat-menus ]]
then
	echo "Setup iStat Menus config"
	if [[ ! -f $ISTAT_PREF_FILE ]]
	then
		curl --progress-bar -L -o ${ISTAT_PREF_FILE} ${ISTAT_CONFIG_URI}
	else
		echo Existing iStat prefs left alone at $ISTAT_PREF_FILE
	fi
fi

#iTerm2 Config
if [[ -d /opt/homebrew-cask/Caskroom/iterm2 ]]
then
	echo "Setup iTerm2 config"
	if [[ ! -f $ITERM2_PREF_FILE ]]
	then
		curl --progress-bar -L -o ${ITERM2_PREF_FILE} ${ITERM2_CONFIG_URI}
		curl -L https://raw.githubusercontent.com/chriskempson/base16-iterm2/master/base16-ocean.dark.itermcolors > /tmp/base16-ocean.dark.itermcolors
		open /tmp/base16-ocean.dark.itermcolors
	else
		echo Existing iStat prefs left alone at $ITERM2_PREF_FILE
	fi
fi

#Vmware Fusion Config
if [[ -d /opt/homebrew-cask/Caskroom/vmware-fusion7 ]]
then
	echo "Setup VMWare config"
	if [[ ! -f $VMWARE_PREF_FILE ]]
	then
		curl --progress-bar -L -o ${VMWARE_PREF_FILE} ${VMWARE_CONFIG_URI}
	else
		echo Existing VMWare prefs left alone at $VMWARE_PREF_FILE
	fi
fi

#Vagrant Config/Licence
if [[ -d /opt/homebrew-cask/Caskroom/vagrant ]]
then
	echo "Install Vagrant VMWare plugin"
	curl --progress-bar -L -o /tmp/license.lic ${VAGRANT_LICENCE_URI}
	vagrant plugin install vagrant-vmware-fusion
	if [[ -f /tmp/license.lic ]]
	then
		vagrant plugin license vagrant-vmware-fusion /tmp/license.lic
	fi
fi

execute_after_confirm \
        "Install CoffeeScript" \
        "npm install -g coffee-script"

execute_after_confirm \
        "Install esvalidate npm for jsvalidate sublime plugin \
        "npm install -g esvalidate"

execute_after_confirm \
	'Install Python PIP' \
	"curl --progress-bar -L -o /tmp/get-pip.py https://bootstrap.pypa.io/get-pip.py" \
	"sudo -H python /tmp/get-pip.py"

execute_after_confirm \
	'Install AWS CLI' \
	"sudo -H pip install awscli" \
	"complete -C '`which aws_completer`' aws"

execute_after_confirm \
	'Install Powerline' \
	"pip install --user powerline-status" \
	"pip install --user pyuv"

