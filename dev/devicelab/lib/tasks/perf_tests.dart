// Copyright (c) 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert' show json;
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/ios.dart';
import '../framework/utils.dart';

TaskFunction createComplexLayoutScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'complex_layout_scroll_perf',
  ).run;
}

TaskFunction createTilesScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
    'test_driver/scroll_perf.dart',
    'tiles_scroll_perf',
  ).run;
}

TaskFunction createHomeScrollPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
    'test_driver/scroll_perf.dart',
    'home_scroll_perf',
  ).run;
}

TaskFunction createCullOpacityPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/cull_opacity_perf.dart',
    'cull_opacity_perf',
  ).run;
}

TaskFunction createCubicBezierPerfTest() {
  return PerfTest(
    '${flutterDirectory.path}/dev/benchmarks/macrobenchmarks',
    'test_driver/cubic_bezier_perf.dart',
    'cubic_bezier_perf',
  ).run;
}

TaskFunction createFlutterGalleryStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/examples/flutter_gallery',
  ).run;
}

TaskFunction createComplexLayoutStartupTest() {
  return StartupTest(
    '${flutterDirectory.path}/dev/benchmarks/complex_layout',
  ).run;
}

TaskFunction createFlutterGalleryCompileTest() {
  return CompileTest('${flutterDirectory.path}/examples/flutter_gallery').run;
}

TaskFunction createHelloWorldCompileTest() {
  return CompileTest('${flutterDirectory.path}/examples/hello_world', reportPackageContentSizes: true).run;
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

    if (!(await sampleDir.exists()))
      throw 'Failed to create default Flutter app in ${sampleDir.path}';

    return CompileTest(sampleDir.path).run();
  };
}


/// Measure application startup performance.
class StartupTest {
  const StartupTest(this.testDirectory, { this.reportMetrics = true });

  final String testDirectory;
  final bool reportMetrics;

  Future<TaskResult> run() async {
    return await inDirectory<TaskResult>(testDirectory, () async {
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
      ]);
      final Map<String, dynamic> data = json.decode(file('$testDirectory/build/start_up_info.json').readAsStringSync());

      if (!reportMetrics)
        return TaskResult.success(data);

      return TaskResult.success(data, benchmarkScoreKeys: <String>[
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
    return inDirectory<TaskResult>(testDirectory, () async {
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
        return TaskResult.failure(
          'Timeline contains too few frames: ${data['frame_count']}. Possibly '
          'trace events are not being captured.',
        );
      }

      return TaskResult.success(data, benchmarkScoreKeys: <String>[
        'average_frame_build_time_millis',
        'worst_frame_build_time_millis',
        'missed_frame_build_budget_count',
        '90th_percentile_frame_build_time_millis',
        '99th_percentile_frame_build_time_millis',
        'average_frame_rasterizer_time_millis',
        'worst_frame_rasterizer_time_millis',
        'missed_frame_rasterizer_budget_count',
        '90th_percentile_frame_rasterizer_time_millis',
        '99th_percentile_frame_rasterizer_time_millis',
      ]);
    });
  }
}

/// Measures how long it takes to compile a Flutter app and how big the compiled
/// code is.
class CompileTest {
  const CompileTest(this.testDirectory, { this.reportPackageContentSizes = false });

  final String testDirectory;
  final bool reportPackageContentSizes;

  Future<TaskResult> run() async {
    return await inDirectory<TaskResult>(testDirectory, () async {
      final Device device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      final Map<String, dynamic> metrics = <String, dynamic>{}
        ..addAll(await _compileAot())
        ..addAll(await _compileApp(reportPackageContentSizes: reportPackageContentSizes))
        ..addAll(await _compileDebug());

      return TaskResult.success(metrics, benchmarkScoreKeys: metrics.keys.toList());
    });
  }

  static Future<Map<String, dynamic>> _compileAot() async {
    // Generate blobs instead of assembly.
    await flutter('clean');
    final Stopwatch watch = Stopwatch()..start();
    final List<String> options = <String>[
      'aot',
      '-v',
      '--extra-gen-snapshot-options=--print_snapshot_sizes',
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
    setLocalEngineOptionIfNecessary(options);
    final String compileLog = await evalFlutter('build', options: options);
    watch.stop();

    final RegExp metricExpression = RegExp(r'([a-zA-Z]+)\(CodeSize\)\: (\d+)');
    final Map<String, dynamic> metrics = <String, dynamic>{};
    for (Match m in metricExpression.allMatches(compileLog)) {
      metrics[_sdkNameToMetricName(m.group(1))] = int.parse(m.group(2));
    }
    if (metrics.length != _kSdkNameToMetricNameMapping.length) {
      throw 'Expected metrics: ${_kSdkNameToMetricNameMapping.keys}, but got: ${metrics.keys}.';
    }
    metrics['aot_snapshot_compile_millis'] = watch.elapsedMilliseconds;

    return metrics;
  }

  static Future<Map<String, dynamic>> _compileApp({ bool reportPackageContentSizes = false }) async {
    await flutter('clean');
    final Stopwatch watch = Stopwatch();
    int releaseSizeInBytes;
    final List<String> options = <String>['--release'];
    setLocalEngineOptionIfNecessary(options);
    final Map<String, dynamic> metrics = <String, dynamic>{};

    switch (deviceOperatingSystem) {
      case DeviceOperatingSystem.ios:
        options.insert(0, 'ios');
        await prepareProvisioningCertificates(cwd);
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        final String appPath =  '$cwd/build/ios/Release-iphoneos/Runner.app/';
        // IPAs are created manually, https://flutter.dev/ios-release/
        await exec('tar', <String>['-zcf', 'build/app.ipa', appPath]);
        releaseSizeInBytes = await file('$cwd/build/app.ipa').length();
        if (reportPackageContentSizes)
          metrics.addAll(await getSizesFromIosApp(appPath));
        break;
      case DeviceOperatingSystem.android:
        options.insert(0, 'apk');
        watch.start();
        await flutter('build', options: options);
        watch.stop();
        String apkPath = '$cwd/build/app/outputs/apk/app.apk';
        File apk = file(apkPath);
        if (!apk.existsSync()) {
          // Pre Android SDK 26 path
          apkPath = '$cwd/build/app/outputs/apk/app-release.apk';
          apk = file(apkPath);
        }
        releaseSizeInBytes = apk.lengthSync();
        if (reportPackageContentSizes)
          metrics.addAll(await getSizesFromApk(apkPath));
        break;
    }

    metrics.addAll(<String, dynamic>{
      'release_full_compile_millis': watch.elapsedMilliseconds,
      'release_size_bytes': releaseSizeInBytes,
    });

    return metrics;
  }

  static Future<Map<String, dynamic>> _compileDebug() async {
    await flutter('clean');
    final Stopwatch watch = Stopwatch();
    final List<String> options = <String>['--debug'];
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

  static const Map<String, String> _kSdkNameToMetricNameMapping = <String, String> {
    'VMIsolate': 'aot_snapshot_size_vmisolate',
    'Isolate': 'aot_snapshot_size_isolate',
    'ReadOnlyData': 'aot_snapshot_size_rodata',
    'Instructions': 'aot_snapshot_size_instructions',
    'Total': 'aot_snapshot_size_total',
  };

  static String _sdkNameToMetricName(String sdkName) {

    if (!_kSdkNameToMetricNameMapping.containsKey(sdkName))
      throw 'Unrecognized SDK snapshot metric name: $sdkName';

    return _kSdkNameToMetricNameMapping[sdkName];
  }

  static Future<Map<String, dynamic>> getSizesFromIosApp(String appPath) async {
    // Thin the binary to only contain one architecture.
    final String xcodeBackend = path.join(flutterDirectory.path, 'packages', 'flutter_tools', 'bin', 'xcode_backend.sh');
    await exec(xcodeBackend, <String>['thin'], environment: <String, String>{
      'ARCHS': 'arm64',
      'WRAPPER_NAME': path.basename(appPath),
      'TARGET_BUILD_DIR': path.dirname(appPath),
    });

    final File appFramework = File(path.join(appPath, 'Frameworks', 'App.framework', 'App'));
    final File flutterFramework = File(path.join(appPath, 'Frameworks', 'Flutter.framework', 'Flutter'));

    return <String, dynamic>{
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

    final _UnzipListEntry libflutter = fileToMetadata['lib/armeabi-v7a/libflutter.so'];
    final _UnzipListEntry isolateSnapshotData = fileToMetadata['assets/isolate_snapshot_data'];
    final _UnzipListEntry isolateSnapshotInstr = fileToMetadata['assets/isolate_snapshot_instr'];
    final _UnzipListEntry vmSnapshotData = fileToMetadata['assets/vm_snapshot_data'];
    final _UnzipListEntry vmSnapshotInstr = fileToMetadata['assets/vm_snapshot_instr'];
    final _UnzipListEntry license = fileToMetadata['assets/flutter_assets/LICENSE'];

    return <String, dynamic>{
      'libflutter_uncompressed_bytes': libflutter.uncompressedSize,
      'libflutter_compressed_bytes': libflutter.compressedSize,
      'snapshot_uncompressed_bytes': isolateSnapshotData.uncompressedSize +
          isolateSnapshotInstr.uncompressedSize +
          vmSnapshotData.uncompressedSize +
          vmSnapshotInstr.uncompressedSize,
      'snapshot_compressed_bytes': isolateSnapshotData.compressedSize +
          isolateSnapshotInstr.compressedSize +
          vmSnapshotData.compressedSize +
          vmSnapshotInstr.compressedSize,
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
  Future<void> get receivedNextMessage => _receivedNextMessage?.future;
  Completer<void> _receivedNextMessage;
  String _nextMessage;

  /// Prepares the [receivedNextMessage] future such that it will complete
  /// when `adb logcat` sees a log line with the given `message`.
  void prepareForNextMessage(String message) {
    _nextMessage = message;
    _receivedNextMessage = Completer<void>();
  }

  int get iterationCount => 10;

  Device get device => _device;
  Device _device;

  Future<TaskResult> run() {
    return inDirectory<TaskResult>(project, () async {
      // This test currently only works on Android, because device.logcat,
      // device.getMemoryStats, etc, aren't implemented for iOS.

      _device = await devices.workingDevice;
      await device.unlock();
      await flutter('packages', options: <String>['get']);

      if (deviceOperatingSystem == DeviceOperatingSystem.ios)
        await prepareProvisioningCertificates(project);

      final StreamSubscription<String> adb = device.logcat.listen(
        (String data) {
          if (data.contains('==== MEMORY BENCHMARK ==== $_nextMessage ===='))
            _receivedNextMessage.complete();
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
        await device.stop(package);
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }

      await adb.cancel();

      final ListStatistics startMemoryStatistics = ListStatistics(_startMemory);
      final ListStatistics endMemoryStatistics = ListStatistics(_endMemory);
      final ListStatistics diffMemoryStatistics = ListStatistics(_diffMemory);

      final Map<String, dynamic> memoryUsage = <String, dynamic>{};
      memoryUsage.addAll(startMemoryStatistics.asMap('start'));
      memoryUsage.addAll(endMemoryStatistics.asMap('end'));
      memoryUsage.addAll(diffMemoryStatistics.asMap('diff'));

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
      '-d', device.deviceId,
      test,
    ]);
    print('awaiting "ready" message...');
    await receivedNextMessage;
  }

  /// To change the behaviour of the test, override this.
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
    await device.tap(100, 100);
    print('awaiting "done" message...');
    await receivedNextMessage;

    await recordEnd();
  }

  final List<int> _startMemory = <int>[];
  final List<int> _endMemory = <int>[];
  final List<int> _diffMemory = <int>[];

  Map<String, dynamic> _startMemoryUsage;

  @protected
  Future<void> recordStart() async {
    assert(_startMemoryUsage == null);
    print('snapshotting memory usage...');
    _startMemoryUsage = await device.getMemoryStats(package);
  }

  @protected
  Future<void> recordEnd() async {
    assert(_startMemoryUsage != null);
    print('snapshotting memory usage...');
    final Map<String, dynamic> endMemoryUsage = await device.getMemoryStats(package);
    _startMemory.add(_startMemoryUsage['total_kb']);
    _endMemory.add(endMemoryUsage['total_kb']);
    _diffMemory.add(endMemoryUsage['total_kb'] - _startMemoryUsage['total_kb']);
  }
}

/// Holds simple statistics of an odd-lengthed list of integers.
class ListStatistics {
  factory ListStatistics(Iterable<int> data) {
    assert(data.isNotEmpty);
    assert(data.length % 2 == 1);
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
    final List<String> data = line.trim().split(RegExp('\\s+'));
    assert(data.length == 8);
    return _UnzipListEntry._(
      uncompressedSize:  int.parse(data[0]),
      compressedSize: int.parse(data[2]),
      path: data[7],
    );
  }

  _UnzipListEntry._({
    @required this.uncompressedSize,
    @required this.compressedSize,
    @required this.path,
  }) : assert(uncompressedSize != null),
       assert(compressedSize != null),
       assert(compressedSize <= uncompressedSize),
       assert(path != null);

  final int uncompressedSize;
  final int compressedSize;
  final String path;
}
