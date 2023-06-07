// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:developer';
import 'dart:typed_data';

import 'package:meta/meta.dart';

import '_timeline_io.dart'
  if (dart.library.js_util) '_timeline_web.dart' as impl;

/// Measures how long blocks of code take to run.
///
/// This class can be used as a drop-in replacement for [Timeline] as it
/// provides methods compatible with [Timeline] signature-wise, and it has
/// minimal overhead.
///
/// Provides [reset] and [collect] methods that make it convenient to use in
/// frame-oriented environment where collected metrics can be attributed to a
/// frame, then aggregated into frame statistics, e.g. frame averages.
///
/// Forwards measurements to [Timeline] so they appear in Flutter DevTools.
abstract final class FlutterTimeline {
  static _BlockBuffer _buffer = _BlockBuffer();

  /// Whether block timings are collected and can be retrieved using the
  /// [collect] method.
  static bool get collectionEnabled => _collectionEnabled;

  /// Enables metric collection.
  ///
  /// Metric collection can only be enabled in non-release modes. It is most
  /// useful in the profile mode where application performance is representative
  /// of a deployed application.
  ///
  /// When disabled, resets collected data by calling [reset].
  ///
  /// Throws a [StateError] if invoked in release mode.
  static set collectionEnabled(bool value) {
    if (value == _collectionEnabled) {
      return;
    }
    _collectionEnabled = value;
    reset();
  }

  static bool _collectionEnabled = false;

  /// Start a synchronous operation labeled [name].
  ///
  /// Optionally takes a map of [arguments]. This slice may also optionally be
  /// associated with a [Flow] event. This operation must be finished by calling
  /// [finishSync] before returning to the event queue.
  static void startSync(String name, { Map<String, Object?>? arguments, Flow? flow }) {
    Timeline.startSync(name, arguments: arguments, flow: flow);
    if (_collectionEnabled) {
      _buffer.startSync(name, arguments: arguments, flow: flow);
    }
  }

  /// Finish the last synchronous operation that was started.
  static void finishSync() {
    Timeline.finishSync();
    if (_collectionEnabled) {
      _buffer.finishSync();
    }
  }

  /// Emit an instant event.
  static void instantSync(String name, { Map<String, Object?>? arguments }) {
    Timeline.instantSync(name, arguments: arguments);
  }

  /// A utility method to time a synchronous [function]. Internally calls
  /// [function] bracketed by calls to [startSync] and [finishSync].
  static T timeSync<T>(String name, TimelineSyncFunction<T> function,
      { Map<String, Object?>? arguments, Flow? flow }) {
    startSync(name, arguments: arguments, flow: flow);
    try {
      return function();
    } finally {
      finishSync();
    }
  }

  /// The current time stamp from the clock used by the timeline in
  /// microseconds.
  ///
  /// When run on the Dart VM, uses the same monotonic clock as the embedding
  /// API's `Dart_TimelineGetMicros`.
  ///
  /// When run on the web, uses `window.performance.now`.
  static int get now => impl.performanceTimestamp.toInt();

  /// Returns timings collected since [collectionEnabled] was set to true, or
  /// since the previous [reset], whichever was last.
  static AggregatedTimings collect() {
    if (!_collectionEnabled) {
      throw StateError('Timeline metric collection not enabled.');
    }
    return AggregatedTimings(_buffer.timings);
  }

  /// Forgets all previously collected timing data.
  ///
  /// This method can be used to break up the data by frames. To do that, call
  /// [collect] at the end of the frame, then call [reset] so that the next
  /// frame collects independent data.
  static void reset() {
    _buffer = _BlockBuffer();
  }
}

/// Provides [start], [end], and [duration] of a named block of code, timed by
/// [FlutterTimeline].
@immutable
final class TimedBlock {
  /// Creates a timed block of code from a [name], [start], and [end].
  ///
  /// The [name] should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  const TimedBlock({
    required this.name,
    required this.start,
    required this.end,
  }) : assert(end >= start, 'The start timestamp must not be greater than the end timestamp.');

  /// A readable label for a block of code that was measured.
  ///
  /// This field should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  final String name;

  /// The timestamp in microseconds that marks the beginning of the measure block
  /// of code.
  final double start;

  /// The timestamp in microseconds that marks the end of the measure block of
  /// code.
  final double end;

  /// How long the measured block of code took to execute in microseconds.
  double get duration => end - start;

  @override
  String toString() {
    return 'TimedBlock($name, $start, $end, $duration)';
  }
}

/// Provides aggregated results for timings collected by [FlutterTimeline].
@immutable
final class AggregatedTimings {
  /// Creates aggregated timings for the provided timed blocks.
  AggregatedTimings(this.timedBlocks) {
    final Map<String, (double, int)> aggregate = <String, (double, int)>{};
    for (final TimedBlock block in timedBlocks) {
      final (double, int) previousValue = aggregate.putIfAbsent(block.name, () => (0, 0));
      aggregate[block.name] = (previousValue.$1 + block.duration, previousValue.$2 + 1);
    }

    aggregatedBlocks = aggregate.entries.map<AggregatedTimedBlock>(
      (MapEntry<String, (double, int)> entry) {
        return AggregatedTimedBlock(name: entry.key, duration: entry.value.$1, count: entry.value.$2);
      }
    ).toList();
  }

  /// All timed blocks collected between the last reset and [FlutterTimeline.collect].
  final List<TimedBlock> timedBlocks;

  /// Aggregated timed blocks collected between the last reset and [FlutterTimeline.collect].
  ///
  /// Does not guarantee that all code blocks will be reported. Only those that
  /// executed since the last reset are listed here. Use [getAggregated] for
  /// graceful handling of missing code blocks.
  late final List<AggregatedTimedBlock> aggregatedBlocks;

  /// Returns aggregated numbers for a named block of code.
  ///
  /// If the block in question never executed since the last reset, returns an
  /// aggregation with zero duration and count.
  AggregatedTimedBlock getAggregated(String name) {
    return aggregatedBlocks.singleWhere(
      (AggregatedTimedBlock block) => block.name == name,
      // Handle the case where there are no recorded blocks of the specified
      // type. In this case, the aggregated duration is simply zero, and so is
      // the number of occurrences (i.e. count).
      orElse: () => AggregatedTimedBlock(name: name, duration: 0, count: 0),
    );
  }
}

/// Aggregates multiple [TimedBlock] objects that share a [name].
///
/// It is common for the same block of code to be executed multiple times within
/// a frame. It is useful to combine multiple executions and report the total
/// amount of time attributed to that block of code.
@immutable
final class AggregatedTimedBlock {
  /// Creates a timed block of code from a [name] and [duration].
  ///
  /// The [name] should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  const AggregatedTimedBlock({
    required this.name,
    required this.duration,
    required this.count,
  }) : assert(duration >= 0);

  /// A readable label for a block of code that was measured.
  ///
  /// This field should be sufficiently unique and descriptive for someone to
  /// easily tell which part of code was measured.
  final String name;

  /// The sum of [TimedBlock.duration] values of aggretaged blocks.
  final double duration;

  /// The number of [TimedBlock] objects aggregated.
  final int count;

  @override
  String toString() {
    return 'AggregatedTimedBlock($name, $duration, $count)';
  }
}

const int _kSliceSize = 500;

/// A growable list of float64 values with predictable [add] performance.
///
/// The list is organized into a "chain" of [Float64List]s. The object starts
/// with a `Float64List` "slice". When [add] is called, the value is added to
/// the slice. Once the slice is full, it is moved into the chain, and a new
/// slice is allocated. Slice size is static and therefore its allocation has
/// predictable cost. This is unlike the default [List] implementation, which,
/// when full, doubles its buffer size and copies all old elements into the new
/// buffer, leading to unpredictable performance. This makes it a poor choice
/// for recording performance because buffer reallocation would affect the
/// runtime.
///
/// The trade-off is that reading values back from the chain is more expensive
/// compared to [List] because it requires iterating over multiple slices. This
/// is a reasonable trade-off for performance metrics, because it is more
/// important to minimize the overhead while recording metrics, than it is when
/// reading them.
final class _Float64ListChain {
  _Float64ListChain();

  final List<Float64List> _chain = <Float64List>[];
  Float64List _slice = Float64List(_kSliceSize);
  int _pointer = 0;

  int get length => _length;
  int _length = 0;

  /// Adds and [element] to this chain.
  void add(double element) {
    _slice[_pointer] = element;
    _pointer += 1;
    _length += 1;
    if (_pointer >= _kSliceSize) {
      _chain.add(_slice);
      _slice = Float64List(_kSliceSize);
      _pointer = 0;
    }
  }

  /// Returns all elements added to this chain.
  ///
  /// This getter is not optimized to be fast. It is assumed that when metrics
  /// are read back, they do not affect the timings of the work being
  /// benchmarked.
  List<double> get elements {
    final List<double> result = <double>[];
    for (int i = 0; i < _pointer; i++) {
      result.add(_slice[i]);
    }
    _chain.forEach(result.addAll);
    return result;
  }
}

/// Same as [_Float64ListChain] but for recording string values.
final class _StringListChain {
  _StringListChain();

  final List<List<String?>> _chain = <List<String?>>[];
  List<String?> _slice = List<String?>.filled(_kSliceSize, null);
  int _pointer = 0;

  int get length => _length;
  int _length = 0;

  /// Adds and [element] to this chain.
  void add(String element) {
    _slice[_pointer] = element;
    _pointer += 1;
    _length += 1;
    if (_pointer >= _kSliceSize) {
      _chain.add(_slice);
      _slice = List<String?>.filled(_kSliceSize, null);
      _pointer = 0;
    }
  }

  /// Returns all elements added to this chain.
  ///
  /// This getter is not optimized to be fast. It is assumed that when metrics
  /// are read back, they do not affect the timings of the work being
  /// benchmarked.
  List<String> get elements {
    final List<String> result = <String>[];
    for (int i = 0; i < _pointer; i++) {
      result.add(_slice[i]!);
    }
    for (final List<String?> slice in _chain) {
      for (final String? element in slice) {
        result.add(element!);
      }
    }
    return result;
  }
}

/// A buffer that records starts and ends of code blocks, and their names.
final class _BlockBuffer {
  // Start-finish blocks can be nested. Track this nestedness by stacking the
  // start timestamps. Finish timestamps will pop timings from the stack and
  // add the (start, finish) tuple to the _block.
  static const int _stackDepth = 10000;
  static final Float64List _startStack = Float64List(_stackDepth);
  static final List<String?> _nameStack = List<String?>.filled(_stackDepth, null);
  static int _stackPointer = 0;

  final _Float64ListChain _starts = _Float64ListChain();
  final _Float64ListChain _finishes = _Float64ListChain();
  final _StringListChain _names = _StringListChain();

  List<TimedBlock> get timings {
    assert(
      _stackPointer == 0,
      'Invalid sequence of `startSync` and `finishSync`.\n'
      'The operation stack was not empty. The following operations are still '
      'waiting to be finished via the `finishSync` method:\n'
      '${List<String>.generate(_stackPointer, (int i) => _nameStack[i]!).join(', ')}'
    );

    final List<TimedBlock> result = <TimedBlock>[];
    final int length = _finishes.length;
    final List<double> starts = _starts.elements;
    final List<double> finishes = _finishes.elements;
    final List<String> names = _names.elements;

    assert(starts.length == length);
    assert(finishes.length == length);
    assert(names.length == length);

    for (int i = 0; i < length; i++) {
      result.add(TimedBlock(
        start: starts[i],
        end: finishes[i],
        name: names[i],
      ));
    }

    return result;
  }

  void startSync(String name, { Map<String, Object?>? arguments, Flow? flow }) {
    _startStack[_stackPointer] = impl.performanceTimestamp;
    _nameStack[_stackPointer] = name;
    _stackPointer += 1;
  }

  void finishSync() {
    assert(
      _stackPointer > 0,
      'Invalid sequence of `startSync` and `finishSync`.\n'
      'Attempted to finish timing a block of code, but there are no pending '
      '`startSync` calls.'
    );

    final double finishTime = impl.performanceTimestamp;
    final double startTime = _startStack[_stackPointer - 1];
    final String name = _nameStack[_stackPointer - 1]!;
    _stackPointer -= 1;

    _starts.add(startTime);
    _finishes.add(finishTime);
    _names.add(name);
  }
}
