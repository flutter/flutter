// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show LineSplitter, json, utf8;
import 'dart:io';
import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/host_agent.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

/// Must match flutter_driver/lib/src/common.dart.
///
/// Redefined here to avoid taking a dependency on flutter_driver.
String _testOutputDirectory(String testDirectory) {
  return Platform.environment['FLUTTER_TEST_OUTPUTS_DIR'] ?? '$testDirectory/build';
}

TaskFunction createComplexLayoutScrollPerfTest({
  bool measureCpuGpu = true,
  bool badScroll = false,
  bool enableImpeller = false,
}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    badScroll
      ? 'test_driver/scroll_perf_bad.dart'
      : 'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
    measureCpuGpu: measureCpuGpu,
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createTilesScrollPerfTest({bool enableImpeller = false}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'tiles_scroll_perf',
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createUiKitViewScrollPerfTest({bool enableImpeller = false}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/platform_views_layout',
    'test_driver/uikit_view_scroll_perf.dart',
    'platform_views_scroll_perf',
    testDriver: 'test_driver/scroll_perf_test.dart',
    needsFullTimeline: false,
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createAndroidTextureScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/platform_views_layout',
    'test_driver/android_view_scroll_perf.dart',
    'platform_views_scroll_perf',
    testDriver: 'test_driver/scroll_perf_test.dart',
  ).run;
}

TaskFunction createAndroidViewScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/platform_views_layout_hybrid_composition',
    'test_driver/android_view_scroll_perf.dart',
    'platform_views_scroll_perf_hybrid_composition',
    testDriver: 'test_driver/scroll_perf_test.dart',
  ).run;
}

TaskFunction createHomeScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
    'test_driver/scroll_perf.dart',
    'home_scroll_perf',
  ).run;
}

TaskFunction createCullOpacityPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'cull_opacity_perf',
    testDriver: 'test_driver/cull_opacity_perf_test.dart',
  ).run;
}

TaskFunction createCullOpacityPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/cull_opacity_perf_e2e.dart',
  ).run;
}

TaskFunction createCubicBezierPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'cubic_bezier_perf',
    testDriver: 'test_driver/cubic_bezier_perf_test.dart',
  ).run;
}

TaskFunction createCubicBezierPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/cubic_bezier_perf_e2e.dart',
  ).run;
}

TaskFunction createFlutterGalleryTransitionsPerfSkSLWarmupTest() {
  return PerfTestWithSkSL(
    '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
    'test_driver/transitions_perf.dart',
    'transitions',
  ).run;
}

TaskFunction createBackdropFilterPerfTest({
    bool measureCpuGpu = true,
    bool enableImpeller = false,
}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'backdrop_filter_perf',
    measureCpuGpu: measureCpuGpu,
    testDriver: 'test_driver/backdrop_filter_perf_test.dart',
    saveTraceFile: true,
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createAnimationWithMicrotasksPerfTest({bool measureCpuGpu = true}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'animation_with_microtasks_perf',
    measureCpuGpu: measureCpuGpu,
    testDriver: 'test_driver/animation_with_microtasks_perf_test.dart',
    saveTraceFile: true,
  ).run;
}

TaskFunction createBackdropFilterPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/backdrop_filter_perf_e2e.dart',
  ).run;
}

TaskFunction createPostBackdropFilterPerfTest({bool measureCpuGpu = true}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'post_backdrop_filter_perf',
    measureCpuGpu: measureCpuGpu,
    testDriver: 'test_driver/post_backdrop_filter_perf_test.dart',
    saveTraceFile: true,
  ).run;
}

TaskFunction createSimpleAnimationPerfTest({
  bool measureCpuGpu = true,
  bool enableImpeller = false,
}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'simple_animation_perf',
    measureCpuGpu: measureCpuGpu,
    testDriver: 'test_driver/simple_animation_perf_test.dart',
    saveTraceFile: true,
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createAnimatedPlaceholderPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/animated_placeholder_perf_e2e.dart',
  ).run;
}

TaskFunction createPictureCachePerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'picture_cache_perf',
    testDriver: 'test_driver/picture_cache_perf_test.dart',
  ).run;
}

TaskFunction createPictureCachePerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/picture_cache_perf_e2e.dart',
  ).run;
}

TaskFunction createPictureCacheComplexityScoringPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'picture_cache_complexity_scoring_perf',
    testDriver: 'test_driver/picture_cache_complexity_scoring_perf_test.dart',
  ).run;
}

TaskFunction createOpenPayScrollPerfTest({bool measureCpuGpu = true}) {
  return PerfTest(
    openpayDirectory.path,
    'test_driver/scroll_perf.dart',
    'openpay_scroll_perf',
    measureCpuGpu: measureCpuGpu,
    testDriver: 'test_driver/scroll_perf_test.dart',
    saveTraceFile: true,
  ).run;
}

TaskFunction createFlutterGalleryStartupTest({String target = 'lib/main.dart'}) {
  return StartupTest(
    '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
    target: target,
  ).run;
}

TaskFunction createComplexLayoutStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
  ).run;
}

TaskFunction createFlutterGalleryCompileTest() {
  return CompileTest('${flutterDirectory.path}/dev/integration_tests/flutter_gallery').run;
}

TaskFunction createHelloWorldCompileTest() {
  return CompileTest('${flutterDirectory.path}/examples/hello_world', reportPackageContentSizes: true).run;
}

TaskFunction createWebCompileTest() {
  return const WebCompileTest().run;
}

TaskFunction createComplexLayoutCompileTest() {
  return CompileTest('${flutterDirectory.path}/dev/benchmarks/complex_layout').run;
}

TaskFunction createFlutterViewStartupTest() {
  return StartupTest(
      '${flutterDirectory.path}/examples/flutter_view',
      reportMetrics: false,
  ).run;
}

TaskFunction createPlatformViewStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/examples/platform_view',
    reportMetrics: false,
  ).run;
}

TaskFunction createBasicMaterialCompileTest() {
  return () async {
    const String sampleAppName = 'sample_flutter_app';
    final Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    rmTree(sampleDir);

    await inDirectory<void>(Directory.systemTemp, () async {
      await flutter('create', options: <String>['--template=app', sampleAppName]);
    });

    if (!sampleDir.existsSync()) {
      throw 'Failed to create default Flutter app in ${sampleDir.path}';
    }

    return CompileTest(sampleDir.path).run();
  };
}

TaskFunction createTextfieldPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'textfield_perf',
    testDriver: 'test_driver/textfield_perf_test.dart',
  ).run;
}

TaskFunction createTextfieldPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/textfield_perf_e2e.dart',
  ).run;
}

TaskFunction createStackSizeTest() {
  final String testDirectory =
      '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks';
  const String testTarget = 'test_driver/run_app.dart';
  const String testDriver = 'test_driver/stack_size_perf_test.dart';
  return () {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      await flutter('drive', options: <String>[
        '--no-android-gradle-daemon',
        '-v',
        '--verbose-system-logs',
        '--profile',
        '-t', testTarget,
        '--driver', testDriver,
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = json.decode(
        file('${_testOutputDirectory(testDirectory)}/stack_size.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final Map<String, dynamic> result = <String, dynamic>{
        'stack_size_per_nesting_level': data['stack_size'],
      };
      return TaskResult.success(
        result,
        benchmarkScoreKeys: result.keys.toList(),
      );
    });
  };
}

TaskFunction createFullscreenTextfieldPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'fullscreen_textfield_perf',
    testDriver: 'test_driver/fullscreen_textfield_perf_test.dart',
  ).run;
}

TaskFunction createFullscreenTextfieldPerfE2ETest({
  bool enableImpeller = false,
}) {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/fullscreen_textfield_perf_e2e.dart',
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createClipperCachePerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/clipper_cache_perf_e2e.dart',
  ).run;
}

TaskFunction createColorFilterAndFadePerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'color_filter_and_fade_perf',
    testDriver: 'test_driver/color_filter_and_fade_perf_test.dart',
    saveTraceFile: true,
  ).run;
}

TaskFunction createColorFilterAndFadePerfE2ETest({bool enableImpeller = false}) {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/color_filter_and_fade_perf_e2e.dart',
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createColorFilterCachePerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/color_filter_cache_perf_e2e.dart',
  ).run;
}

TaskFunction createColorFilterWithUnstableChildPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/color_filter_with_unstable_child_perf_e2e.dart',
  ).run;
}

TaskFunction createRasterCacheUseMemoryPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/raster_cache_use_memory_perf_e2e.dart',
  ).run;
}

TaskFunction createShaderMaskCachePerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/shader_mask_cache_perf_e2e.dart',
  ).run;
}

TaskFunction createFadingChildAnimationPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'fading_child_animation_perf',
    testDriver: 'test_driver/fading_child_animation_perf_test.dart',
    saveTraceFile: true,
  ).run;
}

TaskFunction createImageFilteredTransformAnimationPerfTest({
  bool enableImpeller = false,
}) {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/run_app.dart',
    'imagefiltered_transform_animation_perf',
    testDriver: 'test_driver/imagefiltered_transform_animation_perf_test.dart',
    saveTraceFile: true,
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createsMultiWidgetConstructPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/multi_widget_construction_perf_e2e.dart',
  ).run;
}

TaskFunction createListTextLayoutPerfE2ETest({bool enableImpeller = false}) {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/list_text_layout_perf_e2e.dart',
    enableImpeller: enableImpeller,
  ).run;
}

TaskFunction createsScrollSmoothnessPerfTest() {
  final String testDirectory =
      '${flutterDirectory.path}/dev/benchmarks/complex_layout';
  const String testTarget = 'test/measure_scroll_smoothness.dart';
  return () {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      await flutter('drive', options: <String>[
        '--no-android-gradle-daemon',
        '-v',
        '--verbose-system-logs',
        '--profile',
        '-t', testTarget,
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = json.decode(
        file('${_testOutputDirectory(testDirectory)}/scroll_smoothness_test.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      final Map<String, dynamic> result = <String, dynamic>{};
      void addResult(dynamic data, String suffix) {
        assert(data is Map<String, dynamic>);
        if (data is Map<String, dynamic>) {
          const List<String> metricKeys = <String>[
            'janky_count',
            'average_abs_jerk',
            'dropped_frame_count',
          ];
          for (final String key in metricKeys) {
            result[key + suffix] = data[key];
          }
        }
      }
      addResult(data['resample on with 90Hz input'], '_with_resampler_90Hz');
      addResult(data['resample on with 59Hz input'], '_with_resampler_59Hz');
      addResult(data['resample off with 90Hz input'], '_without_resampler_90Hz');
      addResult(data['resample off with 59Hz input'], '_without_resampler_59Hz');

      return TaskResult.success(
        result,
        benchmarkScoreKeys: result.keys.toList(),
      );
    });
  };
}

TaskFunction createFramePolicyIntegrationTest() {
  final String testDirectory =
      '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks';
  const String testTarget = 'test/frame_policy.dart';
  return () {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      await flutter('drive', options: <String>[
        '--no-android-gradle-daemon',
        '-v',
        '--verbose-system-logs',
        '--profile',
        '-t', testTarget,
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = json.decode(
        file('${_testOutputDirectory(testDirectory)}/frame_policy_event_delay.json').readAsStringSync(),
      ) as Map<String, dynamic>;
      final Map<String, dynamic> fullLiveData = data['fullyLive'] as Map<String, dynamic>;
      final Map<String, dynamic> benchmarkLiveData = data['benchmarkLive'] as Map<String, dynamic>;
      final Map<String, dynamic> dataFormatted = <String, dynamic>{
        'average_delay_fullyLive_millis':
          fullLiveData['average_delay_millis'],
        'average_delay_benchmarkLive_millis':
          benchmarkLiveData['average_delay_millis'],
        '90th_percentile_delay_fullyLive_millis':
          fullLiveData['90th_percentile_delay_millis'],
        '90th_percentile_delay_benchmarkLive_millis':
          benchmarkLiveData['90th_percentile_delay_millis'],
      };

      return TaskResult.success(
        dataFormatted,
        benchmarkScoreKeys: dataFormatted.keys.toList(),
      );
    });
  };
}

TaskFunction createOpacityPeepholeOneRectPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_one_rect_perf_e2e.dart',
  ).run;
}

TaskFunction createOpacityPeepholeColOfRowsPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_col_of_rows_perf_e2e.dart',
  ).run;
}

TaskFunction createOpacityPeepholeOpacityOfGridPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_opacity_of_grid_perf_e2e.dart',
  ).run;
}

TaskFunction createOpacityPeepholeGridOfOpacityPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_grid_of_opacity_perf_e2e.dart',
  ).run;
}

TaskFunction createOpacityPeepholeFadeTransitionTextPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_fade_transition_text_perf_e2e.dart',
  ).run;
}

TaskFunction createOpacityPeepholeGridOfAlphaSaveLayersPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_grid_of_alpha_savelayers_perf_e2e.dart',
  ).run;
}

TaskFunction createOpacityPeepholeColOfAlphaSaveLayerRowsPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/opacity_peephole_col_of_alpha_savelayer_rows_perf_e2e.dart',
  ).run;
}

TaskFunction createGradientDynamicPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/gradient_dynamic_perf_e2e.dart',
  ).run;
}

TaskFunction createGradientConsistentPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/gradient_consistent_perf_e2e.dart',
  ).run;
}

TaskFunction createGradientStaticPerfE2ETest() {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/gradient_static_perf_e2e.dart',
  ).run;
}

TaskFunction createAnimatedComplexOpacityPerfE2ETest({
  bool enableImpeller = false,
}) {
  return PerfTest.e2e(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test/animated_complex_opacity_perf_e2e.dart',
    enableImpeller: enableImpeller,
  ).run;
}

Map<String, dynamic> _average(List<Map<String, dynamic>> results, int iterations) {
  final Map<String, dynamic> tally = <String, dynamic>{};
  for (final Map<String, dynamic> item in results) {
    item.forEach((String key, dynamic value) {
      if (tally.containsKey(key)) {
        tally[key] = (tally[key] as int) + (value as int);
      } else {
        tally[key] = value;
      }
    });
  }
  tally.forEach((String key, dynamic value) {
    tally[key] = (value as int) ~/ iterations;
  });
  return tally;
}

/// Measure application startup performance.
class StartupTest {
  const StartupTest(this.testDirectory, { this.reportMetrics = true, this.target = 'lib/main.dart' });

  final String testDirectory;
  final bool reportMetrics;
  final String target;

  Future<TaskResult> run() async {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      const int iterations = 5;
      final List<Map<String, dynamic>> results = <Map<String, dynamic>>[];

      section('Building application');
      String? applicationBinaryPath;
      switch (deviceOperatingSystem) {
        case DeviceOperatingSystem.android:
          await flutter('build', options: <String>[
            'apk',
            '-v',
            '--profile',
            '--target-platform=android-arm,android-arm64',
            '--target=$target',
          ]);
          applicationBinaryPath = '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
          break;
        case DeviceOperatingSystem.androidArm:
          await flutter('build', options: <String>[
            'apk',
            '-v',
            '--profile',
            '--target-platform=android-arm',
            '--target=$target',
          ]);
          applicationBinaryPath = '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
          break;
        case DeviceOperatingSystem.androidArm64:
          await flutter('build', options: <String>[
            'apk',
            '-v',
            '--profile',
            '--target-platform=android-arm64',
            '--target=$target',
          ]);
          applicationBinaryPath = '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
          break;
        case DeviceOperatingSystem.fake:
        case DeviceOperatingSystem.fuchsia:
          break;
        case DeviceOperatingSystem.ios:
        case DeviceOperatingSystem.macos:
          await flutter('build', options: <String>[
            if (deviceOperatingSystem == DeviceOperatingSystem.ios) 'ios' else 'macos',
             '-v',
            '--profile',
            '--target=$target',
          ]);
          final String buildRoot = path.join(testDirectory, 'build');
          applicationBinaryPath = _findDarwinAppInBuildDirectory(buildRoot);
          break;
        case DeviceOperatingSystem.windows:
          await flutter('build', options: <String>[
            'windows',
            '-v',
            '--profile',
            '--target=$target',
          ]);
          final String basename = path.basename(testDirectory);
          applicationBinaryPath = path.join(
            testDirectory,
            'build',
            'windows',
            'runner',
            'Profile',
            '$basename.exe'
          );
          break;
      }

      const int maxFailures = 3;
      int currentFailures = 0;
      for (int i = 0; i < iterations; i += 1) {
        final int result = await flutter('run', options: <String>[
          '--no-android-gradle-daemon',
          '--no-publish-port',
          '--verbose',
          '--profile',
          '--trace-startup',
          '--target=$target',
          '-d',
          device.deviceId,
          if (applicationBinaryPath != null)
            '--use-application-binary=$applicationBinaryPath',
         ], canFail: true);
        if (result == 0) {
          final Map<String, dynamic> data = json.decode(
            file('${_testOutputDirectory(testDirectory)}/start_up_info.json').readAsStringSync(),
          ) as Map<String, dynamic>;
          results.add(data);
        } else {
          currentFailures += 1;
          if (hostAgent.dumpDirectory != null) {
            await flutter(
              'screenshot',
              options: <String>[
                '-d',
                device.deviceId,
                '--out',
                hostAgent.dumpDirectory!
                    .childFile('screenshot_startup_failure_$currentFailures.png')
                    .path,
              ],
              canFail: true,
            );
          }
          i -= 1;
          if (currentFailures == maxFailures) {
            return TaskResult.failure('Application failed to start $maxFailures times');
          }
        }

        await flutter('install', options: <String>[
          '--uninstall-only',
          '-d',
          device.deviceId,
        ]);
      }

      final Map<String, dynamic> averageResults = _average(results, iterations);

      if (!reportMetrics) {
        return TaskResult.success(averageResults);
      }

      return TaskResult.success(averageResults, benchmarkScoreKeys: <String>[
        'timeToFirstFrameMicros',
        'timeToFirstFrameRasterizedMicros',
      ]);
    });
  }
}

/// A one-off test to verify that devtools starts in profile mode.
class DevtoolsStartupTest {
  const DevtoolsStartupTest(this.testDirectory);

  final String testDirectory;

  Future<TaskResult> run() async {
    return inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;

      section('Building application');
      String? applicationBinaryPath;
      switch (deviceOperatingSystem) {
        case DeviceOperatingSystem.android:
          await flutter('build', options: <String>[
            'apk',
            '-v',
            '--profile',
            '--target-platform=android-arm,android-arm64',
          ]);
          applicationBinaryPath = '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
          break;
        case DeviceOperatingSystem.androidArm:
          await flutter('build', options: <String>[
            'apk',
            '-v',
            '--profile',
            '--target-platform=android-arm',
          ]);
          applicationBinaryPath = '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
          break;
        case DeviceOperatingSystem.androidArm64:
          await flutter('build', options: <String>[
            'apk',
            '-v',
            '--profile',
            '--target-platform=android-arm64',
          ]);
          applicationBinaryPath = '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
          break;
        case DeviceOperatingSystem.ios:
          await flutter('build', options: <String>[
            'ios',
             '-v',
            '--profile',
          ]);
          applicationBinaryPath = _findDarwinAppInBuildDirectory('$testDirectory/build/ios/iphoneos');
          break;
        case DeviceOperatingSystem.fake:
        case DeviceOperatingSystem.fuchsia:
        case DeviceOperatingSystem.macos:
        case DeviceOperatingSystem.windows:
          break;
      }

      final Process process = await startProcess(path.join(flutterDirectory.path, 'bin', 'flutter'), <String>[
        'run',
        '--no-android-gradle-daemon',
        '--no-publish-port',
        '--verbose',
        '--profile',
        '-d',
        device.deviceId,
        if (applicationBinaryPath != null)
          '--use-application-binary=$applicationBinaryPath',
       ]);
      final Completer<void> completer = Completer<void>();
      bool sawLine = false;
      process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((String line) {
          print('[STDOUT]: $line');
        // Wait for devtools output.
        if (line.contains('The Flutter DevTools debugger and profiler')) {
          sawLine = true;
          completer.complete();
        }
      });
      bool didExit = false;
      unawaited(process.exitCode.whenComplete(() {
        didExit = true;
      }));
      await Future.any(<Future<void>>[completer.future, Future<void>.delayed(const Duration(minutes: 5)), process.exitCode]);
      if (!didExit) {
        process.stdin.writeln('q');
        await process.exitCode;
      }

      await flutter('install', options: <String>[
        '--uninstall-only',
        '-d',
        device.deviceId,
      ]);

      if (sawLine) {
        return TaskResult.success(null, benchmarkScoreKeys: <String>[]);
      }
      return TaskResult.failure('Did not see line "The Flutter DevTools debugger and profiler" in output');
    });
  }
}

/// A callback function to be used to mock the flutter drive command in PerfTests.
///
/// The `options` contains all the arguments in the `flutter drive` command in PerfTests.
typedef FlutterDriveCallback = void Function(List<String> options);

/// Measures application runtime performance, specifically per-frame
/// performance.
class PerfTest {
  const PerfTest(
    this.testDirectory,
    this.testTarget,
    this.timelineFileName, {
    this.measureCpuGpu = true,
    this.measureMemory = true,
    this.saveTraceFile = false,
    this.testDriver,
    this.needsFullTimeline = true,
    this.benchmarkScoreKeys,
    this.dartDefine = '',
    String? resultFilename,
    this.device,
    this.flutterDriveCallback,
    this.enableImpeller = false,
  }): _resultFilename = resultFilename;

  const PerfTest.e2e(
    this.testDirectory,
    this.testTarget, {
    this.measureCpuGpu = false,
    this.measureMemory = false,
    this.testDriver =  'test_driver/e2e_test.dart',
    this.needsFullTimeline = false,
    this.benchmarkScoreKeys = _kCommonScoreKeys,
    this.dartDefine = '',
    String resultFilename = 'e2e_perf_summary',
    this.device,
    this.flutterDriveCallback,
    this.enableImpeller = false,
  }) : saveTraceFile = false, timelineFileName = null, _resultFilename = resultFilename;

  /// The directory where the app under test is defined.
  final String testDirectory;
  /// The main entry-point file of the application, as run on the device.
  final String testTarget;
  // The prefix name of the filename such as `<timelineFileName>.timeline_summary.json`.
  final String? timelineFileName;
  String get traceFilename => '$timelineFileName.timeline';
  String get resultFilename => _resultFilename ?? '$timelineFileName.timeline_summary';
  final String? _resultFilename;
  /// The test file to run on the host.
  final String? testDriver;
  /// Whether to collect CPU and GPU metrics.
  final bool measureCpuGpu;
  /// Whether to collect memory metrics.
  final bool measureMemory;
  /// Whether to collect full timeline, meaning if `--trace-startup` flag is needed.
  final bool needsFullTimeline;
  /// Whether to save the trace timeline file `*.timeline.json`.
  final bool saveTraceFile;
  /// The device to test on.
  ///
  /// If null, the device is selected depending on the current environment.
  final Device? device;

  /// The function called instead of the actually `flutter drive`.
  ///
  /// If it is not `null`, `flutter drive` will not happen in the PerfTests.
  final FlutterDriveCallback? flutterDriveCallback;

  /// Whether the perf test should enable Impeller.
  final bool enableImpeller;

  /// The keys of the values that need to be reported.
  ///
  /// If it's `null`, then report:
  /// ```Dart
  /// <String>[
  ///   'average_frame_build_time_millis',
  ///   'worst_frame_build_time_millis',
  ///   '90th_percentile_frame_build_time_millis',
  ///   '99th_percentile_frame_build_time_millis',
  ///   'average_frame_rasterizer_time_millis',
  ///   'worst_frame_rasterizer_time_millis',
  ///   '90th_percentile_frame_rasterizer_time_millis',
  ///   '99th_percentile_frame_rasterizer_time_millis',
  ///   'average_vsync_transitions_missed',
  ///   '90th_percentile_vsync_transitions_missed',
  ///   '99th_percentile_vsync_transitions_missed',
  ///   if (measureCpuGpu) 'average_cpu_usage',
  ///   if (measureCpuGpu) 'average_gpu_usage',
  /// ]
  /// ```
  final List<String>? benchmarkScoreKeys;

  /// Additional flags for `--dart-define` to control the test
  final String dartDefine;

  Future<TaskResult> run() {
    return internalRun();
  }

  @protected
  Future<TaskResult> internalRun({
      bool cacheSkSL = false,
      String? existingApp,
      String? writeSkslFileName,
  }) {
    return inDirectory<TaskResult>(testDirectory, () async {
      late Device selectedDevice;
      if (device != null) {
        selectedDevice = device!;
      } else {
        selectedDevice = await devices.workingDevice;
      }
      await selectedDevice.unlock();
      final String deviceId = selectedDevice.deviceId;
      final String? localEngine = localEngineFromEnv;
      final String? localEngineSrcPath = localEngineSrcPathFromEnv;

      final List<String> options = <String>[
        if (localEngine != null)
          ...<String>['--local-engine', localEngine],
        if (localEngineSrcPath != null)
          ...<String>['--local-engine-src-path', localEngineSrcPath],
        '--no-dds',
        '--no-android-gradle-daemon',
        '-v',
        '--verbose-system-logs',
        '--profile',
        if (needsFullTimeline)
          '--trace-startup', // Enables "endless" timeline event buffering.
        '-t', testTarget,
        if (testDriver != null)
          ...<String>['--driver', testDriver!],
        if (existingApp != null)
          ...<String>['--use-existing-app', existingApp],
        if (writeSkslFileName != null)
          ...<String>['--write-sksl-on-exit', writeSkslFileName],
        if (cacheSkSL) '--cache-sksl',
        if (dartDefine.isNotEmpty)
          ...<String>['--dart-define', dartDefine],
        if (enableImpeller) '--enable-impeller',
        '-d',
        deviceId,
      ];
      if (flutterDriveCallback != null) {
        flutterDriveCallback!(options);
      } else {
        await flutter('drive', options:options);
      }
      final Map<String, dynamic> data = json.decode(
        file('${_testOutputDirectory(testDirectory)}/$resultFilename.json').readAsStringSync(),
      ) as Map<String, dynamic>;

      if (data['frame_count'] as int < 5) {
        return TaskResult.failure(
          'Timeline contains too few frames: ${data['frame_count']}. Possibly '
          'trace events are not being captured.',
        );
      }

      // TODO(liyuqian): Remove isAndroid restriction once
      // https://github.com/flutter/flutter/issues/61567 is fixed.
      final bool isAndroid = deviceOperatingSystem == DeviceOperatingSystem.android;
      return TaskResult.success(
        data,
        detailFiles: <String>[
          if (saveTraceFile)
            '${_testOutputDirectory(testDirectory)}/$traceFilename.json',
        ],
        benchmarkScoreKeys: benchmarkScoreKeys ?? <String>[
          ..._kCommonScoreKeys,
          'average_vsync_transitions_missed',
          '90th_percentile_vsync_transitions_missed',
          '99th_percentile_vsync_transitions_missed',
          if (measureCpuGpu && !isAndroid) ...<String>[
            // See https://github.com/flutter/flutter/issues/68888
            if (data['average_cpu_usage'] != null) 'average_cpu_usage',
            if (data['average_gpu_usage'] != null) 'average_gpu_usage',
          ],
          if (measureMemory && !isAndroid) ...<String>[
            // See https://github.com/flutter/flutter/issues/68888
            if (data['average_memory_usage'] != null) 'average_memory_usage',
            if (data['90th_percentile_memory_usage'] != null) '90th_percentile_memory_usage',
            if (data['99th_percentile_memory_usage'] != null) '99th_percentile_memory_usage',
          ],
          if (data['30hz_frame_percentage'] != null) '30hz_frame_percentage',
          if (data['60hz_frame_percentage'] != null) '60hz_frame_percentage',
          if (data['80hz_frame_percentage'] != null) '80hz_frame_percentage',
          if (data['90hz_frame_percentage'] != null) '90hz_frame_percentage',
          if (data['120hz_frame_percentage'] != null) '120hz_frame_percentage',
          if (data['illegal_refresh_rate_frame_count'] != null) 'illegal_refresh_rate_frame_count',
        ],
      );
    });
  }
}

const List<String> _kCommonScoreKeys = <String>[
  'average_frame_build_time_millis',
  'worst_frame_build_time_millis',
  '90th_percentile_frame_build_time_millis',
  '99th_percentile_frame_build_time_millis',
  'average_frame_rasterizer_time_millis',
  'worst_frame_rasterizer_time_millis',
  '90th_percentile_frame_rasterizer_time_millis',
  '99th_percentile_frame_rasterizer_time_millis',
  'average_layer_cache_count',
  '90th_percentile_layer_cache_count',
  '99th_percentile_layer_cache_count',
  'worst_layer_cache_count',
  'average_layer_cache_memory',
  '90th_percentile_layer_cache_memory',
  '99th_percentile_layer_cache_memory',
  'worst_layer_cache_memory',
  'average_picture_cache_count',
  '90th_percentile_picture_cache_count',
  '99th_percentile_picture_cache_count',
  'worst_picture_cache_count',
  'average_picture_cache_memory',
  '90th_percentile_picture_cache_memory',
  '99th_percentile_picture_cache_memory',
  'worst_picture_cache_memory',
  'new_gen_gc_count',
  'old_gen_gc_count',
];

class PerfTestWithSkSL extends PerfTest {
  PerfTestWithSkSL(
    super.testDirectory,
    super.testTarget,
    String super.timelineFileName, {
    super.measureCpuGpu = false,
    super.testDriver,
    super.needsFullTimeline,
    super.benchmarkScoreKeys,
  });


  PerfTestWithSkSL.e2e(
    super.testDirectory,
    super.testTarget, {
    String super.testDriver,
    super.resultFilename,
  }) : super.e2e(
    needsFullTimeline: false,
  );

  @override
  Future<TaskResult> run() async {
    return inDirectory<TaskResult>(testDirectory, () async {
      // Some initializations
      _device = await devices.workingDevice;
      _flutterPath = path.join(flutterDirectory.path, 'bin', 'flutter');

      // Prepare the SkSL by running the driver test.
      await _generateSkSL();

      // Build the app with SkSL artifacts and run that app
      final String observatoryUri = await _runApp(skslPath: _skslJsonFileName);

      // Attach to the running app and run the final driver test to get metrics.
      final TaskResult result = await internalRun(
        existingApp: observatoryUri,
      );

      _runProcess.kill();
      await _runProcess.exitCode;

      return result;
    });
  }

  Future<void> _generateSkSL() async {
    // `flutter drive` without `flutter run`, and `flutter drive --existing-app`
    // with `flutter run` may generate different SkSLs. Hence we run both
    // versions to generate as many SkSLs as possible.
    //
    // 1st, `flutter drive --existing-app` with `flutter run`. The
    // `--write-sksl-on-exit` option doesn't seem to be compatible with
    // `flutter drive --existing-app` as it will complain web socket connection
    // issues.
    final String observatoryUri = await _runApp(cacheSkSL: true);
    await super.internalRun(cacheSkSL: true, existingApp: observatoryUri);
    _runProcess.kill();
    await _runProcess.exitCode;

    // 2nd, `flutter drive` without `flutter run`. The --no-build option ensures
    // that we won't remove the SkSLs generated earlier.
    await super.internalRun(
      cacheSkSL: true,
      writeSkslFileName: _skslJsonFileName,
    );
  }

  Future<String> _runApp({String? appBinary, bool cacheSkSL = false, String? skslPath}) async {
    if (File(_vmserviceFileName).existsSync()) {
      File(_vmserviceFileName).deleteSync();
    }
    final String? localEngine = localEngineFromEnv;
    final String? localEngineSrcPath = localEngineSrcPathFromEnv;
    _runProcess = await startProcess(
      _flutterPath,
      <String>[
        'run',
        if (localEngine != null)
          ...<String>['--local-engine', localEngine],
        if (localEngineSrcPath != null)
          ...<String>['--local-engine-src-path', localEngineSrcPath],
        '--no-dds',
        if (deviceOperatingSystem == DeviceOperatingSystem.ios)
          ...<String>[
            '--device-timeout', '5',
          ],
        '--verbose',
        '--verbose-system-logs',
        '--purge-persistent-cache',
        '--no-publish-port',
        '--profile',
        if (skslPath != null) '--bundle-sksl-path=$skslPath',
        if (cacheSkSL) '--cache-sksl',
        '-d', _device.deviceId,
        '-t', testTarget,
        '--endless-trace-buffer',
        if (appBinary != null) ...<String>['--use-application-binary', _appBinary],
        '--vmservice-out-file', _vmserviceFileName,
      ],
    );

    final Stream<List<int>> broadcastOut = _runProcess.stdout.asBroadcastStream();
    _forwardStream(broadcastOut, 'run stdout');
    _forwardStream(_runProcess.stderr, 'run stderr');

    final File file = await waitForFile(_vmserviceFileName);
    return file.readAsStringSync();
  }

  String get _skslJsonFileName => '$testDirectory/flutter_01.sksl.json';
  String get _vmserviceFileName => '$testDirectory/$_kVmserviceOutFileName';

  bool get _isAndroid => deviceOperatingSystem == DeviceOperatingSystem.android;

  String get _appBinary {
    if (_isAndroid) {
      return '$testDirectory/build/app/outputs/flutter-apk/app-profile.apk';
    }
    for (final FileSystemEntity entry in Directory('$testDirectory/build/ios/iphoneos/').listSync()) {
      if (entry.path.endsWith('.app')) {
        return entry.path;
      }
    }
    throw 'No app found.';
  }

  Stream<String> _transform(Stream<List<int>> stream) =>
      stream.transform<String>(utf8.decoder).transform<String>(const LineSplitter());

  void _forwardStream(Stream<List<int>> stream, String label) {
    _transform(stream).listen((String line) {
      print('$label: $line');
    });
  }

  late String _flutterPath;
  late Device _device;
  late Process _runProcess;

  static const String _kVmserviceOutFileName = 'vmservice.out';
}

/// Measures how long it takes to compile a Flutter app to JavaScript and how
/// big the compiled code is.
class WebCompileTest {
  const WebCompileTest();

  Future<TaskResult> run() async {
    final Map<String, Object> metrics = <String, Object>{};

    metrics.addAll(await runSingleBuildTest(
      directory: '${flutterDirectory.path}/examples/hello_world',
      metric: 'hello_world',
    ));

    metrics.addAll(await runSingleBuildTest(
      directory: '${flutterDirectory.path}/dev/integration_tests/flutter_gallery',
      metric: 'flutter_gallery',
    ));

    const String sampleAppName = 'sample_flutter_app';
    final Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    rmTree(sampleDir);

    await inDirectory<void>(Directory.systemTemp, () async {
      await flutter('create', options: <String>['--template=app', sampleAppName]);
    });

    metrics.addAll(await runSingleBuildTest(
      directory: sampleDir.path,
      metric: 'basic_material_app',
    ));

    return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
  }

  /// Run a single web compile test and return its metrics.
  ///
  /// Run a single web compile test for the app under [directory], and store
  /// its metrics with prefix [metric].
  static Future<Map<String, int>> runSingleBuildTest({
    required String directory,
    required String metric,
    bool measureBuildTime = false,
  }) {
    return inDirectory<Map<String, int>>(directory, () async {
      final Map<String, int> metrics = <String, int>{};

      await flutter('packages', options: <String>['get']);
      final Stopwatch? watch = measureBuildTime ? Stopwatch() : null;
      watch?.start();
      await evalFlutter('build', options: <String>[
        'web',
        '-v',
        '--release',
        '--no-pub',
      ]);
      watch?.stop();
      final String outputFileName = path.join(directory, 'build/web/main.dart.js');
      metrics.addAll(await getSize(outputFileName, metric: metric));

      if (measureBuildTime) {
        metrics['${metric}_dart2js_millis'] = watch!.elapsedMilliseconds;
      }

      return metrics;
    });
  }

  /// Obtains the size and gzipped size of a file given by [fileName].
  static Future<Map<String, int>> getSize(String fileName, {required String metric}) async {
    final Map<String, int> sizeMetrics = <String, int>{};

    final ProcessResult result = await Process.run('du', <String>['-k', fileName]);
    sizeMetrics['${metric}_dart2js_size'] = _parseDu(result.stdout as String);

    await Process.run('gzip',<String>['-k', '9', fileName]);
    final ProcessResult resultGzip = await Process.run('du', <String>['-k', '$fileName.gz']);
    sizeMetrics['${metric}_dart2js_size_gzip'] = _parseDu(resultGzip.stdout as String);

    return sizeMetrics;
  }

  static int _parseDu(String source) {
    return int.parse(source.split(RegExp(r'\s+')).first.trim());
  }
}

/// Measures how long it takes to compile a Flutter app and how big the compiled
/// code is.
class CompileTest {
  const CompileTest(this.testDirectory, { this.reportPackageContentSizes = false });

  final String testDirectory;
  final bool reportPackageContentSizes;

  Future<TaskResult> run() async {
    return inDirectory<TaskResult>(testDirectory, () async {
      await flutter('packages', options: <String>['get']);

      // "initial" compile required downloading and creating the `android/.gradle` directory while "full"
      // compiles only run `flutter clean` between runs.
      final Map<String, dynamic> compileInitialRelease = await _compileApp(deleteGradleCache: true);
      final Map<String, dynamic> compileFullRelease = await _compileApp(deleteGradleCache: false);
      final Map<String, dynamic> compileInitialDebug = await _compileDebug(
        clean: true,
        deleteGradleCache: true,
        metricKey: 'debug_initial_compile_millis',
      );
      final Map<String, dynamic> compileFullDebug = await _compileDebug(
        clean: true,
        deleteGradleCache: false,
        metricKey: 'debug_full_compile_millis',
      );
      // Build again without cleaning, should be faster.
      final Map<String, dynamic> compileSecondDebug = await _compileDebug(
        clean: false,
        deleteGradleCache: false,
        metricKey: 'debug_second_compile_millis',
      );

      final Map<String, dynamic> metrics = <String, dynamic>{
        ...compileInitialRelease,
        ...compileFullRelease,
        ...compileInitialDebug,
        ...compileFullDebug,
        ...compileSecondDebug,
      };

      final File mainDart = File('$testDirectory/lib/main.dart');
      if (mainDart.existsSync()) {
        final List<int> bytes = mainDart.readAsBytesSync();
        // "Touch" the file
        mainDart.writeAsStringSync(' ', mode: FileMode.append, flush: true);
        // Build after "edit" without clean should be faster than first build
        final Map<String, dynamic> compileAfterEditDebug = await _compileDebug(
          clean: false,
          deleteGradleCache: false,
          metricKey: 'debug_compile_after_edit_millis',
        );
        metrics.addAll(compileAfterEditDebug);
        // Revert the changes
        mainDart.writeAsBytesSync(bytes, flush: true);
      }

      return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
    });
  }

  Future<Map<String, dynamic>> _compileApp({required bool deleteGradleCache}) async {
    await flutter('clean');
    if (deleteGradleCache) {
      final Directory gradleCacheDir = Directory('$testDirectory/android/.gradle');
      gradleCacheDir.deleteSync(recursive: true);
    }
    final Stopwatch watch = Stopwatch();
    int releaseSizeInBytes;
    final List<String> options = <String>['--release'];
    final Map<String, dynamic> metrics = <String, dynamic>{};

    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
      case DeviceOperatingSystem.macos:
        unawaited(stderr.flush());
        late final String deviceId;
        if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
          deviceId = 'ios';
        } else if (deviceOperatingSystem == DeviceOperatingSystem.macos) {
          deviceId = 'macos';
        } else {
          throw Exception('Attempted to run darwin compile workflow with $deviceOperatingSystem');
        }

        options.insert(0, deviceId);
        options.add('--tree-shake-icons');
        options.add('--split-debug-info=infos/');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final Directory buildDirectory = dir(path.join(
          cwd,
          'build',
        ));
        final String? appPath =
            _findDarwinAppInBuildDirectory(buildDirectory.path);
        if (appPath == null) {
          throw 'Failed to find app bundle in ${buildDirectory.path}';
        }
        // Validate changes in Dart snapshot format and data layout do not
        // change compression size. This also simulates the size of an IPA on iOS.
        await exec('tar', <String>['-zcf', 'build/app.tar.gz', appPath]);
        releaseSizeInBytes = await file('$cwd/build/app.tar.gz').length();
        if (reportPackageContentSizes) {
          final Map<String, Object> sizeMetrics = await getSizesFromDarwinApp(
            appPath: appPath,
            operatingSystem: deviceOperatingSystem,
          );
          metrics.addAll(sizeMetrics);
        }
        break;
      case DeviceOperatingSystem.android:
      case DeviceOperatingSystem.androidArm:
        options.insert(0, 'apk');
        options.add('--target-platform=android-arm');
        options.add('--tree-shake-icons');
        options.add('--split-debug-info=infos/');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final String apkPath = '$cwd/build/app/outputs/flutter-apk/app-release.apk';
        final File apk = file(apkPath);
        releaseSizeInBytes = apk.lengthSync();
        if (reportPackageContentSizes) {
          metrics.addAll(await getSizesFromApk(apkPath));
        }
        break;
      case DeviceOperatingSystem.androidArm64:
        options.insert(0, 'apk');
        options.add('--target-platform=android-arm64');
        options.add('--tree-shake-icons');
        options.add('--split-debug-info=infos/');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final String apkPath = '$cwd/build/app/outputs/flutter-apk/app-release.apk';
        final File apk = file(apkPath);
        releaseSizeInBytes = apk.lengthSync();
        if (reportPackageContentSizes) {
          metrics.addAll(await getSizesFromApk(apkPath));
        }
        break;
      case DeviceOperatingSystem.fake:
        throw Exception('Unsupported option for fake devices');
      case DeviceOperatingSystem.fuchsia:
        throw Exception('Unsupported option for Fuchsia devices');
      case DeviceOperatingSystem.windows:
        unawaited(stderr.flush());
        options.insert(0, 'windows');
        options.add('--tree-shake-icons');
        options.add('--split-debug-info=infos/');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final String basename = path.basename(cwd);
        final String exePath = path.join(
          cwd,
          'build',
          'windows',
          'runner',
          'release',
          '$basename.exe');
        final File exe = file(exePath);
        // On Windows, we do not produce a single installation package file,
        // rather a directory containing an .exe and .dll files.
        // The release size is set to the size of the produced .exe file
        releaseSizeInBytes = exe.lengthSync();
        break;
    }

    metrics.addAll(<String, dynamic>{
      'release_${deleteGradleCache ? 'initial' : 'full'}_compile_millis': watch.elapsedMilliseconds,
      'release_size_bytes': releaseSizeInBytes,
    });

    return metrics;
  }

  Future<Map<String, dynamic>> _compileDebug({
    required bool deleteGradleCache,
    required bool clean,
    required String metricKey,
  }) async {
    if (clean) {
      await flutter('clean');
    }
    if (deleteGradleCache) {
      final Directory gradleCacheDir = Directory('$testDirectory/android/.gradle');
      gradleCacheDir.deleteSync(recursive: true);
    }
    final Stopwatch watch = Stopwatch();
    final List<String> options = <String>['--debug'];
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.insert(0, 'ios');
        break;
      case DeviceOperatingSystem.android:
      case DeviceOperatingSystem.androidArm:
        options.insert(0, 'apk');
        options.add('--target-platform=android-arm');
        break;
      case DeviceOperatingSystem.androidArm64:
        options.insert(0, 'apk');
        options.add('--target-platform=android-arm64');
        break;
      case DeviceOperatingSystem.fake:
        throw Exception('Unsupported option for fake devices');
      case DeviceOperatingSystem.fuchsia:
        throw Exception('Unsupported option for Fuchsia devices');
      case DeviceOperatingSystem.macos:
        unawaited(stderr.flush());
        options.insert(0, 'macos');
        break;
      case DeviceOperatingSystem.windows:
        unawaited(stderr.flush());
        options.insert(0, 'windows');
        break;
    }
    watch.start();
    await flutter('build', options: options);
    watch.stop();

    return <String, dynamic>{
      metricKey: watch.elapsedMilliseconds,
    };
  }

  static Future<Map<String, Object>> getSizesFromDarwinApp({
    required String appPath,
    required DeviceOperatingSystem operatingSystem,
  }) async {
    late final File flutterFramework;
    late final String frameworkDirectory;
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        frameworkDirectory = path.join(
          appPath,
          'Frameworks',
        );
        flutterFramework = File(path.join(
          frameworkDirectory,
          'Flutter.framework',
          'Flutter',
        ));
        break;
      case DeviceOperatingSystem.macos:
        frameworkDirectory = path.join(
          appPath,
          'Contents',
          'Frameworks',
        );
        flutterFramework = File(path.join(
          frameworkDirectory,
          'FlutterMacOS.framework',
          'FlutterMacOS',
        )); // https://github.com/flutter/flutter/issues/70413
        break;
      case DeviceOperatingSystem.android:
      case DeviceOperatingSystem.androidArm:
      case DeviceOperatingSystem.androidArm64:
      case DeviceOperatingSystem.fake:
      case DeviceOperatingSystem.fuchsia:
      case DeviceOperatingSystem.windows:
        throw Exception('Called ${CompileTest.getSizesFromDarwinApp} with $operatingSystem.');
    }

    final File appFramework = File(path.join(
      frameworkDirectory,
      'App.framework',
      'App',
    ));

    return <String, Object>{
      'app_framework_uncompressed_bytes': await appFramework.length(),
      'flutter_framework_uncompressed_bytes': await flutterFramework.length(),
    };
  }

  static Future<Map<String, dynamic>> getSizesFromApk(String apkPath) async {
    final  String output = await eval('unzip', <String>['-v', apkPath]);
    final List<String> lines = output.split('\n');
    final Map<String, _UnzipListEntry> fileToMetadata = <String, _UnzipListEntry>{};

    // First three lines are header, last two lines are footer.
    for (int i = 3; i < lines.length - 2; i++) {
      final _UnzipListEntry entry = _UnzipListEntry.fromLine(lines[i]);
      fileToMetadata[entry.path] = entry;
    }

    final _UnzipListEntry libflutter = fileToMetadata['lib/armeabi-v7a/libflutter.so']!;
    final _UnzipListEntry libapp = fileToMetadata['lib/armeabi-v7a/libapp.so']!;
    final _UnzipListEntry license = fileToMetadata['assets/flutter_assets/NOTICES.Z']!;

    return <String, dynamic>{
      'libflutter_uncompressed_bytes': libflutter.uncompressedSize,
      'libflutter_compressed_bytes': libflutter.compressedSize,
      'libapp_uncompressed_bytes': libapp.uncompressedSize,
      'libapp_compressed_bytes': libapp.compressedSize,
      'license_uncompressed_bytes': license.uncompressedSize,
      'license_compressed_bytes': license.compressedSize,
    };
  }
}

/// Measure application memory usage.
class MemoryTest {
  MemoryTest(this.project, this.test, this.package);

  final String project;
  final String test;
  final String package;

  /// Completes when the log line specified in the last call to
  /// [prepareForNextMessage] is seen by `adb logcat`.
  Future<void>? get receivedNextMessage => _receivedNextMessage?.future;
  Completer<void>? _receivedNextMessage;
  String? _nextMessage;

  /// Prepares the [receivedNextMessage] future such that it will complete
  /// when `adb logcat` sees a log line with the given `message`.
  void prepareForNextMessage(String message) {
    _nextMessage = message;
    _receivedNextMessage = Completer<void>();
  }

  int get iterationCount => 10;

  Device? get device => _device;
  Device? _device;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      // This test currently only works on Android, because device.logcat,
      // device.getMemoryStats, etc, aren't implemented for iOS.

      _device = await devices.workingDevice;
      await device!.unlock();
      await flutter('packages', options: <String>['get']);

      final StreamSubscription<String> adb = device!.logcat.listen(
        (String data) {
          if (data.contains('==== MEMORY BENCHMARK ==== $_nextMessage ====')) {
            _receivedNextMessage?.complete();
          }
        },
      );

      for (int iteration = 0; iteration < iterationCount; iteration += 1) {
        print('running memory test iteration $iteration...');
        _startMemoryUsage = null;
        await useMemory();
        assert(_startMemoryUsage != null);
        assert(_startMemory.length == iteration + 1);
        assert(_endMemory.length == iteration + 1);
        assert(_diffMemory.length == iteration + 1);
        print('terminating...');
        await device!.stop(package);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await adb.cancel();
      await flutter('install', options: <String>['--uninstall-only', '-d', device!.deviceId]);

      final ListStatistics startMemoryStatistics = ListStatistics(_startMemory);
      final ListStatistics endMemoryStatistics = ListStatistics(_endMemory);
      final ListStatistics diffMemoryStatistics = ListStatistics(_diffMemory);

      final Map<String, dynamic> memoryUsage = <String, dynamic>{
        ...startMemoryStatistics.asMap('start'),
        ...endMemoryStatistics.asMap('end'),
        ...diffMemoryStatistics.asMap('diff'),
      };

      _device = null;
      _startMemory.clear();
      _endMemory.clear();
      _diffMemory.clear();

      return TaskResult.success(memoryUsage, benchmarkScoreKeys: memoryUsage.keys.toList());
    });
  }

  /// Starts the app specified by [test] on the [device].
  ///
  /// The [run] method will terminate it by its package name ([package]).
  Future<void> launchApp() async {
    prepareForNextMessage('READY');
    print('launching $project$test on device...');
    await flutter('run', options: <String>[
      '--verbose',
      '--release',
      '--no-resident',
      '-d', device!.deviceId,
      test,
    ]);
    print('awaiting "ready" message...');
    await receivedNextMessage;
  }

  /// To change the behavior of the test, override this.
  ///
  /// Make sure to call recordStart() and recordEnd() once each in that order.
  ///
  /// By default it just launches the app, records memory usage, taps the device,
  /// awaits a DONE notification, and records memory usage again.
  Future<void> useMemory() async {
    await launchApp();
    await recordStart();

    prepareForNextMessage('DONE');
    print('tapping device...');
    await device!.tap(100, 100);
    print('awaiting "done" message...');
    await receivedNextMessage;

    await recordEnd();
  }

  final List<int> _startMemory = <int>[];
  final List<int> _endMemory = <int>[];
  final List<int> _diffMemory = <int>[];

  Map<String, dynamic>? _startMemoryUsage;

  @protected
  Future<void> recordStart() async {
    assert(_startMemoryUsage == null);
    print('snapshotting memory usage...');
    _startMemoryUsage = await device!.getMemoryStats(package);
  }

  @protected
  Future<void> recordEnd() async {
    assert(_startMemoryUsage != null);
    print('snapshotting memory usage...');
    final Map<String, dynamic> endMemoryUsage = await device!.getMemoryStats(package);
    _startMemory.add(_startMemoryUsage!['total_kb'] as int);
    _endMemory.add(endMemoryUsage['total_kb'] as int);
    _diffMemory.add((endMemoryUsage['total_kb'] as int) - (_startMemoryUsage!['total_kb'] as int));
  }
}

class DevToolsMemoryTest {
  DevToolsMemoryTest(this.project, this.driverTest);

  final String project;
  final String driverTest;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      _device = await devices.workingDevice;
      await _device.unlock();

      await flutter(
        'drive',
        options: <String>[
          '-d', _device.deviceId,
          '--profile',
          '--profile-memory', _kJsonFileName,
          '--no-publish-port',
          '-v',
          driverTest,
        ],
      );

      final Map<String, dynamic> data = json.decode(
        file('$project/$_kJsonFileName').readAsStringSync(),
      ) as Map<String, dynamic>;
      final List<dynamic> samples = (data['samples'] as Map<String, dynamic>)['data'] as List<dynamic>;
      int maxRss = 0;
      int maxAdbTotal = 0;
      for (final Map<String, dynamic> sample in samples.cast<Map<String, dynamic>>()) {
        if (sample['rss'] != null) {
          maxRss = math.max(maxRss, sample['rss'] as int);
        }
        if (sample['adb_memoryInfo'] != null) {
          maxAdbTotal = math.max(maxAdbTotal, (sample['adb_memoryInfo'] as Map<String, dynamic>)['Total'] as int);
        }
      }

      return TaskResult.success(
        <String, dynamic>{'maxRss': maxRss, 'maxAdbTotal': maxAdbTotal},
        benchmarkScoreKeys: <String>['maxRss', 'maxAdbTotal'],
      );
    });
  }

  late Device _device;

  static const String _kJsonFileName = 'devtools_memory.json';
}

enum ReportedDurationTestFlavor {
  debug, profile, release
}

String _reportedDurationTestToString(ReportedDurationTestFlavor flavor) {
  switch (flavor) {
    case ReportedDurationTestFlavor.debug:
      return 'debug';
    case ReportedDurationTestFlavor.profile:
      return 'profile';
    case ReportedDurationTestFlavor.release:
      return 'release';
  }
}

class ReportedDurationTest {
  ReportedDurationTest(this.flavor, this.project, this.test, this.package, this.durationPattern);

  final ReportedDurationTestFlavor flavor;
  final String project;
  final String test;
  final String package;
  final RegExp durationPattern;

  final Completer<int> durationCompleter = Completer<int>();

  int get iterationCount => 10;

  Device? get device => _device;
  Device? _device;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      // This test currently only works on Android, because device.logcat,
      // device.getMemoryStats, etc, aren't implemented for iOS.

      _device = await devices.workingDevice;
      await device!.unlock();
      await flutter('packages', options: <String>['get']);

      final StreamSubscription<String> adb = device!.logcat.listen(
        (String data) {
          if (durationPattern.hasMatch(data)) {
            durationCompleter.complete(int.parse(durationPattern.firstMatch(data)!.group(1)!));
          }
        },
      );
      print('launching $project$test on device...');
      await flutter('run', options: <String>[
        '--verbose',
        '--no-publish-port',
        '--no-fast-start',
        '--${_reportedDurationTestToString(flavor)}',
        '--no-resident',
        '-d', device!.deviceId,
        test,
      ]);

      final int duration = await durationCompleter.future;
      print('terminating...');
      await device!.stop(package);
      await adb.cancel();

      _device = null;

      final Map<String, dynamic> reportedDuration = <String, dynamic>{
        'duration': duration,
      };
      _device = null;

      return TaskResult.success(reportedDuration, benchmarkScoreKeys: reportedDuration.keys.toList());
    });
  }
}

/// Holds simple statistics of an odd-lengthed list of integers.
class ListStatistics {
  factory ListStatistics(Iterable<int> data) {
    assert(data.isNotEmpty);
    assert(data.length.isOdd);
    final List<int> sortedData = data.toList()..sort();
    return ListStatistics._(
      sortedData.first,
      sortedData.last,
      sortedData[(sortedData.length - 1) ~/ 2],
    );
  }

  const ListStatistics._(this.min, this.max, this.median);

  final int min;
  final int max;
  final int median;

  Map<String, int> asMap(String prefix) {
    return <String, int>{
      '$prefix-min': min,
      '$prefix-max': max,
      '$prefix-median': median,
    };
  }
}

class _UnzipListEntry {
  factory _UnzipListEntry.fromLine(String line) {
    final List<String> data = line.trim().split(RegExp(r'\s+'));
    assert(data.length == 8);
    return _UnzipListEntry._(
      uncompressedSize:  int.parse(data[0]),
      compressedSize: int.parse(data[2]),
      path: data[7],
    );
  }

  _UnzipListEntry._({
    required this.uncompressedSize,
    required this.compressedSize,
    required this.path,
  }) : assert(uncompressedSize != null),
       assert(compressedSize != null),
       assert(compressedSize <= uncompressedSize),
       assert(path != null);

  final int uncompressedSize;
  final int compressedSize;
  final String path;
}

/// Wait for up to 1 hour for the file to appear.
Future<File> waitForFile(String path) async {
  for (int i = 0; i < 180; i += 1) {
    final File file = File(path);
    print('looking for ${file.path}');
    if (file.existsSync()) {
      return file;
    }
    await Future<void>.delayed(const Duration(seconds: 20));
  }
  throw StateError('Did not find vmservice out file after 1 hour');
}

String? _findDarwinAppInBuildDirectory(String searchDirectory) {
  for (final FileSystemEntity entity in Directory(searchDirectory)
    .listSync(recursive: true)) {
    if (entity.path.endsWith('.app')) {
      return entity.path;
    }
  }
  return null;
}
