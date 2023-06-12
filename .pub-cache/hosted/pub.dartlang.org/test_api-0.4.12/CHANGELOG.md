## 0.4.12

* Internal cleanup.

## 0.4.11

* Support the latest version of `package:matcher`.

## 0.4.10

* Add `Target` to restrict `TestOn` annotation to library level.

## 0.4.9

* Add `ignoreTimeouts` option to `Suite`, which disables all timeouts for all
  tests in that suite.

## 0.4.8

* `TestFailure` implements `Exception` for compatibility with
  `only_throw_exceptions`.

## 0.4.7

* Remove logging about enabling the chain-stack-traces flag from the invoker.

## 0.4.6

* Give a better exception when using `markTestSkipped` outside of a test.
* Format stack traces if a formatter is available when serializing tests
  and groups from the remote listener.

## 0.4.5

* Add defaulting for older test backends that don't pass a configuration for
  the `allow_duplicate_test_names` parameter to the remote listener.

## 0.4.4

* Allow disabling duplicate test or group names in the `Declarer`.

## 0.4.3

* Use the latest `package:matcher`.

## 0.4.2

* Update `analyzer` constraint to `>=1.5.0 <3.0.0`.

## 0.4.1

* Give a better error when `printOnFailure` is called from outside a test
  zone.

## 0.4.0

* Add libraries `scaffolding.dart`, and `expect.dart` to allow importing as
  subset of the normal surface area.
* Add new APIs in `hooks.dart` to allow writing custom expectation frameworks
  which integrate with the test runner.
* Add examples to `throwsA` and make top-level `throws...` matchers refer to it.
* Disable stack trace chaining by default.
* Fix `expectAsync` function type checks.
* Add `RemoteException`, `RemoteListener`, `StackTraceFormatter`, and
  `StackTraceMapper` to `backend.dart`.
* **Breaking** remove `Runtime.phantomJS`
* **Breaking** Add callback to get the suite channel in the `beforeLoad`
  callback of `RemoteListener.start`. This is now used in place of using zones
  to communicate the value.

## 0.3.0

* **Breaking** `TestException.message` is now nullable.
  * Fixes handling of `null` messages in remote exceptions.

## 0.2.20

* Fix some strong null safety mode errors in the original migration.

## 0.2.19

* Stable release for null safety.

## 0.2.19-nullsafety.7

* Expand upper bound constraints for some null safe migrated packages.

## 0.2.19-nullsafety.6

* Fix `spawnHybridUri` to respect language versioning of the spawned uri.

## 0.2.19-nullsafety.5

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 0.2.19-nullsafety.4

* Allow prerelease versions of the 2.12 sdk.

## 0.2.19-nullsafety.3

* Add capability to filter to a single exact test name in `Declarer`.
* Add `markTestSkipped` API.

## 0.2.19-nullsafety.2

* Allow `2.10` stable and `2.11.0-dev` SDKs.
* Annotate the classes used as annotations to restrict their usage to library
  level.

## 0.2.19-nullsafety

* Migrate to NNBD.
  * The vast majority of changes are intended to express the pre-existing
    behavior of the code regarding to handling of nulls.
  * **Breaking Change**: `GroupEntry.name` is no longer nullable, the root
    group now has the empty string as its name.
* Add the `Fake` class, available through `package:test_api/fake.dart`.  This
  was previously part of the Mockito package, but with null safety it is useful
  enough that we decided to make it available through `package:test`.  In a
  future release it will be made available directly through
  `package:test_api/test_api.dart` (and hence through
  `package:test_core/test_core.dart` and `package:test/test.dart`).

## 0.2.18+1 (Backport)

* Fix `spawnHybridUri` to respect language versioning of the spawned uri.

## 0.2.18

* Update to `matcher` version `0.12.9`.

## 0.2.17

* Add `languageVersionComment` on the `MetaData` class. This should only be
  present for test suites.

## 0.2.16

* Deprecate `LiveTestController.liveTest`, the `LiveTestController` instance now
  implements `LiveTest` and can be used directly.

## 0.2.15

* Cancel any StreamQueue that is created as a part of a stream matcher once it
  is done matching.
  * This fixes a bug where using a matcher on a custom stream controller and
    then awaiting the `close()` method on that controller would hang.
* Avoid causing the test runner to hang if there is a timeout during a
  `tearDown` callback following a failing test case.

## 0.2.14

* Bump minimum SDK to `2.4.0` for safer usage of for-loop elements.

## 0.2.13

* Work around a bug in the `2.3.0` SDK by avoiding for-loop elements at the top
  level.

## 0.2.12

* Link to docs on setting timeout when a test times out with the default
  duration.
* No longer directly depend on `package:pedantic`.

## 0.2.11

* Extend the timeout for synthetic tests, e.g. `tearDownAll`.

## 0.2.10

* Update to latest `package:matcher`. Improves output for instances of private
  classes.

## 0.2.9

* Treat non-solo tests as skipped so they are properly reported.

## 0.2.8

* Remove logic which accounted for a race condition in state change. The logic
  was required because `package:sse` used to not guarantee order. This is no
  longer the case.

## 0.2.7

* Prepare for upcoming `Stream<List<int>>` changes in the Dart SDK.
* Mark `package:test_api` as deprecated to prevent accidental use.

## 0.2.6

* Don't swallow exceptions from callbacks in `expectAsync*`.
* Internal cleanup - fix lints.
* Fixed a race condition that caused tests to occasionally fail during
  `tearDownAll` with the message `(tearDownAll) - did not complete [E]`.

## 0.2.5

* Expose the  `Metadata`, `PlatformSelector`, `Runtime`, and `SuitePlatform`
  classes publicly through a new `backend.dart` import.

## 0.2.4

* Allow `stream_channel` version `2.0.0`.

## 0.2.3

* Update to matcher version `0.12.5`.

## 0.2.2

* Require Dart SDK `>=2.1.0`.

## 0.2.1

* Add `remote_listener.dart` and `suite_channel_manager.dart`.

## 0.2.0

* Remove "runner" extensions.


## 0.1.1

* Update `stack_trace_formatter` to fold `test_api` frames by default.


## 0.1.0

* Initial release of `test_api`. Provides the basic API for writing tests and
  touch points for implementing a custom test runner.
