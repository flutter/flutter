// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Interact with developer tools such as the debugger and inspector.
///
/// This is a specialized library intended for interacting with the Dart runtime
/// programmatically for debugging and inspection. Sample uses include advanced
/// debugging, and creating developer tools.
///
/// This library has platform specific implementations for Dart web
/// and Dart Native (VM). A specific platform may not support all operations.
///
/// The functionality provided by this library is generally only available
/// to Dart code run in development mode, e.g., `dart run`, and not in production
/// mode, e.g., the output of `dart compile exe`.
///
/// ## Debugging
/// The [debugger] function can be used to stop the program as if a breakpoint
/// was hit. The breakpoint will be placed right after the call to `debugger`.
/// This functionality can be useful for triggering breakpoints based on logic
/// in the code.
///
/// Example:
///
/// ```dart template:main
/// var counter = 0;
/// final someInterestingValue = 1000;
/// while (true) {
///   if (counter == someInterestingValue) {
///     // Trigger a breakpoint in the the debugger.
///     debugger();
///   }
///   counter++;
/// }
/// ```
///
/// When executed with `dart run --observe`, and opened in DevTools, the
/// debugger will be stopped with `counter` at the value `1000`.
///
/// ## Inspection
/// Developer tools, such as Dart DevTools, connected to the runtime system
/// may allow for inspecting execution timing in a "timeline" view.
/// The static methods of [Timeline] can add extra information and timing events
/// to this view.
///
/// Example:
///
/// ```dart
/// void main() {
///   Timeline.timeSync('Calculation loop', () {
///     for (var i = 30; i < 50; i++) {
///       Timeline.timeSync('fib($i)', () {
///         fibonacci(i);
///       });
///     }
///   });
/// }
///
/// int fibonacci(int n) => (n < 2) ? n : fibonacci(n - 2) + fibonacci(n - 1);
/// ```
///
/// When executed with `dart run --observe`, and opened in DevTools,
/// the Performance tab will display a timeline containing the annotations
/// passed to `timeSync`.
///
/// ## Developer tools
/// A developer tool, like the debugger built into the `dart` command,
/// may access information about the running application
/// exposed by the runtime system,
/// using the [Service] and [ServiceProtocolInfo] classes.
///
/// {@category Core}
library dart.developer;

import 'dart:_internal' show checkNotNullable, Since;
import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:isolate' show Isolate, RawReceivePort, SendPort;

part 'extension.dart';
part 'http_profiling.dart';
part 'profiler.dart';
part 'service.dart';
part 'timeline.dart';

/// If [when] is true, stop the program as if a breakpoint were hit at the
/// following statement.
///
/// Returns the value of [when]. Some debuggers may display [message].
///
/// NOTE: When invoked, the isolate will not return until a debugger
/// continues execution. When running in the Dart VM, the behaviour is the same
/// regardless of whether or not a debugger is connected. When compiled to
/// JavaScript, this uses the "debugger" statement, and behaves exactly as
/// that does.
external bool debugger({bool when = true, String? message});

/// Send a reference to [object] to any attached debuggers.
///
/// Debuggers may open an inspector on the object. Returns the argument.
external Object? inspect(Object? object);

/// Emit a log event.
///
/// This function was designed to map closely to the logging information
/// collected by `package:logging`.
///
/// - [message] is the log message
/// - [time] (optional) is the timestamp
/// - [sequenceNumber] (optional) is a monotonically increasing sequence number
/// - [level] (optional) is the severity level (a value between 0 and 2000); see
///   the `package:logging` `Level` class for an overview of the possible values
/// - [name] (optional) is the name of the source of the log message
/// - [zone] (optional) the zone where the log was emitted
/// - [error] (optional) an error object associated with this log event
/// - [stackTrace] (optional) a stack trace associated with this log event
external void log(
  String message, {
  DateTime? time,
  int? sequenceNumber,
  int level = 0,
  String name = '',
  Zone? zone,
  Object? error,
  StackTrace? stackTrace,
});

/// Current reachability barrier state.
///
/// A reachability barrier state that provides a way to synchronize on
/// reachability. At value 'x', any object that became unreachable during
/// 'value' < 'x' has been collected and any associated finalizers have been
/// scheduled for execution, i.e. the non-execution of a finalizer reliably
/// indicates the object is still reachable in the previous barrier state.
///
/// Objects that became unreachable in the current barrier state may have not
/// yet been collected or finalized.
///
/// NOTE: There are no guarantees of forward progress. An implementation may
/// return the same value forever for this barrier state.
@Since('2.19')
external int get reachabilityBarrier;

/// Functionality available on the native runtime.
@Since('3.0')
abstract final class NativeRuntime {
  /// The build ID for the running application.
  ///
  /// The build ID of an application is a string containing a hexadecimal
  /// representation of an arbitrarily sized sequence of bytes. This string
  /// can be used to match a specific ahead-of-time compiled version of an
  /// application, for example, to determine which debugging artifacts emitted
  /// during compilation should be used to translate crash and error reports.
  ///
  /// The build ID is only available for ahead-of-time compiled programs. If a
  /// build ID is not available, the value is `null`.
  @Since('3.1')
  external static String? get buildId;

  /// Writes a snapshot of the heap to [filepath].
  ///
  /// The [filepath] should be a native file path that can be opened for writing.
  /// Relative paths will be relative to the current working directory. If the
  /// file already exists it will be overwritten.
  ///
  /// **WARNING**: Only works on a native runtime in certain configurations. An
  /// [UnsupportedError] error is thrown if this functionality is not available
  /// (e.g. in product mode, in non-standalone VM, ...)
  ///
  /// NOTE: This is an experimental function. We reserve the right to change
  /// or remove it in the future.
  external static void writeHeapSnapshotToFile(String filepath);
}
