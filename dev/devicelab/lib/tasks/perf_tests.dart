// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createComplexLayoutScrollPerfTest() {
  return new PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
  ).run;
}

TaskFunction createComplexLayoutScrollMemoryTest() {
  return new MemoryTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'com.yourcompany.complexLayout',
    testTarget: 'test_driver/scroll_perf.dart',
  ).run;
}

TaskFunction createFlutterGalleryStartupTest() {
  return new StartupTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
  ).run;
}

TaskFunction createComplexLayoutStartupTest() {
  return new StartupTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
  ).run;
}

TaskFunction createFlutterGalleryCompileTest() {
  return new CompileTest('${flutterDirectory.path}/examples/flutter_gallery').run;
}

TaskFunction createComplexLayoutCompileTest() {
  return new CompileTest('${flutterDirectory.path}/dev/benchmarks/complex_layout').run;
}

TaskFunction createHelloWorldMemoryTest() {
  return new MemoryTest(
    '${flutterDirectory.path}/examples/hello_world',
    'io.flutter.examples.hello_world',
  ).run;
}

TaskFunction createGalleryNavigationMemoryTest() {
  return new MemoryTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    'io.flutter.demo.gallery',
    testTarget: 'test_driver/memory_nav.dart',
  ).run;
}

TaskFunction createGalleryBackButtonMemoryTest() {
  return new AndroidBackButtonMemoryTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    'io.flutter.demo.gallery',
    'io.flutter.demo.gallery.MainActivity',
  ).run;
}

TaskFunction createFlutterViewStartupTest() {
  return new StartupTest(
      '${flutterDirectory.path}/examples/flutter_view',
      reportMetrics: false,
  ).run;
}

TaskFunction createBasicMaterialCompileTest() {
  return () async {
    const String sampleAppName = 'sample_flutter_app';
    final Directory sampleDir = dir('${Directory.systemTemp.path}/$sampleAppName');

    if (await sampleDir.exists())
      rmTree(sampleDir);

    await inDirectory(Directory.systemTemp, () async {
      await flutter('create', options: <String>[sampleAppName]);
    });

    if (!(await sampleDir.exists()))
      throw 'Failed to create default Flutter app in ${sampleDir.path}';

    return new CompileTest(sampleDir.path).run();
  };
}


/// Measure application startup performance.
class StartupTest {
  static const Duration _startupTimeout = const Duration(minutes: 5);

  const StartupTest(this.testDirectory, { this.reportMetrics: true });

  final String testDirectory;
  final bool reportMetrics;

  Future<TaskResult> run() async {
    return await inDirectory(testDirectory, () async {
      final String deviceId = (await devices.workingDevice).deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(testDirectory);

      await flutter('run', options: <String>[
        '--verbose',
        '--profile',
        '--trace-startup',
        '-d',
        deviceId,
      ]).timeout(_startupTimeout);
      final Map<String, dynamic> data = json.decode(file('$testDirectory/build/start_up_info.json').readAsStringSync());

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
  const PerfTest(this.testDirectory, this.testTarget, this.timelineFileName);

  final String testDirectory;
  final String testTarget;
  final String timelineFileName;

  Future<TaskResult> run() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(testDirectory);

      await flutter('drive', options: <String>[
        '-v',
        '--profile',
        '--trace-startup', // Enables "endless" timeline event buffering.
        '-t',
        testTarget,
        '-d',
        deviceId,
      ]);
      final Map<String, dynamic> data = json.decode(file('$testDirectory/build/$timelineFileName.timeline_summary.json').readAsStringSync());

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

/// Measures how long it takes to compile a Flutter app and how big the compiled
/// code is.
class CompileTest {
  const CompileTest(this.testDirectory);

  final String testDirectory;

  Future<TaskResult> run() async {
    return await inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      final Map<String, dynamic> metrics = <String, dynamic>{}
        ..addAll(await _compileAot())
        ..addAll(await _compileApp())
        ..addAll(await _compileDebug())
        ..addAll(_suffix(await _compileAot(previewDart2: true), '__preview_dart_2'))
        ..addAll(_suffix(await _compileApp(previewDart2: true), '__preview_dart_2'))
        ..addAll(_suffix(await _compileDebug(previewDart2: true), '__preview_dart_2'));

      return new TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
    });
  }

  static Map<String, dynamic> _suffix(Map<String, dynamic> map, String suffix) {
    return new Map<String, dynamic>.fromIterables(
      map.keys.map<String>((String key) => '$key$suffix'),
      map.values,
    );
  }

  static Future<Map<String, dynamic>> _compileAot({ bool previewDart2: false }) async {
    // Generate blobs instead of assembly.
    await flutter('clean');
    final Stopwatch watch = new Stopwatch()..start();
    final List<String> options = <String>[
      'aot',
      '-v',
      '--release',
      '--no-pub',
      '--target-platform',
    ];
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.add('ios');
        break;
      case DeviceOperatingSystem.android:
        options.add('android-arm');
        break;
    }
    if (previewDart2)
      options.add('--preview-dart-2');
    setLocalEngineOptionIfNecessary(options);
    final String compileLog = await evalFlutter('build', options: options);
    watch.stop();

    final RegExp metricExpression = new RegExp(r'([a-zA-Z]+)\(CodeSize\)\: (\d+)');
    final Map<String, dynamic> metrics = <String, dynamic>{};
    for (Match m in metricExpression.allMatches(compileLog)) {
      metrics[_sdkNameToMetricName(m.group(1))] = int.parse(m.group(2));
    }
    metrics['aot_snapshot_compile_millis'] = watch.elapsedMilliseconds;

    return metrics;
  }

  static Future<Map<String, dynamic>> _compileApp({ bool previewDart2: false }) async {
    await flutter('clean');
    final Stopwatch watch = new Stopwatch();
    int releaseSizeInBytes;
    final List<String> options = <String>['--release'];
    if (previewDart2)
      options.add('--preview-dart-2');
    setLocalEngineOptionIfNecessary(options);
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.insert(0, 'ios');
        await prepareProvisioningCertificates(cwd);
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        // IPAs are created manually AFAICT
        await exec('tar', <String>['-zcf', 'build/app.ipa', 'build/ios/Release-iphoneos/Runner.app/']);
        releaseSizeInBytes = await file('$cwd/build/app.ipa').length();
        break;
      case DeviceOperatingSystem.android:
        options.insert(0, 'apk');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        File apk = file('$cwd/build/app/outputs/apk/app.apk');
        if (!apk.existsSync()) {
          // Pre Android SDK 26 path
          apk = file('$cwd/build/app/outputs/apk/app-release.apk');
        }
        releaseSizeInBytes = apk.lengthSync();
        break;
    }

    return <String, dynamic>{
      'release_full_compile_millis': watch.elapsedMilliseconds,
      'release_size_bytes': releaseSizeInBytes,
    };
  }

  static Future<Map<String, dynamic>> _compileDebug({ bool previewDart2: false }) async {
    await flutter('clean');
    final Stopwatch watch = new Stopwatch();
    final List<String> options = <String>['--debug'];
    if (previewDart2)
      options.add('--preview-dart-2');
    setLocalEngineOptionIfNecessary(options);
    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.insert(0, 'ios');
        await prepareProvisioningCertificates(cwd);
        break;
      case DeviceOperatingSystem.android:
        options.insert(0, 'apk');
        break;
    }
    watch.start();
    await flutter('build', options: options);
    watch.stop();

    return <String, dynamic>{
      'debug_full_compile_millis': watch.elapsedMilliseconds,
    };
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
  const MemoryTest(this.testDirectory, this.packageName, { this.testTarget });

  final String testDirectory;
  final String packageName;

  /// Path to a flutter driver script that will run after starting the app.
  ///
  /// If not specified, then the test will start the app, gather statistics, and then exit.
  final String testTarget;

  Future<TaskResult> run() {
    return inDirectory(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      final String deviceId = device.deviceId;
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(testDirectory);

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
  const AndroidBackButtonMemoryTest(this.testDirectory, this.packageName, this.activityName);

  final String testDirectory;
  final String packageName;
  final String activityName;

  Future<TaskResult> run() {
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
        final String output = await device.shellEval('am', <String>['start', '-n', '$packageName/$activityName']);
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
