#!/usr/bin/env bash

git()
(
    # Encapsulate logic inside sub-shell

    function usage() {
        echo "usage: git flow <feature|release|bugfix|hotfix> <start|publish|finish> <branch-name> [version-tag] [tag-message] --wize-flow"
    }

    function print_hints_banner() {

        echo "------------------------- WizeFlow -------------------------"
        echo
        if [[ "${__git_status-1}" == 0 || "${__wize_flow_status-1}" == 0 ]]; then
            case "$__stage" in
                start)
                    echo "Next step: Implement, add and commit your changes and continue with 'git flow $__git_flow_type publish $__branch_name --wize-flow' when ready to submit PR"
                    ;;
                publish)
                    echo "Next step: Open PR using previous GitHub URL and wait for approval to merge"
                    echo "           After merging, run 'git flow $__git_flow_type finish $__branch_name --wize-flow' command to back merge (if applies) and clean-up"
                    ;;
                finish)
                    echo "Congratulations! Your branch $__branch_name was merged succesfully"
                    ;;
                *)
                    usage
                    ;;
            esac
        else
            echo "Something went wrong with previous git flow command. Verify and try again"
        fi
            
        echo
        echo "------------------------- WizeFlow -------------------------"
                
    }

    function validate_wize_flow {
        local -r wize_flow_dir="$(git rev-parse --show-toplevel)"/.git/wize-flow
        if [[ ! -d "$wize_flow_dir" ]]; then
            echo "ERROR: Git Repository must be initialized with 'wize-flow init' before using --wize-flow option" 1>&2
            exit 1
        fi
    }

    function validate_inputs() {

        __all_args=("$@")
        __git_override="false"
        __wize_flow_hints="false"
        local git_verb="${1-undefined}"

        # If not going to call override script, return here
        [[ "$git_verb" == "flow" && "${@:$#}" == "--wize-flow" ]] && __wize_flow_hints="true"

        [[ "$__wize_flow_hints" == "true" ]] && validate_wize_flow
        
        if [[ "$__wize_flow_hints" == "false" || ( "${2-undefined}" != "finish" && "${3-undefined}" != "finish" ) || (( "${2-undefined}" == "release" || "${2-undefined}" == "hotfix" ) && "$#" -lt 7 ) || (("${2-undefined}" == "feature" || "${2-undefined}" == "bugfix" ) && "$#" -lt 5 ) ]]; then
            if [[ $__wize_flow_hints == "true" && ( "${2-undefined}" == "finish" || "${3-undefined}" == "finish" ) ]]; then
                usage
                exit 1
            fi
            if [[ "$__wize_flow_hints" == "true" ]]; then
                # TOFIX: Set this variables correctly when some are missing
                __git_flow_type="${2-undefined}"
                __stage="${3-undefined}"
                __branch_name="${4-undefined}"
                set -- "${@:1:$(($#-1))}"
                __all_args=("$@")
            fi
            return
        fi

        # If last argument is --wize-flow, remove it from the argument list
        # Hacky stuff. For more info see: https://stackoverflow.com/questions/20398499/remove-last-argument-from-argument-list-of-shell-script-bash
        if [[ "$__wize_flow_hints" == "true" ]]; then
            set -- "${@:1:$(($#-1))}"
            __all_args=("$@")
        fi

        __git_override="true" 
        __git_flow_type="$2"
        __stage="$3"
        __branch_name="$4"
        __version_tag="${5-undefined}"
        __tag_message="${6-undefined}"
        __all_args=("$__git_flow_type" "$__branch_name")
        [[ "$__version_tag" != "undefined" ]] && __all_args=("${__all_args[@]}" "$__version_tag")
        [[ "$__tag_message" != "undefined" ]] && __all_args=("${__all_args[@]}" "$__tag_message")

    }

    function run_git_flow() {

        # We run 'git' if we are not running our wize-flow script later
        if [[ "$__git_override" == "false" ]]; then
            # Hacky way to avoid an unbound error for an empty array.
            # See: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u
            command git ${__all_args[@]+"${__all_args[@]}"}
            __git_status=$?
        fi
       
    }

    function run_wize_flow() {

        if [[ "$__wize_flow_hints" == "true" ]]; then

            if [[ "$__git_override" == "true" ]]; then
                # Hacky way to avoid an unbound error for an empty array.
                # See: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u
                "$(git rev-parse --show-toplevel)"/.git/wize-flow/git-flow-finish.sh ${__all_args[@]+"${__all_args[@]}"}
                __wize_flow_status=$?
            fi
            
            print_hints_banner
        fi
           
    }
    
    ####### GIT FUNCTION START #######

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set -o pipefail

    validate_inputs "$@"
    run_git_flow
    run_wize_flow

    ####### GIT FUNCTION END #######

)
