The framework gardener role currently makes use of several tools and communication channels only available to Google employees. See [On-call scheduling for Flutter] for an overview of work required to make this process more open.

## Objective

The framework gardener's role is to eliminate impediments to engineering velocity on the framework, tool, and related teams working on the [Flutter framework][flutter/flutter] repository, to unblock rolls into the repository, and to minimize the latency with which critical fixes arrive in our customers' hands. To that end, we maintain a rotation so that there is a clear owner and point of contact for Flutter repo issues, and so that engineers can plan their work around an assumption of reduced productivity during their rotation.

The framework gardener's core responsibilities are:
* Keep the framework tree green to keep developers, upstream autorollers, and the release process unblocked.
* Ensure others are informed of issues which may affect them.
* Ensure bugs/investigations are delegated and taken care of by the right person, which may be themself.

Gardener responsibility does not include:
* Work beyond working hours. **Tree redness does not trump work-life balance.** Contributors may escalate issues outside of the gardener's working hours, but the gardener is not responsible for responding until the next work day.
* Personally investigate issues or fix bugs, unless the right person to investigate and fix is the gardener themself.

As such, the gardener should use their badge and hat to:
* Aggressively roll back problematic changes.
* Delegate investigations/issues to the right engineer(s) on the team, and follow-up.
* Detect infrastructure issues that cause test failures and flakiness and report to the infrastructure team.
* Notify the engine sheriff when an engine roll causes the [flutter/flutter] tree to close.
* Proactively communicate issues/status to others upstream/downstream.

## Rotation

Rotations are managed in the [Rotations tool]. The [Framework Gardener calendar] can be added to your calendar. Both of these links are currently Google internal.

Team members are not expected to participate in multiple Flutter rotations. For example, those on the engine rotation are exempt and vice versa. New team members should be added to a single rotation, depending on the team to which they belong.

Before heading out on holiday, or if you get to your shift and find you can't do it, check the upcoming rotations and find a volunteer to swap shifts with while you're out. During some holiday periods when many team members are out and activity is particularly low on the tree, it may not be essential to have a dedicated gardener.

## Periodic scan

Open the [Framework build dashboard].
1. If the tree is closed, identify which test shards are failing. If there are yellow boxes with an exclamation point, that means that the failed tests are automatically re-running themselves. The tree is not fully closed until there are solid red boxes or red boxes with exclamation points. You can begin investigation as soon as you notice the tree going red, but it is suggested not to begin escalation until re-runs have completed.
1. Identify which test within the shard failed, and try to locate obvious errors or failures in the logs. This procedure will be different if the failure is in [devicelab](#handling-a-devicelab-failure) or [LUCI](#handling-a-luci-failure).
1. Update the [tree-gardener channel] on [Discord] with an announcement that the tree is red, the affected shard(s), and the failure message from the logs.
1. Cross reference the failure with the commit in question. If it is obvious the PR in question caused the failure, [revert](#reverting-commits) immediately.
1. Search through the [Flutter issues] for any existing issues with the same error. Some flakes are not specific to a specific test suite, but are nonetheless flakes and should not require a revert.
1. If the failure is happening on an engine roll, [escalate to the engine sheriff](#handling-an-engine-roll-failure).
1. If the test failure is not a known flake or infrastructure issue, [revert it immediately](#reverting-commits).
1. Escalate to the [test owner][TESTOWNERS].
1. When the tree reopens, announce it in the [tree-gardener channel] on [Discord].
1. If the tree is open, investigate green exclamation point squares, which are tests that have failed, rerun, and then passed. They may be [flaky and warrant an investigation](#handling-a-flaky-test). They also may have hit an intermittent infrastructure issue.
1. Check [benchmarks](#handling-a-benchmark-regression) for regressions. File issues and escalate.

Unmute the [tree-gardener channel] and [hackers-infra channel] on [Discord]. Contributors are encouraged to escalate tree closures to you. Respond there as quickly as possible. If you'd like automatic notifications of when the tree goes red, you can also unmute the [tree-status channel].

### Escalation

Escalate to the [test owner][TESTOWNERS]. File GitHub issues if none are already open.
1. The title should include the name of the failing test.
1. Assign the issue to the test owner with a `P1` priority.
1. Add the `team` label.
1. Include links to the failing tests. Download any relevant logs and attach them to the issue, even if the link to the failing tests has the same information. This prevents the issues from becoming stale when logs are expunged.
1. @ mention the test owner in the [tree-gardener channel] on [Discord] with a link to the GitHub issue. If they are unavailable, escalate to another team member. Continue escalating until someone acknowledges the issue is being investigated.

### Handling a devicelab failure

See [Why Flutter Devicelab Tests Break].
1. If devicelab square (Android, Apple, or Windows icon) is red or yellow, click the square and click the _Download All Logs_ button. Note these logs may include the output from several test runs, since they will automatically rerun on failure to detect flakes.
1. If many different tests are failing on the same agent, this may be an indication of infra failure. File an [infrastructure ticket] if needed.
1. Note that phones occasionally require manual reboot. If this occurs, escalate on the [hackers-infra channel] on [Discord] file an [infrastructure ticket].

### Handling a Firebase Test Lab failure

The devices in the Firebase test lab are not managed by the Flutter infra team.

1. The LUCI logs will typically list the device that the test failed for. Check the logs for a Firebase link that will contain logs from the failing device. [Example log](https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8772117221814493585/+/u/test_execution/gcloud_firebase__2_/stdout).
1. If the failure described in the logs does not appear to be related to a recent commit, contact the [omnilab-ftl-flutter](https://groups.google.com/a/google.com/g/omnilab-ftl-flutter/about) group.
1. Alternatively, check the LUCI log for instructions on how to notify Firebase via Slack.

### Handling a LUCI failure

1. If Chrome icon (LUCI) square is red, click the red square and _Open Log for Build #1234_ to see the failing test in LUCI.
1. File an [infrastructure ticket] if needed.

### Reverting commits

If the test failure is not a known flake or infrastructure issue, revert the commit immediately.

If the commit landed within the last 24 hours:
1. Locate the patch PR and add the `Revert` label. Our infrastructure will automatically create a revert PR and land it.

If the commit could not be automatically reverted:
1. Create a revert pull request from the bad merged pull request via the "Revert" button at the bottom.
1. Add the `revert` label to the PR to allow the bot to land it without approval.
1. Add the original author to the as a reviewer so they are notified. If they are not a member of [flutter-hackers], also include the original pull request reviewers.
1. In "Related Issues" add a link to any GitHub issues that describe the failure.
1. @ mention the author in the [tree-gardener channel] with a link to the revert pull request. If they are unavailable, send an email. If they are not a [Flutter committer][flutter-hackers] and are not on Discord, escalate to the reviewers of the original pull request.
1. As soon as the `analyze-linux` test passes, merge it. You do not need to wait for all presubmit tests to pass, or for an LGTM.
1. Reopen any issues that were automatically closed by the original commit. Add a comment: "This has been reverted with pull request #1234."

### Handling a flaky test
Flakes are particularly productivity-killing since they silently trigger all of the key problems the gardener is meant to prevent: red tree status. As such flakes should be treated in the same way a reproducible breakage is treated -- as though it were always failing.

If you see a test failure that appears to be a flake:
1. Re-trigger the test.
1. If the build fails to fail (i.e. "passes"), it's a flake and should be treated as a failing test.
1. Follow the instructions in this guide to find or create a new GitHub issue.
1. If the test has neither been recently introduced, nor recently changed, disable the test. The test owner will turn it back on or delete the test as part of their investigation.

### Handling an engine roll failure
If the failure is happening on an engine roll, contact the [Engine Sheriff chat] so the engine sheriff can locate and revert the engine or upstream commit(s) causing the issue.

Coordinate with the engine sheriff on pausing and unpausing the [Engine to Framework autoroller] during this process.

### Handling a benchmark regression

Check [framework benchmarks] for regressions. File issues and escalate.

Review [engine benchmarks] for any regressions. Choose the _Triage_ item on the left, and walk through new issues. For each commit that caused a regression you'll see marks in columns corresponding to the regression --- those marks indicate whether the results at that commit are low or high.

Click a mark, and you'll be taken to a popup with the plot of recent data around the commit in question. From here you can:
1. Choose _View Dashboard_ to see long term trends around the commit. (When in the dashboard you can use the WASD keys to zoom in and out).
1. Click the commit to get a sub-popup with a link that can take you to the commit in question.

If there is a new regression not deemed to be noise in a benchmark:
1. [Add a new issue to GitHub][new issue]
1. Label the issue with `team: benchmark`, and `severe:regression` labels. Label it with the `severe:performance` label if the benchmark is a performance one.
1. Paste a link to the performance plot from skia-perf into the bug. This is a "permalink", and will help others see what you're seeing.
1. Determine the CL at which the regression started and label with which part of the codebase might be causing the problem and whoever submitted the CL if possible.
1. Attempt to determine the team who should receive the issue. Usually the suspect roll is a clue.
1. Assign an initial priority.
   1. Reserve `P0` for regressions significantly (1.5x or more) above the noted baselines, or with regular spikes that suggests a possible issue with the device lab.
   1. Reserve `P2` for issues where slow creep appears to be happening.
1. Note the bug ID in the comment where you address the regression in skia-perf and reject the benchmark (click the _X_).
1. Notify the target teams where you've identified regressions on [Discord], and include links. When you do so, make sure you @ someone (ideally the TL for that team) so that it's noticed.
1. Notify the Flutter engine sheriff and Flutter Hackers Discord chats with any issues you file.
If it's noise, accept the benchmark by clicking the checkbox in the triage details popup.

### Handling a Skia gold failure

See the [golden test build breakage] guide.

## Filing an infra ticket

1. Open a [new infra issue].
1. Add a descriptive title. A message like "Add a LUCI builder for linux web engine" or "Debug gallery startup" is much more helpful than "quick request" or "test doesn't work?".
1. Clearly describe the issue or request in the description field. For example, if a ticket is requesting running several commands on the bots, the ticket should explain why, what commands are needed, on which bots and how to verify the results.
1. Add the `team: infra` label and a priority label:
   * `P0` (immediate): Such as a build break or regression.
      * Fix as soon as possible, before any other work.
      * Should be very rare, and only used when critical work is blocked without a workaround.
      * Ideally is downgraded to P1 as soon as a workaround is found.
   * `P1` (high): Users are suffering but not blocked; or, an immediate-level incident will happen if this is not addressed (e.g., almost out of quota).
      * Fix today (8 business hours).
      * Degraded service (Build bots work but are slow to start).
      * Time-sensitive requests.
      * Should be relatively rare.
   * Anything below `P1` is not suitable for the infra ticket queue and will be treated as a normal infra bug.
1. Add the project "Infra Ticket Queue".
1. Click the create button. No need to set an assignee; infra oncall will handle all new tickets.

## Communication channels (public)

The bulk of communication happens on [Discord].
* Tree closure escalation and announcements: [tree-gardener channel].
* Automated bot posts of tree red/green status: [tree-status channel].
* Infra issues: [hackers-infra channel]
* Infrastructure tickets: File an [infrastructure ticket].

## Communication channels (Google-internal)

* Engine issues: [🐣 Flutter Engine Sheriff ($USERNAME) ⛑️][Engine Sheriff chat]
* LUCI help chat: [LUCI Users][LUCI Users chat]

## References
* [Flutter Engine Sheriff Playbook] (Google internal)
* [On-call scheduling for Flutter]

[infrastructure ticket]: #filing-an-infra-ticket

[flutter/flutter]: https://github.com/flutter/flutter
[Flutter issues]: https://github.com/flutter/flutter/issues
[TESTOWNERS]: https://github.com/flutter/flutter/blob/main/TESTOWNERS
[flutter-hackers]: https://github.com/orgs/flutter/teams/flutter-hackers
[golden test build breakage]: /docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md#build-breakage
[new issue]: https://github.com/flutter/flutter/issues/new/choose
[new infra issue]: https://github.com/flutter/flutter/issues/new?template=6_infrastructure.yml

[Framework build dashboard]: https://flutter-dashboard.appspot.com/#/build
[framework benchmarks]: https://flutter-flutter-perf.skia.org/e/
[engine benchmarks]: https://flutter-engine-perf.skia.org/e/

[Discord]: https://discord.gg/BS8KZyg
[tree-gardener channel]: https://discord.com/channels/608014603317936148/1290464157765865552
[tree-status channel]: https://discord.com/channels/608014603317936148/613398423093116959
[hackers-infra channel]: https://discord.com/channels/608014603317936148/608021351567065092
[Engine Sheriff chat]: http://go/engine-sheriff
[LUCI Users chat]: https://mail.google.com/chat/u/0/#chat/space/AAAAXGgrwSo

[Rotations tool]: https://rotations.corp.google.com/rotation/5721991649689600
[Framework Gardener calendar]: https://calendar.google.com/calendar/render?cid=c_him0pti4q5k4h9999u2dv9oouk@group.calendar.google.com

[Flutter Engine Sheriff Playbook]: https://goto.google.com/engine-sheriff
[On-call scheduling for Flutter]: https://docs.google.com/document/d/1i-11by4J3zvxWG3qLMm4MKfJ8DrjIJna6DPA9tBmJWc/edit#heading=h.w8bl5vic6x95

[Engine to Framework autoroller]: https://autoroll.skia.org/r/flutter-engine-flutter-autoroll?tab=status
