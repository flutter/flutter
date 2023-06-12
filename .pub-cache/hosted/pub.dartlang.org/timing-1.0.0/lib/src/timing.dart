// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:json_annotation/json_annotation.dart';

import 'clock.dart';

part 'timing.g.dart';

/// The timings of an operation, including its [startTime], [stopTime], and
/// [duration].
@JsonSerializable()
class TimeSlice {
  /// The total duration of this operation, equivalent to taking the difference
  /// between [stopTime] and [startTime].
  Duration get duration => stopTime.difference(startTime);

  final DateTime startTime;

  final DateTime stopTime;

  TimeSlice(this.startTime, this.stopTime);

  factory TimeSlice.fromJson(Map<String, dynamic> json) =>
      _$TimeSliceFromJson(json);

  Map<String, dynamic> toJson() => _$TimeSliceToJson(this);

  @override
  String toString() => '($startTime + $duration)';
}

/// The timings of an async operation, consist of several sync [slices] and
/// includes total [startTime], [stopTime], and [duration].
@JsonSerializable()
class TimeSliceGroup implements TimeSlice {
  final List<TimeSlice> slices;

  @override
  DateTime get startTime => slices.first.startTime;

  @override
  DateTime get stopTime => slices.last.stopTime;

  /// The total duration of this operation, equivalent to taking the difference
  /// between [stopTime] and [startTime].
  @override
  Duration get duration => stopTime.difference(startTime);

  /// Sum of [duration]s of all [slices].
  ///
  /// If some of slices implements [TimeSliceGroup] [innerDuration] will be used
  /// to compute sum.
  Duration get innerDuration => slices.fold(
      Duration.zero,
      (duration, slice) =>
          duration +
          (slice is TimeSliceGroup ? slice.innerDuration : slice.duration));

  TimeSliceGroup(this.slices);

  /// Constructs TimeSliceGroup from JSON representation
  factory TimeSliceGroup.fromJson(Map<String, dynamic> json) =>
      _$TimeSliceGroupFromJson(json);

  @override
  Map<String, dynamic> toJson() => _$TimeSliceGroupToJson(this);

  @override
  String toString() => slices.toString();
}

abstract class TimeTracker implements TimeSlice {
  /// Whether tracking is active.
  ///
  /// Tracking is only active after `isStarted` and before `isFinished`.
  bool get isTracking;

  /// Whether tracking is finished.
  ///
  /// Tracker can't be used as [TimeSlice] before it is finished
  bool get isFinished;

  /// Whether tracking was started.
  ///
  /// Equivalent of `isTracking || isFinished`
  bool get isStarted;

  T track<T>(T Function() action);
}

/// Tracks only sync actions
class SyncTimeTracker implements TimeTracker {
  /// When this operation started, call [_start] to set this.
  @override
  DateTime get startTime => _startTime!;
  DateTime? _startTime;

  /// When this operation stopped, call [_stop] to set this.
  @override
  DateTime get stopTime => _stopTime!;
  DateTime? _stopTime;

  /// Start tracking this operation, must only be called once, before [_stop].
  void _start() {
    assert(_startTime == null && _stopTime == null);
    _startTime = now();
  }

  /// Stop tracking this operation, must only be called once, after [_start].
  void _stop() {
    assert(_startTime != null && _stopTime == null);
    _stopTime = now();
  }

  /// Splits tracker into two slices
  ///
  /// Returns new [TimeSlice] started on [startTime] and ended now.
  /// Modifies [startTime] of tracker to current time point
  ///
  /// Don't change state of tracker. Can be called only while [isTracking], and
  /// tracker will sill be tracking after call.
  TimeSlice _split() {
    if (!isTracking) {
      throw StateError('Can be only called while tracking');
    }
    final _now = now();
    final prevSlice = TimeSlice(_startTime!, _now);
    _startTime = _now;
    return prevSlice;
  }

  @override
  T track<T>(T Function() action) {
    if (isStarted) {
      throw StateError('Can not be tracked twice');
    }
    _start();
    try {
      return action();
    } finally {
      _stop();
    }
  }

  @override
  bool get isStarted => _startTime != null;

  @override
  bool get isTracking => _startTime != null && _stopTime == null;

  @override
  bool get isFinished => _startTime != null && _stopTime != null;

  @override
  Duration get duration => _stopTime!.difference(_startTime!);

  /// Converts to JSON representation
  ///
  /// Can't be used before [isFinished]
  @override
  Map<String, dynamic> toJson() => _$TimeSliceToJson(this);
}

/// Async actions returning [Future] will be tracked as single sync time span
/// from the beginning of execution till completion of future
class SimpleAsyncTimeTracker extends SyncTimeTracker {
  @override
  T track<T>(T Function() action) {
    if (isStarted) {
      throw StateError('Can not be tracked twice');
    }
    T result;
    _start();
    try {
      result = action();
    } catch (_) {
      _stop();
      rethrow;
    }
    if (result is Future) {
      return result.whenComplete(_stop) as T;
    } else {
      _stop();
      return result;
    }
  }
}

/// No-op implementation of [SyncTimeTracker] that does nothing.
class NoOpTimeTracker implements TimeTracker {
  static final sharedInstance = NoOpTimeTracker();

  @override
  Duration get duration =>
      throw UnsupportedError('Unsupported in no-op implementation');

  @override
  DateTime get startTime =>
      throw UnsupportedError('Unsupported in no-op implementation');

  @override
  DateTime get stopTime =>
      throw UnsupportedError('Unsupported in no-op implementation');

  @override
  bool get isStarted =>
      throw UnsupportedError('Unsupported in no-op implementation');

  @override
  bool get isTracking =>
      throw UnsupportedError('Unsupported in no-op implementation');

  @override
  bool get isFinished =>
      throw UnsupportedError('Unsupported in no-op implementation');

  @override
  T track<T>(T Function() action) => action();

  @override
  Map<String, dynamic> toJson() =>
      throw UnsupportedError('Unsupported in no-op implementation');
}

/// Track all async execution as disjoint time [slices] in ascending order.
///
/// Can [track] both async and sync actions.
/// Can exclude time of tested trackers.
///
/// If tracked action spawns some dangled async executions behavior is't
/// defined. Tracked might or might not track time of such executions
class AsyncTimeTracker extends TimeSliceGroup implements TimeTracker {
  final bool trackNested;

  static const _zoneKey = #timing_AsyncTimeTracker;

  AsyncTimeTracker({this.trackNested = true}) : super([]);

  T _trackSyncSlice<T>(ZoneDelegate parent, Zone zone, T Function() action) {
    // Ignore dangling runs after tracker completes
    if (isFinished) {
      return action();
    }

    final isNestedRun = slices.isNotEmpty &&
        slices.last is SyncTimeTracker &&
        (slices.last as SyncTimeTracker).isTracking;
    final isExcludedNestedTrack = !trackNested && zone[_zoneKey] != this;

    // Exclude nested sync tracks
    if (isNestedRun && isExcludedNestedTrack) {
      final timer = slices.last as SyncTimeTracker;
      // Split already tracked time into new slice.
      // Replace tracker in slices.last with splitted slice, to indicate for
      // recursive calls that we not tracking.
      slices.last = parent.run(zone, timer._split);
      try {
        return action();
      } finally {
        // Split tracker again and discard slice that was spend in nested tracker
        parent.run(zone, timer._split);
        // Add tracker back to list of slices and continue tracking
        slices.add(timer);
      }
    }

    // Exclude nested async tracks
    if (isExcludedNestedTrack) {
      return action();
    }

    // Split time slices in nested sync runs
    if (isNestedRun) {
      return action();
    }

    final timer = SyncTimeTracker();
    slices.add(timer);

    // Pass to parent zone, in case of overwritten clock
    return parent.runUnary(zone, timer.track, action);
  }

  static final asyncTimeTrackerZoneSpecification = ZoneSpecification(
    run: <R>(Zone self, ZoneDelegate parent, Zone zone, R Function() f) {
      final tracker = self[_zoneKey] as AsyncTimeTracker;
      return tracker._trackSyncSlice(parent, zone, () => parent.run(zone, f));
    },
    runUnary: <R, T>(Zone self, ZoneDelegate parent, Zone zone, R Function(T) f,
        T arg) {
      final tracker = self[_zoneKey] as AsyncTimeTracker;
      return tracker._trackSyncSlice(
          parent, zone, () => parent.runUnary(zone, f, arg));
    },
    runBinary: <R, T1, T2>(Zone self, ZoneDelegate parent, Zone zone,
        R Function(T1, T2) f, T1 arg1, T2 arg2) {
      final tracker = self[_zoneKey] as AsyncTimeTracker;
      return tracker._trackSyncSlice(
          parent, zone, () => parent.runBinary(zone, f, arg1, arg2));
    },
  );

  @override
  T track<T>(T Function() action) {
    if (isStarted) {
      throw StateError('Can not be tracked twice');
    }
    _tracking = true;
    final result = runZoned(action,
        zoneSpecification: asyncTimeTrackerZoneSpecification,
        zoneValues: {_zoneKey: this});
    if (result is Future) {
      return result
          // Break possible sync processing of future completion, so slice trackers can be finished
          .whenComplete(() => Future.value())
          .whenComplete(() => _tracking = false) as T;
    } else {
      _tracking = false;
      return result;
    }
  }

  bool? _tracking;

  @override
  bool get isStarted => _tracking != null;

  @override
  bool get isFinished => _tracking == false;

  @override
  bool get isTracking => _tracking == true;
}
