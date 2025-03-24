This page describes the process of updating flutter/packages after a stable Flutter release. Hotfix releases don't require any changes, since the auto-roller will update the [pinned stable version](https://github.com/flutter/packages/blob/main/.ci/flutter_stable.version), but full stable releases (roughly once per quarter) require manual updates to the repository:
* [The stable pin](https://github.com/flutter/packages/blob/main/.ci/flutter_stable.version) needs to be updated. The autoroller will open a PR, but because it includes a separate commit for every Flutter commit since the last stable, it will overwhelm the CLA check and it will fail. Either the CLA check can be overridden (which is safe since the source repo enforces the CLA), or a new manual PR can be made that updates the hash.
* The [Flutter Dart version mapping](https://github.com/flutter/packages/blob/b4985e25fe0763ece3cfd7af58e0e8c9b9f04fc4/script/tool/lib/src/common/core.dart#L59-L71) needs to be updated. The [Flutter SDK releases page](https://docs.flutter.dev/release/archive) is a useful reference.
  * In addition to adding the new release, add the last bugfix version of the previous stable, for the next step.
* The [N-1 and N-2 legacy analysis tests](https://github.com/flutter/packages/blob/b4985e25fe0763ece3cfd7af58e0e8c9b9f04fc4/.ci.yaml#L223-L237) need to be updated. We generally use the latest bugfix versions for these tests.
* The [minimum allowed Flutter version](https://github.com/flutter/packages/blob/b4985e25fe0763ece3cfd7af58e0e8c9b9f04fc4/.ci/targets/repo_checks.yaml#L19) for the repo needs to be updated to the N-2 version. (We generally use .0 here, not the latest hotfix, under the assumption that there are not going to be analysis-breaking changes in a hotfix.)
  * This should ideally be done in the same PR as the previous step, since that is the point at which we no longer have any coverage of the previous minimum version.
* All packages need to be updated to that minimum version. This can be trivially done with the repo tooling. E.g.:

  `dart run script/tool/bin/flutter_plugin_tools.dart update-min-sdk --flutter-min=3.7.0`

  * Per [repo policy](../contributing/README.md#version), we do not version-bump these changes, so the associated `update-release-info` command should use `--version=next`. A convenient way to run the `update-release-info` command on only the necessary packages is to make the `update-min-sdk` run its own commit, then use `--base-branch HEAD^ --run-on-changed-packages` to target only the packages changed in that commit.
  * This must be done in the same PR as the previous step, or CI will fail.
* The [release action](https://github.com/flutter/packages/blob/e7d812cefce083fa09762d25cd42303737d05b9f/.github/workflows/release.yml#L34) should be updated to use the new stable.

Many of these steps can be done separately, but they can also be done in combined PRs (as few as one). As an example, 3.13 was done in two PRs: [#4370](https://github.com/flutter/packages/pull/4730) and  [#4371](https://github.com/flutter/packages/pull/4731).

### Issue Updates

Sweep all [`p: waiting for stable update` issues](https://github.com/flutter/flutter/labels/p%3A%20waiting%20for%20stable%20update), and update those that are now unblocked to indicate that they can now be addressed (removing the label).

For any that are about deprecated API usage, upgrade them to `P1`, and either find an owner for them or remove the owning team's `triaged-*` label, leaving a comment that the deprecated API usage needs to be removed ASAP to minimize future disruption to package clients.
  * The motivation for treating these as P1 is that many clients do not update their packages (in particular, their transitive dependencies) frequently, so the further in advance of the eventual API *removal* the publishing of an update is, the fewer clients will have build errors on future updates of Flutter.

### PR Updates

Similarly sweep all [`p: waiting for stable update` PRs](https://github.com/flutter/packages/labels/waiting%20for%20stable%20update) and comment and remove labels as necessary.