## 0.4.16

* Make the labels for test loading more readable in the compact and expanded
  reporters, use gray instead of black.
* Print a command to re-run the failed test after each failure in the compact
  reporter.
* Fix the package config path used when running pre-compiled vm tests.

## 0.4.15

* Support the latest `package:test_api`.

## 0.4.14

* Update the github reporter to output the platform in the test names when
  multiple platforms are used.
* Fix `spawnHybridUri` support for `package:` uris.

## 0.4.13

* Re-publish changes from 0.4.12.
* Stop relying on setUpAllName and tearDownAllName constants from test_api.

## 0.4.12 (retracted)

* Remove wait for VM platform isolate exits.
* Drop `dart2jsPath` configuration support.
* Allow loading tests under a path with the directory named `packages`.
* Require analyzer version `3.3.0`, and allow version `4.x`.

## 0.4.11

* Update `vm_service` constraint to `>=6.0.0 <9.0.0`.

## 0.4.10

* Update `analyzer` constraint to `>=2.14.0 <3.0.0`.
* Add an `--ignore-timeouts` command line flag, which disables all timeouts
  for all tests.
* Experimental: Add a VM service extension `ext.test.pauseAfterTests` which
  configures VM platform tests to pause for debugging after tests are run,
  before the test isolates are killed.

## 0.4.9

* Wait for paused VM platform isolates before shutdown.

## 0.4.8

* Add logging about enabling stack trace chaining to the compact and expanded
  reporters (moved from the invoker). This will now only be logged once after
  all tests have ran.

## 0.4.7

* Fix parsing of file paths into a URI on windows.

## 0.4.6

* Support query parameters `name`, `full-name`, `line`, and `col` on test paths,
  which will apply the filters to only those test suites.
  * All specified filters must match for a test to run.
  * Global filters (ie: `--name`) are also still respected and must match.
  * The `line` and `col` will match if any frame from the test trace matches
    (the test trace is the current stack trace where `test` is invoked).
* Support the latest `test_api`.

## 0.4.5

* Use newer analyzer APIs.

## 0.4.4

* Support the latest `test_api`.

## 0.4.3

* Add an option to disallow duplicate test or group names in `directRunTests`.
* Add configuration to disallow duplicate test and group names by default. See
  the [docs][allow_duplicate_test_names] for more information.
* Remove dependency on pedantic.

[allow_duplicate_test_names]: https://github.com/dart-lang/test/blob/master/pkgs/test/doc/configuration.md#allow_duplicate_test_names

## 0.4.2

* Re-use the cached dill file from previous runs on subsequent runs.

## 0.4.1

* Use the latest `package:matcher`.

## 0.4.0

* **BREAKING**: All parameters to the `SuiteConfiguration` and `Configuration`
  constructors are now required. Some specialized constructors have been added
  for the common cases where a subset are intended to be provided.
* **BREAKING**: Remove support for `FORCE_TEST_EXIT`.
* Report incomplete tests as errors in the JSON reporter when the run is
  canceled early.
* Don't log the --test-randomization-ordering-seed if using the json reporter.
* Add a new exit code, 79, which is used when no tests were ran.
  * Previously you would have gotten either exit code 1 or 65 (65 if you had
    provided a test name regex).
* When no tests were ran but tags were provided, list the tag configuration.
* Update `analyzer` constraint to `>=1.0.0 <3.0.0`.

## 0.3.29

* Fix a bug where a tag level configuration would cause test suites with that
  tag to ignore the `--test-randomize-ordering-seed` argument.

## 0.3.28

* Add `time` field to the json reporters `allSuites` event type so that all
  event types can be unified.

## 0.3.27

* Restore the `Configuration.loadFromString` constructor.

## 0.3.26

* Give a better error when `printOnFailure` is called from outside a test
  zone.

## 0.3.25

* Support the latest vm_service release (`7.0.0`).

## 0.3.24

* Fix race condition between compilation of vm tests and the running of
  isolates.

## 0.3.23

* Forward experiment args from the runner executable to the compiler with the
  new vm test loading strategy.

## 0.3.22

* Fix a windows issue with the new loading strategy.

## 0.3.21

* Fix an issue where you couldn't have tests compiled in both sound and
  unsound null safety modes.

## 0.3.20

* Add library `scaffolding.dart` to allow importing a subset of the normal
  surface area.
* Remove `suiteChannel`. This is now handled by an additional argument to the
  `beforeLoad` callback in `serializeSuite`.
* Disable stack trace chaining by default.
* Change the default way VM tests are launched and ran to greatly speed up
  loading performance.
  * You can force the old strategy with `--use-data-isolate-strategy` flag if
    you run into issues, but please also file a bug.
* Improve the error message for `hybridMain` functions with an incompatible
  StreamChannel parameter type.
* Change the `message` argument to `PlatformPlugin.load` to `Map<String,
  Object?>`. In an upcoming release this will be required as the type for this
  argument when passed through to `deserializeSuite`.

## 0.3.19

* ~~Disable stack trace chaining by default.~~

## 0.3.18

* Update `spawnHybridCode` to default to the current packages language version.
* Update to the latest `test_api`.

## 0.3.17

* Complete the null safety migration.

## 0.3.16

* Allow package:io version 1.0.0.

## 0.3.14

* Handle issue closing `stdin` during shutdown.

## 0.3.13

* Allow the latest analyzer `1.0.0`.

## 0.3.12

* Stable null safety release.

## 0.3.12-nullsafety.17

* Use the `test_api` for stable null safety.

## 0.3.12-nullsafety.16

* Expand upper bound constraints for some null safe migrated packages.

## 0.3.12-nullsafety.15

* Support the latest vm_service release (`6.x.x`).

## 0.3.12-nullsafety.14

* Support the latest coverage release (`0.15.x`).

## 0.3.12-nullsafety.13

* Allow the latest args release (`2.x`).

## 0.3.12-nullsafety.12

* Allow the latest glob release (`2.x`).

## 0.3.12-nullsafety.11

* Fix `spawnHybridUri` on windows.
* Allow `package:yaml` version `3.x.x`.

## 0.3.12-nullsafety.10

* Allow `package:analyzer` version `0.41.x`.

## 0.3.12-nullsafety.9

* Fix `spawnHybridUri` to respect language versioning of the spawned uri.
* Pre-emptively fix legacy library import lint violations, and unmigrate some
  libraries as necessary.

## 0.3.12-nullsafety.8

* Fix a bug where the test runner could crash when printing the elapsed time.
* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.


## 0.3.12-nullsafety.7

* Allow prerelease versions of the 2.12 sdk.

## 0.3.12-nullsafety.6

* Add experimental `directRunTests`, `directRunSingle`, and `enumerateTestCases`
  APIs to enable test runners written around a single executable that can report
  and run any single test case.

## 0.3.12-nullsafety.5

* Allow `2.10` stable and `2.11.0-dev` SDKs.
* Add `src/platform.dart` library to consolidate the necessary imports required
  to write a custom platform.
* Stop required a `SILENT_OBSERVATORY` environment variable to run with
  debugging and the JSON reporter.

## 0.3.12-nullsafety.4

* Support latest `package:vm_service`.

## 0.3.12-nullsafety.3

* Clean up `--help` output.

## 0.3.12-nullsafety.2

* Allow version `0.40.x` of `analyzer`.

## 0.3.12-nullsafety.1

* Update source_maps constraint.

## 0.3.12-nullsafety

* Migrate to null safety.

## 0.3.11+4 (Backport)

* Fix `spawnHybridUri` on windows.

## 0.3.11+3 (Backport)

* Support `package:analyzer` version `0.41.x`.

## 0.3.11+2 (Backport)

* Fix `spawnHybridUri` to respect language versioning of the spawned uri.

## 0.3.11+1

* Allow analyzer 0.40.x.

## 0.3.11

* Update to `matcher` version `0.12.9`.

## 0.3.10

* Prepare for `unawaited` from `package:meta`.

## 0.3.9

* Ignore a null `RunnerSuite` rather than throw an error.

## 0.3.8

* Update vm bootstrapping logic to ensure the bootstrap library has the same
  language version as the test.
* Populate `languageVersionComment` in the `Metadata` returned from
  `parseMetadata`.

## 0.3.7

* Support the latest `package:coverage`.

## 0.3.6

* Expose the `Configuration` class and related classes through `backend.dart`.

## 0.3.5

* Add additional information to an exception when we end up with a null
  `RunnerSuite`.

* Update vm bootstrapping logic to ensure the bootstrap library has the same
  language version as the test.
* Populate `languageVersionComment` in the `Metadata` returned from
  `parseMetadata`.

## 0.3.4

* Fix error messages for incorrect string literals in test annotations.

## 0.3.3

* Support latest `package:vm_service`.

## 0.3.2

* Drop the `package_resolver` dependency.

## 0.3.1

* Support latest `package:vm_service`.
* Enable asserts in code running through `spawnHybrid` APIs.
* Exit with a non-zero code if no tests were ran, whether due to skips or having
  no tests defined.

## 0.3.0

* Bump minimum SDK to `2.4.0` for safer usage of for-loop elements.
* Deprecate `PhantomJS` and provide warning when used. Support for `PhantomJS`
  will be removed in version `2.0.0`.
* Differentiate between test-randomize-ordering-seed not set and 0 being chosen
  as the random seed.
* `deserializeSuite` now takes an optional `gatherCoverage` callback.
* Support retrying of entire test suites when they fail to load.
* Fix the `compiling` message in precompiled mode so it says `loading` instead,
  which is more accurate.
* Change the behavior of the concurrency setting so that loading and running
  don't have separate pools.
  * The loading and running of a test are now done with the same resource, and
    the concurrency setting uniformly affects each. With `-j1` only a single
    test will ever be loaded at a time.
  * Previously the loading pool was 2x larger than the actual concurrency
    setting which could cause flaky tests due to tests being loaded while
    other tests were running, even with `-j1`.
* Avoid printing uncaught errors within `spawnHybridUri`.

## 0.2.18

* Allow `test_api` `0.2.13` to work around a bug in the SDK version `2.3.0`.

## 0.2.17

* Add `file_reporters` configuration option and `--file-reporter` CLI option to
  allow specifying a separate reporter that writes to a file.

## 0.2.16

* Internal cleanup.
* Add `customHtmlTemplateFile` configuration option to allow sharing an
  html template between tests
* Depend on the latest `test_api`.

## 0.2.15

* Add a `StringSink` argument to reporters to prepare for reporting to a file.
* Add --test-randomize-ordering-seed` argument to randomize test
execution order based on a provided seed
* Depend on the latest `test_api`.

## 0.2.14

* Support the latest `package:analyzer`.
* Update to latest `package:matcher`. Improves output for instances of private
  classes.

## 0.2.13

* Depend on the latest `package:test_api`.

## 0.2.12

* Conditionally import coverage logic in `engine.dart`. This ensures the engine
  is platform agnostic.

## 0.2.11

* Implement code coverage gathering for VM tests.

## 0.2.10

* Add a `--debug` argument for running the VM/Chrome in debug mode.

## 0.2.9+2

* Depend on the latest `test_api`.

## 0.2.9+1

* Allow the latest `package:vm_service`.

## 0.2.9

* Mark `package:test_core` as deprecated to prevent accidental use.
* Depend on the latest `test_api`.

## 0.2.8

* Depend on `vm_service` instead of `vm_service_lib`.
* Drop dependency on `pub_semver`.
* Allow `analyzer` version `0.38.x`.

## 0.2.7

* Depend on `vm_service_lib` instead of `vm_service_client`.
* Depend on latest `package:analyzer`.

## 0.2.6

* Internal cleanup - fix lints.
* Use the latest `test_api`.

## 0.2.5

* Fix an issue where non-completed tests were considered passing.
* Updated `compact` and `expanded` reporters to display non-completed tests.

## 0.2.4

* Avoid `dart:isolate` imports on code loaded in tests.
* Expose the `parseMetadata` function publicly through a new `backend.dart`
  import, as well as re-exporting `package:test_api/backend.dart`.

## 0.2.3

* Switch import for `IsolateChannel` for forwards compatibility with `2.0.0`.

## 0.2.2

* Allow `analyzer` version `0.36.x`.
* Update to matcher version `0.12.5`.

## 0.2.1+1

* Allow `analyzer` version `0.35.x`.

## 0.2.1

* Require Dart SDK `>=2.1.0`.
* Require latest `test_api`.

## 0.2.0

* Remove `remote_listener.dart` and `suite_channel_manager.dart` from runner
  and depend on them from `test_api`.

## 0.1.0

* Initial release of `test_core`. Provides the basic API for writing and running
  tests on the VM.
