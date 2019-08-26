#!/usr/bin/env bash

git()
(
    # Encapsulate logic inside sub-shell

    function usage() {
        echo "usage: git flow <feature|release|bugfix|hotfix> <start|publish|finish> <branch-name> [tag-version] --wize-flow"
    }

    function print_hints_banner() {

        echo "------------------------- WizeFlow -------------------------"
        echo
        if [[ "${__git_status-1}" == 0 || "${__wize_flow_status-1}" == 0 ]]; then
            case "${__stage-undefined}" in
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

    function contains_element () {
        local e match="$1"
        shift
        for e; do [[ "$e" == "$match" ]] && return 0; done
        return 1
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
        local -r git_verb="${1-undefined}"

        # If verb is not flow or wise-flow flag is not present, return to run normal git
        if [[ "$git_verb" != "flow" || "${__all_args[${#__all_args[@]}-1]}" != "--wize-flow" ]]; then
            return 
        fi

        validate_wize_flow
        __wize_flow_hints="true"

        # Remove wize-flow flag from the argument list
        # Hacky stuff. For more info see: https://stackoverflow.com/questions/20398499/remove-last-argument-from-argument-list-of-shell-script-bash
        set -- "${@:1:$(($#-1))}"
        __all_args=("$@")
        
        contains_element "show-usage" "${__all_args[@]}" && usage && exit 1

        local will_override="false"
        if contains_element "finish" "${__all_args[@]}"; then
            will_override="true"
        fi

        # TODO: Consider case: 'git flow finish [tag] --wize-flow' when release or hotfix branch
        case "${__all_args[1]-undefined}" in
            feature|bugfix|release|hotfix)
                __git_flow_type="${__all_args[1]}"
                case "${__all_args[2]-undefined}" in
                    start|publish|finish)
                        __stage="${__all_args[2]}"
                        ;;
                    *)
                        usage
                        exit 1
                        ;; 
                esac 
                local branch_provided=false
                if [[ "${__all_args[3]-undefined}" != "undefined" ]]; then
                    __branch_name="${__all_args[3]}"
                    branch_provided=true
                else
                    __branch_name=$(git rev-parse --abbrev-ref head | sed "s:$__git_flow_type/::")
                fi
                if [[ "$will_override" == "true" && ( "$__git_flow_type" == "release" || "$__git_flow_type" == "hotfix" ) ]]; then
                    if [[ "$branch_provided" != "true" && "${#__all_args[@]}" == 3 ]]; then 
                        __tag_version="${__all_args[2]}"
                    elif [[ "$branch_provided" == "true" && "${#__all_args[@]}" == 4 ]]; then
                        __tag_version="${__all_args[3]}"
                    elif [[ "$branch_provided" == "true" && "${#__all_args[@]}" == 5 ]]; then
                        __tag_version="${__all_args[4]}"
                    else
                        echo "tag-version is mandatory for $__git_flow_type branch" 1>&2
                        usage
                        exit 1
                    fi
                fi
                ;;
            start|publish|finish)
                __git_flow_type=$(git rev-parse --abbrev-ref HEAD | grep -o '^[^\/]*')
                __stage="${__all_args[1]}"
                local branch_provided=false
                if [[ "${__all_args[2]-undefined}" != "undefined" ]]; then
                    __branch_name="${__all_args[2]}"
                    branch_provided=true
                else
                    __branch_name=$(git rev-parse --abbrev-ref head | sed "s:$__git_flow_type/::")
                fi
                if [[ "$will_override" == "true" && ( "$__git_flow_type" == "release" || "$__git_flow_type" == "hotfix" ) ]]; then
                    if [[ "$branch_provided" != "true" && "${#__all_args[@]}" == 3 ]]; then                
                        __tag_version="${__all_args[2]}"
                    elif [[ "$branch_provided" == "true" && "${#__all_args[@]}" == 4 ]]; then
                        __tag_version="${__all_args[3]}"
                    elif [[ "$branch_provided" == "true" && "${#__all_args[@]}" == 5 ]]; then
                        __tag_version="${__all_args[4]}"
                    else
                        echo "tag-version is mandatory for $__git_flow_type branch" 1>&2
                        usage
                        exit 1
                    fi
                fi
                ;;
            *)
                usage
                exit 1
                ;;
        esac

        case "$__git_flow_type" in
            feature|bugfix|release|hotfix)
                ;;
            *)
                echo "ERROR: $__git_flow_type should be feature|bugfix|release|hotfix" 1>&2
                usage
                exit 1
                ;;
        esac

        # If no argument is finish, return and run normal git
        [[ "$__stage" != "finish" ]] && return

        __git_override="true" 
        __all_args=("$__git_flow_type" "$__branch_name")
        if [[ "$__git_flow_type" == "release" || "$__git_flow_type" == "hotfix" ]]; then
             __all_args=("${__all_args[@]}" "$__tag_version")
        fi

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
