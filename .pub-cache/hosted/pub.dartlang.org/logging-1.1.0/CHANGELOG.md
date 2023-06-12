## 1.1.0

* Add `Logger.attachedLoggers` which exposes all loggers created with the
  default constructor.
* Enable the `avoid_dynamic_calls` lint.

## 1.0.2

* Update description.
* Add example.

## 1.0.1

* List log levels in README.

## 1.0.0

* Stable null safety release.

## 1.0.0-nullsafety.0

* Migrate to null safety.
* Removed the deprecated `LoggerHandler` typedef.

## 0.11.4

* Add top level `defaultLevel`.
* Require Dart `>=2.0.0`.
* Make detached loggers work regardless of `hierarchicalLoggingEnabled`.

## 0.11.3+2

* Set max SDK version to `<3.0.0`, and adjust other dependencies.

## 0.11.3+1

* Fixed several documentation comments.

## 0.11.3

* Added optional `LogRecord.object` field.

* `Logger.log` sets `LogRecord.object` if the message is not a string or a
  function that returns a string. So that a handler can access the original
  object instead of just its `toString()`.

## 0.11.2

* Added `Logger.detached` - a convenience factory to obtain a logger that is not
  attached to this library's logger hierarchy.

## 0.11.1+1

* Include default error with the auto-generated stack traces.

## 0.11.1

* Add support for automatically logging the stack trace on error messages. Note
  this can be expensive, so it is off by default.

## 0.11.0

* Revert change in `0.10.0`. `stackTrace` must be an instance of `StackTrace`.
  Use the `Trace` class from the [stack_trace package][] to convert strings.

[stack_trace package]: https://pub.dev/packages/stack_trace

## 0.10.0

* Change type of `stackTrace` from `StackTrace` to `Object`.

## 0.9.3

* Added optional `LogRecord.zone` field.

* Record current zone (or user specified zone) when creating new `LogRecord`s.
