// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json, JsonEncoder;
import 'dart:math' as math;

import 'package:file/file.dart';
import 'package:path/path.dart' as path;

import 'common.dart';
import 'percentile_utils.dart';
import 'profiling_summarizer.dart';
import 'raster_cache_summarizer.dart';
import 'scene_display_lag_summarizer.dart';
import 'timeline.dart';
import 'vsync_frame_lag_summarizer.dart';

const JsonEncoder _prettyEncoder = JsonEncoder.withIndent('  ');

/// The maximum amount of time considered safe to spend for a frame's build
/// phase. Anything past that is in the danger of missing the frame as 60FPS.
const Duration kBuildBudget = Duration(milliseconds: 16);

/// The name of the framework frame build events we need to filter or extract.
const String kBuildFrameEventName = 'Frame';

/// The name of the engine frame rasterization events we need to filter or extract.
const String kRasterizeFrameEventName = 'GPURasterizer::Draw';

/// Extracts statistics from a [Timeline].
class TimelineSummary {
  /// Creates a timeline summary given a full timeline object.
  TimelineSummary.summarize(this._timeline);

  final Timeline _timeline;

  /// Average amount of time spent per frame in the framework building widgets,
  /// updating layout, painting and compositing.
  ///
  /// Returns null if no frames were recorded.
  double computeAverageFrameBuildTimeMillis() {
    return _averageInMillis(_extractFrameDurations());
  }

  /// The [p]-th percentile frame rasterization time in milliseconds.
  ///
  /// Returns null if no frames were recorded.
  double computePercentileFrameBuildTimeMillis(double p) {
    return _percentileInMillis(_extractFrameDurations(), p);
  }

  /// The longest frame build time in milliseconds.
  ///
  /// Returns null if no frames were recorded.
  double computeWorstFrameBuildTimeMillis() {
    return _maxInMillis(_extractFrameDurations());
  }

  /// The number of frames that missed the [kBuildBudget] and therefore are
  /// in the danger of missing frames.
  int computeMissedFrameBuildBudgetCount([ Duration frameBuildBudget = kBuildBudget ]) => _extractFrameDurations()
    .where((Duration duration) => duration > kBuildBudget)
    .length;

  /// Average amount of time spent per frame in the engine rasterizer.
  ///
  /// Returns null if no frames were recorded.
  double computeAverageFrameRasterizerTimeMillis() {
    return _averageInMillis(_extractGpuRasterizerDrawDurations());
  }

  /// The longest frame rasterization time in milliseconds.
  ///
  /// Returns null if no frames were recorded.
  double computeWorstFrameRasterizerTimeMillis() {
    return _maxInMillis(_extractGpuRasterizerDrawDurations());
  }

  /// The [p]-th percentile frame rasterization time in milliseconds.
  ///
  /// Returns null if no frames were recorded.
  double computePercentileFrameRasterizerTimeMillis(double p) {
    return _percentileInMillis(_extractGpuRasterizerDrawDurations(), p);
  }

  /// The number of frames that missed the [kBuildBudget] on the raster thread
  /// and therefore are in the danger of missing frames.
  int computeMissedFrameRasterizerBudgetCount([ Duration frameBuildBudget = kBuildBudget ]) => _extractGpuRasterizerDrawDurations()
      .where((Duration duration) => duration > kBuildBudget)
      .length;

  /// The total number of frames recorded in the timeline.
  int countFrames() => _extractFrameDurations().length;

  /// The total number of rasterizer cycles recorded in the timeline.
  int countRasterizations() => _extractGpuRasterizerDrawDurations().length;

  /// The total number of old generation garbage collections recorded in the timeline.
  int oldGenerationGarbageCollections() {
    return _timeline.events!.where((TimelineEvent event) {
      return event.category == 'GC' && event.name == 'CollectOldGeneration';
    }).length;
  }

  /// The total number of new generation garbage collections recorded in the timeline.
  int newGenerationGarbageCollections() {
    return _timeline.events!.where((TimelineEvent event) {
      return event.category == 'GC' && event.name == 'CollectNewGeneration';
    }).length;
  }

  /// Encodes this summary as JSON.
  ///
  /// Data ends with "_time_millis" means time in milliseconds and numbers in
  /// the "frame_build_times", "frame_rasterizer_times", "frame_begin_times" and
  /// "frame_rasterizer_begin_times" lists are in microseconds.
  ///
  /// * "average_frame_build_time_millis": Average amount of time spent per
  ///   frame in the framework building widgets, updating layout, painting and
  ///   compositing.
  ///   See [computeAverageFrameBuildTimeMillis].
  /// * "90th_percentile_frame_build_time_millis" and
  ///   "99th_percentile_frame_build_time_millis": The p-th percentile frame
  ///   rasterization time in milliseconds. 90 and 99-th percentile number is
  ///   usually a better metric to estimate worse cases. See discussion in
  ///   https://github.com/flutter/flutter/pull/19121#issuecomment-419520765
  ///   See [computePercentileFrameBuildTimeMillis].
  /// * "worst_frame_build_time_millis": The longest frame build time.
  ///   See [computeWorstFrameBuildTimeMillis].
  /// * "missed_frame_build_budget_count': The number of frames that missed
  ///   the [kBuildBudget] and therefore are in the danger of missing frames.
  ///   See [computeMissedFrameBuildBudgetCount].
  /// * "average_frame_rasterizer_time_millis": Average amount of time spent
  ///   per frame in the engine rasterizer.
  ///   See [computeAverageFrameRasterizerTimeMillis].
  /// * "90th_percentile_frame_rasterizer_time_millis" and
  ///   "99th_percentile_frame_rasterizer_time_millis": The 90/99-th percentile
  ///   frame rasterization time in milliseconds.
  ///   See [computePercentileFrameRasterizerTimeMillis].
  /// * "worst_frame_rasterizer_time_millis": The longest frame rasterization
  ///   time.
  ///   See [computeWorstFrameRasterizerTimeMillis].
  /// * "missed_frame_rasterizer_budget_count": The number of frames that missed
  ///   the [kBuildBudget] on the raster thread and therefore are in the danger
  ///   of missing frames.
  ///   See [computeMissedFrameRasterizerBudgetCount].
  /// * "frame_count": The total number of frames recorded in the timeline. This
  ///   is also the length of the "frame_build_times" and the "frame_begin_times"
  ///   lists.
  ///   See [countFrames].
  /// * "frame_rasterizer_count": The total number of rasterizer cycles recorded
  ///   in the timeline. This is also the length of the "frame_rasterizer_times"
  ///   and the "frame_rasterizer_begin_times" lists.
  ///   See [countRasterizations].
  /// * "frame_build_times": The build time of each frame, by tracking the
  ///   [TimelineEvent] with name [kBuildFrameEventName].
  /// * "frame_rasterizer_times": The rasterize time of each frame, by tracking
  ///   the [TimelineEvent] with name [kRasterizeFrameEventName]
  /// * "frame_begin_times": The build begin timestamp of each frame.
  /// * "frame_rasterizer_begin_times": The rasterize begin time of each frame.
  /// * "average_vsync_transitions_missed": Computes the average of the
  ///   `vsync_transitions_missed` over the lag events.
  ///   See [SceneDisplayLagSummarizer.computeAverageVsyncTransitionsMissed].
  /// * "90th_percentile_vsync_transitions_missed" and
  ///   "99th_percentile_vsync_transitions_missed": The 90/99-th percentile
  ///   `vsync_transitions_missed` over the lag events.
  ///   See [SceneDisplayLagSummarizer.computePercentileVsyncTransitionsMissed].
  /// * "average_vsync_frame_lag": Computes the average of the time between
  ///   platform vsync signal and the engine frame process start time.
  ///   See [VsyncFrameLagSummarizer.computeAverageVsyncFrameLag].
  /// * "90th_percentile_vsync_frame_lag" and "99th_percentile_vsync_frame_lag":
  ///   The 90/99-th percentile delay between platform vsync signal and engine
  ///   frame process start time.
  ///   See [VsyncFrameLagSummarizer.computePercentileVsyncFrameLag].
  /// * "average_layer_cache_count": The average of the values seen for the
  ///   count of the engine layer cache entries.
  ///   See [RasterCacheSummarizer.computeAverageLayerCount].
  /// * "90th_percentile_layer_cache_count" and
  ///   "99th_percentile_layer_cache_count": The 90/99-th percentile values seen
  ///   for the count of the engine layer cache entries.
  ///   See [RasterCacheSummarizer.computePercentileLayerCount].
  /// * "worst_layer_cache_count": The worst (highest) value seen for the
  ///   count of the engine layer cache entries.
  ///   See [RasterCacheSummarizer.computeWorstLayerCount].
  /// * "average_layer_cache_memory": The average of the values seen for the
  ///   memory used for the engine layer cache entries, in megabytes.
  ///   See [RasterCacheSummarizer.computeAverageLayerMemory].
  /// * "90th_percentile_layer_cache_memory" and
  ///   "99th_percentile_layer_cache_memory": The 90/99-th percentile values seen
  ///   for the memory used for the engine layer cache entries.
  ///   See [RasterCacheSummarizer.computePercentileLayerMemory].
  /// * "worst_layer_cache_memory": The worst (highest) value seen for the
  ///   memory used for the engine layer cache entries.
  ///   See [RasterCacheSummarizer.computeWorstLayerMemory].
  /// * "average_picture_cache_count": The average of the values seen for the
  ///   count of the engine picture cache entries.
  ///   See [RasterCacheSummarizer.computeAveragePictureCount].
  /// * "90th_percentile_picture_cache_count" and
  ///   "99th_percentile_picture_cache_count": The 90/99-th percentile values seen
  ///   for the count of the engine picture cache entries.
  ///   See [RasterCacheSummarizer.computePercentilePictureCount].
  /// * "worst_picture_cache_count": The worst (highest) value seen for the
  ///   count of the engine picture cache entries.
  ///   See [RasterCacheSummarizer.computeWorstPictureCount].
  /// * "average_picture_cache_memory": The average of the values seen for the
  ///   memory used for the engine picture cache entries, in megabytes.
  ///   See [RasterCacheSummarizer.computeAveragePictureMemory].
  /// * "90th_percentile_picture_cache_memory" and
  ///   "99th_percentile_picture_cache_memory": The 90/99-th percentile values seen
  ///   for the memory used for the engine picture cache entries.
  ///   See [RasterCacheSummarizer.computePercentilePictureMemory].
  /// * "worst_picture_cache_memory": The worst (highest) value seen for the
  ///   memory used for the engine picture cache entries.
  ///   See [RasterCacheSummarizer.computeWorstPictureMemory].
  Map<String, dynamic> get summaryJson {
    final SceneDisplayLagSummarizer sceneDisplayLagSummarizer = _sceneDisplayLagSummarizer();
    final VsyncFrameLagSummarizer vsyncFrameLagSummarizer = _vsyncFrameLagSummarizer();
    final Map<String, dynamic> profilingSummary = _profilingSummarizer().summarize();
    final RasterCacheSummarizer rasterCacheSummarizer = _rasterCacheSummarizer();

    final Map<String, dynamic> timelineSummary = <String, dynamic>{
      'average_frame_build_time_millis': computeAverageFrameBuildTimeMillis(),
      '90th_percentile_frame_build_time_millis': computePercentileFrameBuildTimeMillis(90.0),
      '99th_percentile_frame_build_time_millis': computePercentileFrameBuildTimeMillis(99.0),
      'worst_frame_build_time_millis': computeWorstFrameBuildTimeMillis(),
      'missed_frame_build_budget_count': computeMissedFrameBuildBudgetCount(),
      'average_frame_rasterizer_time_millis': computeAverageFrameRasterizerTimeMillis(),
      '90th_percentile_frame_rasterizer_time_millis': computePercentileFrameRasterizerTimeMillis(90.0),
      '99th_percentile_frame_rasterizer_time_millis': computePercentileFrameRasterizerTimeMillis(99.0),
      'worst_frame_rasterizer_time_millis': computeWorstFrameRasterizerTimeMillis(),
      'missed_frame_rasterizer_budget_count': computeMissedFrameRasterizerBudgetCount(),
      'frame_count': countFrames(),
      'frame_rasterizer_count': countRasterizations(),
      'new_gen_gc_count': newGenerationGarbageCollections(),
      'old_gen_gc_count': oldGenerationGarbageCollections(),
      'frame_build_times': _extractFrameDurations()
          .map<int>((Duration duration) => duration.inMicroseconds)
          .toList(),
      'frame_rasterizer_times': _extractGpuRasterizerDrawDurations()
          .map<int>((Duration duration) => duration.inMicroseconds)
          .toList(),
      'frame_begin_times': _extractBeginTimestamps(kBuildFrameEventName)
          .map<int>((Duration duration) => duration.inMicroseconds)
          .toList(),
      'frame_rasterizer_begin_times': _extractBeginTimestamps(kRasterizeFrameEventName)
          .map<int>((Duration duration) => duration.inMicroseconds)
          .toList(),
      'average_vsync_transitions_missed': sceneDisplayLagSummarizer.computeAverageVsyncTransitionsMissed(),
      '90th_percentile_vsync_transitions_missed': sceneDisplayLagSummarizer.computePercentileVsyncTransitionsMissed(90.0),
      '99th_percentile_vsync_transitions_missed': sceneDisplayLagSummarizer.computePercentileVsyncTransitionsMissed(99.0),
      'average_vsync_frame_lag': vsyncFrameLagSummarizer.computeAverageVsyncFrameLag(),
      '90th_percentile_vsync_frame_lag': vsyncFrameLagSummarizer.computePercentileVsyncFrameLag(90.0),
      '99th_percentile_vsync_frame_lag': vsyncFrameLagSummarizer.computePercentileVsyncFrameLag(99.0),
      'average_layer_cache_count': rasterCacheSummarizer.computeAverageLayerCount(),
      '90th_percentile_layer_cache_count': rasterCacheSummarizer.computePercentileLayerCount(90.0),
      '99th_percentile_layer_cache_count': rasterCacheSummarizer.computePercentileLayerCount(99.0),
      'worst_layer_cache_count': rasterCacheSummarizer.computeWorstLayerCount(),
      'average_layer_cache_memory': rasterCacheSummarizer.computeAverageLayerMemory(),
      '90th_percentile_layer_cache_memory': rasterCacheSummarizer.computePercentileLayerMemory(90.0),
      '99th_percentile_layer_cache_memory': rasterCacheSummarizer.computePercentileLayerMemory(99.0),
      'worst_layer_cache_memory': rasterCacheSummarizer.computeWorstLayerMemory(),
      'average_picture_cache_count': rasterCacheSummarizer.computeAveragePictureCount(),
      '90th_percentile_picture_cache_count': rasterCacheSummarizer.computePercentilePictureCount(90.0),
      '99th_percentile_picture_cache_count': rasterCacheSummarizer.computePercentilePictureCount(99.0),
      'worst_picture_cache_count': rasterCacheSummarizer.computeWorstPictureCount(),
      'average_picture_cache_memory': rasterCacheSummarizer.computeAveragePictureMemory(),
      '90th_percentile_picture_cache_memory': rasterCacheSummarizer.computePercentilePictureMemory(90.0),
      '99th_percentile_picture_cache_memory': rasterCacheSummarizer.computePercentilePictureMemory(99.0),
      'worst_picture_cache_memory': rasterCacheSummarizer.computeWorstPictureMemory(),
    };

    timelineSummary.addAll(profilingSummary);
    return timelineSummary;
  }

  /// Writes all of the recorded timeline data to a file.
  ///
  /// By default, this will dump [summaryJson] to a companion file named
  /// `$traceName.timeline_summary.json`. If you want to skip the summary, set
  /// the `includeSummary` parameter to false.
  ///
  /// See also:
  ///
  /// * [Timeline.fromJson], which explains detail about the timeline data.
  Future<void> writeTimelineToFile(
    String traceName, {
    String? destinationDirectory,
    bool pretty = false,
    bool includeSummary = true,
  }) async {
    destinationDirectory ??= testOutputsDirectory;
    await fs.directory(destinationDirectory).create(recursive: true);
    final File file = fs.file(path.join(destinationDirectory, '$traceName.timeline.json'));
    await file.writeAsString(_encodeJson(_timeline.json, pretty));

    if (includeSummary) {
      await _writeSummaryToFile(traceName, destinationDirectory: destinationDirectory, pretty: pretty);
    }
  }

  /// Writes [summaryJson] to a file.
  @Deprecated(
    'Use TimelineSummary.writeTimelineToFile. '
    'This feature was deprecated after v2.1.0-13.0.pre.'
  )
  Future<void> writeSummaryToFile(
    String traceName, {
    String? destinationDirectory,
    bool pretty = false,
  }) async {
    destinationDirectory ??= testOutputsDirectory;
    await _writeSummaryToFile(traceName, destinationDirectory: destinationDirectory, pretty: pretty);
  }

  Future<void> _writeSummaryToFile(
    String traceName, {
    required String destinationDirectory,
    bool pretty = false,
  }) async {
    await fs.directory(destinationDirectory).create(recursive: true);
    final File file = fs.file(path.join(destinationDirectory, '$traceName.timeline_summary.json'));
    await file.writeAsString(_encodeJson(summaryJson, pretty));
  }

  String _encodeJson(Map<String, dynamic> jsonObject, bool pretty) {
    return pretty
      ? _prettyEncoder.convert(jsonObject)
      : json.encode(jsonObject);
  }

  List<TimelineEvent> _extractNamedEvents(String name) {
    return _timeline.events!
      .where((TimelineEvent event) => event.name == name)
      .toList();
  }

  List<TimelineEvent> _extractEventsWithNames(Set<String> names) {
    return _timeline.events!
      .where((TimelineEvent event) => names.contains(event.name))
      .toList();
  }

  List<Duration> _extractDurations(
    String name,
    Duration Function(TimelineEvent beginEvent, TimelineEvent endEvent) extractor,
  ) {
    final List<Duration> result = <Duration>[];
    final List<TimelineEvent> events = _extractNamedEvents(name);

    // Timeline does not guarantee that the first event is the "begin" event.
    TimelineEvent? begin;
    for (final TimelineEvent event in events) {
      if (event.phase == 'B' || event.phase == 'b') {
        begin = event;
      } else {
        if (begin != null) {
          result.add(extractor(begin, event));
          // each begin only gets used once.
          begin = null;
        }
      }
    }

    return result;
  }

  /// Extracts Duration list that are reported as a pair of begin/end events.
  ///
  /// Extracts Duration of events by looking for events with the name and phase
  /// begin ("ph": "B"). This routine assumes that the next event with the same
  /// name is phase end ("ph": "E"), but it's not examined.
  /// "SceneDisplayLag" event is an exception, with phase ("ph") labeled
  /// 'b' and 'e', meaning begin and end phase for an async event.
  /// See [SceneDisplayLagSummarizer].
  /// See: https://docs.google.com/document/d/1CvAClvFfyA5R-PhYUmn5OOQtYMH4h6I0nSsKchNAySU
  List<Duration> _extractBeginEndEvents(String name) {
    return _extractDurations(
      name,
      (TimelineEvent beginEvent, TimelineEvent endEvent) {
        return Duration(microseconds: endEvent.timestampMicros! - beginEvent.timestampMicros!);
      },
    );
  }

  List<Duration> _extractBeginTimestamps(String name) {
    final List<Duration> result = _extractDurations(
      name,
      (TimelineEvent beginEvent, TimelineEvent endEvent) {
        return Duration(microseconds: beginEvent.timestampMicros!);
      },
    );

    // Align timestamps so the first event is at 0.
    for (int i = result.length - 1; i >= 0; i -= 1) {
      result[i] = result[i] - result[0];
    }
    return result;
  }

  double _averageInMillis(Iterable<Duration> durations) {
    if (durations.isEmpty)
      throw ArgumentError('durations is empty!');
    final double total = durations.fold<double>(0.0, (double t, Duration duration) => t + duration.inMicroseconds.toDouble() / 1000.0);
    return total / durations.length;
  }

  double _percentileInMillis(Iterable<Duration> durations, double percentile) {
    if (durations.isEmpty)
      throw ArgumentError('durations is empty!');
    assert(percentile >= 0.0 && percentile <= 100.0);
    final List<double> doubles = durations.map<double>((Duration duration) => duration.inMicroseconds.toDouble() / 1000.0).toList();
    return findPercentile(doubles, percentile);
  }

  double _maxInMillis(Iterable<Duration> durations) {
    if (durations.isEmpty)
      throw ArgumentError('durations is empty!');
    return durations
        .map<double>((Duration duration) => duration.inMicroseconds.toDouble() / 1000.0)
        .reduce(math.max);
  }

  SceneDisplayLagSummarizer _sceneDisplayLagSummarizer() => SceneDisplayLagSummarizer(_extractNamedEvents(kSceneDisplayLagEvent));

  List<Duration> _extractGpuRasterizerDrawDurations() => _extractBeginEndEvents(kRasterizeFrameEventName);

  ProfilingSummarizer _profilingSummarizer() => ProfilingSummarizer.fromEvents(_extractEventsWithNames(kProfilingEvents));

  List<Duration> _extractFrameDurations() => _extractBeginEndEvents(kBuildFrameEventName);

  VsyncFrameLagSummarizer _vsyncFrameLagSummarizer() => VsyncFrameLagSummarizer(_extractEventsWithNames(kVsyncTimelineEventNames));

  RasterCacheSummarizer _rasterCacheSummarizer() => RasterCacheSummarizer(_extractNamedEvents(kRasterCacheEvent));
}
