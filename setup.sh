#!/usr/bin/env bash
# shellcheck disable=SC2001,SC2032,SC2033

#TOFIX: Remove joker!!
function usage() {
    echo "setup.sh <install|uninstall> <bash|joker> [<custom-directory>] [--force] [--ignore-dependencies]" 1>&2
}

macos_install() {

    if ! command -v brew >/dev/null; then
        echo "Installing homebrew..."
        ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)" </dev/null
    fi

    if ! command -v git-flow >/dev/null || ! command -v hub >/dev/null; then 
        echo "Updating brew and installing dependencies..."
        brew update &>/dev/null
    fi

    if ! command -v git-flow >/dev/null; then 
        brew install git-flow-avh &>/dev/null
    fi

    if ! command -v jq >/dev/null; then
        brew install jq
    fi

    if ! command -v hub >/dev/null; then
        brew install hub &>/dev/null
    fi

}

linux_install() {

    local -r sudo_command="$1"
    local package_manager="apt-get"
    local update_command="update"

    if ! command -v apt-get >/dev/null; then
        if command -v yum >/dev/null; then
            package_manager="yum"
            update_command="check-update"
        else
            echo "Could not find a supported package manager" 1>&2
            echo "Install apt-get or yum and retry" 1>&2
            exit 1
        fi
    fi

    if ! command -v git >/dev/null \
        || ! command -v git-flow >/dev/null \
        || ! command -v jq >/dev/null \
        || ! command -v hub >/dev/null; then
        echo "Updating $package_manager and installing dependencies..."
        $sudo_command $package_manager $update_command -y &>/dev/null
    fi

    if ! command -v git >/dev/null; then
        $sudo_command $package_manager install -y git &>/dev/null
    fi

    if ! command -v git-flow >/dev/null; then
        if ! command -v wget >/dev/null; then
            $sudo_command $package_manager install -y wget &>/dev/null
        fi
        wget -q \
            https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh \
            &>/dev/null
        $sudo_command bash gitflow-installer.sh install stable &>/dev/null
        $sudo_command rm -fr gitflow &>/dev/null
        rm -f ./gitflow-installer.sh &>/dev/null
    fi

    if ! command -v jq >/dev/null; then
        $sudo_command $package_manager install -y jq &>/dev/null
    fi

    if ! command -v hub >/dev/null; then
        $sudo_command $package_manager install -y wget tar &>/dev/null
        wget https://github.com/github/hub/releases/download/v2.12.8/hub-linux-amd64-2.12.8.tgz &>/dev/null
        tar xvfz ./hub-linux-amd64-2.12.8.tgz -C /tmp &>/dev/null
        $sudo_command mv /tmp/hub-linux-amd64-2.12.8/bin/hub /usr/local/bin &>/dev/null
        chmod +x /usr/local/bin/hub &>/dev/null
        rm -fr /tmp/hub-linux-amd64-2.12.8 &>/dev/null
    fi

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
        if ! command -v git-flow &>/dev/null; then
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
    
    sudo_command=""
    if [[ ( "$ignore_deps" == "false" && "$is_linux_status" -eq 0 ) \
         || ! -w "$base_installation_dir" \
         || ( "$custom" == "false" && ! -w "$binary_installation_dir" ) ]]; then
        check_sudo
        sudo_command="sudo"
    fi

    if [[ "$ignore_deps" == "false" ]]; then

        if [[ "$is_darwin_status" -eq 0 ]]; then
            macos_install 
        elif [[ "$is_linux_status" -eq 0 ]]; then
            linux_install "$sudo_command"
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

linux_uninstall() {

    local -r sudo_command="$1"
    local package_manager="apt-get"

    if ! command -v apt-get >/dev/null; then
        if command -v yum >/dev/null; then
            package_manager="yum"
        else
            echo "Could not find a supported package manager" 1>&2
            echo "Install apt-get or yum and retry" 1>&2
            exit 1
        fi
    fi
    
    wget -q \
        https://raw.githubusercontent.com/petervanderdoes/gitflow-avh/develop/contrib/gitflow-installer.sh \
        &>/dev/null
    $sudo_command bash gitflow-installer.sh uninstall stable &>/dev/null
    rm -f ./gitflow-installer.sh &>/dev/null
    
    $sudo_command $package_manager remove -y jq &>/dev/null

    $sudo_command rm -f /usr/local/bin/hub &>/dev/null

}

macos_uninstall() {

    brew uninstall git-flow-avh &>/dev/null
    brew uninstall jq &>/dev/null
    brew uninstall hub &>/dev/null

}

uninstall() {

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
        installation_dir="$(cd "$2"; pwd)"
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
    
    local -r is_darwin_status=$(uname -a | grep -q 'Darwin'; echo $?)
    local -r is_linux_status=$(uname -a | grep -q 'Linux'; echo $?)
    
    if [[ "$ignore_deps" == "false" ]]; then

        echo "Uninstalling dependencies..."
        if [[ "$is_darwin_status" -eq 0 ]]; then
            macos_uninstall 
        elif [[ "$is_linux_status" -eq 0 ]]; then
            linux_uninstall "$sudo_command"
        else
            echo "Only Linux based distros are supported" 1>&2
            exit 1
        fi

    fi

    if [[ "$forced" == "false" && \
        ( ! -f "$installation_dir/wize-flow" \
        || ! -f "$binary_installation_dir/git-wize-flow" ) ]]; then
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
