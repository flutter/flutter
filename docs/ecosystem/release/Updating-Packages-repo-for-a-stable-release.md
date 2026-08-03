This page describes the process of updating flutter/packages and flutter/core-packages after a stable Flutter release.

# Repository Updates

## flutter/packages

Hotfix releases don't require any changes, since the auto-roller will update the [pinned stable version](https://github.com/flutter/packages/blob/main/.ci/flutter_stable.version), but full stable releases (roughly once per quarter) require manual updates to the repository:
* [The stable pin](https://github.com/flutter/packages/blob/main/.ci/flutter_stable.version) needs to be updated. The autoroller will open a PR, but because it includes a separate commit for every Flutter commit since the last stable, it will overwhelm the CLA check and it will fail. Either the CLA check can be overridden (which is safe since the source repo enforces the CLA), or a new manual PR can be made that updates the hash.
* The [Flutter Dart version mapping](https://github.com/flutter/packages/blob/3498b9d7b67143a68dc43b90951acb577e92f64e/script/tool/lib/src/common/core.dart#L70-L106) needs to be updated. The [Flutter SDK releases page](https://docs.flutter.dev/release/archive) is a useful reference.
  * In addition to adding the new release, add the last bugfix version of the previous stable, for the next step.
* The [N-1 and N-2 legacy analysis tests](https://github.com/flutter/packages/blob/3498b9d7b67143a68dc43b90951acb577e92f64e/.ci.yaml#L290-L304) need to be updated. We generally use the latest bugfix versions for these tests.
* The [minimum allowed Flutter version](https://github.com/flutter/packages/blob/3498b9d7b67143a68dc43b90951acb577e92f64e/.repo_tool_config.yaml#L12) for the repo needs to be updated to the N-2 version. (We generally use .0 here, not the latest hotfix, under the assumption that there are not going to be analysis-breaking changes in a hotfix.)
  * This should ideally be done in the same PR as the previous step, since that is the point at which we no longer have any coverage of the previous minimum version.
* All packages need to be updated to that minimum version. This can be trivially done with the repo tooling. E.g.:

  `dart run script/tool/bin/flutter_plugin_tools.dart update-min-sdk --flutter-min=3.44.0`

  * Per [repo policy](../contributing/README.md#version), we do not version-bump these changes, so the associated `update-release-info` command should use `--version=next`. A convenient way to run the `update-release-info` command on only the necessary packages is to make the `update-min-sdk` run its own commit, then use a command like:
  
    `dart run script/tool/bin/flutter_plugin_tools.dart update-release-info --version=next --changelog="Updates minimum supported SDK version to Flutter 3.44/Dart 3.12." --base-branch HEAD^ --run-on-changed-packages`
  
    to target only the packages changed in that commit. Some manual cleanup will be needed to remove SDK bump lines from the previous `stable` in packages that have not released in the meantime, to avoid having multiple SDK bumps in the same changelog entry.
  * This must be done in the same PR as the previous step, or CI will fail.
* The [release action](https://github.com/flutter/packages/blob/e7d812cefce083fa09762d25cd42303737d05b9f/.github/workflows/release.yml#L34) should be updated to use the new stable.

Many of these steps can be done separately, but it's often easiest to combine them into a single PR ([example](https://github.com/flutter/packages/pull/11741)).

## flutter/core-packages

flutter/core-packages needs the same conceptual changes as flutter/packages, but the CI configuration is different:
* There is not a single `stable` pin, or separate tasks for N-1/N-2 testing. Instead, each GitHub Action that references a specific Dart version needs to be updated. For example:
  * [The multi-version Dart analysis and test matrix](https://github.com/flutter/core-packages/blob/6e41b6679caec9c229e65a71169a6fee1e3e3825/.github/workflows/multi_version_tasks.yaml#L31), which should include the corresponding stable, N-1, and N-2 Dart versions for each of the Flutter versions in flutter/packages.
  * [Dart unit tests on Windows](https://github.com/flutter/core-packages/blob/6e41b6679caec9c229e65a71169a6fee1e3e3825/.github/workflows/windows_unit_tests.yaml#L36)
  * [The release action](https://github.com/flutter/core-packages/blob/6e41b6679caec9c229e65a71169a6fee1e3e3825/.github/workflows/release.yml#L31)
* The repo-level tool configuration sets [a minimum Dart version](https://github.com/flutter/core-packages/blob/6e41b6679caec9c229e65a71169a6fee1e3e3825/.repo_tool_config.yaml#L14) rather than a minimum Flutter version.
* Currently the repository tooling does not have a `--dart-min` option for `update-min-sdk`, so you will need to run `update-min-sdk` using your local copy of the repo tooling that includes the version mapping changes from the flutter/packages steps, and pass the same `--flutter-min` (which will then map to the correct Dart minimum).

# Issue Updates

Sweep all [`p: waiting for stable update` issues](https://github.com/flutter/flutter/labels/p%3A%20waiting%20for%20stable%20update), and update those that are now unblocked to indicate that they can now be addressed (removing the label).

For any that are about deprecated API usage, upgrade them to `P1`, and either find an owner for them or remove the owning team's `triaged-*` label, leaving a comment that the deprecated API usage needs to be removed ASAP to minimize future disruption to package clients.
  * The motivation for treating these as P1 is that many clients do not update their packages (in particular, their transitive dependencies) frequently, so the further in advance of the eventual API *removal* the publishing of an update is, the fewer clients will have build errors on future updates of Flutter.

# PR Updates

Similarly sweep all [`p: waiting for stable update` PRs](https://github.com/flutter/packages/labels/waiting%20for%20stable%20update) and comment and remove labels as necessary.
