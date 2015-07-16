// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library stack_trace.chain;

import 'dart:async';
import 'dart:collection';

import 'frame.dart';
import 'stack_zone_specification.dart';
import 'trace.dart';
import 'utils.dart';

/// A function that handles errors in the zone wrapped by [Chain.capture].
typedef void ChainHandler(error, Chain chain);

/// A chain of stack traces.
///
/// A stack chain is a collection of one or more stack traces that collectively
/// represent the path from [main] through nested function calls to a particular
/// code location, usually where an error was thrown. Multiple stack traces are
/// necessary when using asynchronous functions, since the program's stack is
/// reset before each asynchronous callback is run.
///
/// Stack chains can be automatically tracked using [Chain.capture]. This sets
/// up a new [Zone] in which the current stack chain is tracked and can be
/// accessed using [new Chain.current]. Any errors that would be top-leveled in
/// the zone can be handled, along with their associated chains, with the
/// `onError` callback. For example:
///
///     Chain.capture(() {
///       // ...
///     }, onError: (error, stackChain) {
///       print("Caught error $error\n"
///             "$stackChain");
///     });
class Chain implements StackTrace {
  /// The line used in the string representation of stack chains to represent
  /// the gap between traces.
  static const _GAP = '===== asynchronous gap ===========================\n';

  /// The stack traces that make up this chain.
  ///
  /// Like the frames in a stack trace, the traces are ordered from most local
  /// to least local. The first one is the trace where the actual exception was
  /// raised, the second one is where that callback was scheduled, and so on.
  final List<Trace> traces;

  /// The [StackZoneSpecification] for the current zone.
  static StackZoneSpecification get _currentSpec =>
    Zone.current[#stack_trace.stack_zone.spec];

  /// Runs [callback] in a [Zone] in which the current stack chain is tracked
  /// and automatically associated with (most) errors.
  ///
  /// If [onError] is passed, any error in the zone that would otherwise go
  /// unhandled is passed to it, along with the [Chain] associated with that
  /// error. Note that if [callback] produces multiple unhandled errors,
  /// [onError] may be called more than once. If [onError] isn't passed, the
  /// parent Zone's `unhandledErrorHandler` will be called with the error and
  /// its chain.
  ///
  /// Note that even if [onError] isn't passed, this zone will still be an error
  /// zone. This means that any errors that would cross the zone boundary are
  /// considered unhandled.
  ///
  /// If [callback] returns a value, it will be returned by [capture] as well.
  ///
  /// Currently, capturing stack chains doesn't work when using dart2js due to
  /// issues [15171] and [15105]. Stack chains reported on dart2js will contain
  /// only one trace.
  ///
  /// [15171]: https://code.google.com/p/dart/issues/detail?id=15171
  /// [15105]: https://code.google.com/p/dart/issues/detail?id=15105
  static capture(callback(), {ChainHandler onError}) {
    var spec = new StackZoneSpecification(onError);
    return runZoned(() {
      try {
        return callback();
      } catch (error, stackTrace) {
        // TODO(nweiz): Don't special-case this when issue 19566 is fixed.
        return Zone.current.handleUncaughtError(error, stackTrace);
      }
    }, zoneSpecification: spec.toSpec(), zoneValues: {
      #stack_trace.stack_zone.spec: spec
    });
  }

  /// Returns [futureOrStream] unmodified.
  ///
  /// Prior to Dart 1.7, this was necessary to ensure that stack traces for
  /// exceptions reported with [Completer.completeError] and
  /// [StreamController.addError] were tracked correctly.
  @Deprecated("Chain.track is not necessary in Dart 1.7+.")
  static track(futureOrStream) => futureOrStream;

  /// Returns the current stack chain.
  ///
  /// By default, the first frame of the first trace will be the line where
  /// [Chain.current] is called. If [level] is passed, the first trace will
  /// start that many frames up instead.
  ///
  /// If this is called outside of a [capture] zone, it just returns a
  /// single-trace chain.
  factory Chain.current([int level=0]) {
    if (_currentSpec != null) return _currentSpec.currentChain(level + 1);
    return new Chain([new Trace.current(level + 1)]);
  }

  /// Returns the stack chain associated with [trace].
  ///
  /// The first stack trace in the returned chain will always be [trace]
  /// (converted to a [Trace] if necessary). If there is no chain associated
  /// with [trace] or if this is called outside of a [capture] zone, this just
  /// returns a single-trace chain containing [trace].
  ///
  /// If [trace] is already a [Chain], it will be returned as-is.
  factory Chain.forTrace(StackTrace trace) {
    if (trace is Chain) return trace;
    if (_currentSpec == null) return new Chain([new Trace.from(trace)]);
    return _currentSpec.chainFor(trace);
  }

  /// Parses a string representation of a stack chain.
  ///
  /// Specifically, this parses the output of [Chain.toString].
  factory Chain.parse(String chain) =>
    new Chain(chain.split(_GAP).map((trace) => new Trace.parseFriendly(trace)));

  /// Returns a new [Chain] comprised of [traces].
  Chain(Iterable<Trace> traces)
      : traces = new UnmodifiableListView<Trace>(traces.toList());

  /// Returns a terser version of [this].
  ///
  /// This calls [Trace.terse] on every trace in [traces], and discards any
  /// trace that contain only internal frames.
  Chain get terse {
    var terseTraces = traces.map((trace) => trace.terse);
    var nonEmptyTraces = terseTraces.where((trace) {
      // Ignore traces that contain only internal processing.
      return trace.frames.length > 1;
    });

    // If all the traces contain only internal processing, preserve the last
    // (top-most) one so that the chain isn't empty.
    if (nonEmptyTraces.isEmpty && terseTraces.isNotEmpty) {
      return new Chain([terseTraces.last]);
    }

    return new Chain(nonEmptyTraces);
  }

  /// Returns a new [Chain] based on [this] where multiple stack frames matching
  /// [predicate] are folded together.
  ///
  /// This means that whenever there are multiple frames in a row that match
  /// [predicate], only the last one is kept. In addition, traces that are
  /// composed entirely of frames matching [predicate] are omitted.
  ///
  /// This is useful for limiting the amount of library code that appears in a
  /// stack trace by only showing user code and code that's called by user code.
  Chain foldFrames(bool predicate(Frame frame)) {
    var foldedTraces = traces.map((trace) => trace.foldFrames(predicate));
    var nonEmptyTraces = foldedTraces.where((trace) {
      // Ignore traces that contain only folded frames. These traces will be
      // folded into a single frame each.
      return trace.frames.length > 1;
    });

    // If all the traces contain only internal processing, preserve the last
    // (top-most) one so that the chain isn't empty.
    if (nonEmptyTraces.isEmpty && foldedTraces.isNotEmpty) {
      return new Chain([foldedTraces.last]);
    }

    return new Chain(nonEmptyTraces);
  }

  /// Converts [this] to a [Trace].
  ///
  /// The trace version of a chain is just the concatenation of all the traces
  /// in the chain.
  Trace toTrace() => new Trace(flatten(traces.map((trace) => trace.frames)));

  String toString() => traces.join(_GAP);
}
