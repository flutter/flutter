"Google testing" is the test suite that Google runs to test a flutter pull request against their internal code base. This check shows up as one of the many check runs at the bottom of an open pull request.

![Screenshot 2023-02-24 at 3 45 33 PM](https://user-images.githubusercontent.com/38773539/221321907-edaca6c3-2165-4bfe-b436-00fcd64e820e.png)

## Validation Pipeline (60 minutes total)

1. Triggering google testing (<1 minute)

   Google testing starts once an approval from a Flutter hacker is given. For Googlers, the check is run immediately. Google testing is triggered on GitHub webhooks, and uses a 30-minute cron job to backfill when webhooks are dropped.

2. Running google testing (30 minutes)

   A subset of tests have been selected to run on presubmit as our smoke test suite. This gives quick, high coverage for PRs without running everything.

3. Propagating results back to GitHub (30 minutes)

   Once Google Testing finishes, it takes up to 1 hour for the results to be propagated back to Github. Once the result is available on Github, it will show "Google Testing" as either "success" or "failure".

## Common issues

### There's goldens failures on my PR, but those are expected

If a Googler has verified the goldens are expected, the Googler can update internally the check to passing. This will indicate that we should accept the scubas. However, once merged, this will go through a second round of review as our smoke test suite only runs a subset of the codebase.

### My PR got reverted due to it breaking Google, but the check never ran on presubmit!

As of January 2024, Google testing is using webhooks to power most of the validation. In the rare case this happens, please file a bug and add "team-google-testing" as the label to it so we can see what went wrong.

### My PR has an infra error

Use the GitHub check run UI to rerun. If it goes from failing -> passing, it will be marked as a flake. The team that owns Google testing monitors the flake rate, and is working to get it under <1%.

If the issue is not a flake, a Googler is necessary to investigate the infra error. As of Feb 2024, the most common infra error is related to race conditions when creating the internal CL for testing.

#### What if the failure is expected or unrelated to my change?

Googlers can go to http://frob and override the results.

## Where can I get help?

GitHub issues with the label "team-google-testing" are triaged weekly.

For Googlers, you can use go/file-frob-bug for issues where confidential information is needed for debugging.

For live questions, you can ask in [#hackers-infra](https://discord.com/channels/608014603317936148/608021351567065092).