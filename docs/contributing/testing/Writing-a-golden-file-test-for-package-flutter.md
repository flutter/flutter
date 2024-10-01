# Writing a golden file test for package:flutter

_(This page is referenced by comments in the Flutter codebase.)_

**If you want to learn how to write a golden test for your package, see [the `matchesGoldenFile` API docs](https://api.flutter.dev/flutter/flutter_test/matchesGoldenFile.html).** This wiki page describes the special process specifically for the Flutter team itself.

Golden file tests for `package:flutter` use [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) for baseline and version management of golden files. This allows for golden file testing on Linux, Windows, macOS and Web, which accounts for the occasional subtle rendering differences between these platforms.

## Index

- [Known Issues](#known-issues)
- [Build Breakage](#build-breakage)
- [Creating a New Golden File Test](#creating-a-new-golden-file-test)
  - [Add or configure a `.ci.yaml` task](#add-or-configure-a-ciyaml-task)
  - [Adding a known task name to the `flutter-gold` check](#adding-a-known-task-name-to-the-flutter-gold-check)
  - [Writing and submitting the test](#writing-and-submitting-the-test)
- [Adding a new key in the Skia Client](#adding-a-new-key-in-the-skia-client)
- [Updating a Golden File Test](#updating-a-golden-file-test)
- [Flutter Gold Login](#flutter-gold-login)
- [`flutter-gold` Check](#flutter-gold-check)
- [`reduced-test-set` tag](#reduced-test-set-tag)
- [Troubleshooting](#troubleshooting)

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
  Note: These instructions are also referred to in the flutter/engine repository
  ensure that when updating them, the workflow is either consistent or the
  differences are clearly called out.
-->

Writing a _new_ golden file test if the _test suite_ (sometimes called "task"
or "shard") is not already configured for golden file testing is an involved
process, and missing a step can result in a broken build or a failing test.

The process involves:

1. [Adding or configuring a `.ci.yaml` task](#add-or-configure-a-ciyaml-task).
1. [Writing and submitting the test](#writing-and-submitting-the-test).
1. [Adding a known task name to the `flutter-gold` check](#adding-a-known-task-name-to-the-flutter-gold-check).

### Add or configure a `.ci.yaml` task

_If you are editing an existing test or test suite that already includes the
`goldctl` dependency (as seen below), you can skip this step._

Every test suite that runs tests (golden file tests included) needs to be
configured in the top-level [`.ci.yaml` file](../../../.ci.yaml), which contains
the configuration for all the CI tasks that run on the Flutter repository. For
example, the task `Linux framework_tests_widgets` (as of 2024-08-27) looks like
this:

```yaml
# Some parts omitted for brevity

- name: Linux framework_tests_widgets
  properties:
    dependencies: >-
      [
        {"dependency": "goldctl", "version": "git_revision:2387d6fff449587eecbb7e45b2692ca0710b63b9"}
      ]
```

What this means is that the task, `Linux framework_tests_widgets`, will install
the `goldctl` tool (which is used to interface with Skia Gold) at the specified
revision. If you are adding a new test suite, or adding golden testing to a
test suite that didn't have it before, you will need to add or modify a task in
the `.ci.yaml` file:

```diff
+  properties:
+    dependencies: >-
+      [
+        {"dependency": "goldctl", "version": "git_revision:2387d6fff449587eecbb7e45b2692ca0710b63b9"}
+      ]
```

> [!TIP]
> The exact git revision of `goldctl` should be copied from an existing task.

If a new dependency was added, see [adding a known task name to the `flutter-gold` check](#adding-a-known-task-name-to-the-flutter-gold-check).

### Adding a known task name to the `flutter-gold` check

The `flutter-gold` check is a cron job that is scheduled to run (every 5
minutes) through every open (non-draft) PR across `flutter/flutter` and
`flutter/engine` is checked for tasks that are _known_ to run golden file tests,
and if they are present, the check asks (via a Skia Gold API) if there were any
untriaged images generated, showing a :question: if so, or a :white_check_mark:
if not.

This list is manually curated in the [`flutter/cocoon` codebase](https://github.com/flutter/cocoon/blob/65e89508cad5b6f9622ee072a1178913fed5001e/app_dart/lib/src/request_handlers/push_gold_status_to_github.dart#L123-L144)
and needs to be updated when new tasks are added or removed.

See [#149544](https://github.com/flutter/flutter/pull/149544) for an example of adding a new task to the list
and [#143863](https://github.com/flutter/flutter/issues/143863#issuecomment-2310898513) for a discussion on the topic.

Failure to add a new task to this list will result in the `flutter-gold` check
not running on some PRs (and build breakages as a result).

### Writing and submitting the test

> [!NOTE]
> These instructions are specific to writing golden file tests for
> `package:flutter`. If you are writing integration tests, or tests in another
> repository (such as `flutter/engine`) the specifics will be different; consult
> relevant documentation and/or team members about the process. Examples:
>
> - [`engine > testing > skia_gold_client > README.md`](https://github.com/flutter/engine/blob/main/testing/skia_gold_client/README.md)
> - [`engine > impeller > golden_tests > README.md`](https://github.com/flutter/engine/blob/main/impeller/golden_tests/README.md)

Write your test as a normal test, using `testWidgets` and `await tester.pumpWidget` and so on.

Put a `RepaintBoundary` widget around the part of the subtree that you want to verify. If you don't, the output will be a 2400x1800 image, since the tests by default use an 800x600 viewport with a device pixel ratio of 3.0. If you would like to further control the image size, put a `SizedBox` around your `RepaintBoundary` to set constraints.

Add an expectation along the following lines:

```dart
  await expectLater(
    find.byType(RepaintBoundary),
    matchesGoldenFile('test_name.subtest.subfile.png'),
  );
```

The argument to `matchesGoldenFile` is the filename for the screenshot. The part up to the first dot should exactly match the test filename (e.g. if your test is `widgets/foo_bar_test.dart`, use `foo_bar`). The `subtest` part should be unique to this `testWidgets` entry, and the part after that should be unique within the `testWidgets` entry. This allows each file to have multiple `testWidgets` tests each with their own namespace for the images, and then allows for disambiguation within each test in case there are multiple screenshots per test.

Golden tests may be executed locally on Linux, macOS, and Windows platforms. All reference images can be found at [Flutter Gold baselines](https://flutter-gold.skia.org/list?fdiffmax=-1&fref=false&frgbamax=255&frgbamin=0&head=true&include=false&limit=50&master=false&match=name&metric=combined&neg=false&new_clstore=true&offset=0&pos=true&query=source_type%3Dflutter&sort=desc&unt=true). Some tests may have multiple golden masters for a given test, to account for rendering differences across platforms. The parameter set for each image is listed in each image digest to differentiate renderings.

Once you have written your test, run `flutter test --update-goldens test/foo/bar_test.dart` in the `flutter` package directory (where the filename is the relative path to your new test). This will update the images in `bin/cache/pkg/skia_goldens/packages/flutter/test/`; the directories below that will match the hierarchy of the directories in the `test` directory of the `flutter` package. Verify that the images are what you expect; update your test and repeat this step until you are happy with the image.

When running `flutter test` locally without the `--update-goldens` flag, your test will pass, as it does not yet have a baseline for comparison on the [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) dashboard. The test will be recognized as new, and provide output for validation.

When you are happy with your image, you are ready to submit your PR for review. The reviewer should also verify your golden image(s), so make sure to include the golden(s) in your PR description.

New test results will be compiled into a tryjob on the Flutter Gold dashboard, under [ChangeLists](https://flutter-gold.skia.org/changelists). There you will see your pull request and the associated golden files that were generated. Gold will also leave a comment on your pull request linking to your image results.

New tests can be triaged from these tryjobs, which will cause the pending `flutter-gold` check to pass. Review the tryjob and the images that were generated, making sure they look as expected. Currently, we generate images for Linux, Mac, Windows, and Web platforms. It is common for there to be slight differences between them. Click the checkmark to approve the change, completing triage.

And that’s it! Your new golden file(s) will be checked in as the baseline(s) for your new test(s), and your PR will be ready to merge. :tada:

## Adding a new key in the Skia Client

Approved golden file images on the [Flutter Gold Dashboard] [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter)
are keyed with parameters like platform, CI environment, test name, browser, and image extension.

When adding new keys, consider all possible values, and whether or not they are covered by the CI environments that are used
to test changes in presubmit and postsubmit testing. If not all possible values are accounted for, false negatives can occur
in local testing.

For example, we once included an abi key, which in our CI environments at the time could be linux_x64, windows_x64, or mac_x64.
These keys are used to look up approved images for local testing, so when a mac_arm64 machine would run local tests,
no image could be found and the tests would fail.
Omitting the key in the lookup did most often find the right image, but it was not consistently reliable, so we removed it.

If the CI environments available for testing changes do not cover all value of a particular key, it is not a good key to
include as part of testing.

## Updating a Golden File Test

If renderings change, then the golden baseline in [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) will need to be updated.

When developing your change, local testing will produce a failure along with visual diff output. This visual diff will be generated using the golden baseline from [Flutter Gold](https://flutter-gold.skia.org/?query=source_type%3Dflutter) that matches the current paramset of your testing environment (currently based on platform). This allows for quick iterations and validation of your change. Locally, this test will not pass until the new baseline has been checked in.

When you are happy with your golden change, you are ready to submit your PR for review. The reviewer should also verify your golden image(s), so make sure to include the golden changes you have made in your PR description. Changes to tests will be compiled into a tryjob on the Flutter Gold dashboard, under [ChangeLists](https://flutter-gold.skia.org/changelists). There you will see your pull request and the associated golden files that were generated, as well as the visual differences between the pre-existing baselines. Gold will also leave a comment on your pull request linking to your image results.

The updated tests can be triaged from these tryjobs, which will cause the pending `flutter-gold` check to pass. Review the tryjob and the images that were generated, making sure they look as expected. Currently, we generate images for Linux, Mac, Windows and Web platforms. It is common for there to be slight differences between them. Click the checkmark to approve the change, completing triage.

And that’s it! Your new golden file(s) will be checked in as the baseline(s) for your new test(s), and your PR will be ready to merge. :tada:

## Flutter Gold Login

Triage permission is currently restricted to members of _flutter-hackers_. For more information, see [Contributor Access](../Contributor-access.md).
Once you have been added as an authorized user for Flutter Gold, you can log in through the [homepage of the Flutter Gold dashboard](https://flutter-gold.skia.org/) and proceed to triage your image results under [Changelists](https://flutter-gold.skia.org/changelists).

## `flutter gold` Check

The `flutter-gold` check is applied to pull requests in flutter/flutter that execute golden file tests and are ready for review.

As golden file tests are run across multiple test shards, this check waits for all other tests to complete before checking to see if Gold received new images. While awaiting test completion, and in the event there are image changes, the `flutter-gold` check will hold a pending state. This is primarily due to how the auto-roller used by flutter/engine works (context: https://github.com/flutter/flutter/issues/48744).

If there are no image changes, the `flutter-gold` check will go green. If image changes were detected, a comment on your pull request will notify and provide a direct link to the images. Upon triaging, or approving, the images, the `flutter-gold` check will go green within five minutes.

## `reduced test set` tag

On some CI platforms in pre-submit, hermetic tests suites are not executed in order to conserve resources and expedite testing of other changes. To ensure that a golden file image is available for every platform, test files with golden tests are tagged with `reduced-test-set`. This marks them for execution in these conservative test environments. Currently, framework tests on Mac and Windows platforms execute these reduced test sets. The analyzer will alert you if the tag is omitted from the test file. The tag should be formatted as such at the top of the file:

```dart
@Tags(<String>['reduced-test-set'])
```

For more context, see [flutter.dev/go/reduce-ci-tests](https://flutter.dev/go/reduce-ci-tests).

## Troubleshooting

- Trouble: the `flutter-gold` is stuck at pending status while all other checks are successful (if they are not, see [flutter-gold check](#flutter-gold-check)).
  - Solution: this may be a side-effect of force-pushed commits (`git push -f`) and a known Skia Gold issue (https://issues.skia.org/issues/40044676), typically after a rebase. If this happens, try rebasing or pushing an empty commit without force pushing. This side-effect is flaky.
- Trouble: the `flutter-gold` check posted a message saying "Golden file changes have been found..." but the triage page is empty.
  - Solution: this may be another side-effect of force-pushed commits (see above), but may also be a side-effect of untriaged goldens from already submitted PRs. Try rebasing again, or reach out in #hackers-infra on the Discord.

## Additional Resources

- [Gold APIs used by the Flutter Framework](https://docs.google.com/document/d/1H3CDqT7zBUt4Je2HPQpleYA-drwj2oy0mdPlSdf2d4A/edit?usp=sharing)
