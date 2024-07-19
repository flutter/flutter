# Flutter postmortem: Beta 1 release process

Status: draft<br>
Owners: [@tvolkert](https://github.com/tvolkert), [@Hixie](https://github.com/Hixie)

## Summary

Description: Flutter launched beta 1 on February 27, 2018.  This document attempts to dissect what could have gone smoother strictly from a technical release process point of view.<br>

## Timeline (all times in PST)

### _2018/02/20 - 2018/02/25_

[@tvolkert](https://github.com/tvolkert) tests v0.1.4 in preparation for releasing it to beta on 2018/02/27.

### _2018/02/26_

| Time | |
| --- | --- |
| _11:40_ | [@tvolkert](https://github.com/tvolkert) tries to push v0.1.4 to beta but doesn’t have sufficient permissions, because the branch is protected on GitHub. |
| _12:02_ | [@Hixie](https://github.com/Hixie) adds [@tvolkert](https://github.com/tvolkert) to the beta branch ACL so can push the beta release. |
| _12:07_ | [@tvolkert](https://github.com/tvolkert) pushes v0.1.4 to the beta branch |
| _12:20_ | [@mit-mit](https://github.com/mit-mit) tries to upgrade to the new beta and runs into [#15096](https://github.com/flutter/flutter/issues/15096).  The exact cause is not yet known. |
| _12:39_ | From similar reports from [@timsneath](https://github.com/timsneath) and [@mit-mit](https://github.com/mit-mit), [@tvolkert](https://github.com/tvolkert) notices that switching channels doesn’t fetch updated refs from GitHub and files [#14893](https://github.com/flutter/flutter/issues/14893). |
| _14:40_ | [@timsneath](https://github.com/timsneath) runs into more trouble upgrading.  [@tvolkert](https://github.com/tvolkert) begins trying to diagnose based on the reports. |
| _16:53_ | After a few back-and-forths with [@timsneath](https://github.com/timsneath) over email, [@tvolkert](https://github.com/tvolkert) enlists the help of [@jason-simmons](https://github.com/jason-simmons) and [@cbracken](https://github.com/cbracken) in tracking down the cause for the problems [@timsneath](https://github.com/timsneath) is encountering.  The goal is to determine whether the problems are an outlier unique to [@timsneath's](https://github.com/timsneath) setup or whether they’re likely to affect most users once the influx of users begins. |
| _17:30_ | [@jason-simmons](https://github.com/jason-simmons) discovers that before [#14507](https://github.com/flutter/flutter/pull/14507) (v0.0.24), the “channel” command could create local (non-tracking) branches and that if [@timsneath](https://github.com/timsneath) was bitten by this, it would explain the behavior he’s seeing.  The team tentatively decides the errors that [@timsneath](https://github.com/timsneath) is seeing are likely an outlier. |
| _20:00_ | [@tvolkert](https://github.com/tvolkert) manages to reconstruct [@timsneath's](https://github.com/timsneath) environment setup and confirms [@jason-simmons'](https://github.com/jason-simmons) theory.  The team adds a [section to the wiki](../releases/Flutter-build-release-channels.md#workaround) covering this case for users who may run into it. |

### _2018/02/27_

| Time | |
| --- | --- |
| _01:48_ | [@mit-mit](https://github.com/mit-mit) discovers that the gallery doesn’t run against the beta build and files [#14912](https://github.com/flutter/flutter/issues/14912).
| _02:18_ | [@mravn-google](https://github.com/mravn-google) tracks down the cause of the failing gallery builds and discovers that it’s already been fixed in [#14714](https://github.com/flutter/flutter/pull/14714) (v0.1.5).
| _06:00_ | The beta release is announced publicly.
| _09:30_ | The Flutter team decides to push v0.1.5 to beta to pick up the fix to the gallery builds.  [@tvolkert](https://github.com/tvolkert) begins testing v0.1.5.

### _2018/02/28_

| Time | |
| --- | --- |
| _10:00_ | [@tvolkert](https://github.com/tvolkert) pushes v0.1.5 to beta.
| _10:20_ | [@tvolkert](https://github.com/tvolkert) [announces](https://groups.google.com/d/msg/flutter-dev/AFj7Rd_MNhY/lkMfRTDwAQAJ) the updated beta to the flutter-dev mailing list.
| _16:00_ | [@tvolkert](https://github.com/tvolkert) discovers that docs.flutter.io did not update to reflect the beta release and files [#15002](https://github.com/flutter/flutter/issues/15002).

## Lessons Learned

### What Worked

* Beta 1 was successfully released on the target date!

* Most users have been able to successfully install Flutter against the beta release or upgrade from the dev channel.  We’ve received only a few reports of problems; e.g. [#15074](https://github.com/flutter/flutter/issues/15074), [#14959](https://github.com/flutter/flutter/issues/14959)

* When the report of the failing gallery build hit, we were able to successfully vet a new dev build and push a new release to beta a day and a half later.

### What Didn't Work

* Our internal Google tests purposely don’t exercise our external build code paths (e.g. Gradle builds) — since within Google, everything is built using Bazel.  This meant that although the gallery was unable to be built on the beta branch ([#14912](https://github.com/flutter/flutter/issues/14912)), we had no knowledge of this failure until after beta was pushed (and [@mit-mit](https://github.com/mit-mit) manually discovered the breakage).  The bug had actually already been fixed on a newer dev build (in [#14714](https://github.com/flutter/flutter/pull/14714)), but we didn’t mark the affected build range as bad until after this was discovered and traced back to code that pointed to the existing fix. Our external tests were also [allowing failures on Travis](https://github.com/flutter/flutter/blob/5b46e0a4bef24e1c1302ba3ca40a99bd20a192da/.travis.yml#L18-L19), which was intentional at the time because we didn’t yet have confidence in those tests.  In addition to fixing the issue, [#14714](https://github.com/flutter/flutter/pull/14714) also enabled those tests on Travis.

* The Flutter [release process](../releases/Release-process.md#rolling-the-beta-channel) didn’t call out the need to build and run the gallery as part of the beta vetting process, which further allowed the previous issue to go unnoticed.

* The Flutter team didn’t have on its radar to mark builds as bad when they saw or fixed issues that would warrant marking a build as bad.  It’d be nice to have a better (ideally more automated) process around this.

* The release process instructs the person doing the release to ensure that the build:
  > can be successfully upgraded _to_ from an earlier dev build (via 'flutter upgrade')<br>
  > can be successfully upgraded _from_ to a later dev builds (via 'flutter upgrade')

  Yet, there’s no way to cause the upgrade to stop at the target build - it always upgrades to tip-of-tree on the relevant branch.  This means that the person doing the release is not experiencing the exact same upgrade path that the user will be experiencing.

* [@tvolkert](https://github.com/tvolkert), who was doing the roll, didn’t have permission to update `HEAD:beta` because it’s a restricted branch on GitHub.

* We pushed a follow-on beta build (v0.1.4 -> v0.1.5) the day after launch to fix the issue with the gallery building.  Yet absent of [reading the flutter-dev email list](https://groups.google.com/forum/#!msg/flutter-dev/AFj7Rd_MNhY/lkMfRTDwAQAJ), users had no way of knowing that an upgrade was available because the flutter tool doesn’t alert them.

* The release process calls for the person doing the roll to simulate the upgrade path of our users, but it says “can be successfully upgraded to from an earlier dev build,” which is not explicitly the same upgrade that our users will face; they’ll be upgrading from one of the previous beta releases.  This distinction would have led us to realize that such users would be bitten by [#15096](https://github.com/flutter/flutter/issues/15096).

* Users who stay exclusively on the beta channel and only upgrade when new beta releases are available will have Git repositories without any of the newer refs that have been added since their last upgrade.  The person doing the beta release, on the other hand, will have a fresh clone of our Git repository and will be simulating our users’ upgrade path by issuing a `git reset --hard <old-version>` command.  This distinction turned out to be substantive when trying to reproduce an error report from [@timsneath](https://github.com/timsneath).  Ideally, the person doing the roll would be able to construct a Git repository synced to the previous beta release without any refs newer than that release.

### Bugs That Got in the Way

* In the “channel” command, we weren’t fetching updated refs from GitHub before [checking out the branch](https://github.com/flutter/flutter/blob/eaa9b47a4ac278a9439468911d2c361a472b114b/packages/flutter_tools/lib/src/commands/channel.dart#L103).  This meant that if a user had switched to the beta branch in the past, then switched back to the alpha/dev branch as their primary channel, their beta Git head would be pointing to a commit in December.  Net result: we had to [recommend](../releases/Flutter-build-release-channels.md#how-to-change-channels) that users run `flutter channel beta && flutter upgrade`, which is clunky.

* Until Feb 7 ([#14507](https://github.com/flutter/flutter/pull/14507)), we had a bug in the channel switching logic that would create branches as local (non-tracking) branches.  If users tried to upgrade such channels, they’d get an error message about “no upstream repository configured.”  Users who had tried switching to the beta channel that we had quietly pushed in December 2017 were bitten by this and found their local Git repository in a bad state.  This likely only affected a very small number of users (perhaps only members of the Flutter team), but [@timsneath](https://github.com/timsneath) was one such user, and it took some time to remotely diagnose what was going on with his setup and whether his problems were indicative of a larger issue that was going to affect a large subset of our users.  This time added uncertainty to our launch during crunch-time, where we weren’t sure if we should call off the launch announcements.

* The change that prepared the docs site for the beta launch ([#14606](https://github.com/flutter/flutter/pull/14606)) had a bug in it whereby docs would never get updated on the main docs site ([#15002](https://github.com/flutter/flutter/issues/15002)), and unfortunately this didn’t get caught in code review (partially due to GitHub code review’s auto-folding of very relevant content).  This means that the main docs site hasn’t been updated since ~Feb 13 (and will now get updated in the next beta push).

* Once the beta branch was pushed, Travis began failing due to [#14975](https://github.com/flutter/flutter/issues/14975).  A similar failure had happened on master and was fixed by [#14853](https://github.com/flutter/flutter/pull/14853), but the implications of that failure and how it’d manifest on the beta branch caused some confusion as to whether there was a real problem with the beta release.

## Action items

### Prevention

| Action Item | Owner | Issue | Notes |
|-------------|-------|-------|-------|
| Ensure that Travis tests the ability to build the gallery. | [@xster](https://github.com/xster) || [Done](https://github.com/flutter/flutter/pull/14714) |
| Build all examples on Travis and AppVeyor on the dev branch. | [@xster](https://github.com/xster) | [#15164](https://github.com/flutter/flutter/issues/15164) ||
| Add a hidden `--version` argument to `flutter upgrade` to allow the person doing a beta roll to better simulate the upgrade path. | [@tvolkert](https://github.com/tvolkert) | [#14970](https://github.com/flutter/flutter/issues/14970) ||
| Fetch upstream refs before switching channels in the “channel” command. | [@tvolkert](https://github.com/tvolkert) | [#14893](https://github.com/flutter/flutter/issues/14893) | [Done](https://github.com/flutter/flutter/pull/14896) |

### Mitigation

| Action Item | Owner | Issue | Notes |
|-------------|-------|-------|-------|
| Make the flutter tool alert users when an upgrade is available. | [@tvolkert](https://github.com/tvolkert) | [#14920](https://github.com/flutter/flutter/issues/14920) ||

### Process

| Action Item | Owner | Issue | Notes |
|-------------|-------|-------|-------|
| Add a wiki page on identifying bad builds | [@tvolkert](https://github.com/tvolkert) | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp; | [Done](../releases/Bad-Builds.md) |
| Send an email to the core Flutter team about the need to think about marking builds as bad. | [@tvolkert](https://github.com/tvolkert) || Done |
| Update our release process to call out the need to ensure that the gallery can be built and run. | [@tvolkert](https://github.com/tvolkert) || [Done](../releases/Release-process.md#rolling-the-beta-channel) |
| Update release process to require that the Travis build go green on the beta branch before sending out any announcements or issuing any public communications. | [@tvolkert](https://github.com/tvolkert) || [Done](../releases/Release-process.md#rolling-the-beta-channel) |
| Make a beta pusher group in GitHub, to control who has access to push beta releases. | [@Hixie](https://github.com/Hixie) || [Done](../releases/Release-process.md#rolling-the-beta-channel) |
| Update beta release process to require that the candidate dev build “can be successfully upgraded to from the dev build to which the beta branch currently points.” | [@tvolkert](https://github.com/tvolkert) || [Done](../releases/Release-process.md#rolling-the-beta-channel) |
| Update the release process to include downloading and installing the packaged archive for the dev build that represents the prior beta — and ensuring that it’s able to upgrade to the newest release. | [@gspen...](https://github.com/gspencergoog) |||

### Fixes

| Action Item | Owner | Issue | Notes |
|-------------|-------|-------|-------|
| Fix docs to get uploaded on the next beta push | [@tvolkert](https://github.com/tvolkert) | [#15002](https://github.com/flutter/flutter/issues/15002) | [Done](https://github.com/flutter/flutter/pull/15003) |
| Fix create_test.dart to depend on package:flutter_test for its “package” template tests (not package:test) | [@tvolkert](https://github.com/tvolkert) | [#14975](https://github.com/flutter/flutter/issues/14975) | [Done](https://github.com/flutter/flutter/pull/14976) |
