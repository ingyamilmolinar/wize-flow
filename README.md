# wize-flow
An opinionated implementation of GitFlow

## Overview
Before starting, you must be familiar with the git workflow [GitFlow](https://nvie.com/posts/a-successful-git-branching-model/) and with AVH's implementation of git extensions for `GitFlow` [git-flow-avh](https://github.com/petervanderdoes/gitflow-avh). You can check out a simplified cheatsheet of how the tool works [here](https://danielkummer.github.io/git-flow-cheatsheet/)

This project intention is to build upon what `git-flow-avh` already provides in order to achieve three main goals:
1. Provide end-to-end automation by integrating `git-flow-avh` with a usual PR review process in a remote hosting service (ex: GitHub).
2. Provide safety when merging and pushing to long-living branches in the remote repositories by providing git hooks.
3. Provide simplicity of usage by providing sane defaults for `git-flow-avh` that work for the vast majority of the cases.

## OS support
This project has been tested on MacOS and Ubuntu Linux. 

## Dependencies
- [git](https://github.com/git/git)
- [jq](https://github.com/stedolan/jq)
- [git-flow-avh](https://github.com/petervanderdoes/gitflow-avh)
- [hub](https://github.com/github/hub)

## Setup
1. Clone this repo
2. Run the installation script `<wize-flow-repo-path>/setup.sh install`
3. Setup your repository by running: `git wize-flow init <your-repo-path> <your-repo-url>`

## Uninstall
1. To de-initialize the repository run `git wize-flow remove <your-repo-path>`
2. To uninstall wize-flow completely run `<wize-flow-repo-path>/setup.sh uninstall` 

## Usage
For `git-flow-avh` usage refer to the [cheatsheet](https://danielkummer.github.io/git-flow-cheatsheet/). `git-flow-avh` functionality for `start`, `publish`, `pull` ([discouraged](https://github.com/petervanderdoes/gitflow-avh/issues/128)) and `track` commands is unmodified. 

The `finish` command functionality was changed so that it now expects a `merged` PR in GitHub before continuing the back-merge, tagging and cleanup process. This was in part in response of suggestions to the original project: [#358](https://github.com/petervanderdoes/gitflow-avh/issues/358).

## Development
### Static analysis
- Install [shellcheck](https://github.com/koalaman/shellcheck)
- Run shellcheck on bash sources: `( ls *.sh | sed 's:\*::'; find src/bash src/common -type f ) | xargs shellcheck --external-sources --shell=bash`

### Testing
- Install [bats](https://github.com/bats-core/bats-core/)
- Configure hub by either setting user/password: `export GITHUB_USER=<your-github-username> && export GITHUB_PASSWORD=<your-github-password>` or by setting an access token: `export GITHUB_TOKEN=<your-github-access-token>`
- For unit tests run `./run-test.sh`
- For integration tests run `INTEGRATION_TESTS=true ./run-test.sh` (Internet connection needed)
- To run an individual test from ./tests/ directory run `./run-test.sh <test-filename>`
- NOTE: Always use the `run-test.sh` driver. Do not attempt to run bats directly on the .bats files.

### [WIP] Code Coverage
- Install [ruby](https://www.ruby-lang.org/en/documentation/installation/)
- Install bashcov: `sudo gem install bashcov`
- To get the test coverage for integration tests: `INTEGRATION_TESTS=true bashcov ./run-test.sh`
