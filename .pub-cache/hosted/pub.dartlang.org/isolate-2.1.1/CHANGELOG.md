## 2.1.1

* **DISCONTINUE PACKAGE**
  This package is no longer maintained by the Dart team.
* Make `IsolateRunner.close` not hang if called more than once.

## 2.1.0

* Migrate to null safety.
* Add `singleResponseFutureWithTimeout` and `singleCallbackPortWithTimeout`,
  while deprecating the timeout functionality of
  `singleResponseFuture` and `singleCallbackPort`.

## 2.0.3

* Update SDK requirements.
* Fix bug in `IsolateRunner.kill` with a zero duration.
* Update some type from `Future` to `Future<void>`.
* Make `LoadBalancer.runMultiple` properly generic.

## 2.0.1

* Use lower-case constants from dart:io.

## 2.0.0

* Make port functions generic so they can be used in a Dart 2 type-safe way.

## 1.1.0

* Add generic arguments to `run` in `LoadBalancer` and `IsolateRunner`.
* Add generic arguments to `singleCallbackPort` and `singleCompletePort`.

## 1.0.0

* Change to using `package:test` for testing.

## 0.2.3

* Fixed strong mode analysis errors.
* Migrated tests to package:test.

## 0.2.2

* Made `Isolate.kill` parameter `priority` a named parameter.

## 0.2.1

* Fixed spelling in a number of doc comments and the README.

## 0.2.0

* Renamed library `isolaterunner.dart` to `isolate_runner.dart`.
* Renamed library `loadbalancer.dart' to `load_balancer.dart`.

## 0.1.0

* Initial version
* Adds `IsolateRunner` as a helper around Isolate.
* Adds single-message port helpers and a load balancer.
