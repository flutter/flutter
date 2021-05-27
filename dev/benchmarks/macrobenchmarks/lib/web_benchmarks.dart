// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:html' as html;
import 'dart:math' as math;

import 'package:macrobenchmarks/src/web/bench_text_layout.dart';
import 'package:macrobenchmarks/src/web/bench_text_out_of_picture_bounds.dart';

import 'src/web/bench_build_image.dart';
import 'src/web/bench_build_material_checkbox.dart';
import 'src/web/bench_card_infinite_scroll.dart';
import 'src/web/bench_child_layers.dart';
import 'src/web/bench_clipped_out_pictures.dart';
import 'src/web/bench_default_target_platform.dart';
import 'src/web/bench_draw_rect.dart';
import 'src/web/bench_dynamic_clip_on_static_picture.dart';
import 'src/web/bench_mouse_region_grid_hover.dart';
import 'src/web/bench_mouse_region_grid_scroll.dart';
import 'src/web/bench_mouse_region_mixed_grid_hover.dart';
import 'src/web/bench_pageview_scroll_linethrough.dart';
import 'src/web/bench_paths.dart';
import 'src/web/bench_picture_recording.dart';
import 'src/web/bench_simple_lazy_text_scroll.dart';
import 'src/web/bench_text_out_of_picture_bounds.dart';
import 'src/web/bench_wrapbox_scroll.dart';
import 'src/web/recorder.dart';

typedef RecorderFactory = Recorder Function();

const bool isCanvasKit = bool.fromEnvironment('FLUTTER_WEB_USE_SKIA', defaultValue: false);

/// List of all benchmarks that run in the devicelab.
///
/// When adding a new benchmark, add it to this map. Make sure that the name
/// of your benchmark is unique.
final Map<String, RecorderFactory> benchmarks = <String, RecorderFactory>{
  BenchDefaultTargetPlatform.benchmarkName: () => BenchDefaultTargetPlatform(),
  BenchBuildImage.benchmarkName: () => BenchBuildImage(),
  BenchCardInfiniteScroll.benchmarkName: () => BenchCardInfiniteScroll.forward(),
  BenchCardInfiniteScroll.benchmarkNameBackward: () => BenchCardInfiniteScroll.backward(),
  BenchClippedOutPictures.benchmarkName: () => BenchClippedOutPictures(),
  BenchDrawRect.benchmarkName: () => BenchDrawRect.staticPaint(),
  BenchDrawRect.variablePaintBenchmarkName: () => BenchDrawRect.variablePaint(),
  BenchPathRecording.benchmarkName: () => BenchPathRecording(),
  BenchTextOutOfPictureBounds.benchmarkName: () => BenchTextOutOfPictureBounds(),
  BenchSimpleLazyTextScroll.benchmarkName: () => BenchSimpleLazyTextScroll(),
  BenchBuildMaterialCheckbox.benchmarkName: () => BenchBuildMaterialCheckbox(),
  BenchDynamicClipOnStaticPicture.benchmarkName: () => BenchDynamicClipOnStaticPicture(),
  BenchPageViewScrollLineThrough.benchmarkName: () => BenchPageViewScrollLineThrough(),
  BenchPictureRecording.benchmarkName: () => BenchPictureRecording(),
  BenchUpdateManyChildLayers.benchmarkName: () => BenchUpdateManyChildLayers(),
  BenchMouseRegionGridScroll.benchmarkName: () => BenchMouseRegionGridScroll(),
  BenchMouseRegionGridHover.benchmarkName: () => BenchMouseRegionGridHover(),
  BenchMouseRegionMixedGridHover.benchmarkName: () => BenchMouseRegionMixedGridHover(),
  BenchWrapBoxScroll.benchmarkName: () => BenchWrapBoxScroll(),
  if (isCanvasKit)
    BenchBuildColorsGrid.canvasKitBenchmarkName: () => BenchBuildColorsGrid.canvasKit(),

  // Benchmarks that we don't want to run using CanvasKit.
  if (!isCanvasKit) ...<String, RecorderFactory>{
    BenchTextLayout.domBenchmarkName: () => BenchTextLayout(useCanvas: false),
    BenchTextLayout.canvasBenchmarkName: () => BenchTextLayout(useCanvas: true),
    BenchTextCachedLayout.domBenchmarkName: () => BenchTextCachedLayout(useCanvas: false),
    BenchTextCachedLayout.canvasBenchmarkName: () => BenchTextCachedLayout(useCanvas: true),
    BenchBuildColorsGrid.domBenchmarkName: () => BenchBuildColorsGrid.dom(),
    BenchBuildColorsGrid.canvasBenchmarkName: () => BenchBuildColorsGrid.canvas(),
  },
};

final LocalBenchmarkServerClient _client = LocalBenchmarkServerClient();

Future<void> main() async {
  // Check if the benchmark server wants us to run a specific benchmark.
  final String nextBenchmark = await _client.requestNextBenchmark();

  if (nextBenchmark == LocalBenchmarkServerClient.kManualFallback) {
    _fallbackToManual('The server did not tell us which benchmark to run next.');
    return;
  }

  await _runBenchmark(nextBenchmark);
  html.window.location.reload();
}

Future<void> _runBenchmark(String benchmarkName) async {
  final RecorderFactory recorderFactory = benchmarks[benchmarkName];

  if (recorderFactory == null) {
    _fallbackToManual('Benchmark $benchmarkName not found.');
    return;
  }

  await runZoned<Future<void>>(
    () async {
      final Recorder recorder = recorderFactory();
      final Runner runner = recorder.isTracingEnabled && !_client.isInManualMode
          ? Runner(
              recorder: recorder,
              setUpAllDidRun: () => _client.startPerformanceTracing(benchmarkName),
              tearDownAllWillRun: _client.stopPerformanceTracing,
            )
          : Runner(recorder: recorder);

      final Profile profile = await runner.run();
      if (!_client.isInManualMode) {
        await _client.sendProfileData(profile);
      } else {
        _printResultsToScreen(profile);
        print(profile);
      }
    },
    zoneSpecification: ZoneSpecification(
      print: (Zone self, ZoneDelegate parent, Zone zone, String line) async {
        if (_client.isInManualMode) {
          parent.print(zone, '[$benchmarkName] $line');
        } else {
          await _client.printToConsole(line);
        }
      },
      handleUncaughtError: (
        Zone self,
        ZoneDelegate parent,
        Zone zone, Object error,
        StackTrace stackTrace,
      ) async {
        if (_client.isInManualMode) {
          parent.print(zone, '[$benchmarkName] $error, $stackTrace');
          parent.handleUncaughtError(zone, error, stackTrace);
        } else {
          await _client.reportError(error, stackTrace);
        }
      },
    ),
  );
}

void _fallbackToManual(String error) {
  html.document.body.appendHtml('''
    <div id="manual-panel">
      <h3>$error</h3>

      <p>Choose one of the following benchmarks:</p>

      <!-- Absolutely position it so it receives the clicks and not the glasspane -->
      <ul style="position: absolute">
        ${
          benchmarks.keys
            .map((String name) => '<li><button id="$name">$name</button></li>')
            .join('\n')
        }
      </ul>
    </div>
  ''', validator: html.NodeValidatorBuilder()..allowHtml5()..allowInlineStyles());

  for (final String benchmarkName in benchmarks.keys) {
    final html.Element button = html.document.querySelector('#$benchmarkName');
    button.addEventListener('click', (_) {
      final html.Element manualPanel = html.document.querySelector('#manual-panel');
      manualPanel?.remove();
      _runBenchmark(benchmarkName);
    });
  }
}

/// Visualizes results on the Web page for manual inspection.
void _printResultsToScreen(Profile profile) {
  html.document.body.remove();
  html.document.body = html.BodyElement();
  html.document.body.appendHtml('<h2>${profile.name}</h2>');

  profile.scoreData.forEach((String scoreKey, Timeseries timeseries) {
    html.document.body.appendHtml('<h2>$scoreKey</h2>');
    html.document.body.appendHtml('<pre>${timeseries.computeStats()}</pre>');
    html.document.body.append(TimeseriesVisualization(timeseries).render());
  });
}

/// Draws timeseries data and statistics on a canvas.
class TimeseriesVisualization {
  TimeseriesVisualization(this._timeseries) {
    _stats = _timeseries.computeStats();
    _canvas = html.CanvasElement();
    _screenWidth = html.window.screen.width;
    _canvas.width = _screenWidth;
    _canvas.height = (_kCanvasHeight * html.window.devicePixelRatio).round();
    _canvas.style
      ..width = '100%'
      ..height = '${_kCanvasHeight}px'
      ..outline = '1px solid green';
    _ctx = _canvas.context2D;

    // The amount of vertical space available on the chart. Because some
    // outliers can be huge they can dwarf all the useful values. So we
    // limit it to 1.5 x the biggest non-outlier.
    _maxValueChartRange = 1.5 * _stats.samples
      .where((AnnotatedSample sample) => !sample.isOutlier)
      .map<double>((AnnotatedSample sample) => sample.magnitude)
      .fold<double>(0, math.max);
  }

  static const double _kCanvasHeight = 200;

  final Timeseries _timeseries;
  TimeseriesStats _stats;
  html.CanvasElement _canvas;
  html.CanvasRenderingContext2D _ctx;
  int _screenWidth;

  // Used to normalize benchmark values to chart height.
  double _maxValueChartRange;

  /// Converts a sample value to vertical canvas coordinates.
  ///
  /// This does not work for horizontal coordinates.
  double _normalized(double value) {
    return _kCanvasHeight * value / _maxValueChartRange;
  }

  /// A utility for drawing lines.
  void drawLine(num x1, num y1, num x2, num y2) {
    _ctx.beginPath();
    _ctx.moveTo(x1, y1);
    _ctx.lineTo(x2, y2);
    _ctx.stroke();
  }

  /// Renders the timeseries into a `<canvas>` and returns the canvas element.
  html.CanvasElement render() {
    _ctx.translate(0, _kCanvasHeight * html.window.devicePixelRatio);
    _ctx.scale(1, -html.window.devicePixelRatio);

    final double barWidth = _screenWidth / _stats.samples.length;
    double xOffset = 0;
    for (int i = 0; i < _stats.samples.length; i++) {
      final AnnotatedSample sample = _stats.samples[i];

      if (sample.isWarmUpValue) {
        // Put gray background behing warm-up samples.
        _ctx.fillStyle = 'rgba(200,200,200,1)';
        _ctx.fillRect(xOffset, 0, barWidth, _normalized(_maxValueChartRange));
      }

      if (sample.magnitude > _maxValueChartRange) {
        // The sample value is so big it doesn't fit on the chart. Paint it purple.
        _ctx.fillStyle = 'rgba(100,50,100,0.8)';
      } else if (sample.isOutlier) {
        // The sample is an outlier, color it light red.
        _ctx.fillStyle = 'rgba(255,50,50,0.6)';
      } else {
        // A non-outlier sample, color it light blue.
        _ctx.fillStyle = 'rgba(50,50,255,0.6)';
      }

      _ctx.fillRect(xOffset, 0, barWidth - 1, _normalized(sample.magnitude));
      xOffset += barWidth;
    }

    // Draw a horizontal solid line corresponding to the average.
    _ctx.lineWidth = 1;
    drawLine(0, _normalized(_stats.average), _screenWidth, _normalized(_stats.average));

    // Draw a horizontal dashed line corresponding to the outlier cut off.
    _ctx.setLineDash(<num>[5, 5]);
    drawLine(0, _normalized(_stats.outlierCutOff), _screenWidth, _normalized(_stats.outlierCutOff));

    // Draw a light red band that shows the noise (1 stddev in each direction).
    _ctx.fillStyle = 'rgba(255,50,50,0.3)';
    _ctx.fillRect(
      0,
      _normalized(_stats.average * (1 - _stats.noise)),
      _screenWidth,
      _normalized(2 * _stats.average * _stats.noise),
    );

    return _canvas;
  }
}

/// Implements the client REST API for the local benchmark server.
///
/// The local server is optional. If it is not available the benchmark UI must
/// implement a manual fallback. This allows debugging benchmarks using plain
/// `flutter run`.
class LocalBenchmarkServerClient {
  /// This value is returned by [requestNextBenchmark].
  static const String kManualFallback = '__manual_fallback__';

  /// Whether we fell back to manual mode.
  ///
  /// This happens when you run benchmarks using plain `flutter run` rather than
  /// devicelab test harness. The test harness spins up a special server that
  /// provides API for automatically picking the next benchmark to run.
  bool isInManualMode;

  /// Asks the local server for the name of the next benchmark to run.
  ///
  /// Returns [kManualFallback] if local server is not available (uses 404 as a
  /// signal).
  Future<String> requestNextBenchmark() async {
    final html.HttpRequest request = await _requestXhr(
      '/next-benchmark',
      method: 'POST',
      mimeType: 'application/json',
      sendData: json.encode(benchmarks.keys.toList()),
    );

    // 404 is expected in the following cases:
    // - The benchmark is ran using plain `flutter run`, which does not provide "next-benchmark" handler.
    // - We ran all benchmarks and the benchmark is telling us there are no more benchmarks to run.
    if (request.status == 404) {
      isInManualMode = true;
      return kManualFallback;
    }

    isInManualMode = false;
    return request.responseText;
  }

  void _checkNotManualMode() {
    if (isInManualMode) {
      throw StateError('Operation not supported in manual fallback mode.');
    }
  }

  /// Asks the local server to begin tracing performance.
  ///
  /// This uses the chrome://tracing tracer, which is not available from within
  /// the page itself, and therefore must be controlled from outside using the
  /// DevTools Protocol.
  Future<void> startPerformanceTracing(String benchmarkName) async {
    _checkNotManualMode();
    await html.HttpRequest.request(
      '/start-performance-tracing?label=$benchmarkName',
      method: 'POST',
      mimeType: 'application/json',
    );
  }

  /// Stops the performance tracing session started by [startPerformanceTracing].
  Future<void> stopPerformanceTracing() async {
    _checkNotManualMode();
    await html.HttpRequest.request(
      '/stop-performance-tracing',
      method: 'POST',
      mimeType: 'application/json',
    );
  }

  /// Sends the profile data collected by the benchmark to the local benchmark
  /// server.
  Future<void> sendProfileData(Profile profile) async {
    _checkNotManualMode();
    final html.HttpRequest request = await html.HttpRequest.request(
      '/profile-data',
      method: 'POST',
      mimeType: 'application/json',
      sendData: json.encode(profile.toJson()),
    );
    if (request.status != 200) {
      throw Exception(
        'Failed to report profile data to benchmark server. '
        'The server responded with status code ${request.status}.'
      );
    }
  }

  /// Reports an error to the benchmark server.
  ///
  /// The server will halt the devicelab task and log the error.
  Future<void> reportError(dynamic error, StackTrace stackTrace) async {
    _checkNotManualMode();
    await html.HttpRequest.request(
      '/on-error',
      method: 'POST',
      mimeType: 'application/json',
      sendData: json.encode(<String, dynamic>{
        'error': '$error',
        'stackTrace': '$stackTrace',
      }),
    );
  }

  /// Reports a message about the demo to the benchmark server.
  Future<void> printToConsole(String report) async {
    _checkNotManualMode();
    await html.HttpRequest.request(
      '/print-to-console',
      method: 'POST',
      mimeType: 'text/plain',
      sendData: report,
    );
  }

  /// This is the same as calling [html.HttpRequest.request] but it doesn't
  /// crash on 404, which we use to detect `flutter run`.
  Future<html.HttpRequest> _requestXhr(
    String url, {
    String method,
    bool withCredentials,
    String responseType,
    String mimeType,
    Map<String, String> requestHeaders,
    dynamic sendData,
  }) {
    final Completer<html.HttpRequest> completer = Completer<html.HttpRequest>();
    final html.HttpRequest xhr = html.HttpRequest();

    method ??= 'GET';
    xhr.open(method, url, async: true);

    if (withCredentials != null) {
      xhr.withCredentials = withCredentials;
    }

    if (responseType != null) {
      xhr.responseType = responseType;
    }

    if (mimeType != null) {
      xhr.overrideMimeType(mimeType);
    }

    if (requestHeaders != null) {
      requestHeaders.forEach((String header, String value) {
        xhr.setRequestHeader(header, value);
      });
    }

    xhr.onLoad.listen((html.ProgressEvent e) {
      completer.complete(xhr);
    });

    xhr.onError.listen(completer.completeError);

    if (sendData != null) {
      xhr.send(sendData);
    } else {
      xhr.send();
    }

    return completer.future;
  }
}
