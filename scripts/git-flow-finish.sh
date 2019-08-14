#!/usr/bin/env bash

usage() {

    echo "Usage: $0 <feature|release|bugfix|hotfix> <branch-name> [version-tag] [tag-message]" 1>&2 
    exit 1

}

validate_inputs() {

    GIT_FLOW_TYPE=$1
    BRANCH_NAME=$2
    VERSION_TAG=$3
    TAG_MESSAGE=$4

    if [[ -z "$GIT_FLOW_TYPE" ]]; then 
        echo "Not enough arguments: GitFlow workflow is mandatory" 1>&2
        usage
    fi

    if [[ -z "$BRANCH_NAME" ]]; then 
        echo "Not enough arguments: Branch name is mandatory" 1>&2
        usage
    else
        if [[ $BRANCH_NAME == "feature/"* || $BRANCH_NAME == "bugfix/"* || $BRANCH_NAME == "hotfix/"* || $BRANCH_NAME == "release/"* ]]; then
            SANITIZED_BRANCH=$(echo $BRANCH_NAME | sed "s:feature/::g" | sed "s:bugfix/::g" | sed "s:hotfix/::g" | sed "s:release/::g" )
            echo "Incorrect argument: Branch name contains feature|release|bugfix|hotfix" 1>&2
            echo "Did you mean? $SANITIZED_BRANCH" 1>&2
            usage
        fi
    fi

    if [[ ( $GIT_FLOW_TYPE == "release" || $GIT_FLOW_TYPE == "hotfix" ) && ( -z "$VERSION_TAG" || -z "$TAG_MESSAGE" ) ]]; then
        echo "Not enough arguments: Version tag and tag message are mandatory for release|hotfix workflows" 1>&2
        usage
    fi

    if [[ ! -z "$VERSION_TAG" && ( $GIT_FLOW_TYPE != "release" && $GIT_FLOW_TYPE != "hotfix" ) ]]; then
        echo "Version tag and tag message are only required for release|hotfix workflows" 1>&2
        usage
    fi

    MAX_AMOUNT_OF_ARGS=4
    if [[ "$#" > $MAX_AMOUNT_OF_ARGS ]]; then
        echo "Too many arguments: $# is greater thant the maximum amount of arguments supported" 1>&2
        usage
    fi
    shift $(( $MAX_AMOUNT_OF_ARGS - 1 ))
    
    BRANCH_TO_MERGE="$GIT_FLOW_TYPE/$BRANCH_NAME"
    if ! git branch | grep " $BRANCH_TO_MERGE$" 2>&1 1>/dev/null; then
        echo "$BRANCH_TO_MERGE branch does not exist" 1>&2
        usage
    fi

}

validate_hub() {

    if ! hub pr list -h $(git branch | grep \* | sed 's/\* //g') 2>&1 1>/dev/null; then
        "ERROR: You probably need to 'Enable SSO' for your current access token from your GitHub account settings"
        exit 1
    fi

}

init_config_params() {

    # Get current branch base branch
    if [[ $GIT_FLOW_TYPE == "hotfix" ]]; then
        BASE_BRANCH=develop
    else
        BASE_BRANCH=$(git show-branch | grep '*' | grep -v "$(git rev-parse --abbrev-ref HEAD)" | head -n1 | sed 's/.*\[\(.*\)\].*/\1/' | sed 's/[\^~].*//')
    fi

    # Set target branch
    if [[ $GIT_FLOW_TYPE == "hotfix" || $GIT_FLOW_TYPE == "release" ]]; then
        TARGET_BRANCH=master
    elif [[ $GIT_FLOW_TYPE == "bugfix" ]]; then
        TARGET_BRANCH=$BASE_BRANCH
    else
        TARGET_BRANCH=develop
    fi

    HEAD_BRANCH=$(git branch | grep \* | sed 's/\* //g')

    # Gets latest merged PR num for current branch
    PR_NUM=$(hub pr list -s merged -h $HEAD_BRANCH -b $TARGET_BRANCH | head -n1 | awk '{print $1}' | sed s/\#//)

    # Gets Github username from .git/config
    GITHUB_USERNAME=$(grep -A 1 'remote \"origin\"' .git/config | grep -o ':.*/' | sed s/://g | sed s:/::g)

    # Gets Github repository from .git/config
    GITHUB_REPOSITORY=$(grep -A 1 'remote \"origin\"' .git/config | grep -o '/.*\.' | sed s:/::g | sed 's:\.::g')

    if ! hub api /repos/$GITHUB_USERNAME/$GITHUB_REPOSITORY/pulls/$PR_NUM | python -m json.tool | grep 'merged' | grep 'true' 2>&1 1>/dev/null; then
        # Gets latest non-merged PR num for current branch
        PR_NUM=$(hub pr list -h $HEAD_BRANCH -b $TARGET_BRANCH | head -n1 | awk '{print $1}' | sed s/\#//)
        if [[ -z $PR_NUM ]]; then
            echo "No PR has been created from $BRANCH_TO_MERGE to $TARGET_BRANCH" 1>&2
        else
            echo "The PR $PR_NUM on repository $GITHUB_REPOSITORY has not been merged" 1>&2
        fi
        exit 1
    fi

}

set_git_flow_opts() {

    GIT_FLOW_FINISH_OPTIONS=()
    case $GIT_FLOW_TYPE in
        release|hotfix)
            GIT_FLOW_FINISH_OPTIONS=("--tagname" "$VERSION_TAG" "--message" "$TAG_MESSAGE")
            ;;
    esac

}

sync_base_branch() {

    git checkout $TARGET_BRANCH
    git pull origin $TARGET_BRANCH
    if [[ $GIT_FLOW_TYPE == "release" || $GIT_FLOW_TYPE == "hotfix" ]]; then
        git checkout develop
        git pull origin develop
    fi
    git checkout $HEAD_BRANCH  
    
}

exec_git_flow_finish() {

    AUTOMATED_PUSH=true git flow $GIT_FLOW_TYPE finish $BRANCH_NAME "${GIT_FLOW_FINISH_OPTIONS[@]}"

}

####### SCRIPT START #######

validate_inputs "$@"
validate_hub
init_config_params
set_git_flow_opts

sync_base_branch
exec_git_flow_finish

####### SCRIPT END #######
