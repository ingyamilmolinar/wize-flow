#!/usr/bin/env bash

git config gitflow.feature.start.fetch yes --local
git config gitflow.feature.finish.fetch yes --local
git config gitflow.feature.finish.push yes --local
git config gitflow.feature.finish.no-ff yes --local

git config gitflow.release.start.fetch yes --local
git config gitflow.release.finish.fetch yes --local
git config gitflow.release.finish.push yes --local
# Because this will be managed through PR
git config gitflow.release.finish.nodevelopmerge yes --local
git config gitflow.release.finish.pushdevelop no --local
git config gitflow.release.finish.nobackmerge yes --local

git config gitflow.bugfix.start.fetch yes --local
git config gitflow.bugfix.finish.fetch yes --local
git config gitflow.bugfix.finish.push yes --local
git config gitflow.bugfix.finish.no-ff yes --local

git config gitflow.hotfix.start.fetch yes --local
git config gitflow.hotfix.finish.fetch yes --local
git config gitflow.hotfix.finish.push yes --local
git config gitflow.hotfix.finish.nobackmerge yes --local
