#!/usr/bin/env bash
# shellcheck disable=SC2086

usage() {
    echo "usage: $__script_name <feature|release|bugfix|hotfix> <branch-name> [tag-version]" 1>&2 
    exit 1
}

match_branch_prefix() {
    [[ "$1" == "feature/"* \
    || "$1" == "bugfix/"* \
    || "$1" == "hotfix/"* \
    || "$1" == "release/"* ]]
}

remove_branch_prefix() {
    echo "$1" \
         | sed "s:feature/::g" \
         | sed "s:bugfix/::g" \
         | sed "s:hotfix/::g" \
         | sed "s:release/::g"
}

tag_required_for_type() {
    [[ "$1" == "release" || "$1" == "hotfix" ]]
}

current_branch() {
    git branch | grep '\*' | sed 's/\* //g'
}

merged_pr_from_to() {
    local -r branch_to_merge="$1"
    local -r target_branch="$2"
    hub pr list -s merged -h "$branch_to_merge" -b "$target_branch" \
          | head -n1 \
          | awk '{print $1}' \
          | sed 's/\#//'
}

last_pr_from_to() {
    local -r branch_to_merge="$1"
    local -r target_branch="$2"
    hub pr list -h "$branch_to_merge" -b "$target_branch" \
          | head -n1 \
          | awk '{print $1}' \
          | sed 's/\#//'
}

github_username() {
    git config --get remote.origin.url \
          | grep -o ':.*/' \
          | sed 's/://g' \
          | sed 's:/::g'
}

github_repository() {
    git config --get remote.origin.url \
          | grep -o '/.*' \
          | sed 's:/::g' \
          | sed 's:\.git::g'
}

last_commit_hash_from_branch() {
    git log "$1" | head -n 1 | awk '{print $2}'
}

last_commit_hash_from_pr() {
    local -r github_username="$1"
    local -r github_repository="$2"
    local -r pr_number="$3"
    hub api "/repos/$github_username/$github_repository/pulls/$pr_number/commits" \
        | jq -r '.[-1].sha'
}

merged_status_from_pr() {
    local -r github_username="$1"
    local -r github_repository="$2"
    local -r pr_number="$3"
    hub api "/repos/$github_username/$github_repository/pulls/$pr_number" \
        | jq -r '.merged' \
        | grep 'true'
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
        if match_branch_prefix "$__branch_name"; then
            local -r sanitized_branch=remove_branch_prefix "$__branch_name"
            echo "Incorrect argument: Branch name contains feature|release|bugfix|hotfix" 1>&2
            echo "Did you mean? $sanitized_branch" 1>&2
            usage
        fi
    fi

    if tag_required_for_type "$__git_flow_type" && \
        [[ "$__tag_version" == "undefined" ]]; then
        echo "Not enough arguments: Version tag is mandatory for release|hotfix workflows" 1>&2
        usage
    fi

    if ! tag_required_for_type "$__git_flow_type" && \
        [[ "$__tag_version" != "undefined" ]]; then
        echo "Version tag is only required for release|hotfix workflows" 1>&2
        usage
    fi

    local -r max_amount_of_args=3
    if [[ "$#" > "$max_amount_of_args" ]]; then
        echo "Too many arguments: $# is greater than the maximum amount of arguments supported" 1>&2
        usage
    fi
    shift "$(( max_amount_of_args - 1 ))"
    
    readonly __branch_to_merge="$__git_flow_type/$__branch_name"
    if ! git branch | grep " $__branch_to_merge$" &>/dev/null; then
        echo "$__branch_to_merge branch does not exist" 1>&2
        usage
    fi

}

validate_hub() {

    if ! hub pr list -h current_branch &>/dev/null; then
        if ! git remote | grep '.'; then
            echo "ERROR: You need to add a remote pointing to a GitHub repository" 1>&2
        else
            echo "ERROR: You need to 'Enable SSO' for your current access token from your GitHub account settings" 1>&2
        fi
        exit 1
    fi

}

init_config_params() {

    # Get base branch. TODO: Find a way to avoid hardcoding this
    case "$__git_flow_type" in
        feature|bugfix|release)
                __base_branch=develop
                ;;
        hotfix)
                __base_branch=master
                ;;
    esac

    # Set target branch for PR
    case "$__git_flow_type" in
        feature|bugfix|release)
                __target_branch=develop
                ;;
        hotfix)
                __target_branch=master
                ;;
    esac

    # Set target branch for automated merge
    case "$__git_flow_type" in
        release)
                __automated_target_branch=master
                ;;
        hotfix)
                __automated_target_branch=develop
                ;;
    esac

    local -r merged_pr_num=$(merged_pr_from_to "$__branch_to_merge" "$__target_branch")
    local -r github_username=$(github_username)
    local -r github_repository=$(github_repository)
    local -r current_branch_last_commit_hash=$(last_commit_hash_from_branch "$__branch_to_merge")
    if [[ -n "$merged_pr_num" ]]; then
        local -r pr_last_commit_hash=$(last_commit_hash_from_pr \
                                       "$github_username" \
                                       "$github_repository" \
                                       "$merged_pr_num")
    fi

    if [[ -z "$merged_pr_num" \
        || "$(merged_status_from_pr "$github_username" "$github_repository" "$merged_pr_num")" != *"true"* \
        || "${pr_last_commit_hash-undefined}" != "$current_branch_last_commit_hash" ]]; then

        local -r non_merged_pr_num=$(last_pr_from_to "$__branch_to_merge" "$__target_branch")
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
            __git_flow_finish_options=("--tagname" "$__tag_version" \
                                       "--message" "$__tag_version")
            ;;
    esac

}

sync_base_branch() {

    git checkout "$__base_branch"
    git pull origin "$__base_branch"
    if [[ "$__target_branch" != "$__base_branch" ]]; then
        git checkout "$__target_branch"
        git pull origin "$__target_branch"
    fi
    if [[ "${__automated_target_branch-undefined}" != "undefined" \
        && "$__automated_target_branch" != "$__base_branch" ]]; then
        git checkout "$__automated_target_branch"
        git pull origin "$__automated_target_branch"
    fi
    git checkout "$__branch_to_merge"
    
}

exec_git_flow_finish() {
    # Hacky way to avoid an unbound error for an empty array.
    # See: https://stackoverflow.com/questions/7577052/bash-empty-array-expansion-with-set-u
    FORCE_PUSH=true git flow "$__git_flow_type" \
                    finish "$__branch_name" \
                    "${__git_flow_finish_options[@]+${__git_flow_finish_options[@]}}"

}

main() {

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

main "$@"
