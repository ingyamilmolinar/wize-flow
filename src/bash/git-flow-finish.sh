#!/usr/bin/env bash

usage() {

    echo "usage: $__script_name <feature|release|bugfix|hotfix> <branch-name> [tag-version]" 1>&2 
    exit 1

}

validate_inputs() {

    readonly __script_name="$0"
    readonly __git_flow_type="${1-undefined}"
    readonly __branch_name="${2-undefined}"
    readonly __tag_version="${3-undefined}"

    if [[ "$__git_flow_type" == "undefined" ]]; then 
        echo "Not enough arguments: GitFlow workflow is mandatory" 1>&2
        usage
    fi

    if [[ "$__branch_name" == "undefined" ]]; then 
        echo "Not enough arguments: Branch name is mandatory" 1>&2
        usage
    else
        if [[ "$__branch_name" == "feature/"* || "$__branch_name" == "bugfix/"* || "$__branch_name" == "hotfix/"* || "$__branch_name" == "release/"* ]]; then
            local -r sanitized_branch=$(echo "$__branch_name" | sed "s:feature/::g" | sed "s:bugfix/::g" | sed "s:hotfix/::g" | sed "s:release/::g" )
            echo "Incorrect argument: Branch name contains feature|release|bugfix|hotfix" 1>&2
            echo "Did you mean? $sanitized_branch" 1>&2
            usage
        fi
    fi

    if [[ ( "$__git_flow_type" == "release" || "$__git_flow_type" == "hotfix" ) && "$__tag_version" == "undefined" ]]; then
        echo "Not enough arguments: Version tag is mandatory for release|hotfix workflows" 1>&2
        usage
    fi

    if [[ "$__tag_version" != "undefined" && ( "$__git_flow_type" != "release" && "$__git_flow_type" != "hotfix" ) ]]; then
        echo "Version tag is only required for release|hotfix workflows" 1>&2
        usage
    fi

    local -r max_amount_of_args=3
    if [[ "$#" > "$max_amount_of_args" ]]; then
        echo "Too many arguments: $# is greater thant the maximum amount of arguments supported" 1>&2
        usage
    fi
    shift "$(( $max_amount_of_args - 1 ))"
    
    readonly __branch_to_merge="$__git_flow_type/$__branch_name"
    if ! git branch | grep " $__branch_to_merge$" &>/dev/null; then
        echo "$__branch_to_merge branch does not exist" 1>&2
        usage
    fi

}

validate_hub() {

    if ! hub pr list -h "$(git branch | grep '\*' | sed 's/\* //g')" &>/dev/null; then
        if ! git remote | grep '.'; then
            echo "ERROR: You need to add a remote pointing to a GitHub repository" 1>&2
        else
            echo "ERROR: You need to 'Enable SSO' for your current access token from your GitHub account settings" 1>&2
        fi
        exit 1
    fi

}

init_config_params() {

    # Get current branch base branch
    local base_branch="undefined"
    if [[ "$__git_flow_type" == "hotfix" ]]; then
        base_branch=develop
    else
        base_branch=$(git show-branch | grep '\*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')
    fi

    # Set target branch
    # TODO: Make release target develop and test. Don't forget to change the git flow config
    __target_branch="undefined"
    if [[ "$__git_flow_type" == "hotfix" || "$__git_flow_type" == "release" ]]; then
        __target_branch=master
    elif [[ $__git_flow_type == "bugfix" ]]; then
        __target_branch="$base_branch"
    else
        __target_branch=develop
    fi

    readonly __head_branch=$(git branch | grep '\*' | sed 's/\* //g')

    # Gets latest merged PR num for current branch
    local -r merged_pr_num=$(hub pr list -s merged -h "$__head_branch" -b "$__target_branch" | head -n1 | awk '{print $1}' | sed 's/\#//')

    # Gets Github username from .git/config
    local -r github_username=$(grep -A 1 'remote \"origin\"' .git/config | grep -o ':.*/' | sed 's/://g' | sed 's:/::g')

    # Gets Github repository from .git/config
    local -r github_repository=$(grep -A 1 'remote \"origin\"' .git/config | grep -o '/.*\.' | sed 's:/::g' | sed 's:\.::g')

    if [[ -z "$merged_pr_num" ]] || ! hub api "/repos/$github_username/$github_repository/pulls/$merged_pr_num" | python -m json.tool | grep 'merged' | grep 'true' &>/dev/null; then
        # Gets latest non-merged PR num for current branch
        local -r non_merged_pr_num=$(hub pr list -h "$__head_branch" -b "$__target_branch" | head -n1 | awk '{print $1}' | sed 's/\#//')
        if [[ -z "${non_merged_pr_num}" ]]; then
            echo "No PR has been created from $__branch_to_merge to $__target_branch on repository $github_repository" 1>&2
        else
            echo "The PR $non_merged_pr_num on repository $github_repository has not been merged" 1>&2
        fi
        exit 1
    fi

}

set_git_flow_opts() {

    __git_flow_finish_options=()
    case "$__git_flow_type" in
        release|hotfix)
            # TOFIX: We are using tag-version for the tag-message too
            __git_flow_finish_options=("--tagname" "$__tag_version" "--message" "$__tag_version")
            ;;
    esac

}

sync_base_branch() {

    git checkout "$__target_branch"
    git pull origin "$__target_branch"
    if [[ "$__git_flow_type" == "release" || "$__git_flow_type" == "hotfix" ]]; then
        git checkout develop
        git pull origin develop
    fi
    git checkout "$__head_branch"
    
}

exec_git_flow_finish() {
    # Hacky way to avoid an unbound error for an empty array.
    # See: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u
    # TODO: Handle conflicts on automated merge
    FORCE_PUSH=true git flow "$__git_flow_type" finish "$__branch_name" "${__git_flow_finish_options[@]+${__git_flow_finish_options[@]}}"

}

####### SCRIPT START #######
function main() {

    # We do not want the script to exit on failed scripts
    set +o errexit
    # We do not want to exit on error inside any functions or subshells.
    set +o errtrace
    # Do not allow use of undefined vars. Use ${VAR:-} to use an undefined VAR
    set -o nounset
    # Catch the error in case mysqldump fails (but gzip succeeds) in `mysqldump |gzip`
    set -o pipefail

    validate_inputs "$@"
    validate_hub
    init_config_params
    set_git_flow_opts

    sync_base_branch
    exec_git_flow_finish

}
####### SCRIPT END #######

main "$@"
