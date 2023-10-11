// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'percentile_utils.dart';
import 'timeline.dart';

class _StartAndEnd {
  const _StartAndEnd(this.start, this.end);

  final TimelineEvent start;
  final TimelineEvent end;

  Duration get duration => Duration(microseconds: end.timestampMicros! - start.timestampMicros!);
}

/// Summarizes [TimelineEvents]s corresponding to GPU start and end events.
class GpuSumarizer {
  /// Creates a RasterCacheSummarizer given the timeline events.
  GpuSumarizer(List<TimelineEvent> gpuEvents) {
    TimelineEvent? start;
    for (final TimelineEvent event in gpuEvents) {
      if (event.name == 'GPUStart') {
        start = event;
      } else if (event.name == 'GPUEnd') {
        if (start != null) {
          _gpuEvents.add(_StartAndEnd(start, event));
          start = null;
        }
      }
    }
  }

  /// Whether or not this event is a GPU event.
  static const Set<String> kGpuEvents = <String>{'GPUStart', 'GPUEnd'};

  final List<_StartAndEnd> _gpuEvents = <_StartAndEnd>[];

  /// Computes the average GPU time recorded.
  double computeAverageGPUTime() => _computeAverage(_gpuEvents);

  /// The [percentile]-th percentile GPU time recorded.
  double computePercentileGPUTime(double percentile) => _computePercentile(_gpuEvents, percentile);

  /// Compute the worst GPU time recorded.
  double computeWorstGPUTime() => _computeWorst(_gpuEvents);

  static double _computeAverage(List<_StartAndEnd> values) {
    if (values.isEmpty) {
      return -1;
    }

    Duration total = Duration.zero;
    for (final _StartAndEnd data in values) {
      total += data.duration;
    }
    return total.inMilliseconds / values.length;
  }

  static double _computePercentile(List<_StartAndEnd> values, double percentile) {
    if (values.isEmpty) {
      return 0;
    }

    final List<double> durationValues = [
      for (final _StartAndEnd data in values)
        data.duration.inMilliseconds.toDouble()
    ];
    return findPercentile(durationValues, percentile);
  }

  static double _computeWorst(List<_StartAndEnd> values) {
    if (values.isEmpty) {
      return 0;
    }

    values.sort((_StartAndEnd a, _StartAndEnd b) => a.duration.compareTo(b.duration));
    return values.last.duration.inMilliseconds.toDouble();
  }
}
