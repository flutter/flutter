Flakiness issue has caused a large portion of the [Flutter tree](https://flutter-dashboard.appspot.com/#/build) redness, and below workflow will be enforced to reduce flaky issues. The framework post-submit DeviceLab tests will be focused on in the beginning, and the logic will be extended to other host only tests in the future.

From [Flutter tree dashboard](https://flutter-dashboard.appspot.com/#/build), a flake is identified as a box with an exclamation icon. There are two types that will result in same flaky box.
* Multiple reruns on the same commit and same task (earlier run fails, but the last run succeeds). For this case, check logs by clicking different build runs.

![Task flakes](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/task_flake_multiple_builds.png)

* A single run on the same commit and same task, but multiple reruns from test runner. For this case, check logs by clicking `stdout` of the test step: it shows data about failed or succeeded runs in the end ([example](https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket.appspot.com/8841146512187805536/+/u/run_build_aar_module_test/stdout)). See [Understanding a LUCI build failure](Understanding-a-LUCI-build-failure.md) for how to locate the test step and `stdout`.

![Flake test runner](https://github.com/flutter/assets-for-api-docs/blob/main/assets/wiki/task_flake_test_runner.png)

# Preventing flaky tests
## [Adding a new DeviceLab test](https://github.com/flutter/flutter/tree/main/dev/devicelab#writing-tests)
DeviceLab tests are located under [`/dev/devicelab/bin/tasks`](https://github.com/flutter/flutter/tree/main/dev/devicelab/bin/tasks). If you plan to add a new DeviceLab test, please follow
* Create a PR to add test files
  * Make sure an ownership entry is created for the test in [TESTOWNERS](https://github.com/flutter/flutter/blob/main/TESTOWNERS) file
* Enable the test in staging pool first
  * Use `bringup: true` in .ci.yaml
  * Monitor the test execution in the [flutter dashboard](https://flutter-dashboard.appspot.com/#/build)
* If no flakiness issue pops up, then enable the test in the prod env.
  * Switch `bringup` to `true`.

# Detecting flaky tests
On a weekly basis, [an automation script](https://github.com/flutter/cocoon/blob/main/app_dart/lib/src/request_handlers/file_flaky_issue_and_pr.dart) will scan through test execution statistics over the past 15 days and identify top flaky ones
* If there are any test builders whose Flaky Ratio >= 2%
  * Create a tracking bug if not existing in the [bug pool](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+project%3Aflutter%2Fflutter%2F189+label%3A%22team%3A+flakes%22).
    * The sub-team TL will be assigned by default for further triage/re-assign.
    * P0 will be labeled
  * If it is not a shard test, the script marks the tests as flaky by updating the entry in [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml).
    * Add a `# TODO(username): github issue url` above the `bringup: true` line

If an issue is closed, there will be a grace period of 15 days before the automation script refile the issue if the same flakiness persists.

# Triaging flaky tests
Figuring out how and why a set of tests is failing can be tricky. Here are a few tips to help kickstart the process.

## Use the generated ticket
The [auto-generated ticket](https://github.com/flutter/flutter/issues?q=is%3Aopen+is%3Aissue+author%3Afluttergithubbot+label%3A%22severe%3A+flake%22) will provide links to:

* An example of recent flakes on the same commit with a link to its Luci build page if available
* A list of flaky builds with links to their Luci build page
* A link to the recent test runs on the flutter dashboard

All of these pieces of information are helpful for further narrowing down the issue.

## Identify infrastructure issues
Things not directly related to the tests being run can be difficult to determine from the stdout logs. Things like timeouts are easier to determine using the `execution details` rather than `test_stdout`. From the Luci build page:

* The failing step should have a red icon with an exclamation point and be expanded
* Click on the `execution details` link
* At the bottom of these logs, look for non-zero exit codes
  * If you find a non-zero exit code, reach out on the [infrastructure discord channel](https://discord.com/channels/608014603317936148/608021351567065092) for further guidance

Some other common infra issues:
* Device not found: [`adb: device 'ZY223CXXGL' not found`](https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8777723365016202673/+/u/run_flutter_gallery__transition_perf_with_semantics/test_stdout)
* [Device disappeared](https://github.com/flutter/flutter/issues/120802) in the middle of test
* Firebase test flakes due to [firebase regression](https://github.com/flutter/flutter/issues/124217)
* [Polluted xcode cache](https://github.com/flutter/flutter/issues/118328)
* [Transient network issue](https://github.com/flutter/flutter/issues/99007)

## Identify failing tests
Sometimes, the reported error is not immediately obvious as to what test has failed. In these cases, digging into the `test_stdout` for clues can be helpful. From the Luci build page:

* The failing step should have a red icon with an exclamation point and be expanded, e.g. step [`run flutter_view_ios__start_up`](https://ci.chromium.org/ui/p/flutter/builders/prod/Mac_ios%20flutter_view_ios__start_up/6939/overview).
* Click on the `test_stdout` link
  * [Example 1](https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8798110684145503985/+/u/run_flutter_view_ios__start_up/test_stdout)
    * Search for "ERROR:" in the logs (don't skip the ":")
    * There will be a "RUNNING:" above any "ERROR:"s that are found, between the preceding "RUNNING:" and the "ERROR:" there are a few different things that could point to a test failure:
      * Keep an eye out for "Failed assertion:" which points to specific failures in dart/flutter tests
      * For non-dart/flutter tests, the output between "RUNNING:" and "ERROR:" can vary greatly, but is usually shorter and should provide some guidance as to what the failure was and how to address it
  * [Example 2](https://logs.chromium.org/logs/flutter/buildbucket/cr-buildbucket/8778092604637310577/+/u/run_test.dart_for_web_tests_shard_and_subshard_2/test_stdout)
    * Search for "[E]" for shard tests flaking on a unit test

## Identifying a pattern
Flakes, by their nature, are inconsistent. Determining a pattern can be very helpful in figuring out what causes the issue, and may help in identifying a fix or workaround. The most useful tool for this is the flutter dashboard link provided by the ticket under "Recent test runs" which will filter to just the relevant flaky test set. E.g. [Linux_android flutter_gallery__transition_perf_with_semantics](https://flutter-dashboard.appspot.com/#/build?taskFilter=Linux_android+flutter_gallery__transition_perf_with_semantics)

### Verify repeating failures
Flakes are reported on the set of tests run, not specific test failures. This can mean that the issue raising us above our 2% threshold is actually more than one issue. This is pretty rare, but does happen on occasion. There's no need to waste a lot of time verifying that _every_ failure is the same, but taking some time to verify _some_ of the failures can save time in the long run. The list of "Flaky builds:" on the automated ticket is very useful for this, and you can often find additional flaky builds in the flutter dashboard.

### Find a first instance
Flakes can be under the 2% threshold for a long time and slowly build up from various small increases in flakiness. Other times they can have a specific cause that started in an obvious location. The latter are much easier to resolve, so it's a good idea to check for a root cause. In the Flutter dashboard:

* Scroll down to load more builds
* Scroll down until you have a long string of green builds (say, a full screen or two)
  * This is a heuristic, so it may not _truly_ be the first instance, but it works well for triaging
* Scroll back up to the first red build or green build with an exclamation point
* Clicking on the profile picture next to the failed/flaky build pops up a link to the commit where this failure occurred
  * See if the commit directly affects any of the tests that are failing by adding randomness, new asserts
  * Keep an eye out for rolls that might affect the tests that are failing as well
* Compare the first instance of the flake with the previous successful run (see "Compare against successful runs" below for tips!)

### Compare against successful runs
Sometimes it can be easier to identify patterns of what's different between test runs than it is to identify a reason for the failure just from the failing runs. After you've identified what's failing, if you can't figure out what's causing the test to fail, keep an eye out for these common patterns:

* Do the tests fail when they're run in a certain order?
  * Our test sets' order is randomized, so sometimes interaction between tests can cause issues that only come up occasionally
  * If you notice that the failing builds fail tests in a certain order, also validate that the successful builds do not fail in that same order
* Do the tests tend to flake at certain times?
  * If the test isn't using something like DateTime.now(), then this may be a coincidence, but it's a good thing to check if you're stumped
  * If the test flakes the first build on a VM each day, it is likely due to the daily fresh provisioning of the bots.
* Do the tests flake on same bot/device?
  * If yes, it is most likely due to hardware issues, and can be routed to infra team for help.

# Fixing flaky tests
The TL will help triage, reassign, and attempt to fix the flakiness.

If the test was marked flaky in CI and then fixed, the test can be re-enabled after being validated for 50 consecutive runs without flakiness issues (task without exclamation point in flutter build dashboard and task not failed due to the same flaky failure). This can be done by updating the test entry in [.ci.yaml](https://github.com/flutter/flutter/blob/main/.ci.yaml) to remove the `bringup: true` entry for that target.

If not fixable, the test will be removed from the flutter build dashboard or deleted from CI completely depending on specific cases.