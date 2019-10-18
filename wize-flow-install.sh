#!/usr/bin/env bash

function usage() {
    echo "wize-flow-install.sh <bash|joker> [<custom-directory>] [--force] [--ignore-dependencies]" 1>&2
}

macos_install() {

    local -r implementation="$1"
    if [ ! "$(command -v brew)" ]; then
        echo "Installing homebrew..."
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
    fi

    echo "Updating brew and installing dependencies..."
    brew update &>/dev/null
    brew install git-flow-avh &>/dev/null
    case "$implementation" in
        bash)
            brew install hub &>/dev/null
            ;;
        joker)
            brew install candid82/brew/joker &>/dev/null
            ;;
    esac

}

linux_install() {

    # Linuxbrew will help with Linux interop
    # It's too fucking slow though
    echo "Installing linuxbrew dependencies..."
    if [[ $(command -v apt-get) ]]; then
        sudo apt-get update && \
        sudo apt-get install -y build-essential curl file git
    fi
    if [[ $(command -v yum) ]]; then
        sudo yum update && \
        sudo yum groupinstall 'Development Tools' && \
        sudo yum install -y curl file git libxcrypt-compat
    fi

    if [ ! "$(command -v brew)" ]; then
        echo "Installing linuxbrew..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/Linuxbrew/install/master/install.sh)" </dev/null
        test -d ~/.linuxbrew && eval "$(~/.linuxbrew/bin/brew shellenv)"
        test -d /home/linuxbrew/.linuxbrew && eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
        test -r ~/.bash_profile && echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.bash_profile
        echo "eval \$($(brew --prefix)/bin/brew shellenv)" >>~/.profile
    fi
    
    echo "Updating brew and installing dependencies..."
    brew update
    brew install git-flow-avh
    case "$implementation" in
        bash)
            brew install python@2
            brew install hub
            ;;
        joker)
            brew install candid82/brew/joker
            ;;
    esac

}

check_sudo() {
    echo "Validating sudo access..."
    if ! sudo -v; then
        echo "You don't have sudo access" 1>&2
        exit 1
    fi
}

main() {

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Do not catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set +o pipefail

    if [[ "$#" != "1" && "$#" != "2" && "$#" != "3" && "$#" != "4" ]]; then
        usage
        exit 1
    fi

    local -r implementation="$1"
    if [[ "$implementation" != "bash" && "$implementation" != "joker" ]]; then
        echo "Unsupported implementation $implementation" 1>&2
        usage
        exit 1
    fi

    local custom=false
    local installation_dir="/usr/local/opt/wize-flow"
    if [[ "${2-undefined}" != "undefined" && "$2" != "--force" && "$2" != "--ignore-dependencies" ]]; then
        if [[ ! -d "$2" ]]; then
            echo "$2 is not a directory" 1>&2
            usage
            exit 1
        fi
        custom=true
        installation_dir="$(cd "$2"; pwd)/wize-flow"
        if [[ "$installation_dir" == "/usr/local/opt/wize-flow" ]]; then
            custom=false
        fi
    fi

    local forced=false
    if [[ "$*" == *"--force"* ]]; then
        forced=true
    fi

    local ignore_deps=false
    if [[ "$*" == *"--ignore-dependencies"* ]]; then
        if ! git flow 2>&1 | grep -q usage; then
            echo "You cannot use --ignore-dependencies if you don't already have them installed" 1>&2
            exit 1
        fi
        ignore_deps=true
    fi

    if [[ -d "$installation_dir" && "$forced" == "false" ]]; then 
        echo "Wize-flow has been already installed on $installation_dir" 1>&2
        echo "Run wize-flow-uninstall.sh to uninstall" 1>&2
        exit 1
    fi

    if [[ "$ignore_deps" == "false" || "$custom" == "false" ]]; then
        check_sudo
    fi

    if [[ "$ignore_deps" == "false" ]]; then
        if uname -a | grep -q 'Darwin'; then
            macos_install "$implementation"
        elif uname -a | grep -q 'Linux'; then
            linux_install "$implementation"
        else
            echo "Only Linux based distros are supported" 1>&2
            exit 1
        fi
    fi

    echo "Installing wize-flow..."
    readonly init_script_relative_path="$(dirname "$0")"/src/"$1"

    local binary_installation_dir="/usr/local/bin"
    if [[ "$custom" == "true" ]]; then
        binary_installation_dir="$installation_dir/bin"
        mkdir -p "$binary_installation_dir"
    else
        sudo chown "$(whoami)" "$binary_installation_dir" 
    fi
    mkdir -p "$installation_dir"

    cp -f "$init_script_relative_path"/../common/* "$installation_dir"
    cp -f "$init_script_relative_path"/* "$installation_dir"
    rm -f "$installation_dir"/git-wize-flow

    # This will extend git with 'git wize-flow'
    # See: https://stackoverflow.com/questions/10978257/extending-git-functionality
    cp -f "$init_script_relative_path"/../common/git-wize-flow "$binary_installation_dir" 

    echo
    echo "wize-flow was installed successfully on $installation_dir"
    echo "git-wize-flow binary was installed on $binary_installation_dir"
    if [[ "$custom" == "true" ]]; then
        echo
        echo "WARNING: This is a custom installation"
        echo "Make sure $installation_dir/bin is under your PATH"
        echo "Make sure WIZE_FLOW_DIR points to $installation_dir every time you run 'git wize-flow ...'"
    fi
}

main "$@"
