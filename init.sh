#!/bin/bash

# CONSTANTS
BASE_SCRIPTS_DIR="$HOME/scripts"
DOCKER_SCRIPTS_DIR="${BASE_SCRIPTS_DIR}/docker"
GIT_SCRIPTS_DIR="${BASE_SCRIPTS_DIR}/git"
GENERAL_SCRIPTS_DIR="${BASE_SCRIPTS_DIR}/general"

SCRIPT_RC="${BASE_SCRIPTS_DIR}/.scriptrc"

## Figure out Operating System / Platform
PLATFORM="$(uname -s)"
LINUX=false
MAC=false
WINDOWS=false
WSL=false

if [[ "$(echo $PLATFORM | cut -c1-5)" = "Linux" ]]; then
    LINUX=true
elif [ "$(echo $PLATFORM | cut -c1-6)" == "Darwin" ]; then
    MAC=true
elif [ "$(echo $PLATFORM | cut -c1-10)" == "MINGW32_NT" ]; then
    WINDOWS=true
elif [ "$(echo $PLATFORM | cut -c1-10)" == "MINGW64_NT" ]; then
    WINDOWS=true
fi
if [ -d /proc/version ] && [ grep -q Microsoft /proc/version ]; then
	WSL=true
fi

## Startup File
if [[ "$LINUX" == true ]]; then
	STARTUP_FILE="$HOME/.bashrc"
elif [[ "$MAC" == true ]]; then
	STARTUP_FILE="$HOME/.bash_profile"
fi


# SETUP LINUX STUFF

## INSTALL SCRIPTS

### Create Script Directories
mkdir -p $BASE_SCRIPTS_DIR
mkdir -p $DOCKER_SCRIPTS_DIR
mkdir -p $GIT_SCRIPTS_DIR
mkdir -p $GENERAL_SCRIPTS_DIR

### COPY SCRIPTS

#### Docker & Docker-Compose Scripts
cp -rn ./scripts/docker/ $DOCKER_SCRIPTS_DIR

#### Git Scripts
cp -rn ./scripts/git/ $GIT_SCRIPTS_DIR

### General Scripts
cp -rn ./scripts/general/ $GENERAL_SCRIPTS_DIR

### UPDATE PATH
SOURCE_SCRIPT="=== Life Knowledge Config ==="
### If it's not already in the startup file, make sure to source $SCRIPT_RC
if [ ! -e $STARTUP_FILE ]; then
	touch $STARTUP_FILE
fi
if ! grep -Fq "=== Life Knowledge Startup Script ===" "$STARTUP_FILE"; then
	echo "=== Life Knowledge Startup Script ===" >> "$STARTUP_FILE"
	echo "source $SCRIPT_RC" >> "$STARTUP_FILE"
	mkdir -p $SCIPT_RC
fi

# Exports by expanding BASE_SCRIPTS_DIR but not $PATH
SOURCE_SCRIPT="${SOURCE_SCRIPT}"$'\n'"export PATH=\"$BASE_SCRIPTS_DIR"':$PATH"'

## SET DEFAULT ENV VARS

# SETUP WINDOWS PROGRAMS #
# ngrok #
# code editor? #
# lice cap # For capturing gifs

## Config Files
tput setaf 6; echo 'Setting configuration settings'; tput sgr0
### Vim
# TODO: Fix these for Windows
if [ ! -e "$HOME/.vimrc" ]; then
	# Try Hard link to main .vimrc
	ln ./config/.vimrc ~/
	if [[ $? == 1 ]]; then
		cp ./config/.vimrc ~/.vimrc
		tput setaf 6; echo 'Could not hard link .vimrc, copying instead'; tput sgr0
	fi
fi
# Soft link to the config/.vim directory
ln -s ./.vim ~/

# Soft link for general config
ln -s ./config/.config ~/

### Tmux
cp -rn ./config/tmux/ ~/
##### Install TPM
if [ ! -d "~/.tmux/plugins/tpm" ]; then
	git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

### Git
cp -rn ./config/git/ ~/
#### Git Completion in bash
curl https://raw.githubusercontent.com/git/git/master/contrib/completion/git-completion.bash -o ~/.git-completion.bash
# $_ is the last argument to the previous command (in this case, the `test` command)
SOURCE_SCRIPT="${SOURCE_SCRIPT}"$'\n'"test -f $HOME/.git-completion.bash && . $_" 

## WSL (Windows Subsystem for Linux) Stuff
# If we're in WSL, we also need to "fix" Docker
if [[ "$WSL" == true ]]; then
	tput setaf 6; echo 'Initializing WSL settings...'; tput sgr0
	SOURCE_SCRIPT="${SOURCE_SCRIPT}"$'\n'"export DOCKER_HOST=\"tcp://localhost:2375\""
	### Fix WSL using /mnt/c instead of /c
	tput setaf 7
	echo 'Fixing Docker mounting requires manual intervention'
	echo 'Copy the following 6 lines into ~/.bashrc and fill in the password'
	echo 'You can also do this manually when you open WSL if you prefer not to have your password in plaintext'
	tput sgr0
	echo
	echo "# Create the /c directory if it doesn't exist"
	echo 'mkdir -p /c'
	echo "# bind mount the default /mnt/c onto just /c"
	echo "echo 'YOUR_PASSWORD_HERE' | sudo -S -p ' ' mount --bind /mnt/c /c"
	echo 'cd ${PWD#/mnt}'
	echo 'echo # for formatting'
	echo ''

	#### Fix docker mounting config with powershell script
	#### Auto-fix outside of WSL if possible
fi

# Write out SCRIPT_RC
echo "$SOURCE_SCRIPT" > $SCRIPT_RC

## Detect operating systems
if [[ "$MAC" == true ]]; then
	echo "Mac OS X; Performing brew commands"
	./brewing.sh
elif [[ "$LINUX" == true ]]; then
	echo "GNU/Linux"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW32_NT" ]; then
	echo "MINGW32_NT"
elif [ "$(expr substr $(uname -s) 1 10)" == "MINGW64_NT" ]; then
	echo "MINGW64_NT"
else
	echo "Unknown operating system..."
fi
