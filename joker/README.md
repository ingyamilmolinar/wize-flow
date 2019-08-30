# wize-flow

## Dependencies
- git
- [git-flow-avh](https://github.com/petervanderdoes/gitflow-avh)
- [joker](https://github.com/candid82/joker)

## Setup
```sh
# install dependencies
$ brew install git-flow-avh
$ brew install joker

# clone the repo & add script to the $PATH
$ git clone git@github.com:wizeline/wize-flow.git
$ export PATH=<path-to>/wize-flow/joker:$PATH
```

## Usage
```sh
$ git wize-flow -h
usage: git wize-flow <subcommand>

Available subcommands are:
   init      Initialize a new git repo with support for the branching model.
   feature   Manage your feature branches.
   bugfix    Manage your bugfix branches.
   release   Manage your release branches.
   hotfix    Manage your hotfix branches.
   support   Manage your support branches.
   version   Shows version information.
   config    Manage your git-flow configuration.
   log       Show log deviating from base branch.

Try 'git wize-flow <subcommand> help' for details.
```
Enjoy!
