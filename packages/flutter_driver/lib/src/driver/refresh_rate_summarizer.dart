// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'timeline.dart';

/// Event name for refresh rate related timeline events.
const String kUIThreadVsyncProcessEvent = 'VsyncProcessCallback';

/// A summary of [TimelineEvents]s corresponding to `kUIThreadVsyncProcessEvent` events.
///
/// `RefreshRate` is the time between the start of a vsync pulse and the target time of that vsync.
class RefreshRateSummary {

  /// Creates a [RefreshRateSummary] given the timeline events.
  factory RefreshRateSummary({required List<TimelineEvent> vsyncEvents}) {
    return RefreshRateSummary._(refreshRates: _computeRefreshRates(vsyncEvents));
  }

  RefreshRateSummary._({required List<double> refreshRates}) {
    _numberOfTotalFrames = refreshRates.length;
    for (final double refreshRate in refreshRates) {
      if ((refreshRate - 30).abs() < _kErrorMargin) {
        _numberOf30HzFrames++;
        continue;
      }
      if ((refreshRate - 60).abs() < _kErrorMargin) {
        _numberOf60HzFrames++;
        continue;
      }
      if ((refreshRate - 90).abs() < _kErrorMargin) {
        _numberOf90HzFrames++;
        continue;
      }
      if ((refreshRate - 120).abs() < _kErrorMargin) {
        _numberOf120HzFrames++;
        continue;
      }
      _framesWithIllegalRefreshRate.add(refreshRate);
    }
    assert(_numberOfTotalFrames ==
        _numberOf30HzFrames +
            _numberOf60HzFrames +
            _numberOf90HzFrames +
            _numberOf120HzFrames +
            _framesWithIllegalRefreshRate.length);
  }

  static const double _kErrorMargin = 6.0;

  /// Number of frames with 30hz refresh rate
  int get numberOf30HzFrames => _numberOf30HzFrames;

  /// Number of frames with 60hz refresh rate
  int get numberOf60HzFrames => _numberOf60HzFrames;

  /// Number of frames with 90hz refresh rate
  int get numberOf90HzFrames => _numberOf90HzFrames;

  /// Number of frames with 120hz refresh rate
  int get numberOf120HzFrames => _numberOf120HzFrames;

  /// The percentage of 30hz frames.
  ///
  /// For example, if this value is 20, it means there are 20 percent of total
  /// frames are 30hz. 0 means no frames are 30hz, 100 means all frames are 30hz.
  double get percentageOf30HzFrames => _numberOfTotalFrames > 0
      ? _numberOf30HzFrames / _numberOfTotalFrames * 100
      : 0;

  /// The percentage of 60hz frames.
  ///
  /// For example, if this value is 20, it means there are 20 percent of total
  /// frames are 60hz. 0 means no frames are 60hz, 100 means all frames are 60hz.
  double get percentageOf60HzFrames => _numberOfTotalFrames > 0
      ? _numberOf60HzFrames / _numberOfTotalFrames * 100
      : 0;

  /// The percentage of 90hz frames.
  ///
  /// For example, if this value is 20, it means there are 20 percent of total
  /// frames are 90hz. 0 means no frames are 90hz, 100 means all frames are 90hz.
  double get percentageOf90HzFrames => _numberOfTotalFrames > 0
      ? _numberOf90HzFrames / _numberOfTotalFrames * 100
      : 0;

  /// The percentage of 90hz frames.
  ///
  /// For example, if this value is 20, it means there are 20 percent of total
  /// frames are 120hz. 0 means no frames are 120hz, 100 means all frames are 120hz.
  double get percentageOf120HzFrames => _numberOfTotalFrames > 0
      ? _numberOf120HzFrames / _numberOfTotalFrames * 100
      : 0;

  /// A list of all the frames with Illegal refresh rate.
  ///
  /// A refresh rate is consider illegal if it does not belong to anyone below:
  /// 30hz, 60hz, 90hz or 120hz.
  List<double> get framesWithIllegalRefreshRate =>
      _framesWithIllegalRefreshRate;

  int _numberOf30HzFrames = 0;
  int _numberOf60HzFrames = 0;
  int _numberOf90HzFrames = 0;
  int _numberOf120HzFrames = 0;
  int _numberOfTotalFrames = 0;

  final List<double> _framesWithIllegalRefreshRate = <double>[];

  static List<double> _computeRefreshRates(List<TimelineEvent> vsyncEvents) {
    final List<double> result = <double>[];
    for (int i = 0; i < vsyncEvents.length; i++) {
      final TimelineEvent event = vsyncEvents[i];
      if (event.phase != 'B') {
        continue;
      }
      assert(event.name == kUIThreadVsyncProcessEvent);
      assert(event.arguments != null);
      final Map<String, dynamic> arguments = event.arguments!;
      const double nanosecondsPerSecond = 1e+9;
      final int startTimeInNanoseconds = int.parse(arguments['StartTime'] as String);
      final int targetTimeInNanoseconds = int.parse(arguments['TargetTime'] as String);
      final int frameDurationInNanoseconds = targetTimeInNanoseconds - startTimeInNanoseconds;
      final double refreshRate = nanosecondsPerSecond /
          frameDurationInNanoseconds;
      result.add(refreshRate);
    }
    return result;
  }
}
