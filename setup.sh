#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2032,SC2033

function usage() {
    echo "setup.sh <install|uninstall> <bash|joker> [<custom-directory>] [--force] [--ignore-dependencies]" 1>&2
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

install() {

    if [[ ! ( "$#" -ge "1" && "$#" -le "4" ) ]]; then
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
    local binary_installation_dir="/usr/local/bin"

    if [[ "${2-undefined}" != "undefined" && "$2" != "--force" && "$2" != "--ignore-dependencies" ]]; then

        if [[ ! -d "$2" ]]; then
            echo "$2 is not a directory" 1>&2
            usage
            exit 1
        fi

        custom=true
        installation_dir="$(cd "$2"; pwd)/wize-flow"
        binary_installation_dir="$installation_dir"

        if [[ "$installation_dir" == "/usr/local/opt/wize-flow" ]]; then
            custom=false
            binary_installation_dir="/usr/local/bin"
        fi

    fi
    local -r base_installation_dir="$( echo "$installation_dir" | sed 's:/wize-flow$::' )"

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
        echo "Run 'setup.sh uninstall' to uninstall" 1>&2
        exit 1
    fi

    local -r is_darwin_status=$(uname -a | grep -q 'Darwin'; echo $?)
    local -r is_linux_status=$(uname -a | grep -q 'Linux'; echo $?)
    
    if [[ ( "$ignore_deps" == "false" && "$is_linux_status" -eq 0 ) \
         || ! -w "$base_installation_dir" \
         || ( "$custom" == "false" && ! -w "$binary_installation_dir" ) ]]; then
        check_sudo
    fi

    if [[ "$ignore_deps" == "false" ]]; then

        if [[ "$is_darwin_status" -eq 0 ]]; then
            macos_install "$implementation"
        elif [[ "$is_linux_status" -eq 0 ]]; then
            linux_install "$implementation"
        else
            echo "Only Linux based distros are supported" 1>&2
            exit 1
        fi

    fi

    echo "Installing wize-flow..."
    readonly init_script_relative_path="$(dirname "$0")"/src/"$1"

    sudo_command=""
    if [[ ! -w "$base_installation_dir" \
         || ( "$custom" == "false" && ! -w "$binary_installation_dir" ) ]]; then
        sudo_command="sudo"
    fi

    $sudo_command mkdir -p "$installation_dir"
    $sudo_command mkdir -p "$binary_installation_dir"
    $sudo_command cp -f "$init_script_relative_path"/../common/* "$installation_dir"
    $sudo_command cp -f "$init_script_relative_path"/* "$installation_dir"
    $sudo_command rm -f "$installation_dir"/git-wize-flow

    # This will extend git with 'git wize-flow'
    # See: https://stackoverflow.com/questions/10978257/extending-git-functionality
    $sudo_command cp -f "$init_script_relative_path"/../common/git-wize-flow "$binary_installation_dir" 

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

uninstall() {

    if [[ ! ( "$#" -ge "0" && "$#" -le "3" ) ]]; then
        usage
        exit 1
    fi

    local custom=false
    local installation_dir="/usr/local/opt/wize-flow"
    local binary_installation_dir="/usr/local/bin"

    if [[ "${1-undefined}" != "undefined" && "$1" != "--force" && "$1" != "--ignore-dependencies" ]]; then

        if [[ ! -d "$1" ]]; then
            echo "$1 is not a directory" 1>&2
            usage
            exit 1
        fi

        custom=true
        installation_dir="$(cd "$1"; pwd)"
        if [[ "$installation_dir" == "/usr/local/opt/wize-flow" ]]; then
            custom=false
        else
            binary_installation_dir="$installation_dir"
        fi
    fi
    local -r base_installation_dir="$( echo "$installation_dir" | sed 's:/wize-flow$::' )"

    local forced=false
    if [[ "$*" == *"--force"* ]]; then
        forced=true
    fi

    local ignore_deps=false
    if [[ "$*" == *"--ignore-dependencies"* ]]; then
        ignore_deps=true
    fi

    if [[ ! -f "$installation_dir/wize-flow" && "$forced" == "false" ]]; then

        echo "Wize-flow has not been installed under $installation_dir" 1>&2

        if [[ "${WIZE_FLOW_DIR-undefined}" != "undefined" ]]; then
            echo "Did you mean 'setup.sh uninstall $WIZE_FLOW_DIR' ?" 1>&2
        elif [[ "$custom" == "true" && -d "$installation_dir/wize-flow" ]]; then
            echo "Perhaps you meant 'setup.sh uninstall $installation_dir/wize-flow'" 1>&2
        fi

        echo "Run 'setup.sh install' to install" 1>&2
        exit 1

    fi

    sudo_command=""
    if [[ ! -w "$base_installation_dir" \
         || ( "$custom" == "false" && ! -w "$binary_installation_dir" ) ]]; then
        check_sudo
        sudo_command="sudo"
    fi
    
    if [[ "$ignore_deps" == "false" ]]; then
        echo "Uninstalling dependencies..."
        brew uninstall git-flow-avh &>/dev/null
        brew uninstall hub &>/dev/null
        brew uninstall candid82/brew/joker &>/dev/null
    fi

    if [[ "$forced" == "false" && ( ! -f "$installation_dir/wize-flow" || ! -f "$binary_installation_dir/git-wize-flow" ) ]]; then
        echo "$installation_dir directory does not contain a wize-flow installation" 1>&2
        exit 1
    fi

    echo "Uninstalling wize-flow..."
    rm -fr "$installation_dir"
    if [[ "$custom" == "true" && "$binary_installation_dir" != "/usr/local/bin" ]]; then
        $sudo_command rm -fr "$binary_installation_dir"
    else
        $sudo_command rm -f "$binary_installation_dir/git-wize-flow"
    fi

    echo
    echo "Successfully uninstalled wize-flow!"
    echo
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

    local -r command="${1-undefined}"
    if [[ "$command" != "install" && "$command" != "uninstall" ]]; then
        usage        
        exit 1
    fi

    shift
    "$command" "$@"
}

main "$@"
