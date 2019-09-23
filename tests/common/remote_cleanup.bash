#!/usr/bin/env bash

# Remove all branches but develop and master both remotely and locally
git fetch --prune
git checkout develop
git branch -a | grep -v -e develop -e master | grep -v origin/ | sed 's:*::g' | xargs git branch -D || true
git branch -a | grep -v -e develop -e master | grep origin/ | sed 's:*::g' | sed 's:remotes/origin/::g' | xargs git push --delete origin || true

# Remove all tags both locally and remotely
git ls-remote --tags origin | grep -v '\^' | awk '{print $2}' | xargs git push --delete origin || true 
git tag | xargs git tag -d || true

# TODO: Think about concurrency safety (If someone merges to develop before I reset, the final state is undefined)
# Reset develop and master to the initial state
git checkout develop &&
git checkout "$(git log --oneline | tail -n1 | awk '{print $1}')" &&
git reset --hard &&
git branch -D develop &&
git checkout -b develop &&
FORCE_PUSH=true git push --force origin develop

git checkout master &&
git checkout "$(git log --oneline | tail -n1 | awk '{print $1}')" &&
git reset --hard &&
git branch -D master &&
git checkout -b master &&
FORCE_PUSH=true git push --force origin master
