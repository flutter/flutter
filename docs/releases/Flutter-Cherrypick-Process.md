# Flutter Cherry-pick Process

## Goal

With branching and branch testability being supported for Flutter & Dart releases, cherry-picking fixes is the preferred method to address issues for released software (beta and stable channels.)  Stability of the release will be the overarching goal, so only highly impactful and critical cherrypicks will be allowed across Dart and Flutter.  This document outlines the process for requesting and approval of cherrypicks.

**Note: This process applies to regressions from the previous release or serious bugs otherwise introduced by the current release.  Feature work is not considered for cherry-picking and will need to wait for the next release.**

## Automatically Creates a Cherry Pick Request

Eligibility:
1. If your cherry pick is expecting to have a merge conflict, please skip this section and follow instructions in the FAQ section below to manually open a cherry pick request instead. (e.g. PRs that contain changes to .ci.yaml files are very likely to hit a merge conflict)
2. The framework PR to be cherry picked needs to have a base commit later than [01/24/2024](https://www.google.com/url?q=https://github.com/flutter/flutter/pull/142058&sa=D&source=docs&ust=1706904517596608&usg=AOvVaw3cFfw8vyiBtY3EzM_N-PEi), and the engine PR to be cherry picked has a base commit later than [02/06/2024](https://github.com/flutter/engine/pull/50265)
3. The target branch is either [beta](https://github.com/flutter/flutter/blob/beta/bin/internal/release-candidate-branch.version) or [stable](https://github.com/flutter/flutter/blob/stable/bin/internal/release-candidate-branch.version). (not a new beta branch that isn't yet created)

For automatic cherry pick:
1. Add the `cp: beta` or `cp: stable` label to the pull request on flutter/flutter master. (you can find [beta](https://github.com/flutter/flutter/blob/beta/bin/internal/release-candidate-branch.version) and [stable](https://github.com/flutter/flutter/blob/stable/bin/internal/release-candidate-branch.version) candidate branch info by following the respective links)
2. Wait about 30 seconds.
3. If automatic cherry pick succeeds (no merge conflict), a new pull requested will be created and you will receive an email. Edit the cherry-pick details in the PR description of the generated pull request, and a release engineer will follow up on the request.
4. If automatic cherry pick fails, a comment will be left on the original PR. In this case you will need to follow instructions in the FAQ section below to manually create a cherry pick PR.

For manual cherry pick:<br >
refer to the FAQ section below

## Frequently asked questions

### How do I request a cherry-pick?

To request a cherry-pick, utilize the [issue template](https://github.com/flutter/flutter/issues/new?template=7_cherry_pick.yml).

### Who can request a cherry-pick?

Anyone can request a cherry-pick.

### When do I request a cherry pick?

- Whenever you have identified a commit on the main/master that fixes an issue that is present on the beta or stable branch.
- Whenever you need to update a pub dependency that fixes an issue that is present on the beta or stable branch (see [Updating dependencies](../infra/Updating-dependencies-in-Flutter.md#to-update-a-single-dependency-for-cherrypicks)

### Who reviews and approves cherry-pick requests?

The release engineering team will assign a cherry-pick reviewer who is an expert in the area of the code that your cherry-pick may affect.

### Lifecycle of a cherry-pick

1. The cherry-pick requester opens a cherry-pick pull request to the [beta](https://github.com/flutter/flutter/blob/beta/bin/internal/release-candidate-branch.version) or [stable](https://github.com/flutter/flutter/blob/stable/bin/internal/release-candidate-branch.version) **candidate** branch (follow the respective link to find the branch name)
2. A cherry-pick issue is filled out completely and created utilizing the [cherry-pick template](https://github.com/flutter/flutter/issues/new?template=7_cherry_pick.yml) in the [flutter/flutter](https://github.com/flutter/flutter) repository.
3. The release engineering team is notified that a cherry-pick request is in queue and assigns an appropriate reviewer who is an expert in the area who will review the cherry-pick issue and associated cherry-pick pull request.
4. The release engineering team applies the `merge-to-beta` or `merge-to-stable` label.
5. The cherry-pick request then enters one of the following states.
   1. Approved: The reviewer has approved the cherry-pick and cherry-pick pull request.
The release engineering team will merge the cherry-pick pull request and apply the `cp: merged` label to the cherry-pick issue.
   2. Denied: The reviewer will comment on the cherry-pick issue why the cherry-pick is denied.
The release engineering team will close the cherry-pick issue and associated cherry-pick pull request.
6. The cherry-pick is picked up in the next release period.
7. Once the cherry-pick has been added to a release, the release engineering team will close the cherry-pick issue.

### This is my first cherry-pick, how do I do it?

This is the perfect opportunity for you to learn and add cherry-picking to your toolbox.  A typical cherry-pick request follows a process similar to the below.

**Note: Commands that are wrapped with < > are variables that apply to your specific situation.**

1. `git checkout <master/main>`
2. `git fetch`
3. `git pull` // ensure all changes from master/main have been pulled
4. `git checkout <candidate branch you want to cherry-pick to>`
5. `git checkout -b <your local branch name for cherry-picking>`
6. `git cherry-pick <your commit hash>`
7. `git push --set-upstream origin <your branch name>`

### What happens if my cherry-pick PR has merge conflicts?

In the case that your cherry-pick commit has a merge conflict, it is up to you to resolve it.  If you can not resolve it, reach out to the original PR author who may be able to help resolve the conflict.

### What if the issue is on a previous stable?

If you discovered an issue on a X version that is no longer on the stable channel, we can still hotfix it in. For stables, we are more likely to do this as that is what most Flutter developers use.

Generally, if the stable is relatively fresh, such as we recently shipped the new stable and a large chunk of developers have not migrated, we would prioritize backporting a fix.

### When should I prioritize fixes to beta instead of stable?

Generally, we ship every third beta to stable, and prioritize fixes to those branches as those are soon to be stable. We have no official comms planned around this yet, but will encourage developers on Discord to try out this beta.

In the last few weeks of a stable, we may opt to only release hotfixes to the beta instead of stable. At end of 2023, we're planning to have more automation around releases, which will allow us to ship hotfixes to both channels easily, and this will be less of a concern.
