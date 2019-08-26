#!/usr/bin/env bash

git config gitflow.feature.start.fetch yes
git config gitflow.feature.finish.fetch yes
git config gitflow.feature.finish.push yes
git config gitflow.feature.finish.no-ff yes

git config gitflow.release.start.fetch yes
git config gitflow.release.finish.fetch yes
git config gitflow.release.finish.push yes
git config gitflow.release.finish.ff-master no

git config gitflow.bugfix.start.fetch yes
git config gitflow.bugfix.finish.fetch yes
git config gitflow.bugfix.finish.push yes
git config gitflow.bugfix.finish.no-ff yes

git config gitflow.hotfix.start.fetch yes
git config gitflow.hotfix.finish.fetch yes
git config gitflow.hotfix.finish.push yes
git config gitflow.hotfix.finish.nobackmerge yes
