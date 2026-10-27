# Writing a golden file test for package:flutter

_(This page is referenced by comments in the Flutter codebase.)_

**If you want to learn how to write a golden test for your package, see [the `matchesGoldenFile` API docs](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html).** This guide describes the process used within the Flutter repository itself.

Golden file tests for `package:flutter` use [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) for baseline and version management of golden files. This enables golden file testing across Linux, Windows, macOS (including Impeller), and Web (CanvasKit and Skwasm), accounting for occasional subtle rendering differences between platforms and renderers.

## Index

- [Known Issues](#known-issues)
- [Build Breakage](#build-breakage)
- [Creating a New Golden File Test](#creating-a-new-golden-file-test)
  - [Add or configure a `.ci.yaml` task](#add-or-configure-a-ciyaml-task)
  - [Writing and submitting the test](#writing-and-submitting-the-test)
- [Adding a new key in the Skia Client](#adding-a-new-key-in-the-skia-client)
- [Updating a Golden File Test](#updating-a-golden-file-test)
- [Flutter Gold Login](#flutter-gold-login)
- [`flutter-gold` Check](#flutter-gold-check)
- [`reduced-test-set` tag](#reduced-test-set-tag)
- [Troubleshooting](#troubleshooting)
- [Additional Resources](#additional-resources)

## Known Issues

### Negative Images

https://github.com/flutter/flutter/issues/145043

If an image is marked `negative` the flutter-gold check will not catch it in presubmit testing. Images should not be marked negative, as the system relies on the `untriaged` and `approved` states. If a negative image is produced in postsubmit, testing will fail and the change can be reverted so the image can be addressed.
If you would like to instantly invalidate all prior renderings, changing the name of the golden file test will accomplish this. Gold already has a process to 'forget' images after they have changed, but does so over time.

## Build Breakage

If the Flutter build is broken due to a golden file test failure, this typically means an image change has landed without being triaged. Golden file images should be triaged in pre-submit before a change lands (as described in the steps below). If this process is not followed, a test with an unapproved golden file image will fail in post-submit testing. This will present in the following error message:

```txt
  Skia Gold received an unapproved image in post-submit
  testing. Golden file images in flutter/flutter are triaged
  in pre-submit during code review for the given PR.

  Visit https://flutter-gold.skia.org/ to view and approve
  the image(s), or revert the associated change. For more
  information, visit the wiki:
  https://github.com/flutter/flutter/blob/main/docs/contributing/testing/Writing-a-golden-file-test-for-package-flutter.md
```

To resolve, visit the [Flutter Gold dashboard](https://flutter-gold.skia.org/) to view the batch of images in question. If they are intended changes, approve them by clicking the checkmark, and re-run the failing test to resolve. If the image changes are not intended, revert the associated change.

Notice, Gold may wrongly attribute blame for image changes on the dashboard. Post-submit testing for flutter/flutter is not executed in the order that commits land. Commits are tested by order of the most recent change. If older commits have not completed testing yet, Gold may assign blame incorrectly until all image results have been processed for pending commits.

## Creating a New Golden File Test

<!--
  Note: These instructions are also referred to by engine golden tests under
  engine/src/flutter; ensure that when updating them, the workflow is either
  consistent or the differences are clearly called out.
-->

Writing a _new_ golden file test if the _test suite_ (sometimes called "task"
or "shard") is not already configured for golden file testing requires CI
configuration, and missing a step can result in skipped or failing golden tests.

The process involves:

1. [Adding or configuring a `.ci.yaml` task](#add-or-configure-a-ciyaml-task).
1. [Writing and submitting the test](#writing-and-submitting-the-test).

### Add or configure a `.ci.yaml` task

_If you are editing an existing test or test suite that already includes the
`goldctl` dependency (as seen below), you can skip this step._

Every test suite that runs golden file tests needs to be configured in the
top-level [`.ci.yaml` file](../../../.ci.yaml), which contains the configuration
for CI tasks that run on the Flutter repository. For example, the task
`Linux framework_tests_widgets` includes:

```yaml
# Some parts omitted for brevity

- name: Linux framework_tests_widgets
  properties:
    dependencies: >-
      [
        {"dependency": "goldctl", "version": "git_revision:7f66c9b9efb2826e72c61bb2f50cdc20b635dea7"}
      ]
```

What this means is that the task, `Linux framework_tests_widgets`, will install
the `goldctl` tool (which is used to interface with Skia Gold) at the specified
revision and populate the `GOLDCTL` environment variable (plus `GOLD_TRYJOB` in
presubmit). If you are adding a new test suite, or adding golden testing to a
test suite that didn't have it before, add or modify the task in `.ci.yaml`:

```diff
+  properties:
+    dependencies: >-
+      [
+        {"dependency": "goldctl", "version": "git_revision:7f66c9b9efb2826e72c61bb2f50cdc20b635dea7"}
+      ]
```

> [!TIP]
> Copy the exact `git_revision` of `goldctl` from an existing task in `.ci.yaml`.

Once `goldctl` is configured on the task, the [`flutter-gold` check](#flutter-gold-check)
automatically picks up any untriaged images uploaded during presubmit after
`Dashboard Checks` finishes; no separate task registration in `flutter/cocoon`
is required.

### Writing and submitting the test

> [!NOTE]
> These instructions are specific to writing golden file tests for
> `package:flutter`. If you are writing integration tests or engine tests
> elsewhere in the monorepo (such as under `engine/src/flutter` or
> `dev/integration_tests`), the specifics differ; consult relevant documentation
> and/or team members about the process. Examples:
>
> - [`engine/src/flutter/testing/skia_gold_client/README.md`](../../../engine/src/flutter/testing/skia_gold_client/README.md) (engine and `felt` web engine golden tests)
> - [`engine/src/flutter/impeller/golden_tests/README.md`](../../../engine/src/flutter/impeller/golden_tests/README.md) (Impeller C++ golden tests)
> - [`dev/tools/android_driver_extensions/lib/skia_gold.dart`](../../../dev/tools/android_driver_extensions/lib/skia_gold.dart) (Android driver golden tests)

Every test file under `packages/flutter/test/` that calls `matchesGoldenFile`
must include the [`reduced-test-set` tag](#reduced-test-set-tag) attached to a
`library;` directive before any `import` statements:

```dart
@Tags(<String>['reduced-test-set'])
library;
```

Write your test as a normal widget test, using `testWidgets` and `await tester.pumpWidget` and so on. By default, framework tests render text with the `FlutterTest` font (see [Flutter Test Fonts](Flutter-Test-Fonts.md)).

Put a `RepaintBoundary` widget around the part of the subtree that you want to verify. If you don't, the output will be a 2400x1800 image, since the tests by default use an 800x600 viewport with a device pixel ratio of 3.0. If you would like to further control the image size, put a `SizedBox` around your `RepaintBoundary` to set constraints.

Add an expectation along the following lines:

```dart
  await expectLater(
    find.byType(RepaintBoundary),
    matchesGoldenFile('test_name.subtest.subfile.png'),
  );
```

The argument to `matchesGoldenFile` is the filename for the screenshot and must end in `.png` (the enclosing test directory name, such as `widgets.`, is prepended automatically when uploading to Flutter Gold). The part up to the first dot should match the test filename (e.g. if your test is `widgets/foo_bar_test.dart`, use `foo_bar`). The `subtest` part should be unique to this `testWidgets` entry, and the part after that should be unique within the `testWidgets` entry. This allows each file to have multiple `testWidgets` tests each with their own namespace for the images, and allows for disambiguation within each test when there are multiple screenshots per test.

Golden tests may be executed locally on Linux, macOS, and Windows, including Web browser tests via Chrome (`flutter test --platform chrome` for CanvasKit, or `flutter test --platform chrome --wasm` for Skwasm). If Flutter Gold cannot be reached (for example, when working offline), tests automatically fall back to skipping golden comparisons. All reference images can be found at [Flutter Gold baselines](https://flutter-gold.skia.org/list?fdiffmax=-1&fref=false&frgbamax=255&frgbamin=0&head=true&include=false&limit=50&master=false&match=name&metric=combined&neg=false&new_clstore=true&offset=0&pos=true&query=source_type%3Dflutter&sort=desc&unt=true). Tests often have multiple golden baselines for a given test name to account for rendering differences across platforms and renderers; the parameter set for each image is listed on each digest.

Once you have written your test, run `flutter test test/foo/bar_test.dart` (with or without `--update-goldens`) in the `packages/flutter` directory, where the path is relative to `packages/flutter`. Because a new test does not yet have a baseline on the [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) dashboard, it will pass locally, log that no expectations were found, and write the generated image under `bin/cache/pkg/skia_goldens/packages/flutter/test/` (matching the directory hierarchy of `packages/flutter/test/`). Verify that the generated images look as expected, updating your test and re-running until you are happy with the rendering.

When you are happy with your image, you are ready to submit your PR for review. The reviewer should also verify your golden image(s), so include the golden(s) in your PR description.

New test results will be compiled into a tryjob on the Flutter Gold dashboard, under [ChangeLists](https://flutter-gold.skia.org/changelists). There you will see your pull request and the associated golden files that were generated. Gold will also apply the `will affect goldens` label and leave a comment on your pull request linking to your image results.

New tests can be triaged from these tryjobs, which will cause the pending `flutter-gold` check to pass. Review the tryjob and the images that were generated, making sure they look as expected. Currently, CI generates images across Linux, macOS (Skia and Impeller via SwiftShader), Windows, and Web (Chrome with CanvasKit and Skwasm). It is common for there to be slight differences between them. Click the checkmark to approve the change, completing triage.

And that’s it! Your new golden file(s) will be recorded as the baseline(s) for your new test(s), and your PR will be ready to merge. :tada:

## Adding a new key in the Skia Client

Approved golden file images on the [Flutter Gold dashboard](https://flutter-gold.skia.org/?query=source_type%3Dflutter)
are keyed with parameters describing the test configuration. `package:flutter_goldens`
currently sets:

- `Platform`: `linux`, `macos`, `windows`, or `linux-browser` (for web tests)
- `CI`: `luci`
- `impeller`: `swiftshader` (when running with `--enable-impeller`)
- `Browser`: `chrome` (for web tests)
- `WebRenderer`: `canvaskit` or `skwasm` (for web tests)

(Along with Skia Gold's standard `name`, `source_type`, and `ext` parameters.)

When adding new keys, consider all possible values, and whether or not they are covered by the CI environments that are used
to test changes in presubmit and postsubmit testing. If not all possible values are accounted for, false negatives or missing
expectations can occur in local testing.

For example, we once included an `abi` key, which in our CI environments at the time could be `linux_x64`, `windows_x64`, or `mac_x64`.
These keys are used to look up approved images for local testing, so when a `mac_arm64` machine ran local tests,
no image could be found. Omitting the key in the lookup did most often find the right image, but it was not consistently reliable, so we removed it.

Similarly, if CI only runs a mode on a subset of platforms, local lookups must account for that:
- Web golden baselines are captured on Linux in CI (`Platform: linux-browser`), so local `--platform chrome` runs on macOS and Windows normalize `Platform` to `linux-browser` when querying baselines.
- CI currently runs `framework_tests` with `--enable-impeller` only on macOS (`Mac framework_tests_impeller`), so running `flutter test --enable-impeller` locally on Linux or Windows will not find an existing baseline in Gold.

If the CI environments available for testing changes do not cover all values of a particular key (and cannot be safely normalized), it is not a good key to
include as part of testing.

## Updating a Golden File Test

If renderings change, then the golden baseline in [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) will need to be updated.

When developing your change, running `flutter test` locally downloads the matching baseline from [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) (cached on disk at `.dart_tool/flutter_goldens_cache/baselines/`) and compares pixels (exact comparison on native platforms; tolerance-aware fuzzy comparison on `--platform chrome`). When a mismatch is detected, local testing fails and writes visual diff artifacts:

- **Native (`linux`, `macos`, `windows`)**: diff and comparison images are written under `bin/cache/pkg/skia_goldens/packages/flutter/test/<subdir>/failures/`.
- **Web (`--platform chrome`)**: `actual.png`, `expected.png`, and `diff.png` are written under `.dart_tool/flutter_goldens_cache/failures/<test_name>/`.

Note that passing `--update-goldens` locally only updates the local preview file under `bin/cache/pkg/skia_goldens/`—it **does not** update baselines on Flutter Gold. Local runs without `--update-goldens` will continue to fail until the new baseline has landed and been approved on Flutter Gold.

When you are happy with your golden change, you are ready to submit your PR for review. The reviewer should also verify your golden image(s), so include the golden changes you have made in your PR description. Changes to tests will be compiled into a tryjob on the Flutter Gold dashboard, under [ChangeLists](https://flutter-gold.skia.org/changelists). There you will see your pull request and the associated golden files that were generated, as well as the visual differences against the pre-existing baselines. Gold will also apply the `will affect goldens` label and leave a comment on your pull request linking to your image results.

The updated tests can be triaged from these tryjobs, which will cause the pending `flutter-gold` check to pass. Review the tryjob and the images that were generated, making sure they look as expected. Currently, CI generates images across Linux, macOS (Skia and Impeller via SwiftShader), Windows, and Web (Chrome with CanvasKit and Skwasm). It is common for there to be slight differences between them. Click the checkmark to approve the change, completing triage.

And that’s it! Your new golden file(s) will be recorded as the baseline(s) for your test(s), and your PR will be ready to merge. :tada:

## Flutter Gold Login

Triage permission is restricted to Google accounts in `@google.com` and allowlisted `@gmail.com` accounts for members of _flutter-hackers_. For more information on requesting access, see [Contributor Access](../Contributor-access.md#access-to-flutter-gold).
Once you have been added as an authorized user for Flutter Gold, you can log in through the [homepage of the Flutter Gold dashboard](https://flutter-gold.skia.org/) and proceed to triage your image results under [ChangeLists](https://flutter-gold.skia.org/changelists).

## `flutter-gold` Check

The `flutter-gold` status check is managed by `flutter/cocoon` (via a cron job that runs every 5 minutes) and is applied to open, non-draft pull requests in `flutter/flutter` targeting `master` (or `main`) once the unified `Dashboard Checks` run is present.

Because golden file tests execute across multiple CI shards, `flutter-gold` waits for `Dashboard Checks` (and any other presubmit checks in the suite) to complete before querying Flutter Gold. Holding a `pending` state while checks run and while image changes are untriaged ensures all shards finish uploading digests to the tryjob and prevents autosubmit or the merge queue from landing unapproved visual changes.

Once presubmit checks finish:

- If no untriaged images were produced (including PRs that did not run or affect golden tests), the `flutter-gold` check goes green.
- If untriaged image changes were detected, `flutter-gold` remains `pending`, adds the `will affect goldens` label, and posts a comment on your pull request with a direct link to triage the images (`https://flutter-gold.skia.org/cl/github/<pr>`). Upon approving the images on Flutter Gold, `flutter-gold` will go green within five minutes.

## `reduced-test-set` tag

CI shards can be configured with `reduced_test_set` (`REDUCED_TEST_SET=True`) to conserve resources by executing only tagged tests while still ensuring golden baselines are generated across platforms. To support this, every test file under `packages/flutter/test/` that uses `matchesGoldenFile` must be tagged with `reduced-test-set`.

The `golden_test_tags` lint rule in `dev/flutter_analyzer_plugin` (run by `dart analyze` and IDEs) reports an error if the tag is missing. Attach `@Tags` to a `library;` directive at the top of the file before any `import` statements:

```dart
@Tags(<String>['reduced-test-set'])
library;
```

For more context, see [flutter.dev/go/reduce-ci-tests](https://flutter.dev/go/reduce-ci-tests).

## Troubleshooting

- Trouble: the `flutter-gold` check is stuck at pending status while all other checks are successful (if they are not, see [`flutter-gold` Check](#flutter-gold-check)).
  - Solution: this may be a side-effect of force-pushed commits (`git push -f`) and a known Skia Gold issue (https://issues.skia.org/issues/40044676), typically after a rebase. If this happens, try rebasing or pushing an empty commit without force pushing. This side-effect is flaky.
  - Solution: if the PR has had no updates for **more than 20 days**, Skia Gold expires the tryjob results and `flutter/cocoon` stops updating `flutter-gold` (posting a stale-PR notice). Rebase or push a new commit to re-run checks and generate fresh tryjob data.
  - Solution: if the PR was converted to **Draft** after `flutter-gold` already posted a `pending` status on the current commit, `flutter/cocoon` will not update it while in draft. Mark the PR ready for review (or push a new commit once ready).
- Trouble: the `flutter-gold` check posted a message saying "Golden file changes have been found..." but the triage page is empty.
  - Solution: this may be another side-effect of force-pushed commits (see above), or a side-effect of untriaged goldens from already submitted PRs. Try rebasing again, or reach out in #hackers-infra on [Discord](../Chat.md).

## Additional Resources

- [Gold APIs used by the Flutter Framework](https://docs.google.com/document/d/1H3CDqT7zBUt4Je2HPQpleYA-drwj2oy0mdPlSdf2d4A/edit?usp=sharing)
