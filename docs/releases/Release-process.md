# Release Process

This page documents the processes involved with creating new Flutter releases. If you're interested in learning more about why certain branch points are chosen, or how releases are built, continue reading. If you're looking for the current release info, see the appendix at the bottom.

## Creating new branches

Flutter's has [a list of candidate branches](https://github.com/flutter/flutter/branches/all?query=flutter-), following the format of `flutter-X.Y-candidate.Z`. These are created whenever Flutter is rolled into Google's internal systems. For Googlers, see go/flutter-life-of-a-pr. Generally, these branches are created every few days, and stabilized so they don't break Google tests (such as reverting commits with breakages).

## Selecting a candidate branch

At the start of every month, Flutter aims to ship a new beta to users. We prefer picking the most recent candidate branches for betas, but there are some things we check for:
1. Dart version is ok to ship.

    A. Verify the version has been rolled and verified in Google's internal codebase

    B. Dart team is ok with shipping this release

2. No risky changes (such as large scale changes being in progress on the branch)
3. Timing makes sense
  A. For betas that will be promoted to stable, announcements are sent to contributors about the cutoff date. A beta may be held to ensure the cut off date has had a branch point

## Conducting releases

[Conductor](https://github.com/flutter/flutter/tree/main/dev/conductor) is a release tool written in Dart to drive Flutter releases. It's the source of truth for what's needed to ship a release. Generally, it can promote candidate branches to betas, betas to stable, and hotfix releases. It handles the nuances of git, such as pushes, cherrypicks, and tagging, and the complexities of Flutter, such as rolling and release infra.

A Flutter release is very similar to what would be seen on the master branch, with some exceptions:
1. Ensure all builds and tests are green
2. Mac engine binaries are codesigned with a flutter.dev account
3. [Versions are tagged](https://github.com/flutter/flutter/tags)

    A. Stable follows the format of `X.Y.Z`

    B. Beta follows the format of `X.Y.Z-M.N.pre`, where M=number of candidate branches since last beta, and N=number of hotfixes since branching

4. Engine artifacts are packaged and published to flutter.dev
5. api.flutter.dev is updated with the latest docs

### Release Process

Prework: Ensure Flutter's release infrastructure is branched for the current version.

1. Apply any Dart cherry-picks to the Dart branch
2. Roll Dart into [flutter/engine](https://github.com/flutter/engine)
3. Apply any engine cherry-picks
4. Verify all engine builds are green
5. Sign engine binaries
6. Roll engine in [flutter/flutter](https://github.com/flutter/flutter)
7. Apply any framework CPs
8. Verify all framework tests are green
9. Push release to the beta or stable branch, and tag it

    A. This then triggers our packaging builders to update the website

### Hot-fixing releases

[Cherry-pick requests are triaged](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+label%3A%22cp%3A+review%22), and determined if they need a hot-fix. Features are not permitted to be hot-fixed into a release. Approved CP requests are then included in the weekly hot-fix.

Hot-fixes follow the same release process.

## FAQ

### What is packaging?

Packaging is the process of creating an offline zip that includes everything needed to run flutter. Generally, it's a git checkout with `flutter precache` run.

### What version strategy does Flutter use?

Flutter does not use semver. Generally, our increments happen based on time intervals. Z is incremented whenever we ship a weekly hotfix.

### Why do releases require a force push?

Since `stable` and `beta` are branches, new Y releases require a force push. This is due to us not merging the release branch back into main.

## See also

- [Flutter Cherrypick Process](Flutter-Cherrypick-Process.md)
- [Quality Assurance](Quality-Assurance.md)
- [Flutter build release channels](Flutter-build-release-channels.md)
- [Release versioning](Release-versioning.md)
- [SDK Releases](https://docs.flutter.dev/development/tools/sdk/releases?tab=linux)
- [Where's my Commit?](Where's-my-commit.md)
