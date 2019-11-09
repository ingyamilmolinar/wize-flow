# wize-flow
Wizeline's opinionated version of GitFlow

## Overview
Before starting, you must be familiar with the git workflow [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) and with AVH's implementation of git extensions for `GitFlow` [git-flow-avh](https://github.com/petervanderdoes/gitflow-avh). You can check out a simplified cheatsheet [here](https://danielkummer.github.io/git-flow-cheatsheet/)

This project intention is to build upon what `git-flow-avh` already provides in order to achieve three main goals:
1. Provide end-to-end automation by integrating `git-flow-avh` with Wizeline's PR review process. 
2. Provide safety when merging and pushing to long-living branches in the remote repositories.
3. Provide simplicity of usage by providing sane defaults for `git-flow-avh` that work for the vast majority of the cases.

## Dependencies
- [git](https://github.com/git/git)
- [jq](https://github.com/stedolan/jq)
- [git-flow-avh](https://github.com/petervanderdoes/gitflow-avh)
- [hub](https://github.com/github/hub)

## Setup
1. Clone this repo
2. Run the installation script `<wize-flow-repo-path>/setup.sh install <bash|joker>`
3. Setup your repository by running: `git wize-flow init <your-repo-path> <your-repo-url>`

## Uninstall
1. To de-initialize the repository run `git wize-flow remove <your-repo-path>`
2. To unsinstall wize-flow completely run `<wize-flow-repo-path>/setup.sh uninstall` 

## Usage
For `git-flow-avh` usage refer to the [cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/). `git-flow-avh` capabilities for `start`, `publish`, `pull` [discouraged](https://github.com/petervanderdoes/gitflow-avh/issues/128) and `track` commands are untouched. The `finish` command was changed so that now it expects a `merged` PR according to Wizeline practices to continue the back-merge, tagging and cleanup process.

For an opinionated guide on how to achieve the different types of workflows using `wize-flow`, check [this](https://docs.google.com/document/d/1gsLuBmR-eGTYKfYwJ5ZxJLVWlO6cA7Jdr5REDV2Y_ZQ/edit?usp=sharing) out!

## Development
### Static analysis (for BASH only)
- Install [shellcheck](https://github.com/koalaman/shellcheck): `brew install shellcheck`
- Run shellcheck on bash sources: `( ls *.sh | sed 's:\*::'; find src/bash src/common -type f ) | xargs shellcheck --external-sources --shell=bash`

### Testing
- Install [bats](https://github.com/bats-core/bats-core/): `brew install bats` 
- Configure hub by either setting user/password: `export GITHUB_USER=<your-github-username> && export GITHUB_PASSWORD=<your-github-password>` or by setting an access token: `export GITHUB_TOKEN=<your-github-access-token>`
- For unit tests run `./run-test.sh <bash|joker>` (Only bash support unit tests for now)
- For integration tests run `INTEGRATION_TESTS=true ./run-test.sh <bash|joker>` (Internet connection needed)
- To run an individual test from ./tests/ directory run `./run-test.sh <bash|joker> <test-filename>`
- NOTE: Always use the `run-test.sh` driver. Do not attempt to run bats directly on the .bats files.

### [WIP] Code Coverage (for BASH only)
- Install ruby: `brew install ruby`
- Install bashcov: `sudo gem install bashcov`
- To get the test coverage for integration tests: `INTEGRATION_TESTS=true bashcov ./run-test.sh <bash|joker>`
