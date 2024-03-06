// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'percentile_utils.dart';
import 'timeline.dart';

/// Summarizes GPU/Device Memory allocations performed by Impeller.
class GPUMemorySumarizer {
  /// Creates a RasterCacheSummarizer given the timeline events.
  GPUMemorySumarizer(List<TimelineEvent> gpuEvents) {
    for (final TimelineEvent event in gpuEvents) {
      final Object? value = event.arguments!['MemoryBudgetUsageMB'];
      if (value is String) {
        final double? parsedValue = double.tryParse(value);
        if (parsedValue != null) {
          _memoryMB.add(parsedValue);
        }
      }
    }
  }

  /// Whether or not this event is a GPU allocation event.
  static const Set<String> kMemoryEvents = <String>{'AllocatorVK'};

  final List<double> _memoryMB = <double>[];

  /// Computes the average GPU memory allocated.
  double computeAverageMemoryUsage() => _computeAverage(_memoryMB);

  /// The [percentile]-th percentile GPU memory allocated.
  double computePercentileMemoryUsage(double percentile) {
    if (_memoryMB.isEmpty) {
      return 0;
    }
    return findPercentile(_memoryMB, percentile);
  }

  /// Compute the worst allocation quantity recorded.
  double computeWorstMemoryUsage() => _computeWorst(_memoryMB);

  static double _computeAverage(List<double> values) {
    if (values.isEmpty) {
      return 0;
    }

    double total = 0;
    for (final double data in values) {
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
