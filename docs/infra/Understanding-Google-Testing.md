# Understanding Google Testing

"Google Testing" is a presubmit check that runs a subset of internal Google
tests on most pull requests, and indicates whether, at the current state of the
Flutter repository + the proposed pull request[^note-for-engine] if most a smoke
test of Google presubmits, are still passing.

[^note-for-engine]:
    For PRs that only update the framework. For engine PRs, the
    best we achieve is "the current state of Google + the current engine at the base
    of the PR + proposed PR".

This check shows up as one of the many check runs at the bottom of an open pull
request:

!["Google testing - Google testing passed!"](https://user-images.githubusercontent.com/38773539/221321907-edaca6c3-2165-4bfe-b436-00fcd64e820e.png)

<details>

<summary>Details about the Validation Pipeline</summary>

1. Triggering google testing (<1 minute)

   Google testing starts once an approval from a member of flutter-hackers is given. For Googlers, the check is run immediately.
   Google testing is triggered on GitHub webhooks, and uses a 30-minute cron job to backfill when webhooks are dropped.

2. Running google testing (30 minutes)

   A subset of tests have been selected to run on presubmit as our smoke test suite. This gives quick, high coverage for PRs without running everything.

3. Propagating results back to GitHub (30 minutes)

   Once Google Testing finishes, it takes up to 1 hour for the results to be propagated back to Github. Once the result is available on Github, it will show "Google Testing" as either "success" or "failure".

</details>

This check helps catch obvious problems, and allow the pull request author and
reviewers an early warning that either:

1. More changes are needed to avoid a breaking change.
1. Google code or golden-files will need to be updated as a part of the roll.
1. Some communication with the roll team is required to make the change safely.

Sometimes the check does not function as expected (see: [common issues](#common-issues)).

## Common issues

### My PR is blocked on Google testing

Google employees can view the test output and provide feedback for next steps.

If your reviewer is a Googler, ping them on the PR to let them know the change is blocked.
Reviewers will typically be notified already if, for example, the [`auto-submit`](Autosubmit-bot.md)
label was removed by the bot.

If your reviewer is not a Googler, reach out in the `#hackers` channel on [Discord](../contributing/Chat.md)
for support.

In order to track pull requests blocked on Google testing for resolution, have your reviewer add yours to
the [Github testing queue project](https://github.com/orgs/flutter/projects/200). Pull requests in the queue
are addressed in a FIFO fashion. The project will display where your change is in the queue.

For full guidance on presubmit failures, see [fix failing checks](../contributing/testing/Fix-failing-checks.md#google-testing).

### There's goldens failures on my PR, but those are expected

If a Googler has verified the goldens are expected, the Googler can internally update the check to passing. This will indicate that we should accept the scubas. However, once merged, this will go through a second round of review as our smoke test suite only runs a subset of the codebase.

### There's non-golden failures on my PR, but that change is intended

If the change is small (a dozen or so changes across files), we ask that a Googler - either the PR author (or reviewer) add what we call
a "g3fix", or otherwise contribute fixes directly into the roll CL that gets the state back to green. If the author and reviewer are unavailable, the roller may choose to revert the PR instead.

### My PR got reverted due to it breaking Google, but the check never ran on presubmit

In the rare case this happens, please file a bug and add `team-infra` as the label to it so we can see what went wrong.

### My PR has an infra error

Use the GitHub check run UI to rerun. If it goes from failing -> passing, it will be marked as a flake.

If the issue is not a flake, a Googler is necessary to investigate the infra error, and if necessary
manually override the results.

## Where can I get help?

Work with your reviewer to resolve blocked changes. If there is an infrastructure issue related to Google testing,
an issue should be filed with the label `team-infra`. Confirm with your reviewer before filing one.

GitHub issues with the label `team-infra` are triaged weekly.

For Googlers, you can use go/file-frob-bug for issues where confidential information is needed for debugging.

For live questions, you can ask in [#hackers-infra](https://discord.com/channels/608014603317936148/608021351567065092).
