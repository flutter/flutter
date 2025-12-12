# Understanding Google Testing

"Google Testing" is a presubmit check that runs a subset of internal Google
tests on most pull requests, and indicates whether the tests are still passing
at the current state of the Flutter repository with the proposed pull request
applied.[^note-for-engine]

[^note-for-engine]: For PRs that only update the framework. For engine PRs, the
    best we achieve is "the current state of Google + the
    current engine at the base of the PR + proposed PR".

This check shows up as one of the many check runs at the bottom of an open pull
request:

!["Google testing - Google testing passed!"](https://user-images.githubusercontent.com/38773539/221321907-edaca6c3-2165-4bfe-b436-00fcd64e820e.png)

<details>

<summary>Details about the Validation Pipeline</summary>

1.  Triggering Google testing (<1 minute)

    Google testing starts once an approval from a member of flutter-hackers is
    given. For Googlers, the check is run immediately. Google testing is
    triggered on GitHub webhooks.

2.  Waiting for the engine to be built (40 minutes)

    If the PR updates the engine, Google testing will wait for the Flutter CI to
    build the engine artifacts.

3.  Running smoke tests (~10 minutes)

    A subset of tests have been selected to run on presubmit as our smoke test
    suite. This gives quick, high coverage for PRs without running everything.

4.  Running a larger test suite (30 - 90 minutes)

    A larger set of tests will run after smoke tests have passed. This usually
    takes 30-90 minutes depending on the change, capacity etc. It could take up
    to several hours on a busy day.

</details>

This check helps catch obvious problems, and allow the pull request author and
reviewers an early warning that either:

1.  More changes are needed to avoid a breaking change.
1.  Google code or golden-files will need to be updated as a part of the roll.
1.  Some communication with the roll team is required to make the change safely.


## Common issues

### My PR is blocked on Google testing

Google employees can view the test output and provide feedback for next steps.

If your reviewer is a Googler, ping them on the PR to let them know the change
is blocked. Reviewers will typically be notified already if, for example, the
[`autosubmit`](Autosubmit-bot.md) label was removed by the bot.

If your reviewer is not a Googler, reach out in the `#hackers` channel on
[Discord](../contributing/Chat.md) for support.

In order to track pull requests blocked on Google testing for resolution, have
your reviewer add yours to the
[Github testing queue project](https://github.com/orgs/flutter/projects/200).
Pull requests in the queue are addressed in a FIFO fashion. The project will
display where your change is in the queue.

For full guidance on presubmit failures, see
[fix failing checks](../contributing/testing/Fix-failing-checks.md#google-testing).

### My PR has expected golden file failures

If a Googler has verified the golden file changes are expected, the Googler can
internally update the check to passing.

### There are non-golden failures on my PR, but that change is intended

If the change is small (a dozen or so changes across files), we ask that a
Googler - either the PR author (or reviewer) add a "g3fix", or otherwise
contribute fixes directly into the roll CL that gets the state back to green. If
the author and reviewer are unavailable, the roller may choose to revert the PR
instead.

### Google testing claims that there is a merge conflict in my PR, but GitHub claims otherwise

The "merge base" that Google testing uses is usually several commits behind
GitHub. Merge conflict could happen if your PR depends on another PR that has
been merged very recently. The issue will usually be resolved in several hours,
try to rebase your PR after several hours, or use the GitHub check run UI to
rerun.

### The test failures are unrelated to my PR

Googlers can use the "Rerun failed tests" button on the internal page.

### My PR failed Google testing because of unrelated infra issue

Use the GitHub check run UI to rerun. If it goes from failing -> passing, it
will be marked as a flake.

If the issue is not a flake, a Googler can help investigate the infra error, and
if necessary manually override the results.

### My PR got reverted due to it breaking Google, but the check never ran on presubmit

In the rare case this happens, please file a bug and add `team-infra` as the
label to it so we can see what went wrong.

## Where can I get help?

Work with your reviewer to resolve blocked changes. If there is an
infrastructure issue related to Google testing, an issue should be filed with
the label `team-infra`. Confirm with your reviewer before filing one.

GitHub issues with the label `team-infra` are triaged weekly.

For Googlers, you can use go/file-frob-bug for issues where confidential
information is needed for debugging.

For live questions, you can ask in
[#hackers-infra](https://discord.com/channels/608014603317936148/608021351567065092).
