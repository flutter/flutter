## 1.3.1

* Populate the pubspec `repository` field.

## 1.3.0

* `FakeTimer.tick` will return a value instead of throwing.
* `FakeAsync.includeTimerStackTrace` allows controlling whether timers created
   with a FakeAsync will include a creation Stack Trace.

## 1.2.0

* Stable release for null safety.

## 1.2.0-nullsafety.3

* Update SDK constraints to `>=2.12.0-0 <3.0.0` based on beta release
  guidelines.

## 1.2.0-nullsafety.2

* Allow prerelease versions of the 2.12 sdk.

## 1.2.0-nullsafety.1

* Allow 2.10 stable and 2.11.0 dev SDK versions.

## 1.2.0-nullsafety

Pre-release for the null safety migration of this package.

Note that `1.2.0` may not be the final stable null safety release version,
we reserve the right to release it as a `2.0.0` breaking change.

This release will be pinned to only allow pre-release sdk versions starting
from `2.10.0-0`.

## 1.1.0

* Exposed the `FakeTimer` class as a public class.
* Added `FakeAsync.pendingTimers` which gives access to all pending timers at
  the time of the call.

## 1.0.2

* Update min SDK to 2.2.0

## 1.0.1

* Update to lowercase Dart core library constants.
* Fix use of deprecated `isInstanceOf` matcher.

## 1.0.0

This release contains the `FakeAsync` class that was defined in [`quiver`][].
It's backwards-compatible with both the `quiver` version *and* the old version
of the `fake_async` package.

[`quiver`]: https://pub.dev/packages/quiver

### New Features

* A top-level `fakeAsync()` function was added that encapsulates
  `new FakeAsync().run(...)`.

### New Features Relative to `quiver`

* `FakeAsync.elapsed` returns the total amount of fake time elapsed since the
  `FakeAsync` instance was created.

* `new FakeAsync()` now takes an `initialTime` argument that sets the default
  time for clocks created with `FakeAsync.getClock()`, and for the `clock`
  package's top-level `clock` variable.

### New Features Relative to `fake_async` 0.1

* `FakeAsync.periodicTimerCount`, `FakeAsync.nonPeriodicTimerCount`, and
  `FakeAsync.microtaskCount` provide visibility into the events scheduled within
  `FakeAsync.run()`.

* `FakeAsync.getClock()` provides access to fully-featured `Clock` objects based
  on `FakeAsync`'s elapsed time.

* `FakeAsync.flushMicrotasks()` empties the microtask queue without elapsing any
  time or running any timers.

* `FakeAsync.flushTimers()` runs all microtasks and timers until there are no
  more scheduled.

## 0.1.2

* Integrate with the clock package.

