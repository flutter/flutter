# Flutter's CI Best Practices

[flutter.dev/to/ci-yaml](https://flutter.dev/to/ci-yaml)

This is a supplemental resource to provide best practices for using Flutter's
internal CI/CD system. It is not a comprehensive guide, but rather a collection of tips and tricks to be as efficient as possible.

---

Table of Contents

- [Flutter's CI Best Practices](#flutters-ci-best-practices)
  - ["This branch is out-of-date" is not (always) a failure](#this-branch-is-out-of-date-is-not-always-a-failure)
  - [Prefer the `auto-submit` label over pressing "merge"](#prefer-the-auto-submit-label-over-pressing-merge)
  - [Prefer the `revert` label over manual reverts of recent commits](#prefer-the-revert-label-over-manual-reverts-of-recent-commits)
  - [Prefer re-running test suites over re-triggering all tests](#prefer-re-running-test-suites-over-re-triggering-all-tests)
  - [Cost of Adding New Test Targets](#cost-of-adding-new-test-targets)
  - [Cost of Renaming/Resharding Tests](#cost-of-renamingresharding-tests)

## "This branch is out-of-date" is not (always) a failure

<img
  alt="This branch is out-of-date"
  width="600"
  src="https://github.com/user-attachments/assets/0de2ad69-fca0-4c63-81ab-79d1b53162d1" />

This message is automatically created by GitHub when at least one commit has
merged into the ancestor branch of the PR. On Flutter's owned repositories, this
is just a warning, and does not prevent merging.

There are two edge cases where merging/rebasing is required or recommended:

1. **When the commit your PR was branched from is causing a test to fail**. If
   a forward fix or revert has since been merged into the ancestor branch, it is
   recommended to rebase your PR to pick up the fix.

2. **When the commit your PR was branched from is more than a few days old**. If
   the commit is more than a few days old, it is recommended to rebase your PR
   in order to make sure that the tests are run against the latest code.

## Prefer the `auto-submit` label over pressing "merge"

<img
  width="400"
  alt="Adding the auto-submit label"
  src="https://github.com/user-attachments/assets/2b9a3d5a-afb0-4c24-8959-5262ce993beb" />

The `auto-submit` label is a special label that can be added to a PR to be
automatically merged (or queued for merging, in `flutter/flutter`'s case) when
the tests are passing. This is the preferred way to merge PRs.

If one or more tests fail, and you're confident that the failure is not related
to your PR (i.e. is a flake), see [prefer re-running test suites over re-triggering all tests](#prefer-re-running-test-suites-over-re-triggering-all-tests).

## Prefer the `revert` label over manual reverts of recent commits

<img
  width="394"
  alt="Adding the revert label"
  src="https://github.com/user-attachments/assets/30fb773e-8b14-4580-94f0-6a650c475469" />

The `revert` label is a special label that can be added to a PR to revert the
commit(s) that are causing a CI failure, and is the preferred way to revert
recently merged commits as it bypasses most testing to get the revert landed as
fast as possible.

Before using this label, You'll need to add a comment on the PR:

```md
reason for revert: This breaks the build, see XYZ link.
```

Please coordinate with the Google team that administrates the repository before
using the `revert` label, as it may not be appropriate to use in all cases, and
could cause confusion if used incorrectly.

## Prefer re-running test suites over re-triggering all tests

<img
  width="341"
  alt="Failing tests with a re-run button"
  src="https://github.com/user-attachments/assets/0076dd4f-3bc3-4ade-8d71-24b1a5e28272" />

Each full test run in `flutter/flutter` uses between 100 and 200 virtual
machines, and takes between 30 and 60 minutes to complete. This is a lot of
resources, and should be avoided if possible.

Pushing a new commit, or using the built-in merge button in GitHub, will
re-trigger all tests in the PR. While sometimes this is necessary, it is a lot
more expensive than re-running a single test suite or even a few test suites.

## Cost of Adding New Test Targets

The Flutter team has a finite amount of resources to run tests, and adding
new test targets, while incrementally useful, can add up to a lot of waiting
time for the team.

As of 2025/05/23, the presubmit pool for `flutter/flutter` has:

- [301 Linux VMs](https://chromium-swarm.appspot.com/botlist?c=id&c=task&c=os&c=status&d=asc&f=os%3AUbuntu&f=pool%3Aluci.flutter.try)
- [131 ARM64 Mac VMs](https://chromium-swarm.appspot.com/botlist?f=cpu%3Aarm64&f=os%3AMac-14&f=pool%3Aluci.flutter.try)
- [134 Windows VMs](https://chromium-swarm.appspot.com/botlist?f=os%3AWindows-10&f=pool%3Aluci.flutter.try)

Resources for on-device testing (device lab) are even more limited.

When you add a new test target, it will consume an entire VM for the time it
takes to clone the repository, setup the test infrastructure, and run the test
suite (often between 15 and 30 minutes, but longer for some integration tests).

While it's important to have a good test suite, consider:

- Does my test target have to run on multiple platforms?
- Is there an existing test target that I can add my test to that is not close
  to the timeout limit?

Consider consulting with the infrastruture team (`team-infra`) before adding a
large number of new test targets, or to get advice on how to best create new
test targets.

## Cost of Renaming/Resharding Tests

_This advice only applies to the `flutter/flutter` repository._

Due to how the test infrastructure works, renaming or resharding tests can be
very time-consuming, and should be avoided if possible, or carefully coordinated
when required:

- New shards must be initially added as `bringup: true`, which means that they
  will not run in presubmit, and do not trigger tree closures in postsubmit.
- The shards will have to be moved to `bringup: false` once they are
  successfully running, which will require a second PR.
- Deleting (or renaming) a shard at tip-of-tree (i.e. `master`) will cause the
  test to be silently skipped in all release candidate branches, and will
  require the `.ci.yaml` file to be cherry-picked into each release candidate
  branch to restore the test coverage.

For example, imagine the following existing test configuration (`.ci.yaml`):

```yaml
targets:
  - name: Linux web_tests_1_2
    shard: web_tests
    subshard: "0"
  - name: Linux web_tests_2_2
    shard: web_tests
    subshard: "1"
```

Behind the scenes, this creates two LUCI builders, one for each test target.

Now imagine you want to add a third shard (effectively, renaming the targets):

```yaml
targets:
  - name: Linux web_tests_1_3
    shard: web_tests
    subshard: "0"
  - name: Linux web_tests_2_3
    shard: web_tests
    subshard: "1"
  - name: Linux web_tests_3_3
    shard: web_tests
    subshard: "2"
```

This will require the following steps:

1. Add 3 new shards to the `.ci.yaml` file, and set `bringup: true` for each of them.
2. Wait for the new shards to be successfully running.
3. Remove the old shards from the `.ci.yaml` file, and set `bringup: false` for each of them.
4. Cherry-pick the `.ci.yaml` file into each release candidate branch to restore the test coverage.

This could require up to 4 PRs, and a lot of coordination with the release team.
