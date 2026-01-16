// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'percentile_utils.dart';
import 'timeline.dart';

/// Summarizes [GpuSumarizer]s corresponding to GPU start and end events.
class GpuSumarizer {
  /// Creates a RasterCacheSummarizer given the timeline events.
  GpuSumarizer(List<TimelineEvent> gpuEvents) {
    for (final event in gpuEvents) {
      final Object? value = event.arguments!['FrameTimeMS'];
      if (value is String) {
        final double? parsedValue = double.tryParse(value);
        if (parsedValue != null) {
          _frameTimes.add(parsedValue);
        }
      }
    }
  }

  /// Whether or not this event is a GPU event.
  static const Set<String> kGpuEvents = <String>{'GPUTracer'};

  final List<double> _frameTimes = <double>[];

  /// Computes the average GPU time recorded.
  double computeAverageGPUTime() => _computeAverage(_frameTimes);

  /// The [percentile]-th percentile GPU time recorded.
  double computePercentileGPUTime(double percentile) {
    if (_frameTimes.isEmpty) {
      return 0;
    }
    return findPercentile(_frameTimes, percentile);
  }

  /// Compute the worst GPU time recorded.
  double computeWorstGPUTime() => _computeWorst(_frameTimes);

  static double _computeAverage(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    double total = 0;
    for (final data in values) {
      total += data;
    }
    return total / values.length;
  }

  static double _computeWorst(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    values.sort();
    return values.last;
  }
}
