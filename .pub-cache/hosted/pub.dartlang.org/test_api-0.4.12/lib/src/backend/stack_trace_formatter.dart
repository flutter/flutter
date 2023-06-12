// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:stack_trace/stack_trace.dart';

import 'invoker.dart';
import 'stack_trace_mapper.dart';

/// The key used to look up [StackTraceFormatter.current] in a zone.
final _currentKey = Object();

/// A class that tracks how to format a stack trace according to the user's
/// configuration.
///
/// This can convert JavaScript stack traces to Dart using source maps, and fold
/// irrelevant frames out of the stack trace.
class StackTraceFormatter {
  /// A class that converts [trace] into a Dart stack trace, or `null` to use it
  /// as-is.
  StackTraceMapper? _mapper;

  /// The set of packages to fold when producing terse [Chain]s.
  var _except = {'test', 'stream_channel', 'test_api'};

  /// If non-empty, all packages not in this list will be folded when producing
  /// terse [Chain]s.
  var _only = <String>{};

  /// Returns the current manager, or `null` if this isn't called within a call
  /// to [asCurrent].
  static StackTraceFormatter? get current =>
      Zone.current[_currentKey] as StackTraceFormatter?;

  /// Runs [body] with this as [StackTraceFormatter.current].
  ///
  /// This is zone-scoped, so this will be the current configuration in any
  /// asynchronous callbacks transitively created by [body].
  T asCurrent<T>(T Function() body) =>
      runZoned(body, zoneValues: {_currentKey: this});

  /// Configure how stack traces are formatted.
  ///
  /// The [mapper] is used to convert JavaScript traces into Dart traces. The
  /// [except] set indicates packages whose frames should be folded away. If
  /// [only] is non-empty, it indicates packages whose frames should *not* be
  /// folded away.
  void configure(
      {StackTraceMapper? mapper, Set<String>? except, Set<String>? only}) {
    if (mapper != null) _mapper = mapper;
    if (except != null) _except = except;
    if (only != null) _only = only;
  }

  /// Converts [stackTrace] to a [Chain] and formats it according to the user's
  /// preferences.
  ///
  /// If [verbose] is `true`, this doesn't fold out irrelevant stack frames. It
  /// defaults to the current test's [Metadata.verboseTrace] configuration, or
  /// `false` if there is no current test.
  Chain formatStackTrace(StackTrace stackTrace, {bool? verbose}) {
    verbose ??= Invoker.current?.liveTest.test.metadata.verboseTrace ?? false;

    var chain =
        Chain.forTrace(_mapper?.mapStackTrace(stackTrace) ?? stackTrace);
    if (verbose) return chain;

    return chain.foldFrames((frame) {
      if (_only.isNotEmpty) return !_only.contains(frame.package);
      return _except.contains(frame.package);
    }, terse: true);
  }
}
