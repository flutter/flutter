The packages gardener role currently makes use of several tools and communication channels only available to Google employees. See [On-call scheduling for Flutter] for an overview of work required to make this process more open.

## Objective

The packages gardener’s role is to eliminate impediments to engineering velocity on teams working on the [flutter/packages] repository, and to minimize the latency with which critical fixes arrive in our customers' hands. To that end, we maintain a rotation so that there is a clear owner and point of contact for flutter/packages issues, and so that engineers can plan their work around an assumption of reduced productivity during their rotation.

The packages gardener's core responsibilities are:
* Keep the flutter/packages tree green to keep developers, and the release process unblocked.
* Keep the various packages rollers (see below) rolling.
* Ensure others are informed of issues which may affect them.
* Ensure bugs/investigations are delegated and taken care of by the right person, which may be themself.
* Update the list of known deprecations (see below).

The gardener's responsibilities do not include:
* Work beyond working hours. **Tree redness does not trump work-life balance.** Contributors may escalate issues outside of the gardener's working hours, but the gardener is not responsible for responding until the next work day.
* Personally investigate issues or fix bugs, unless the right person to investigate and fix is the gardener themself.

As such, the gardener should use their trowel and hat to:
* Aggressively roll back problematic changes (in all relevant repositories including [flutter/packages] and [flutter/flutter]).
* Delegate investigations/issues to the right engineer(s) on the team, and follow-up.
* Detect infrastructure issues that cause test failures and flakiness and report to the infrastructure team.
* Notify the [Flutter framework gardener] when a framework change causes the flutter/packages roller to fail in a way that can’t easily be fixed locally.
* Proactively communicate issues/status to others upstream/downstream.

## Rotation
Rotations are managed in the [Rotations tool]. The [packages gardener calendar] can be added to your calendar. Both of these links are currently Google internal.

Team members are not expected to participate in multiple Flutter rotations. For example, Flutter framework gardeners are exempt and vice versa. New team members should be added to a single rotation.

Before heading out on holiday, or if you get to your shift and find you can't do it, check the upcoming rotations and find a volunteer to swap shifts with while you're out. During some holiday periods when many team members are out and activity is particularly low on the tree, it may not be essential to have a dedicated gardener.

### Journal

Please briefly describe any issues you encountered during your week of gardening in the [packages gardening journal], along with any solutions you think may be useful for other gardeners in the future!

## Periodic scan

Below are the tasks that should be done routinely while gardening.

### Dashboard
Open the [packages build dashboard].
1. If the tree is closed, identify which test shards are failing. If there are yellow boxes with an exclamation point, that means that the failed tests are automatically re-running themselves. The tree is not fully closed until there are solid red boxes or red boxes with exclamation points. You can begin investigation as soon as you notice the tree going red, but it is suggested not to begin escalation until re-runs have completed.
1. Identify which test within the shard failed, and try to locate obvious errors or failures in the logs.
1. Update the [hackers-ecosystem channel] on [Discord] with an announcement that the tree is red, and that you are working on it.
1. Cross reference the failure with the commit in question. If it is obvious the PR in question caused the failure, [revert](#reverting-commits) immediately.
1. Search through the [Flutter issues] for any existing issues with the same error. Some flakes are not specific to a specific test suite, but are nonetheless flakes and should not require a revert.
1. If the test failure is not a known flake or infrastructure issue, [revert it immediately](#reverting-commits).
1. When the tree reopens, announce it in the [hackers-ecosystem channel] on [Discord].
1. If the tree is open, investigate green exclamation point squares, which are tests that have failed, rerun, and then passed. They may be [flaky and warrant an investigation](#handling-a-flaky-test). They also may have hit an intermittent infrastructure issue.

Unmute the [hackers-ecosystem channel] and [hackers-infra channel] on [Discord]. Contributors are encouraged to escalate tree closures to you. Respond there as quickly as possible.

### Rollers

Check that all of the auto-rollers are running:
* [flutter/flutter → flutter/packages][flutter-to-packages roller]
* [flutter/packages → flutter/flutter][packages-to-flutter roller]
    * This roller only rolls once per day, on weekdays, in order to avoid roller loops with the flutter/flutter → flutter/packages roller.
* [Flutter `stable` → flutter/packages][flutter-stable-to-packages roller]
    * This should only do something when there is a Flutter stable channel update, so will often be idle.

If a roller's status is not `running`, contact the person who paused it and work with them make sure whatever work needs to be done to re-activate the roller is happening.

If a roller is failing, check the recent runs to see why, and take action to ensure that the roller starts succeeding again. If the issue will take a while to resolve, pause the roller while resolving it, and include an explanation of why.

### Deprecations

Our analysis options do not flag deprecated API usage ([context][deprecation context]), but it’s important that we not leave deprecated API usage in our packages for any longer than necessary, since when the APIs are eventually removed anyone still using versions of the package predating the fix will get build errors that many developers find confusing and hard to resolve.

Once during your rotation, do a manual check for any new deprecations:
1. Ensure that your local checkout is updated and has no changes.
1. Comment out `deprecated_member_use: ignore` in `analysis_options.yaml` at the root of the repository.
1. Run `dart run script/tool/bin/flutter_plugin_tools.dart analyze \
   --custom-analysis=script/configs/custom_analysis.yaml`
1. Compare the failures to [this list][deprecated api issues] to see if there is anything new, and if so file it.
    * Include the deprecated API in the issue name, and any details from the error message (e.g. suggested replacement) in the issue.
    * Add the `team-ecosystem`, `packages`, `p: deprecated api`, and `c: tech-debt` labels.
        * If possible, assign the issue to the person who did the deprecation. Searching the relevant repository for the deprecation message is often a quick way to find the PR and its author.
    * If fixing it requires an API that is not yet available on stable, add the `p: waiting for stable update` label.
        * If it's easy to determine, include the version that the replacement API will be available in the issue description.
    * Exception: If a deprecation warning is from a package integration test that is testing a deprecated API from that package (which does not count as `deprecated_member_use_from_same_package` since the example is technically a different package), annotate it with an `ignore` instead, so it doesn’t show up in this manual check in the future.

#### Consider fixing deprecated APIs
If old deprecations have reached the point where they can be fixed without losing support for stable, considering using some of your gardening time to replace the deprecated API usage.

## Handling failures

### Tracking
File GitHub issues if none are already open.
1. The title should include the name of the failing test.
1. Assign the issue to the test owner with a `P1` priority.
1. Add the `team` label.
1. Include links to the failing tests. Download any relevant logs and attach them to the issue, even if the link to the failing tests has the same information. This prevents the issues from becoming stale when logs are expunged.
1. @ mention the test owner in the [hackers-ecosystem channel] on [Discord] with a link to the GitHub issue. If they are unavailable, escalate to another team member. Continue escalating until someone acknowledges the issue is being investigated.
1. Investigation updates and questions should not be posted in the [tree-status channel]. This channel should remain free of noise to discourage notification muting.

### Escalation
* If the issue is specific to infrastructure, see [filing an infra ticket] in the Flutter gardener rotation.
* If the [flutter/flutter → flutter/packages][flutter-to-packages roller] is failing in ways that can't easily be resolved locally, contact the Flutter gardener and/or the author of the PR causing the issue, to discuss a revert or fix.

### Reverting commits
If a test failure is attributable to a commit, revert the commit immediately.

If the commit landed within the last 24 hours:
1. Locate the patch PR and add the `Revert` label. Our infrastructure will automatically create a revert PR and land it.

If the commit could not be automatically reverted:
1. Create a revert pull request from the bad merged pull request via the "Revert" button at the bottom.
1. Add the `revert` label to the PR to allow the bot to land it without approval.
1. Add the original author to the as a reviewer so they are notified. If they are not a member of [flutter-hackers], also include the original pull request reviewers.
1. In "Related Issues" add a link to any GitHub issues that describe the failure.
1. @ mention the author in the [hackers-ecosystem channel] with a link to the revert pull request. If they are unavailable, send an email. If they are not a [Flutter committer][flutter-hackers] and are not on Discord, escalate to the reviewers of the original pull request.
1. As soon as analysis test passes, merge it. You do not need to wait for all presubmit tests to pass, or for an LGTM.
1. Reopen any issues that were automatically closed by the original commit. Add a comment: "This has been reverted with pull request #1234."

### Handling a flaky test
Flakes are particularly productivity-killing since they silently trigger all of the key problems the gardener is meant to prevent: red tree status. As such flakes should be treated in the same way a reproducible breakage is treated -- as though they were always failing.

If you see a test failure that appears to be a flake:
1. Re-trigger the test.
1. If the build fails to fail (i.e. "passes"), it's a flake and should be treated as a failing test.
1. Follow the instructions in this guide to find or create a new GitHub issue.
1. If the test has neither been recently introduced, nor recently changed, disable the test. The test owner will turn it back on or delete the test as part of their investigation.

[flutter/packages]: https://github.com/flutter/packages
[flutter/flutter]: https://github.com/flutter/flutter
[Flutter framework gardener]: /docs/infra/Flutter-Framework-Gardener-Rotation.md
[Flutter issues]: https://github.com/flutter/flutter/issues
[deprecation context]: https://github.com/flutter/packages/pull/6111
[deprecated api issues]: https://github.com/flutter/flutter/labels/p%3A%20deprecated%20api
[flutter-hackers]: https://github.com/orgs/flutter/teams/flutter-hackers
[packages build dashboard]: https://flutter-dashboard.appspot.com/#/build?repo=packages
[Discord]: https://discord.gg/BS8KZyg
[hackers-ecosystem channel]: https://discord.com/channels/608014603317936148/608020293944082452
[hackers-infra channel]: https://discord.com/channels/608014603317936148/608021351567065092
[Rotations tool]: https://rotations.corp.google.com/rotation/4867844301914112
[packages gardener calendar]: https://calendar.google.com/calendar/render?cid=c_6q4le5gj1d9jb5lpvk246vug5s@group.calendar.google.com
[filing an infra ticket]: /docs/infra/Flutter-Framework-Gardener-Rotation.md#filing-an-infra-ticket
[flutter-to-packages roller]: https://autoroll.skia.org/r/flutter-packages
[packages-to-flutter roller]: https://autoroll.skia.org/r/flutter-packages-flutter-autoroll
[packages gardening journal]: https://goto.google.com/flutter-packages-gardener-journal
[flutter-stable-to-packages roller]: https://autoroll.skia.org/r/flutter-stable-packages
[On-call scheduling for Flutter]: https://docs.google.com/document/d/1i-11by4J3zvxWG3qLMm4MKfJ8DrjIJna6DPA9tBmJWc/edit#heading=h.w8bl5vic6x95
