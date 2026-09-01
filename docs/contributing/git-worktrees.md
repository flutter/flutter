---
type: Contributor Doc
title: Git & Git Worktree Workflow Guide for Flutter Development
description: How to efficiently manage multiple concurrent branches and pull requests using Git worktrees.
resource: A practical guide to leveraging Git worktrees in Flutter development for tracking multiple release channels (master, beta, stable), managing concurrent feature branches, and conducting PR reviews without duplicating repository clones or managing git stashes.
tags: [git, worktrees, contributing, branches, PR review, feature development]
timestamp: 2026-07-23T15:26:31-0700
---

# Git & Worktree Workflow Guide for Flutter Development

Traditional `git` development follows a simple pattern for smaller projects: clone, commit, push, update. Medium projects tend to add branching and release workflows. Flutter is a large project with many moving parts and engineers wearing different hats at different times: framework, engine, infrastructure, release, android, iOS, gardener, sheriff, triage.

This document covers a recommended workflow that should be flexible for all engineers contributing to Flutter, reduce cloned repository size and wasted space, and provide guidance for common tasks.

## Setup

Having one [flutter development environment](https://github.com/flutter/flutter/blob/main/docs/contributing/Setting-up-the-Framework-development-environment.md#set-up-your-environment) incurs a cost when changing branches between master, stable, and feature development - triggering a redownload of flutter artifacts, recompiling the flutter tool, and oftentimes requiring stashing of work. Running third party tools (vscode, dart analyzer, or agent) can also run into trouble when the local branch is changed. Having multiple git clones requires duplication of the `.git` folder for the same source code, juggling environment path changes or using OS aliasing techniques to call the correct version of flutter.

Instead, we use git worktrees: a way to manage multiple working directories, each with a different branch checked out, all linked to the same Git repository. Using [flutter_worktree](https://github.com/jtmcdole/flutter_worktree#installation) we can end up with a flutter tree setup to track upstream/origin correctly, and have master/stable already checked out.

```shell
~/flutter/
    ├── .bare/         (The bare repo or main tracking folder)
    ├── .git           (pointer to .bare/)
    ├── fswitch.sh     ("fswitch" command line with tab completion - win32:.ps1)
    ├── master/        (Always clean, main development branch)
    ├── stable/        (Locked to latest stable release for repros)
    ├── review-179637/ (Temporary folder for reviewing PR #1234)
    └── feature/new-widget/    (Long-running feature work)
```

This has the benefit of sharing the `.bare` git repository amongst all trees. The source files for each branch must be *unpacked* from `.bare` and the `<tree>/bin/cached` binaries are downloaded to the tree if you run the flutter tool.  The install script for flutter_worktree will create the `fswitch.sh` file which you can use in your bash/zsh/windows profile to quickly `fswitch <branch>` and update your environment's path without re-downloading (on Windows, Linux, and macOS).

With the following directory structure; and with `fswitch.sh` sourced in your profile (e.g. `~/.zshrc`), you can now have multiple terminals open and dedicated to master and stable with a simple `fswitch master` / `fswitch stable`. This updates the current shell session’s OS PATH search to point to `master/bin` or `stable/bin`, allowing for VsCode, Antigravity, and other tooling to find the right version of Flutter for tooling.

```shell
--- /Users/codefu/src/flutter ---
    1.9 GiB [#############################] /master
  932.7 MiB [##############               ] /stable
  738.2 MiB [###########                  ] /pr-review
  487.0 MiB [#######                      ] /.bare
    8.0 KiB [                             ]  fswitch.sh
    4.0 KiB [                             ]  .git
```

> [!WARNING]
> Do not run tools like vscode from the root folder as this can cause them to stall trying to index all of the worktrees.

### Common Scenarios

> [!NOTE]
> This document follows the Flutter conventions for naming remotes:
>
> * **upstream**: `git@github.com:flutter/flutter.git` (Fetch target for master/beta/stable)
> * **origin**: `git@github.com:<your-username>/flutter.git` (Push target for feature PRs)

#### Code Reviews

Instead of doing code reviews on [github.com](https://github.com) and lacking the feature rich dart analyzer, or being able to use an agent and other advanced tooling; check out the PR locally.

Without the `gh` tool:
```shell
# 1. Fetch the PR HEAD
git fetch upstream pull/189954/head:pr-189954

# 2. Checkout the PR - automatically follows pull/189954/head
git worktree add pr-189954

# 3. Perform the review
cd pr-189954

# git log HEAD -n1
# commit d277b8d7652b1baaf5844dc70040c60914b9eb5c (HEAD -> pr-189954)
# Author: engine-flutter-autoroll <engine-flutter-autoroll@skia.org>
# Date:   Thu Jul 23 21:35:02 2026 +0000

# ... vscode, vim, antigravity.

# 4. Delete the worktree when done. Remember to change to any other worktree or the root (with the `.bare` folder)
git worktree remove pr-189954
```

With the `gh` tool it's easier:

```shell
git worktree add prreview
cd prreview
gh pr checkout 189954
```

#### New Feature Development

You picked up a feature to implement a new widget, assign yourself the issue, and start work:

```shell
# Start a new worktree branched from latest HEAD
git worktree add feature/new-widget

# Switch and start work
cd feature/new-widget
code .

# Push it upstream
git push --set-upstream origin $(git branch --show-current)

# ... get reviews, make changes, pass tests

# Delete the tree when done
git worktree remove feature/new-widget
```

There's no need to stash or upload changes until you are ready. You can update master / stable / other feature branches without losing context in `feature/new-widget`.

#### Bug Investigation (Stable)

If you've picked up a well documented  issue to investigate; you can simply `fswitch stable` and test against stable.

```shell
# Switch to stable branch
fswitch stable
# Or if you want to bisect starting at some baseref
git worktree add bugHunt baseref
fswitch bugHunt # updates the binaries in the environment PATH
cd bugHunt # changes to the bugHunt worktree
# ... git bisect
# Get the reprocode from the issue
mkdir repro_code && ....

# Debug however you need to
flutter run

# Alternate to master and see if its already fixed?
fswitch master
flutter clean
flutter run

# You could even check out an old stable
cd ~/src/flutter
git worktree add beta upstream/beta
fswitch beta
flutter clean
flutter run
```

If you verify the bug and want to start a new PR; you can just create a worktree like a feature rather than juggling changes in your stable/master branch.

## Modern Git Commands

Git commands you should be using (and why).

### Git Switch

`git branch` is for managing branches (creating, listing, deleting) - while `git switch` is for **navigating** **between** them.  Prior to 2019, we would use `git checkout` to switch between branches, but this is an overloaded command and leads to confusion…. E.g.  `switch` operates on branches whereas `checkout` can operate on files (`git checkout -- file.txt`)

```shell
# Create and change to new feature
git switch -c new-feature

# Just switch
git switch master

# House keeping
git branch -d new-feature
```

> [!NOTE]
> If `branch` is already checked out in another worktree, git will refuse to switch to it with a message like:
>
> ```shell
> fatal: 'master' is already used by worktree at '/Users/codefu/src/flutter/master'
> ```

### Git Restore

Instead of using `git checkout` as a swiss army knife; use `git restore`:

If you edit a file but realize you made a mess and just want it back to how it was in the last commit:

```shell
git restore config.json
```

If you added a file too early, i.e. the file is in **staging**:

```shell
git restore --staged secret_keys.env
```

### Git Reset

This is for time traveling in your tree and has three modes: soft, mixed, and hard.

#### Oops, I made a typo in the commit (soft)

You committed your work, but realized you forgot to include one file, or you messed up the commit message.

```shell
# The commit is gone, but the files are currently green (staged).
# You can fix the file/message and run git commit again.
git reset --soft HEAD~1
```

#### I want to split a big commit into two smaller ones (--mixed)

This is the default mode when running `git reset`

```shell
# The commit is gone. The files are there but red (unstaged).
# You can now git add file A, commit it, then git add file B,
# and commit that separately.
git reset HEAD~1
```

#### Throwing in the Towel

You've tried fixing a bug, spent 3 hours on it, and realized everything is borked. You just want to go back to when the code worked.

```shell
# All work since the last commit is erased
# Yar, there be dragons.

git reset --hard HEAD~1
```

## Other Git Topics

### Rebase vs Merge

There are two ways to update a Pull Request (PR) branch with upstream changes: **merging** and **rebasing**. Because Flutter is a large-scale project with automated infrastructure, specific assumptions are made regarding a PR's history, diffing, baseline compatibility, and engine artifacts. Flutter runs best with a rebase workflow.

**Technical reasoning:**

* `git merge master` (*discouraged*): Creates a non-linear history by generating a new "merge commit" at the tip of your branch. While a merge does shift the local `git merge-base` forward to include the latest `master` commits, it introduces a diamond-shaped commit graph. Automated tooling or metrics scripts checking chronological commit age or topological order can misinterpret the branch history, leading to flaky CI/CD evaluations.
* `git rebase upstream/master` (*encouraged*): Rewrites your branch history by picking up your unique commits and planting them directly on top of the latest `master` commit. This maintains a perfectly **linear history**. The base of your branch becomes the absolute tip of `master`, ensuring that content hashes, tests, and build artifacts are validated against a clean codebase rather than a mixed history.

**Social reasoning:**

* **Merge**: If you merge `master` into your branch multiple times over a long development cycle, your PR history becomes cluttered with "Merge branch 'master' into..." commits. This noise obscures your actual work, making it difficult for maintainers to review your specific changes.
* **Rebase**: It presents a clean, chronological  story: *"Here is my work, applied directly to the latest codebase."* It signals to the reviewer that you have verified your code works cleanly alongside the most recent upstream changes.

**Conflict Reasoning:**
Given the high velocity of the Flutter repository, conflicts with `master` are common.

* **With a merge**, you resolve conflicts inside a noisy, standalone "merge commit."
* **With a rebase**, you resolve conflicts **within your own individual commits**. This keeps the final code clean and ensures your discrete commits remain atomic and functional if they ever need to be cherry-picked later.

**Force Pushing Safely**

Because a `rebase` rewrites your branch's commit **history**, a standard `git push` will be rejected by GitHub. You must force push.

**Never use** `git push -f`. Instead, always use a lease. This instructs Git to check if anyone else has pushed to your remote branch since you last fetched, preventing you from accidentally overwriting a coworker's or maintainer's work.

```shell
git push --force-with-lease
```

> [!TIP]
> Always git rebase on `upstream/master` on Flutter PRs.

### Interactive Rebase Workflow

Follow this sequence to cleanly update your feature branch and squash minor commits before requesting a review:

```shell
# Update your upstream master references and clean up deleted branches
git fetch upstream --tags --prune

# Or optionally fetch everything. Will take longer.
git fetch --all --tags --prune

# Start an interactive rebase on top of the fresh upstream master
git rebase -i upstream/master
```

**What this does:**

1. Opens your preferred editor with a list of your commits.
2. Allows you to `squash` (combine commits) or `fixup` (combine commits and discard the message). Use this to merge "typo fix" or "wip" commits into meaningful units of work.
3. Re-applies your newly cleaned, atomic commits sequentially directly on top of the latest upstream master

### Stacked PRs

What's better than one giant PR that might be expensive to review? Multiple small PRs that build on top of each other - each building successfully on their own.  GitHub doesn't properly support / render stacked PRs like GitLab / Graphite / others; but we can still achieve a happy path.

Let's say you have broken down a feature into two smaller ones, `feature-1a` and `feature-1b`.

**Base-feature**
Merge-Base: `master`
Head: `feature-1a`
GitHub UI: Shows only changes in `feature-1a`

**Stacked PR**
Merge-Base: `feature-1a`
Head: `feature-1b`
GitHub UI: Shows changes in `feature-1b`  - **only for branches on flutter/flutter**
Clean-diff: https://github.com/<GITHUB_USER>/flutter/compare/<feature-1a>...<feature-1b>

```shell
# 1. Start on latest HEAD
git worktree add feature-1a

# 2. Create Feature 1
cd feature-1a

# ... work, test, commit ...

# 3. Create the second part (Stacking on Feature 1)
git switch -c feature-1b

# ... work, test, commit ...

# Push both PRs
git push origin feature-1a
git push origin feature-1b

# Feedback comes in: changes requested in feature-1a; you are currently in feature 1b
# If its simple; you can interactive rebase and edit
git rebase -i --update-refs upstream/master

# If its not simple; you can checkout feature-1a, do some work, and rebase feature 1b
###
  git switch feature-1a

  # hack hack
  git add <files>
  git commit -m "Fix review comments"

  # Update feature-1b
  git switch feature-1b
  git rebase feature-1a
###

# Once done - update the PRs with lease
git push origin feature-1a # assumes you only made commits to feature-1a
git push --force-with-lease origin feature-1b
```

If you find yourself rebasing this stacked set of features on top of master; you can set the following to have git automatically move tracked branches:

```shell
git config --global rebase.updateRefs true
```

Example:

```shell
(Base)      A --- B --- C  [master]
                   \
(Stack 1)           D  [feature-1a]
                     \
(Stack 2)             E  [feature-1b] (HEAD) <- feature-1b is checked out

git rebase upstream/master

(Base)      A --- B --- C  [master]
                         \
(Stack 1)                 D' [feature-1a]  <-- MOVED AUTOMATICALLY!
                           \
(Stack 2)                   E' [feature-1b] (HEAD)
```

#### Landing feature-1a / updating feature-1b

Since Flutter squashes PRs before merging them to master, the history at master is NOT the same as the history in your stacked changes. If you were to rebase feature-1b onto master, you'll hit conflicts.  To get around this trap, you simply need to:

```shell
# 1. Update to get the new squash commit with feature-1a.
git fetch upstream --tags --prune

# 2. Rebase feature-1b onto master, ignoring the old feature-1a commits
# --onto <new-base> <old-base> <branch-to-move>
git rebase --onto upstream/master feature-1a feature-1b

# 3. Push the update.
git push --force-with-lease origin feature-1b
```
