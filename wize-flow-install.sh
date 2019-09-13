#!/usr/bin/env bash

function usage() {
    echo "wize-flow-install.sh <bash|joker> [--force]" 1>&2
}

[[ "$#" != "1" && "$#" != "2" ]] && usage && exit 1

if [[ -d "/usr/local/opt/wize-flow" && "$2" != "--force" ]]; then 
    echo "Wize-flow has been already installed. Run wize-flow-uninstall.sh to uninstall" 1>&2
    exit 1
fi

if [[ "$1" != "bash" && "$1" != "joker" ]]; then
    usage
    exit 1
fi

#TODO: Catch and handle manual aborts on all scripts
if [[ $(uname -a | grep 'Darwin') ]]; then
    
    if [ ! $(which brew) ]; then
        echo "Installing homebrew..."
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
    fi

    echo "Updating brew and installing dependencies..."
    brew update &>/dev/null
    brew install git-flow-avh &>/dev/null
    case "$1" in
        bash)
            brew install hub &>/dev/null
            ;;
        joker)
            brew install candid82/brew/joker &>/dev/null
            ;;
    esac

elif [[ $(uname -a | grep 'Linux') ]]; then

    # Linuxbrew will help with Linux interop
    # It's too fucking slow though
    echo "Installing linuxbrew dependencies..."
    [[ $(which apt-get) ]] && sudo apt-get update && sudo apt-get install -y build-essential curl file git
    [[ $(which yum) ]] && sudo yum update && sudo yum groupinstall 'Development Tools' && sudo yum install -y curl file git libxcrypt-compat

    if [ ! $(which brew) ]; then
        echo "Installing linuxbrew..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" </dev/null
        test -d ~/.linuxbrew && eval $(~/.linuxbrew/bin/brew shellenv)
        test -d /home/linuxbrew/.linuxbrew && eval $(/home/linuxbrew/.linuxbrew/bin/brew shellenv)
        test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
        echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
    fi
    
    echo "Updating brew and installing dependencies..."
    brew update
    brew install git-flow-avh
    case "$1" in
        bash)
            brew install python@2
            brew install hub
            ;;
        joker)
            brew install candid82/brew/joker
            ;;
    esac
else
    echo "Only Linux based distros are supported" 1>&2
    exit 1
fi

echo "Installing wize-flow..."
readonly init_script_relative_path="$(dirname $0)"/src/"$1"

sudo chown $(whoami) /usr/local /usr/local/bin
mkdir -p /usr/local/opt/wize-flow
# Order matters in the next two commands. We override git-wize-flow on purpose
cp -f "$init_script_relative_path"/../common/* /usr/local/opt/wize-flow
cp -f "$init_script_relative_path"/* /usr/local/opt/wize-flow

# This will extend git with 'git wize-flow'. See: https://stackoverflow.com/questions/10978257/extending-git-functionality
cp -f "$init_script_relative_path"/../common/git-wize-flow /usr/local/bin

echo "Wize-flow was installed successfully on /usr/local/opt/wize-flow"

