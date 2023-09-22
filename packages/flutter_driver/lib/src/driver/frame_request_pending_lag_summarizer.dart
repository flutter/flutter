// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'percentile_utils.dart';
import 'timeline.dart';

/// Event name for frame request pending timeline events.
const String kFrameRequestPendingEvent = 'Frame Request Pending';

/// Summarizes [TimelineEvents]s corresponding to [kFrameRequestPendingEvent] events.
///
/// `FrameRequestPendingLag` is the time between when a new frame is requested
/// to when the frame starts getting built by the Flutter Engine.
class FrameRequestPendingLagSummarizer {
  /// Creates a FrameRequestPendingLagSummarizer given the timeline events.
  FrameRequestPendingLagSummarizer(this.frameRequestPendingEvents);

  /// Timeline events with names in [kFrameRequestPendingTimelineEventNames].
  final List<TimelineEvent> frameRequestPendingEvents;

  /// Computes the average `FrameRequestPendingLag` over the period of the timeline.
  double computeAverageFrameRequestPendingLag() {
    final List<double> frameRequestPendingLags =
        _computeFrameRequestPendingLags();
    if (frameRequestPendingLags.isEmpty) {
      return 0;
    }

    final double total = frameRequestPendingLags.reduce((double a, double b) => a + b);
    return total / frameRequestPendingLags.length;
  }

  /// Computes the [percentile]-th percentile `FrameRequestPendingLag` over the
  /// period of the timeline.
  double computePercentileFrameRequestPendingLag(double percentile) {
    final List<double> frameRequestPendingLags =
        _computeFrameRequestPendingLags();
    if (frameRequestPendingLags.isEmpty) {
      return 0;
    }
    return findPercentile(frameRequestPendingLags, percentile);
  }

  List<double> _computeFrameRequestPendingLags() {
    final List<double> result = <double>[];
		final Map<String, int> starts = <String, int>{};
    for (int i = 0; i < frameRequestPendingEvents.length; i++) {
      final TimelineEvent event = frameRequestPendingEvents[i];
      if (event.phase == 'b') {
				final String? id = event.json['id'] as String?;
				if (id != null) {
					starts[id] = event.timestampMicros!;
				}
      }
			else if (event.phase == 'e') {
				final int? start = starts[event.json['id']];
				if (start != null) {
					result.add((event.timestampMicros! - start).toDouble());
				}
			}
    }
    return result;
  }
}
