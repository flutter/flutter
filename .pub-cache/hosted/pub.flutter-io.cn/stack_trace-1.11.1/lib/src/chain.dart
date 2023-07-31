// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'frame.dart';
import 'lazy_chain.dart';
import 'stack_zone_specification.dart';
import 'trace.dart';
import 'utils.dart';

/// A function that handles errors in the zone wrapped by [Chain.capture].
@Deprecated('Will be removed in stack_trace 2.0.0.')
typedef ChainHandler = void Function(dynamic error, Chain chain);

/// An opaque key used to track the current [StackZoneSpecification].
final _specKey = Object();

/// A chain of stack traces.
///
/// A stack chain is a collection of one or more stack traces that collectively
/// represent the path from `main` through nested function calls to a particular
/// code location, usually where an error was thrown. Multiple stack traces are
/// necessary when using asynchronous functions, since the program's stack is
/// reset before each asynchronous callback is run.
///
/// Stack chains can be automatically tracked using [Chain.capture]. This sets
/// up a new [Zone] in which the current stack chain is tracked and can be
/// accessed using [Chain.current]. Any errors that would be top-leveled in
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
  /// The stack traces that make up this chain.
  ///
  /// Like the frames in a stack trace, the traces are ordered from most local
  /// to least local. The first one is the trace where the actual exception was
  /// raised, the second one is where that callback was scheduled, and so on.
  final List<Trace> traces;

  /// The [StackZoneSpecification] for the current zone.
  static StackZoneSpecification? get _currentSpec =>
      Zone.current[_specKey] as StackZoneSpecification?;

  /// If [when] is `true`, runs [callback] in a [Zone] in which the current
  /// stack chain is tracked and automatically associated with (most) errors.
  ///
  /// If [when] is `false`, this does not track stack chains. Instead, it's
  /// identical to [runZoned], except that it wraps any errors in
  /// [Chain.forTrace]—which will only wrap the trace unless there's a different
  /// [Chain.capture] active. This makes it easy for the caller to only capture
  /// stack chains in debug mode or during development.
  ///
  /// If [onError] is passed, any error in the zone that would otherwise go
  /// unhandled is passed to it, along with the [Chain] associated with that
  /// error. Note that if [callback] produces multiple unhandled errors,
  /// [onError] may be called more than once. If [onError] isn't passed, the
  /// parent Zone's `unhandledErrorHandler` will be called with the error and
  /// its chain.
  ///
  /// The zone this creates will be an error zone if either [onError] is
  /// not `null` and [when] is false,
  /// or if both [when] and [errorZone] are `true`.
  ///  If [errorZone] is `false`, [onError] must be `null`.
  ///
  /// If [callback] returns a value, it will be returned by [capture] as well.
  ///
  /// [zoneValues] is added to the [runZoned] calls.
  static T capture<T>(T Function() callback,
      {void Function(Object error, Chain)? onError,
      bool when = true,
      bool errorZone = true,
      Map<Object?, Object?>? zoneValues}) {
    if (!errorZone && onError != null) {
      throw ArgumentError.value(
          onError, 'onError', 'must be null if errorZone is false');
    }

    if (!when) {
      if (onError == null) return runZoned(callback, zoneValues: zoneValues);
      return runZonedGuarded(callback, (error, stackTrace) {
        onError(error, Chain.forTrace(stackTrace));
      }, zoneValues: zoneValues) as T;
    }

    var spec = StackZoneSpecification(onError, errorZone: errorZone);
    return runZoned(() {
      try {
        return callback();
      } on Object catch (error, stackTrace) {
        // Forward synchronous errors through the async error path to match the
        // behavior of `runZonedGuarded`.
        Zone.current.handleUncaughtError(error, stackTrace);

        // If the expected return type of capture() is not nullable, this will
        // throw a cast exception. But the only other alternative is to throw
        // some other exception. Casting null to T at least lets existing uses
        // where T is a nullable type continue to work.
        return null as T;
      }
    }, zoneSpecification: spec.toSpec(), zoneValues: {
      ...?zoneValues,
      _specKey: spec,
      StackZoneSpecification.disableKey: false
    });
  }

  /// If [when] is `true` and this is called within a [Chain.capture] zone, runs
  /// [callback] in a [Zone] in which chain capturing is disabled.
  ///
  /// If [callback] returns a value, it will be returned by [disable] as well.
  static T disable<T>(T Function() callback, {bool when = true}) {
    var zoneValues =
        when ? {_specKey: null, StackZoneSpecification.disableKey: true} : null;

    return runZoned(callback, zoneValues: zoneValues);
  }

  /// Returns [futureOrStream] unmodified.
  ///
  /// Prior to Dart 1.7, this was necessary to ensure that stack traces for
  /// exceptions reported with [Completer.completeError] and
  /// [StreamController.addError] were tracked correctly.
  @Deprecated('Chain.track is not necessary in Dart 1.7+.')
  static dynamic track(Object? futureOrStream) => futureOrStream;

  /// Returns the current stack chain.
  ///
  /// By default, the first frame of the first trace will be the line where
  /// [Chain.current] is called. If [level] is passed, the first trace will
  /// start that many frames up instead.
  ///
  /// If this is called outside of a [capture] zone, it just returns a
  /// single-trace chain.
  factory Chain.current([int level = 0]) {
    if (_currentSpec != null) return _currentSpec!.currentChain(level + 1);

    var chain = Chain.forTrace(StackTrace.current);
    return LazyChain(() {
      // JS includes a frame for the call to StackTrace.current, but the VM
      // doesn't, so we skip an extra frame in a JS context.
      var first = Trace(chain.traces.first.frames.skip(level + (inJS ? 2 : 1)),
          original: chain.traces.first.original.toString());
      return Chain([first, ...chain.traces.skip(1)]);
    });
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
    if (_currentSpec != null) return _currentSpec!.chainFor(trace);
    if (trace is Trace) return Chain([trace]);
    return LazyChain(() => Chain.parse(trace.toString()));
  }

  /// Parses a string representation of a stack chain.
  ///
  /// If [chain] is the output of a call to [Chain.toString], it will be parsed
  /// as a full stack chain. Otherwise, it will be parsed as in [Trace.parse]
  /// and returned as a single-trace chain.
  factory Chain.parse(String chain) {
    if (chain.isEmpty) return Chain([]);
    if (chain.contains(vmChainGap)) {
      return Chain(chain
          .split(vmChainGap)
          .where((line) => line.isNotEmpty)
          .map(Trace.parseVM));
    }
    if (!chain.contains(chainGap)) return Chain([Trace.parse(chain)]);

    return Chain(chain.split(chainGap).map(Trace.parseFriendly));
  }

  /// Returns a new [Chain] comprised of [traces].
  Chain(Iterable<Trace> traces) : traces = List<Trace>.unmodifiable(traces);

  /// Returns a terser version of this chain.
  ///
  /// This calls [Trace.terse] on every trace in [traces], and discards any
  /// trace that contain only internal frames.
  ///
  /// This won't do anything with a raw JavaScript trace, since there's no way
  /// to determine which frames come from which Dart libraries. However, the
  /// [`source_map_stack_trace`](https://pub.dev/packages/source_map_stack_trace)
  /// package can be used to convert JavaScript traces into Dart-style traces.
  Chain get terse => foldFrames((_) => false, terse: true);

  /// Returns a new [Chain] based on this chain where multiple stack frames
  /// matching [predicate] are folded together.
  ///
  /// This means that whenever there are multiple frames in a row that match
  /// [predicate], only the last one is kept. In addition, traces that are
  /// composed entirely of frames matching [predicate] are omitted.
  ///
  /// This is useful for limiting the amount of library code that appears in a
  /// stack trace by only showing user code and code that's called by user code.
  ///
  /// If [terse] is true, this will also fold together frames from the core
  /// library or from this package, and simplify core library frames as in
  /// [Trace.terse].
  Chain foldFrames(bool Function(Frame) predicate, {bool terse = false}) {
    var foldedTraces =
        traces.map((trace) => trace.foldFrames(predicate, terse: terse));
    var nonEmptyTraces = foldedTraces.where((trace) {
      // Ignore traces that contain only folded frames.
      if (trace.frames.length > 1) return true;
      if (trace.frames.isEmpty) return false;

      // In terse mode, the trace may have removed an outer folded frame,
      // leaving a single non-folded frame. We can detect a folded frame because
      // it has no line information.
      if (!terse) return false;
      return trace.frames.single.line != null;
    });

    // If all the traces contain only internal processing, preserve the last
    // (top-most) one so that the chain isn't empty.
    if (nonEmptyTraces.isEmpty && foldedTraces.isNotEmpty) {
      return Chain([foldedTraces.last]);
    }

    return Chain(nonEmptyTraces);
  }

  /// Converts this chain to a [Trace].
  ///
  /// The trace version of a chain is just the concatenation of all the traces
  /// in the chain.
  Trace toTrace() => Trace(traces.expand((trace) => trace.frames));

  @override
  String toString() {
    // Figure out the longest path so we know how much to pad.
    var longest = traces
        .map((trace) => trace.frames
            .map((frame) => frame.location.length)
            .fold(0, math.max))
        .fold(0, math.max);

    // Don't call out to [Trace.toString] here because that doesn't ensure that
    // padding is consistent across all traces.
    return traces
        .map((trace) => trace.frames
            .map((frame) =>
                '${frame.location.padRight(longest)}  ${frame.member}\n')
            .join())
        .join(chainGap);
  }
}
