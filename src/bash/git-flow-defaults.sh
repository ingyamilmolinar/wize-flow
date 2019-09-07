#!/usr/bin/env bash

git config gitflow.feature.start.fetch yes --local
git config gitflow.feature.finish.fetch yes --local
git config gitflow.feature.finish.push yes --local
git config gitflow.feature.finish.no-ff yes --local

git config gitflow.release.start.fetch yes --local
git config gitflow.release.finish.fetch yes --local
git config gitflow.release.finish.push yes --local
# TOFIX: This one does not work
git config gitflow.release.finish.ff-master no --local

git config gitflow.bugfix.start.fetch yes --local
git config gitflow.bugfix.finish.fetch yes --local
git config gitflow.bugfix.finish.push yes --local
git config gitflow.bugfix.finish.no-ff yes --local

git config gitflow.hotfix.start.fetch yes --local
git config gitflow.hotfix.finish.fetch yes --local
git config gitflow.hotfix.finish.push yes --local
git config gitflow.hotfix.finish.nobackmerge yes --local
