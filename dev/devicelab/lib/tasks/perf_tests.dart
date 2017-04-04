// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show JSON;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';


TaskFunction createPlatformServiceDriverTest() {
  return new DriverTest(
      '${flutterDirectory.path}/examples/platform_channel',
      'test_driver/button_tap.dart',
  );
}

TaskFunction createComplexLayoutScrollPerfTest() {
  return new PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
  );
}

TaskFunction createComplexLayoutScrollMemoryTest() {
  return new MemoryTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'com.yourcompany.complexLayout',
    testTarget: 'test_driver/scroll_perf.dart',
  );
}

TaskFunction createFlutterGalleryStartupTest() {
  return new StartupTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
  );
}

TaskFunction createComplexLayoutStartupTest() {
  return new StartupTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
  );
}

TaskFunction createFlutterGalleryBuildTest() {
  return new BuildTest('${flutterDirectory.path}/examples/flutter_gallery');
}

TaskFunction createComplexLayoutBuildTest() {
  return new BuildTest('${flutterDirectory.path}/dev/benchmarks/complex_layout');
}

TaskFunction createHelloWorldMemoryTest() {
  return new MemoryTest(
    '${flutterDirectory.path}/examples/hello_world',
    'io.flutter.examples.HelloWorld',
  );
}

TaskFunction createGalleryNavigationMemoryTest() {
  return new MemoryTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    'io.flutter.examples.gallery',
    testTarget: 'test_driver/memory_nav.dart',
  );
}

TaskFunction createGalleryBackButtonMemoryTest() {
  return new AndroidBackButtonMemoryTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    'io.flutter.examples.gallery',
  );
}

TaskFunction createFlutterViewStartupTest() {
  return new StartupTest(
      '${flutterDirectory.path}/examples/flutter_view',
      reportMetrics: false,
  );
}

/// Measure application startup performance.
class StartupTest {
  static const Duration _startupTimeout = const Duration(minutes: 5);

  StartupTest(this.testDirectory, { this.reportMetrics: true });

  final String testDirectory;
  final bool reportMetrics;

  Future<TaskResult> call() async {
    return await inDirectory(testDirectory, () async {
      final String deviceId = (await devices.workingDevice).deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
        await prepareProvisioningCertificates(testDirectory);
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('run', options: <String>[
        '--verbose',
        '--profile',
        '--trace-startup',
        '-d',
        deviceId,
      ]).timeout(_startupTimeout);
      final Map<String, dynamic> data = JSON.decode(file('$testDirectory/build/start_up_info.json').readAsStringSync());

      if (!reportMetrics)
        return new TaskResult.success(data);

      return new TaskResult.success(data, benchmarkScoreKeys: <String>[
        'timeToFirstFrameMicros',
      ]);
    });
  }
}

/// Measures application runtime performance, specifically per-frame
/// performance.
class PerfTest {

  PerfTest(this.testDirectory, this.testTarget, this.timelineFileName);

  final String testDirectory;
  final String testTarget;
  final String timelineFileName;

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
        await prepareProvisioningCertificates(testDirectory);
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('drive', options: <String>[
        '-v',
        '--profile',
        '--trace-startup', // Enables "endless" timeline event buffering.
        '-t',
        testTarget,
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = JSON.decode(file('$testDirectory/build/$timelineFileName.timeline_summary.json').readAsStringSync());

      if (data['frame_count'] < 5) {
        return new TaskResult.failure(
          'Timeline contains too few frames: ${data['frame_count']}. Possibly '
          'trace events are not being captured.',
        );
      }

      return new TaskResult.success(data, benchmarkScoreKeys: <String>[
        'average_frame_build_time_millis',
        'worst_frame_build_time_millis',
        'missed_frame_build_budget_count',
        'average_frame_rasterizer_time_millis',
        'worst_frame_rasterizer_time_millis',
        'missed_frame_rasterizer_budget_count',
      ]);
    });
  }
}


class DriverTest {

  DriverTest(this.testDirectory, this.testTarget);

  final String testDirectory;
  final String testTarget;

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
        await prepareProvisioningCertificates(testDirectory);
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      await flutter('drive', options: <String>[
        '-v',
        '-t',
        testTarget,
        '-d',
        deviceId,
      ]);

      return new TaskResult.success(null);
    });
  }
}

class BuildTest {

  BuildTest(this.testDirectory);

  final String testDirectory;

  Future<TaskResult> call() async {
    return await inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      final Stopwatch watch = new Stopwatch()..start();
      final String buildLog = await evalFlutter('build', options: <String>[
        'aot',
        '-v',
        '--profile',
        '--no-pub',
        '--target-platform', 'android-arm'  // Generate blobs instead of assembly.
      ]);
      watch.stop();

      final RegExp metricExpression = new RegExp(r'([a-zA-Z]+)\(CodeSize\)\: (\d+)');

      final Map<String, dynamic> data = new Map<String, dynamic>.fromIterable(
        metricExpression.allMatches(buildLog),
        key: (Match m) => _sdkNameToMetricName(m.group(1)),
        value: (Match m) => int.parse(m.group(2)),
      );
      data['aot_snapshot_build_millis'] = watch.elapsedMilliseconds;

      return new TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
    });
  }

  static String _sdkNameToMetricName(String sdkName) {
    const Map<String, String> kSdkNameToMetricNameMapping = const <String, String> {
      'VMIsolate': 'aot_snapshot_size_vmisolate',
      'Isolate': 'aot_snapshot_size_isolate',
      'ReadOnlyData': 'aot_snapshot_size_rodata',
      'Instructions': 'aot_snapshot_size_instructions',
      'Total': 'aot_snapshot_size_total',
    };

    if (!kSdkNameToMetricNameMapping.containsKey(sdkName))
      throw 'Unrecognized SDK snapshot metric name: $sdkName';

    return kSdkNameToMetricNameMapping[sdkName];
  }
}

/// Measure application memory usage.
class MemoryTest {
  MemoryTest(this.testDirectory, this.packageName, { this.testTarget });

  final String testDirectory;
  final String packageName;

  /// Path to a flutter driver script that will run after starting the app.
  ///
  /// If not specified, then the test will start the app, gather statistics, and then exit.
  final String testTarget;

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios) {
        await prepareProvisioningCertificates(testDirectory);
        // This causes an Xcode project to be created.
        await flutter('build', options: <String>['ios', '--profile']);
      }

      final int observatoryPort = await findAvailablePort();

      final List<String> runOptions = <String>[
        '-v',
        '--profile',
        '--trace-startup', // wait for the first frame to render
        '-d',
        deviceId,
        '--observatory-port',
        observatoryPort.toString(),
      ];
      if (testTarget != null)
        runOptions.addAll(<String>['-t', testTarget]);
      await flutter('run', options: runOptions);

      final Map<String, dynamic> startData = await device.getMemoryStats(packageName);

      final Map<String, dynamic> data = <String, dynamic>{
         'start_total_kb': startData['total_kb'],
      };

      if (testTarget != null) {
        await flutter('drive', options: <String>[
          '-v',
          '-t',
          testTarget,
          '-d',
          deviceId,
          '--use-existing-app=http://localhost:$observatoryPort',
        ]);

        final Map<String, dynamic> endData = await device.getMemoryStats(packageName);
        data['end_total_kb'] = endData['total_kb'];
        data['diff_total_kb'] = endData['total_kb'] - startData['total_kb'];
      }

      await device.stop(packageName);

      return new TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
    });
  }
}

/// Measure application memory usage after pausing and resuming the app
/// with the Android back button.
class AndroidBackButtonMemoryTest {
  final String testDirectory;
  final String packageName;

  AndroidBackButtonMemoryTest(this.testDirectory, this.packageName);

  Future<TaskResult> call() {
    return inDirectory(testDirectory, () async {
      if (deviceOperatingSystem != DeviceOperatingSystem.android) {
        throw 'This test is only supported on Android';
      }

      final AndroidDevice device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      await flutter('run', options: <String>[
        '-v',
        '--profile',
        '--trace-startup', // wait for the first frame to render
        '-d',
        deviceId,
      ]);

      final Map<String, dynamic> startData = await device.getMemoryStats(packageName);

      final Map<String, dynamic> data = <String, dynamic>{
         'start_total_kb': startData['total_kb'],
      };

      // Perform a series of back button suspend and resume cycles.
      for (int i = 0; i < 10; i++) {
        await device.shellExec('input', <String>['keyevent', 'KEYCODE_BACK']);
        await new Future<Null>.delayed(const Duration(milliseconds: 1000));
        final String output = await device.shellEval('am', <String>['start', '-n', 'io.flutter.examples.gallery/io.flutter.app.FlutterActivity']);
        print(output);
        if (output.contains('Error'))
          return new TaskResult.failure('unable to launch activity');
        await new Future<Null>.delayed(const Duration(milliseconds: 1000));
      }

      final Map<String, dynamic> endData = await device.getMemoryStats(packageName);
      data['end_total_kb'] = endData['total_kb'];
      data['diff_total_kb'] = endData['total_kb'] - startData['total_kb'];

      await device.stop(packageName);

      return new TaskResult.success(data, benchmarkScoreKeys: data.keys.toList());
    });
  }
}
