# wize-flow
Wizeline's opinionated version of GitFlow

## Overview
Before starting, you must be familiar with the git workflow [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) and with AVH's implementation of git extensions for `GitFlow` [git-flow-avh](https://github.com/petervanderdoes/gitflow-avh). You can check out a simplified cheatsheet [here](https://danielkummer.github.io/git-flow-cheatsheet/)

This project intention is to build upon what `git-flow-avh` already provides in order to achieve three main goals:
1. Provide end-to-end automation by integrating `git-flow-avh` with Wizeline's PR review process. 
2. Provide safety when merging and pushing to long-living branches in the remote repositories.
3. Provide simplicity of usage by providing sane defaults for `git-flow-avh` that work for the vast majority of the cases.

## Dependencies
- git (already installed on MacOS)
- python 2.7 (already installed on MacOS)
- git-flow-avh
- hub

## Setup
1. `cd` into the repository you want to setup
2. `./wize-flow-init.sh`
3. enjoy!

## Usage
For `git-flow-avh` usage refer to the [cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/). `git-flow-avh` capabilities for `start`, `publish`, `pull` (discouraged)[https://github.com/petervanderdoes/gitflow-avh/issues/128] and `track` commands are practically untouched. The `finish` command was changed so that now it expects a `merged` PR to continue the back-merge, tagging and cleanup process.

For an opinionated guide on how to achieve the different types of workflows using `wize-flow`, check [this](https://docs.google.com/document/d/1gsLuBmR-eGTYKfYwJ5ZxJLVWlO6cA7Jdr5REDV2Y_ZQ/edit?usp=sharing) out!
