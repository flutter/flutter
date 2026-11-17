// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:convert' show json;
import 'dart:io';

import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart';

import 'common.dart';

void main() {
  late Directory testDirectory;
  late File testTarget;
  late Device device;
  late String perfTestOutputPath;

  setUp(() async {
    testDirectory = Directory.systemTemp.createTempSync('test_dir');
    perfTestOutputPath = testOutputDirectory(testDirectory.absolute.path);
    testTarget = File('${testDirectory.absolute.path}/test_file')..createSync();
    device = const FakeDevice(deviceId: 'fakeDeviceId');
    deviceOperatingSystem = DeviceOperatingSystem.fake;
  });

  // This tests when keys like `30hz_frame_percentage`, `60hz_frame_percentage` are not in the generated file.
  test('runs perf tests, no crash if refresh rate percentage keys are not in the data', () async {
    final fakeData = <String, dynamic>{
      'frame_count': 5,
      'average_frame_build_time_millis': 0.1,
      'worst_frame_build_time_millis': 0.1,
      '90th_percentile_frame_build_time_millis': 0.1,
      '99th_percentile_frame_build_time_millis': 0.1,
      'average_frame_rasterizer_time_millis': 0.1,
      'worst_frame_rasterizer_time_millis': 0.1,
      '90th_percentile_frame_rasterizer_time_millis': 0.1,
      '99th_percentile_frame_rasterizer_time_millis': 0.1,
      'average_layer_cache_count': 1,
      '90th_percentile_layer_cache_count': 1,
      '99th_percentile_layer_cache_count': 1,
      'worst_layer_cache_count': 1,
      'average_layer_cache_memory': 1,
      '90th_percentile_layer_cache_memory': 1,
      '99th_percentile_layer_cache_memory': 1,
      'worst_layer_cache_memory': 1,
      'average_picture_cache_count': 1,
      '90th_percentile_picture_cache_count': 1,
      '99th_percentile_picture_cache_count': 1,
      'worst_picture_cache_count': 1,
      'average_picture_cache_memory': 1,
      '90th_percentile_picture_cache_memory': 1,
      '99th_percentile_picture_cache_memory': 1,
      'worst_picture_cache_memory': 1,
      'total_ui_gc_time': 1,
      'new_gen_gc_count': 1,
      'old_gen_gc_count': 1,
      'average_vsync_transitions_missed': 1,
      '90th_percentile_vsync_transitions_missed': 1,
      '99th_percentile_vsync_transitions_missed': 1,
      'average_frame_request_pending_latency': 0.1,
      '90th_percentile_frame_request_pending_latency': 0.1,
      '99th_percentile_frame_request_pending_latency': 0.1,
    };
    const resultFileName = 'fake_result';
    void driveCallback(List<String> arguments) {
      final resultFile = File('$perfTestOutputPath/$resultFileName.json')
        ..createSync(recursive: true);
      resultFile.writeAsStringSync(json.encode(fakeData));
    }

    final perfTest = PerfTest(
      testDirectory.absolute.path,
      testTarget.absolute.path,
      'test_file',
      resultFilename: resultFileName,
      device: device,
      flutterDriveCallback: driveCallback,
    );
    final TaskResult result = await perfTest.run();
    expect(result.data!['frame_count'], 5);
  });

  test(
    'runs perf tests, successfully parse refresh rate percentage key-values from data`',
    () async {
      final fakeData = <String, dynamic>{
        'frame_count': 5,
        'average_frame_build_time_millis': 0.1,
        'worst_frame_build_time_millis': 0.1,
        '90th_percentile_frame_build_time_millis': 0.1,
        '99th_percentile_frame_build_time_millis': 0.1,
        'average_frame_rasterizer_time_millis': 0.1,
        'worst_frame_rasterizer_time_millis': 0.1,
        '90th_percentile_frame_rasterizer_time_millis': 0.1,
        '99th_percentile_frame_rasterizer_time_millis': 0.1,
        'average_layer_cache_count': 1,
        '90th_percentile_layer_cache_count': 1,
        '99th_percentile_layer_cache_count': 1,
        'worst_layer_cache_count': 1,
        'average_layer_cache_memory': 1,
        '90th_percentile_layer_cache_memory': 1,
        '99th_percentile_layer_cache_memory': 1,
        'worst_layer_cache_memory': 1,
        'average_picture_cache_count': 1,
        '90th_percentile_picture_cache_count': 1,
        '99th_percentile_picture_cache_count': 1,
        'worst_picture_cache_count': 1,
        'average_picture_cache_memory': 1,
        '90th_percentile_picture_cache_memory': 1,
        '99th_percentile_picture_cache_memory': 1,
        'worst_picture_cache_memory': 1,
        'total_ui_gc_time': 1,
        'new_gen_gc_count': 1,
        'old_gen_gc_count': 1,
        'average_vsync_transitions_missed': 1,
        '90th_percentile_vsync_transitions_missed': 1,
        '99th_percentile_vsync_transitions_missed': 1,
        '30hz_frame_percentage': 0.1,
        '60hz_frame_percentage': 0.2,
        '80hz_frame_percentage': 0.3,
        '90hz_frame_percentage': 0.4,
        '120hz_frame_percentage': 0.6,
        'illegal_refresh_rate_frame_count': 10,
        'average_frame_request_pending_latency': 0.1,
        '90th_percentile_frame_request_pending_latency': 0.1,
        '99th_percentile_frame_request_pending_latency': 0.1,
      };
      const resultFileName = 'fake_result';
      void driveCallback(List<String> arguments) {
        final resultFile = File('$perfTestOutputPath/$resultFileName.json')
          ..createSync(recursive: true);
        resultFile.writeAsStringSync(json.encode(fakeData));
      }

      final perfTest = PerfTest(
        testDirectory.absolute.path,
        testTarget.absolute.path,
        'test_file',
        resultFilename: resultFileName,
        device: device,
        flutterDriveCallback: driveCallback,
      );
      final TaskResult result = await perfTest.run();
      expect(result.data!['30hz_frame_percentage'], 0.1);
      expect(result.data!['60hz_frame_percentage'], 0.2);
      expect(result.data!['80hz_frame_percentage'], 0.3);
      expect(result.data!['90hz_frame_percentage'], 0.4);
      expect(result.data!['120hz_frame_percentage'], 0.6);
      expect(result.data!['illegal_refresh_rate_frame_count'], 10);
    },
  );

  test('reports Impeller shader warmup metrics when they are in the data', () async {
    final fakeData = <String, dynamic>{
      'frame_count': 5,
      'average_frame_build_time_millis': 0.1,
      'worst_frame_build_time_millis': 0.1,
      '90th_percentile_frame_build_time_millis': 0.1,
      '99th_percentile_frame_build_time_millis': 0.1,
      'average_frame_rasterizer_time_millis': 0.1,
      'worst_frame_rasterizer_time_millis': 0.1,
      '90th_percentile_frame_rasterizer_time_millis': 0.1,
      '99th_percentile_frame_rasterizer_time_millis': 0.1,
      'old_gen_gc_count': 1,
      'total_ui_gc_time': 1,
      'average_vsync_transitions_missed': 1,
      '90th_percentile_vsync_transitions_missed': 1,
      '99th_percentile_vsync_transitions_missed': 1,
      'shader_warmed_draw_percent': 92.65,
      'shader_lazy_variants': 20,
      'shader_warmed_never_drawn_variants': 3,
    };
    const resultFileName = 'fake_result';
    void driveCallback(List<String> arguments) {
      final resultFile = File('$perfTestOutputPath/$resultFileName.json')
        ..createSync(recursive: true);
      resultFile.writeAsStringSync(json.encode(fakeData));
    }

    final perfTest = PerfTest(
      testDirectory.absolute.path,
      testTarget.absolute.path,
      'test_file',
      resultFilename: resultFileName,
      device: device,
      flutterDriveCallback: driveCallback,
    );
    final TaskResult result = await perfTest.run();
    expect(
      result.benchmarkScoreKeys,
      containsAll(<String>[
        'shader_warmed_draw_percent',
        'shader_lazy_variants',
        'shader_warmed_never_drawn_variants',
      ]),
    );
  });

  const initialManifest = '''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application>
        <meta-data
            android:name="flutterEmbedding"
            android:value="2" />
    </application>
</manifest>
''';

  Future<({String manifest, TaskResult result})> runPerfTestAndReadManifest({
    required DeviceOperatingSystem os,
    bool? enableImpeller,
    bool? forceOpenGLES,
    bool enableVulkanGPUTracing = true,
    bool isE2e = false,
  }) async {
    deviceOperatingSystem = os;
    addTearDown(() {
      deviceOperatingSystem = DeviceOperatingSystem.fake;
    });

    final manifestFile =
        File('${testDirectory.absolute.path}/android/app/src/main/AndroidManifest.xml')
          ..createSync(recursive: true)
          ..writeAsStringSync(initialManifest);

    final fakeData = <String, dynamic>{
      'frame_count': 5,
      'average_frame_build_time_millis': 0.1,
      'worst_frame_build_time_millis': 0.1,
      '90th_percentile_frame_build_time_millis': 0.1,
      '99th_percentile_frame_build_time_millis': 0.1,
      'average_frame_rasterizer_time_millis': 0.1,
      'worst_frame_rasterizer_time_millis': 0.1,
      '90th_percentile_frame_rasterizer_time_millis': 0.1,
      '99th_percentile_frame_rasterizer_time_millis': 0.1,
      'old_gen_gc_count': 1,
      'total_ui_gc_time': 1,
      'average_vsync_transitions_missed': 1,
      '90th_percentile_vsync_transitions_missed': 1,
      '99th_percentile_vsync_transitions_missed': 1,
      'average_gpu_frame_time': 1.2,
      'worst_gpu_frame_time': 2.4,
    };
    const resultFileName = 'fake_result';
    String? manifestDuringDrive;
    void driveCallback(List<String> arguments) {
      manifestDuringDrive = manifestFile.readAsStringSync();
      final resultFile = File('$perfTestOutputPath/$resultFileName.json')
        ..createSync(recursive: true);
      resultFile.writeAsStringSync(json.encode(fakeData));
    }

    final perfTest = isE2e
        ? PerfTest.e2e(
            testDirectory.absolute.path,
            testTarget.absolute.path,
            resultFilename: resultFileName,
            device: device,
            flutterDriveCallback: driveCallback,
            enableImpeller: enableImpeller,
            forceOpenGLES: forceOpenGLES,
          )
        : PerfTest(
            testDirectory.absolute.path,
            testTarget.absolute.path,
            'test_file',
            resultFilename: resultFileName,
            device: device,
            flutterDriveCallback: driveCallback,
            enableImpeller: enableImpeller,
            forceOpenGLES: forceOpenGLES,
            enableVulkanGPUTracing: enableVulkanGPUTracing,
          );
    final TaskResult result = await perfTest.run();
    return (manifest: manifestDuringDrive!, result: result);
  }

  test('enables Vulkan GPU tracing in AndroidManifest by default on Android', () async {
    for (final os in <DeviceOperatingSystem>[
      DeviceOperatingSystem.android,
      DeviceOperatingSystem.androidArm,
      DeviceOperatingSystem.androidArm64,
    ]) {
      final (:String manifest, :TaskResult result) = await runPerfTestAndReadManifest(os: os);
      expect(
        manifest,
        contains('android:name="io.flutter.embedding.android.EnableVulkanGPUTracing"'),
      );
      expect(
        result.benchmarkScoreKeys,
        containsAll(<String>['average_gpu_frame_time', 'worst_gpu_frame_time']),
      );
    }
  });

  test('skips Vulkan GPU tracing when enableImpeller is false on Android', () async {
    final (:String manifest, :TaskResult result) = await runPerfTestAndReadManifest(
      os: DeviceOperatingSystem.android,
      enableImpeller: false,
    );
    expect(manifest, equals(initialManifest));
    expect(
      result.benchmarkScoreKeys,
      isNot(anyOf(contains('average_gpu_frame_time'), contains('worst_gpu_frame_time'))),
    );
  });

  test('skips Vulkan GPU tracing when enableVulkanGPUTracing is false on Android', () async {
    final (:String manifest, :TaskResult result) = await runPerfTestAndReadManifest(
      os: DeviceOperatingSystem.android,
      enableVulkanGPUTracing: false,
    );
    expect(manifest, equals(initialManifest));
    expect(
      result.benchmarkScoreKeys,
      isNot(anyOf(contains('average_gpu_frame_time'), contains('worst_gpu_frame_time'))),
    );
  });

  test('skips Vulkan GPU tracing when forceOpenGLES is true on Android', () async {
    final (:String manifest, :TaskResult result) = await runPerfTestAndReadManifest(
      os: DeviceOperatingSystem.android,
      enableImpeller: true,
      forceOpenGLES: true,
    );
    expect(
      manifest,
      isNot(contains('android:name="io.flutter.embedding.android.EnableVulkanGPUTracing"')),
    );
    expect(
      manifest,
      contains('android:name="io.flutter.embedding.android.EnableOpenGLGPUTracing"'),
    );
    expect(
      result.benchmarkScoreKeys,
      containsAll(<String>['average_gpu_frame_time', 'worst_gpu_frame_time']),
    );
  });

  test('skips Vulkan GPU tracing by default on PerfTest.e2e', () async {
    final (:String manifest, :TaskResult result) = await runPerfTestAndReadManifest(
      os: DeviceOperatingSystem.android,
      enableImpeller: true,
      isE2e: true,
    );
    expect(manifest, equals(initialManifest));
    expect(result.succeeded, isTrue);
  });

  test('skips AndroidManifest edits on non-Android even when enableImpeller is true', () async {
    final (:String manifest, :TaskResult result) = await runPerfTestAndReadManifest(
      os: DeviceOperatingSystem.ios,
      enableImpeller: true,
    );
    expect(manifest, equals(initialManifest));
    expect(
      result.benchmarkScoreKeys,
      containsAll(<String>['average_gpu_frame_time', 'worst_gpu_frame_time']),
    );
  });

  test('MemoryTest.handleLogcatLine ignores duplicate benchmark markers', () async {
    final memoryTest = MemoryTest('project', 'test', 'package');
    memoryTest.prepareForNextMessage('TAPPED');

    memoryTest.handleLogcatLine('I/flutter: ==== MEMORY BENCHMARK ==== TAPPED ====');
    await memoryTest.receivedNextMessage;

    // A duplicate marker must not throw a StateError ('Future already completed').
    memoryTest.handleLogcatLine('I/flutter: ==== MEMORY BENCHMARK ==== TAPPED ====');
  });

  test('MemoryTest.tapNotification taps once when TAPPED is received on first tap', () async {
    late _TestMemoryTest memoryTest;
    var tapCalls = 0;
    final tapDevice = _TapRecordingFakeDevice(
      onTap: (int x, int y) async {
        tapCalls += 1;
        memoryTest.handleLogcatLine('I/flutter: ==== MEMORY BENCHMARK ==== TAPPED ====');
      },
    );
    memoryTest = _TestMemoryTest(tapDevice);

    await memoryTest.tapNotification();
    expect(tapCalls, 1);
  });

  test('MemoryTest.tapNotification retries sequentially when initial tap is dropped', () async {
    late _TestMemoryTest memoryTest;
    var tapCalls = 0;
    final tapDevice = _TapRecordingFakeDevice(
      onTap: (int x, int y) async {
        tapCalls += 1;
        if (tapCalls == 2) {
          memoryTest.handleLogcatLine('I/flutter: ==== MEMORY BENCHMARK ==== TAPPED ====');
        }
      },
    );
    memoryTest = _TestMemoryTest(tapDevice);

    await memoryTest.tapNotification();
    expect(tapCalls, 2);
  });
}

class _TapRecordingFakeDevice extends FakeDevice {
  const _TapRecordingFakeDevice({required this.onTap}) : super(deviceId: 'fakeDeviceId');

  final Future<void> Function(int x, int y) onTap;

  @override
  Future<void> tap(int x, int y) => onTap(x, y);
}

class _TestMemoryTest extends MemoryTest {
  _TestMemoryTest(this.device) : super('project', 'test', 'package', requiresTapToStart: true);

  @override
  final Device device;
}
