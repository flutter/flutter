// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/adb.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/tasks/perf_tests.dart' show ListStatistics;
import 'package:path/path.dart' as path;

const String _bundleName = 'dev.flutter.multipleflutters';
const String _activityName = 'MainActivity';
const int _numberOfIterations = 10;

Future<void> _run(String command, List<String> args, String cwd) async {
  print('$command: $args');
  final Process process =
      await Process.start(command, args, workingDirectory: cwd);
  final Future<dynamic> stdoutStream = stdout.addStream(process.stdout);
  final Future<dynamic> stderrStream = stderr.addStream(process.stderr);
  final int exitCode = await process.exitCode;
  if (exitCode != 0) {
    throw Exception('command "$command $args" had exit code: $exitCode');
  }
  await stdoutStream;
  await stderrStream;
}

Future<void> _withApkInstall(
    String apkPath, String bundleName, Function(AndroidDevice) body) async {
  final DeviceDiscovery devices = DeviceDiscovery();
  final AndroidDevice device = await devices.workingDevice as AndroidDevice;
  await device.unlock();
  await device.adb(<String>['install', '-r', apkPath]);
  try {
    await body(device);
  } finally {
    await device.adb(<String>['uninstall', bundleName]);
  }
}

Future<TaskResult> _doTest() async {
  try {
    final List<String> scriptPathComponents = path.split(Platform.script.path);
    final List<String> multipleFluttersPath =
        scriptPathComponents.sublist(0, scriptPathComponents.length - 4);
    multipleFluttersPath.addAll(<String>['benchmarks', 'multiple_flutters']);
    final String modulePath =
        path.joinAll(multipleFluttersPath + <String>['module']);
    final String androidPath =
        path.joinAll(multipleFluttersPath + <String>['android']);

    final String gradlew = Platform.isWindows ? 'gradlew.bat' : 'gradlew';
    final String gradlewExecutable =
        Platform.isWindows ? '.\\$gradlew' : './$gradlew';
    final String flutterPath = path.join(
        Directory(Platform.script.path).parent.parent.parent.parent.parent.path,
        'bin',
        'flutter');
    await _run(flutterPath, <String>['pub', 'get'], modulePath);
    await _run(gradlewExecutable, <String>['assembleRelease'], androidPath);

    final String apkPath = path.joinAll(multipleFluttersPath +
        <String>[
          'android',
          'app',
          'build',
          'outputs',
          'apk',
          'release',
          'app-release.apk'
        ]);

    TaskResult result;
    await _withApkInstall(apkPath, _bundleName, (AndroidDevice device) async {
      final List<int> totalMemorySamples = <int>[];
      for (int i = 0; i < _numberOfIterations; ++i) {
        await device.adb(<String>[
          'shell',
          'am',
          'start',
          '-n',
          '$_bundleName/$_bundleName.$_activityName'
        ]);
        await Future<void>.delayed(const Duration(seconds: 10));
        final Map<String, dynamic> memoryStats =
            await device.getMemoryStats(_bundleName);
        final int totalMemory = memoryStats['total_kb'] as int;
        totalMemorySamples.add(totalMemory);
        await device.stop(_bundleName);
      }
      final ListStatistics totalMemoryStatistics =
          ListStatistics(totalMemorySamples);

      final Map<String, dynamic> results = <String, dynamic>{
        ...totalMemoryStatistics.asMap('totalMemory')
      };
      result = TaskResult.success(results,
          benchmarkScoreKeys: results.keys.toList());
    });

    return result ?? TaskResult.failure('no results found');
  } catch (ex) {
    return TaskResult.failure(ex.toString());
  }
}

Future<void> main() async {
  task(_doTest);
}
