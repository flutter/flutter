The flutter/packages repository has a variety of tests; while many are relatively self-explanatory (for instance, a failure in `dart_unit_tests` in presubmit can be debugged simply by running the failing Dart unit tests locally), others are less straightforward to understand. This page covers test structure and details for the repository, and how to investigate failures.

# Structure

## Tooling

Almost every test run by CI is run via the [repository tooling](https://github.com/flutter/packages/tree/main/script/tool). In general, the CI configuration for a task is a minimal wrapper around one (or, rarely, more than one) repository tool command. This has several benefits:
- It makes it easy to run almost any failing CI task locally, using the same command.
- It makes transitioning between different CI systems relatively straightforward.

CI often runs commands via the `script/tool_runner.sh` script. This is just a thin wrapper that passes arguments that are commonly used for CI (such as `--packages-for-branch`, which makes CI behave differently depending on the branch being run) but are unlikely to be useful when running locally. To run a failing test locally, substitute [`dart run script/tool/bin/flutter_plugin_tools.dart`](https://github.com/flutter/packages/tree/main/script/tool#getting-started) for `script/tool_runner.sh`.

## Infrastructure

flutter/packages uses the same LUCI infrastructure as most of the rest of Flutter. The main exception is the `release` step, which uses GitHub Actions.

### LUCI

This is the CI system used by flutter/flutter and flutter/engine. For information about LUCI results pages, see [Understanding a LUCI build failure](../../infra/Understanding-a-LUCI-build-failure.md).

#### Results

Results for LUCI runs are available on [the Packages dashboard](https://flutter-dashboard.appspot.com/#/build?repo=packages&branch=main).

#### Configuration

LUCI tasks are configured in `.ci.yaml`, and files in `.ci/`. To find the commands corresponding to a given failing target and task, look in `.ci.yaml` for `name: your-target-name-here`, find the YAML file listed in the `target_file` entry, and look in `.ci/targets/that_yaml_file_name.yaml`. Each task will be an entry in that file, which runs `script` (a file relative to the repository root, usually either `script/tool_runner.sh` or in `.ci/scripts/`), optionally with given `args`.

### GitHub Actions

#### Results

GitHub Actions results only show up [in the GitHub UI](https://github.com/flutter/packages/commits/main/packages): click a check mark (passed), red X (failed) or yellow circle (running) for the list of tasks.

#### Configuration

GitHub Actions tasks are configured in `.github/workflows/`.

## Test matrix

The overall testing structure for flutter/packages is:
- Most tests are run on only one host platform: Linux when possible, or the relevant platform if necessary (e.g., Windows target tests must run on Windows hosts, and iOS and macOS tests must run on macOS hosts).
- Most tests are run with both Flutter `master` and Flutter `stable` (see [discussion of supported platforms](../contributing/README.md#supported-flutter-versions) for more details).
    - Since in practice `stable`-only failures are very rare, CI is currently configured to only run `stable` in post-submit to reduce CI time and costs.
- Architecture coverage is as-needed; we generally don't duplicate tests across architectures. For plugins, where architecture is most likely to be an issue, we try to run:
    - the majority of the tests (`*_platform_tests`) on the most popular architecture, and
    - `build_all_packages` on the other.

  This gives us build coverage on both architectures.

## Exclusions

Many test commands in the repository tooling are configured to make having no tests of that type an error, to avoid cases where packages are misconfigured such that we aren't running tests that we think they are (or that an important category of tests is just forgotten). In cases where a missing test is intentional, you can add it to the relevant [exclusion file](https://github.com/flutter/packages/tree/main/script/configs), which are files that are passed to the relevant CI runs.

Exclusions **must** include explanatory comments, and in cases where they are not intended to be permanent, a link to an issue tracking its removal.

# Specific tests

In addition to Dart unit tests, Dart integration tests, and for plugins the various kinds of [native plugin tests](Plugin-Tests.md), there are a number of tests that check for repository best practices or to catch problems that have affected packages in the past. As a rule of thumb, any time we find a bug or mistake only *after* publishing a package, we try to add a check for that in CI to prevent similar issues in the future.

Below are descriptions of many of the less self-evident CI tests, and common solution to failures. Anyone adding new tests is encouraged to document them here.

- **`submit-queue`**: This only shows in PRs (presubmit), and reflects the current state of the tree: if it is red, the tree is currently closed to commits (which can mean either that the tree is red, or that a recently landed PR is still running post-submit tests), and if it is green the tree is open. This has **no relation** to the PR itself, and as a PR author you do not need to do anything about it; Flutter team members monitor the state of the tree, and will handle failures.
    - There is a known issue that sometimes causes the status of this check to be stale; the causes is unknown. If this happens (i.e., the check in red but the tree state as described in the Infrastructure section above is actually green), you an either update your PR by merging in the latest `main` to force updates, or you can reach out to a Flutter team member (in a comment on the PR, or in Discord) to override the incorrect check.
- **`*_platform_tests`**: This runs each package's integration tests on the given target platform, as well as any [native plugin tests](Plugin-Tests.md) for that platform. This can also include native-language-specific analysis or lint checks.
- **`analyze`**: The initial `analyze` step is a straightforward Dart `analyze` run, but the `pathified_analyze` step is more complicated; it is intended to find issues that will cause out-of-band breakage in our own repository when the change being tested is published (most commonly with federated plugins). It does this by finding all packages that have non-breaking-version changes in the PR, and then rewriting all references to those packages in the repository to be `path:` dependencies, then re-running analysis.

  A failure here does not necessarily mean that the PR is wrong; because we use very strict analysis options, changes that are not considered breaking by Dart semver conventions can break our CI. Common sources of failures here include:
    - Accidentally making a breaking change without making a major version change to the plugin.
        - **Solution**: Fix the versioning.
    - Deprecating something that is still in use by another package within the repository.
        - **Solution**: Suppress the warnings with `// ignore: deprecated_member_use` annotations in the other packages using that method, [with a comment](../../contributing/Style-guide-for-Flutter-repo.md#comment-all--ignores) linking to the issue that tracks updating it. Once it lands, do a follow-up PR to update the calls and remove the `ignore`s.
    - Adding a new enum value. We generally do not consider this breaking, but use your judgement and discuss with your reviewer; consider whether it is likely that clients have critical logic that depends on exhaustively handling all enum values, and what the effects are likely to be for those use cases if a new value is added.
        - **Solution**: If it's not treated as breaking, then temporary disable that analyzer warning while adding the value:
            * In the PR that adds the value, suppress the warnings with `// ignore: exhaustive_cases` annotations, [with a comment](../../contributing/Style-guide-for-Flutter-repo.md#comment-all--ignores) linking to the issue that tracks updating it.
            * In the follow-up PR that picks up the new enum value and uses it, remove the `ignore`.
- **`legacy_version_analyze`**: Runs `analyze` with older versions of Flutter than the current `stable` on any package that claims to support them; see [the supported version policy](../contributing/README.md#supported-flutter-versions) for details.
    - **Solution**: Unless you have a specific need to keep support for the old version (unlikely), just update the Flutter constraint in `pubspec.yaml` to exclude the failing version(s) of Flutter.
- **`analyze_downgraded`**: Runs `analyze` after running a `pub downgrade`, to ensure that minimum constraints are correct (e.g., that you don't add usage of an API from version `x.1` of a dependency that is specified as `^x.0` in `pubspec.yaml`).
    - **Solution**: Update the relevant constraint to the version that introduced the new APIs.
- **`*_build_all_packages`**: Builds all packages into the same application, to ensure that there are no conflicts between dependencies, as we generally want clients to be able to use the latest versions of any of our packages in the same project.
    - **Solutions**:
        - If possible, fix the conflict. E.g., if you update a dependency of one package to a new major version, do the same in other packages using that same dependency.
        - Otherwise, temporarily add the necessary package(s) to the `exclude_all_packages_app.yaml` exclusion file (see discussion of exclusion files above).
- **`repo_checks`**: Enforces various best practices (formatting, style, common mistakes, etc.). In most cases, the error messages should give clear and actionable explanations of what is wrong and how to fix it. Some general notes on specific steps:
    - **`license_script`**: All code files must have the repository copyright/license block at the top. In most cases a failure here just means you forgot to add the license to a new file.
    - **`federated_safety_script`**: Changing interdependent sub-packages of a federated plugin in the same PR can mask serious issues, such as undesired breaking changes in platform APIs. See the documentation on [changing federated plugins](../contributing/README.md#changing-federated-plugins) for next steps.

# Out-of-band failures

The flutter/packages repository is more prone to out-of-band failures—persistent failures that do not originate with a PR within the repository—than flutter/engine and flutter/flutter. These are more difficult to debug than most failures since the source may not be obvious, and can be difficult to resolve since there's not necessarily anything that can be reverted to fix them. This page collects information on sources of these failures to help debug and resolve them.

This section doesn't cover flakes. While these failures are easily confused with flakes at first, they can be distinguished by being persistent across retries, as well as showing up in in-progress PRs.

## Infrastructure

This category covers anything that is a function of the CI infrastructure itself: services, machines, etc. It occurs across all repositories, but instances may be specific to one repository.

### LUCI

LUCI tasks are run on Flutter-infrastructure-managed VMs, using an [out-of-repo recipe](https://flutter.googlesource.com/recipes/+/main/recipes/packages/packages.py). Since LUCI images are changed by infrastructure team rollouts, and recipes are out-of-repo, almost any LUCI change is out of band. Potential failure sources include:
- Images changes.
- Recipe changes (very uncommon now that the recipe is generic).

#### Distinguishing features
- May affect all of the LUCI tests.
- Image changes generally result in builds not proceeding at all due to missing dependencies.
- Recipe changes generally cause setup failures or failure to start the test.

#### Distinguishing features
- Usually easy to identify since failures are generally before the tests even run.

#### Investigation & resolution tips
- File an [infrastructure ticket](../../infra/Infra-Ticket-Queue.md).
- Check the recipe file for recent changes.

### Firebase Test Lab (Also known as: "FTL")

Integration tests on Android are run in real devices through the Firebase Test Lab infrastructure by [the `firebase-test-lab` command in the repository tooling](https://github.com/flutter/packages/blob/main/script/tool/lib/src/firebase_test_lab_command.dart). From time to time, the Firebase Test Lab will change what devices are available for testing, and tests will start timing out.

#### Distinguishing features
- `firebase_test_lab` task starts timing out. The output is normally just: `Timed out!` ([Example](https://github.com/flutter/plugins/runs/3930255308).)
  - These timeouts will start as "flake" tests, and get progressively worse, until no amount of "retries" helps them pass (as devices are phased out / less available).
  - `firebase_test_lab` timing out is almost always related to this. Either because of devices becoming unavailable, or by a temporary lack of resource availability.

#### Investigation & resolution tips
- Check the [Deprecation List](https://firebase.google.com/docs/test-lab/android/available-testing-devices#deprecated_devices) in the Firebase documentation, and see if it affects any of the devices [used by the script](https://github.com/flutter/packages/blob/1598ccd896653cbe40b7401fb0eafd890e784b39/.ci/targets/android_device_tests.yaml#L14).
- Pick another device that is more available and update the script. See a [sample PR](https://github.com/flutter/plugins/pull/4436).
  - It is likely that `flutter/engine` and `flutter/flutter` have had the same problem. Use the same devices picked by them.

## Publishing

There are some interdependencies between packages in the repository (notably federated plugins, but a few other cases as well, such as examples of one package that depend on another package). Inter-package dependencies are only tested with published versions ([#52115](https://github.com/flutter/flutter/issues/52115)), so publishing a package can potentially break other packages.

#### Distinguishing features
- Timing will correspond to a package being published. (With autorelease, this will be shortly after the version-updating PR lands, unless something goes wrong.)
- May have a clear reference to the published package in the failure.
  - This is not guaranteed; e.g., Android plugin Gradle changes can have transitive effects on example apps that depend on those packages.

#### Investigation & resolution tips
- Pinning a specific dependency version can confirm or eliminate this as a source of errors.
  - This should generally **not** be used as a mitigation; this category of error is often a failure that will affect clients of the package as well.

## External build dependencies

On platforms where the plugin system includes a dependency management system, there are build-time dependencies on external servers (e.g., Maven for Android, Cocoapods for iOS and macOS). Potential failure sources include:
- Temporary server outages.
- Removal of a package.

#### Distinguishing features
- The logs will be very clear that fetching a dependency failed.
  - The only challenge in identifying them quickly is that they look the same as transient server or network issue flakes, which are much more common.

#### Investigation & resolution tips
- Check for reports of outages on the relevant servers.
- Check whether the entire server is failing, or only fetching a specific package is failing.
- Server-level outages are usually short-lived and just have to be waited out; i.e., they are persistent for a matter of hours before the server issue is resolved.
- Package issues may require repository changes. E.g., for Maven, switching to another server that has the package, or to another version of the package that is still available.

## `pub`

The `publish` command periodically enables new checks. Rarely, such a check will be enabled after presubmits for a PR have run, but before it's submitted.

#### Distinguishing features
- Either the `publish` validation step or the `release` step will fail with a clear error message from the `publish` command.

#### Investigation & resolution tips
- These are usually straightforward to resolve by fixing the newly-flagged issue.