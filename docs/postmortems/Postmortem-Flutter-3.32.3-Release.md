# Flutter 3.32.3 Postmortem

**Author**: @matanlurey

**Status**: Final

## Background

The 3.32.3 hotfix release, which included some usability and memory leak fixes for 3.32, accidentally uploaded unsigned artifacts - including the `dart` binary (which is used by most tooling in Flutter, including the `flutter` CLI itself).

As a result, a manual downgrade and a few other possible workarounds were needed to get a working Flutter SDK on macOS, until 3.32.4 could be published with correctly signed binaries.

Three parts of the system failed (not including the GCP outage):

1. Once we realized we wanted to rollback (release a new version that is actually an older version) we couldn't - the release tool lacked that function.
2. Even if the release tool supported rolling back, it's unclear if the `flutter` tool would understand that change.
3. Our recipe code (Python code that runs on our VM fleet and builds and tests the SDK) had a bug where if there were 2 or more commits merged into a release branch in a somewhat short timespan (< 2 hours), previous commits that were _not_ the latest would be assumed by the recipe that they did originate from a release branch, and would not sign the artifacts.
4. The tests that were written to catch unsigned binaries issued a false-positive; they tested engine artifacts that were built for the _current_ SHA, not the SHA of the engine being pointed to by `engine.version`.

## Timeline

- **Jun 4, 2025**: The 3.32.2 release is successfully published.
- **Jun 4, 2025**: Three more cherry-picks were opened:
  - [#170013](https://github.com/flutter/flutter/issues/170013) Fixes a memory leak in Impeller
  - [#170003](https://github.com/flutter/flutter/issues/170003) Fixes a build failure on Android for app bundles
  - [#170052](https://github.com/flutter/flutter/issues/170052) Reverts a PR causing visual glitches with Navigation\* widgets
- **Jun 5, 2025**: The cherrypicks are accepted and merged into the branch. Due to a bug, the PR that changes the engine does not code-sign artifacts.
- **Jun 10, 2025**: A release engineer is on-duty.
- **Jun 11, 2025**: The release engineer prepares to make the 3.32.3 release. [#170470](https://github.com/flutter/flutter/issues/170470) adds an update `engine.version` and `CHANGELOG.md`. Due to _another_ different bug, the code sign tests test a _different_ binary set.
- **Jun 11, 2025**: A release is published.
- **Jun 12, 2025**: An issue reporting code-signing problems is triaged.
- **Jun 12, 2025**: Reverting the release is proposed, but there was no known process to do that (even after escalating to other members of the team). The safest way to proceed, which would be to re-publish 3.32.2 as 3.32.4 is impossible because the release publishing tool can only publish the latest commit, not a previous commit.
- **Jun 12, 2025**: There is a global GCP outage, affecting access to debug. We could not read LUCI logs to investigate how codesigning failed. We also could not prepare a new, fixed release.
- **Jun 12, 2025**: After a few hours, the problem is discovered, a fix is proposed.
- **Jun 12, 2025**: 3.32.4 is published, fixing 3.32.3.

## What went well

- An issue that could have taken hours/days longer to discover was manually triaged. There was only a ~2 hour delay between the issue being filed and a "bunker room" and threads started with the release and infra team.
- A workaround developers could use to get out of this state was discovered 3 hours after the bug was filed, and communicated on the issue. This slightly lessened the urgency of the issue.
- There was lively engagement between the infra and iOS teams with folks knowledgeable enough to figure out what the problems were - there were no escalations needed, process ran itself pretty smooth.
- Given how complex this _could_ have been, there was a relatively fast resolution in terms of identifying the core problem, figuring out a plan, and rolling out a new release. The action items (see below) are all very achievable without large investments.

## What could have gone better

- We could have detected the issue before it went out. A manual smoke test on macOS would have caught this.
- We wanted to immediately publish 3.32.2 as 3.32.4 but the functionality did not exist.
- There is no playbook for what to do when a release is dead-on-arrival.
- We were unsure how to communicate the bad release to the community.
- We were also unsure if the best course of action was to “unpublish” (not possible?), fix forward to a new version, or somehow patch the existing release with a codesigned binary (probably not correct for attestation?).
- We could have had more testing/confidence around `engine.version` artifacts.

## Action Items

| Action item description                                            | Status |
| ------------------------------------------------------------------ | ------ |
| Update the release tooling to be able to specify a commit SHA      | DONE   |
| Fix recipe to correctly identify a commit as a release candidate   | DONE   |
| Stop providing FLUTTER_PREBUILT_ENGINE_VERSION to release branches | DONE   |
