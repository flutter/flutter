## 1.0.0

- Support null safety.

## 0.2.3

* Prevent `tryCompletion` from crashing when looking up the script name when run
  without a current working directory.

## 0.2.2

* Increase minimum Dart SDK to `2.3.0`.

## 0.2.1+1

* Small fix to error handler.

## 0.2.1

* Exposed the `tryCompletion` method as a public interface.

* Added more complete instructions in the [`README.md`](README.md)

## 0.2.0

* Renamed `COMPLETION_COMMAND_NAME` to `completionCommandName`.

* Added named `logFile` argument to `tryArgsCompletion` and `tryCompletion` to
  aid debugging.

## 0.1.6

* A bunch of internal cleanup.

## 0.1.5

* Support the latest version of `logging`.

## 0.1.4

* Don't blow up if run via `pub run`.

## 0.1.2+5

* Fix for latest `args` version.

## 0.1.2+4

* Allow latest `args` version.

## 0.1.2+3

* Code cleanup.

## 0.1.2+2

* Stopped using deprecated features from `bot` package.

* Formatting

## 0.1.2+1

 * Updated `hop` and added `hop_unittest` dev dependencies.

## 0.1.2

* Fixed test runner.

## 0.1.1 2014-03-04
 * Removed unneeded dependency on `bot_io`
 * Cleanup of other references to `bot_io`

## 0.1.0 2014-02-15 (SDK 1.2.0-dev.5.7 32688)
 * First release
 * Maintains 100% compatibility with the `completion` library from the `bot_io`
   package as of release `0.25.1+2`.
