JSON Reporter Protocol
======================

The test runner supports a JSON reporter which provides a machine-readable
representation of the test runner's progress. This reporter is intended for use
by IDEs and other tools to present a custom view of the test runner's operation
without needing to parse output intended for humans.

Note that the test runner is highly asynchronous, and users of this protocol
shouldn't make assumptions about the ordering of events beyond what's explicitly
specified in this document. It's possible for events from multiple tests to be
intertwined, for a single test to emit an error after it completed successfully,
and so on.

## Usage

Pass the `--reporter json` command-line flag to the test runner to activate the
JSON reporter.

    dart test --reporter json <path-to-test-file>

You may also use the `--file-reporter` option to enable the JSON reporter output
to a file, in addition to another reporter writing to stdout.

    dart test --file-reporter json:reports/tests.json <path-to-test-file>

The JSON stream will be emitted via standard output. It will be a stream of JSON
objects, separated by newlines.

See `json_reporter.schema.json` for a formal description of the protocol schema.
See `test/runner/json_reporter_test.dart` for some sample output.

## Compatibility

The protocol emitted by the JSON reporter is considered part of the public API
of the `test` package, and is subject to its [semantic versioning][semver]
restrictions. In particular:

[semver]: https://dart.dev/tools/pub/versioning#semantic-versions

* No new feature will be added to the protocol without increasing the test
  package's minor version number.

* No breaking change will be made to the protocol without increasing the test
  package's major version number.

The following changes are not considered breaking. This is not necessarily a
comprehensive list.

* Adding a new attribute to an existing object.

* Adding a new type of any object with a `type` parameter.

* Adding new test state values.

## Reading this Document

Each major type of JSON object used by the protocol is described by a class.
Classes have names which are referred to in this document, but are not used as
part of the protocol. Classes have typed attributes, which refer to the types
and names of attributes in the JSON objects. If an attribute's type is another
class, that refers to a nested object. The special type `List<...>` indicates a
JSON list of the given type.

Classes can "extend" one another, meaning that the subclass has all the
attributes of the superclass. Concrete subclasses can be distinguished by the
specific value of their `type` attribute. Classes may be abstract, indicating
that only their subclasses will ever be used.

## Events

### Event

```
abstract class Event {
  // The type of the event.
  //
  // This is always one of the subclass types listed below.
  String type;

  // The time (in milliseconds) that has elapsed since the test runner started.
  int time;
}
```

This is the root class of the protocol. All root-level objects emitted by the
JSON reporter will be subclasses of `Event`.

### StartEvent

```
class StartEvent extends Event {
  String type = "start";

  // The version of the JSON reporter protocol being used.
  //
  // This is a semantic version, but it reflects only the version of the
  // protocol—it's not identical to the version of the test runner itself.
  String protocolVersion;

  // The version of the test runner being used.
  //
  // This is null if for some reason the version couldn't be loaded.
  String? runnerVersion;

  // The pid of the VM process running the tests.
  int pid;
}
```

A single start event is emitted before any other events. It indicates that the
test runner has started running.

### AllSuitesEvent

```
class AllSuitesEvent extends Event {
  String type = "allSuites";

  /// The total number of suites that will be loaded.
  int count;
}
```

A single suite count event is emitted once the test runner knows the total
number of suites that will be loaded over the course of the test run. Because
this is determined asynchronously, its position relative to other events (except
`StartEvent`) is not guaranteed.

### SuiteEvent

```
class SuiteEvent extends Event {
  String type = "suite";

  /// Metadata about the suite.
  Suite suite;
}
```

A suite event is emitted before any `GroupEvent`s for groups in a given test
suite. This is the only event that contains the full metadata about a suite;
future events will refer to the suite by its opaque ID.

### DebugEvent

```
class DebugEvent extends Event {
  String type = "debug";

  /// The suite for which debug information is reported.
  int suiteID;

  /// The HTTP URL for the Dart Observatory, or `null` if the Observatory isn't
  /// available for this suite.
  String? observatory;

  /// The HTTP URL for the remote debugger for this suite's host page, or `null`
  /// if no remote debugger is available for this suite.
  String? remoteDebugger;
}
```

A debug event is emitted after (although not necessarily directly after) a
`SuiteEvent`, and includes information about how to debug that suite. It's only
emitted if the `--debug` flag is passed to the test runner.

Note that the `remoteDebugger` URL refers to a remote debugger whose protocol
may differ based on the browser the suite is running on. You can tell which
protocol is in use by the `Suite.platform` field for the suite with the given
ID. Since the same browser instance is used for multiple suites, different
suites may have the same `host` URL, although only one suite at a time will be
active when `--pause-after-load` is passed.

### GroupEvent

```
class GroupEvent extends Event {
  String type = "group";

  /// Metadata about the group.
  Group group;
}
```

A group event is emitted before any `TestStartEvent`s for tests in a given
group. This is the only event that contains the full metadata about a group;
future events will refer to the group by its opaque ID.

This includes the implicit group at the root of each suite, which has a `null`
name. However, it does *not* include implicit groups for the virtual suites
generated to represent loading test files.

If the group is skipped, a single `TestStartEvent` will be emitted for a test
within the group, followed by a `TestDoneEvent` marked as skipped. The
`group.metadata` field should *not* be used for determining whether a group is
skipped.

### TestStartEvent

```
class TestStartEvent extends Event {
  String type = "testStart";

  // Metadata about the test that started.
  Test test;
}
```

An event emitted when a test begins running. This is the only event that
contains the full metadata about a test; future events will refer to the test by
its opaque ID.

If the test is skipped, its `TestDoneEvent` will have `skipped` set to `true`.
The `test.metadata` should *not* be used for determining whether a test is
skipped.

### MessageEvent

```
class MessageEvent extends Event {
  String type = "print";

  // The ID of the test that printed a message.
  int testID;

  // The type of message being printed.
  String messageType;

  // The message that was printed.
  String message;
}
```

A `MessageEvent` indicates that a test emitted a message that should be
displayed to the user. The `messageType` field indicates the precise type of
this message. Different message types should be visually distinguishable.

A message of type "print" comes from a user explicitly calling `print()`.

A message of type "skip" comes from a test, or a section of a test, being
skipped. A skip message shouldn't be considered the authoritative source that a
test was skipped; the `TestDoneEvent.skipped` field should be used instead.

### ErrorEvent

```
class ErrorEvent extends Event {
  String type = "error";

  // The ID of the test that experienced the error.
  int testID;

  // The result of calling toString() on the error object.
  String error;

  // The error's stack trace, in the stack_trace package format.
  String stackTrace;

  // Whether the error was a TestFailure.
  bool isFailure;
}
```

A `ErrorEvent` indicates that a test encountered an uncaught error. Note
that this may happen even after the test has completed, in which case it should
be considered to have failed.

If a test is asynchronous, it may encounter multiple errors, which will result
in multiple `ErrorEvent`s.

### TestDoneEvent

```
class TestDoneEvent extends Event {
  String type = "testDone";

  // The ID of the test that completed.
  int testID;

  // The result of the test.
  String result;

  // Whether the test's result should be hidden.
  bool hidden;

  // Whether the test (or some part of it) was skipped.
  bool skipped;
}
```

An event emitted when a test completes. The `result` attribute indicates the
result of the test:

* `"success"` if the test had no errors.

* `"failure"` if the test had a `TestFailure` but no other errors.

* `"error"` if the test had an error other than a `TestFailure`.

If the test encountered an error, the `TestDoneEvent` will be emitted after the
corresponding `ErrorEvent`.

The `hidden` attribute indicates that the test's result should be hidden and not
counted towards the total number of tests run for the suite. This is true for
virtual tests created for loading test suites, `setUpAll()`, and
`tearDownAll()`. Only successful tests will be hidden.

Note that it's possible for a test to encounter an error after completing. In
that case, it should be considered to have failed, but no additional
`TestDoneEvent` will be emitted. If a previously-hidden test encounters an
error after completing, it should be made visible.

### DoneEvent

```
class DoneEvent extends Event {
  String type = "done";

  // Whether all tests succeeded (or were skipped).
  //
  // Will be `null` if the test runner was close before all tests completed
  // running.
  bool? success;
}
```

An event indicating the result of the entire test run. This will be the final
event emitted by the reporter.

## Other Classes

### Test

```
class Test {
  // An opaque ID for the test.
  int id;

  // The name of the test, including prefixes from any containing groups.
  String name;

  // The ID of the suite containing this test.
  int suiteID;

  // The IDs of groups containing this test, in order from outermost to
  // innermost.
  List<int> groupIDs;

  // The (1-based) line on which the test was defined, or `null`.
  int? line;

  // The (1-based) column on which the test was defined, or `null`.
  int? column;

  // The URL for the file in which the test was defined, or `null`.
  String? url;

  // The (1-based) line in the original test suite from which the test
  // originated.
  //
  // Will only be present if `root_url` is different from `url`.
  int? root_line;

  // The (1-based) line on in the original test suite from which the test
  // originated.
  //
  // Will only be present if `root_url` is different from `url`.
  int? root_column;

  // The URL for the original test suite in which the test was defined.
  //
  // Will only be present if different from `url`.
  String? root_url;

  // This field is deprecated and should not be used.
  Metadata metadata;
}
```

A single test case. The test's ID is unique in the context of this test run.
It's used elsewhere in the protocol to refer to this test without including its
full representation.

Most tests will have at least one group ID, representing the implicit root
group. However, some may not; these should be treated as having no group
metadata.

The `line`, `column`, and `url` fields indicate the location the `test()`
function was called to create this test. They're treated as a unit: they'll
either all be `null` or they'll all be non-`null`. The URL is always absolute,
and may be a `package:` URL.

### Suite

```
class Suite {
  // An opaque ID for the group.
  int id;

  // The platform on which the suite is running.
  String platform;

  // The path to the suite's file, or `null` if that path is unknown.
  String? path;
}
```

A test suite corresponding to a loaded test file. The suite's ID is unique in
the context of this test run. It's used elsewhere in the protocol to refer to
this suite without including its full representation.

A suite's platform is one of the platforms that can be passed to the
`--platform` option, or `null` if there is no platform (for example if the file
doesn't exist at all). Its path is either absolute or relative to the root of
the current package.

### Group

```
class Group {
  // An opaque ID for the group.
  int id;

  // The name of the group, including prefixes from any containing groups.
  String name;

  // The ID of the suite containing this group.
  int suiteID;

  // The ID of the group's parent group, unless it's the root group.
  int? parentID;

  // The number of tests (recursively) within this group.
  int testCount;

  // The (1-based) line on which the group was defined, or `null`.
  int? line;

  // The (1-based) column on which the group was defined, or `null`.
  int? column;

  // The URL for the file in which the group was defined, or `null`.
  String? url;

  // This field is deprecated and should not be used.
  Metadata metadata;
}
```

A group containing test cases. The group's ID is unique in the context of this
test run. It's used elsewhere in the protocol to refer to this group without
including its full representation.

The implicit group at the root of each test suite has `null` `name` and
`parentID` attributes.

The `line`, `column`, and `url` fields indicate the location the `group()`
function was called to create this group. They're treated as a unit: they'll
either all be `null` or they'll all be non-`null`. The URL is always absolute,
and may be a `package:` URL.

### Metadata

```
class Metadata {
  bool skip;

  // The reason the tests was skipped, or `null` if it wasn't skipped.
  String? skipReason;
}
```

The metadata class is deprecated and should not be used.

## Remote Debugger APIs

When running browser tests with `--pause-after-load`, the test package embeds a
few APIs in the JavaScript context of the host page. These allow tools to
control the debugging process in the same way a user might do from the command
line. They can be accessed by connecting to the remote debugger using the
[`DebugEvent.remoteDebugger`](#DebugEvent) URL.

All APIs are defined as methods on the top-level `dartTest` object. The
following methods are available:

### `resume()`

Calling `resume()` when the test runner is paused causes it to resume running
tests. If the test runner is not paused, it won't do anything. When
`--pause-after-load` is passed, the test runner will pause after loading each
suite but before any tests are run.

This gives external tools a chance to use the remote debugger protocol to set
breakpoints before tests have begun executing. They can start the test runner
with `--pause-after-load`, connect to the remote debugger using the
[`DebugEvent.remoteDebugger`](#DebugEvent) URL, set breakpoints, then call
`dartTest.resume()` in the host frame when they're finished.

### `restartCurrent()`

Calling `restartCurrent()` when the test runner is running a test causes it to
re-run that test once it completes its current run. It's intended to be called
when the browser is paused, as at a breakpoint.
