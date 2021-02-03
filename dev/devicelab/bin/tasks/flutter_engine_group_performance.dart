// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';

import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';

const String _pathSeperator = '/';
const String _bundleName = 'dev.flutter.multipleflutters';
const String _activityName = 'MainActivity';

List<String> _splitAbsPath(String path) {
  if (path[0] != '/') {
    throw Exception('expected absolute path');
  }
  assert(path[0] == '/');
  final List<String> result = path.split(_pathSeperator);
  result.removeWhere((String element) => element.isEmpty);
  return result;
}

String _joinAbsPath(List<String> components) {
  return _pathSeperator + components.join(_pathSeperator);
}

List<String> _addComponent(List<String> components, String value) {
  final List<String> result = <String>[];
  result.addAll(components);
  result.add(value);
  return result;
}

List<String> _addComponents(List<String> components, List<String> values) {
  final List<String> result = <String>[];
  result.addAll(components);
  result.addAll(values);
  return result;
}

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

Future<TaskResult> _doTest() async {
  try {
    final List<String> scriptPathComponents =
        _splitAbsPath(Platform.script.path);
    final List<String> multipleFluttersPath =
        scriptPathComponents.sublist(0, scriptPathComponents.length - 4);
    multipleFluttersPath.addAll(<String>['benchmarks', 'multiple_flutters']);
    final String modulePath =
        _joinAbsPath(_addComponent(multipleFluttersPath, 'module'));
    final String androidPath =
        _joinAbsPath(_addComponent(multipleFluttersPath, 'android'));

    await _run('flutter', <String>['pub', 'get'], modulePath);
    await _run('./gradlew', <String>['assembleRelease'], androidPath);

    final String apkPath = _joinAbsPath(_addComponents(
        multipleFluttersPath, <String>[
      'android',
      'app',
      'build',
      'outputs',
      'apk',
      'release',
      'app-release.apk'
    ]));
    await _run(
        'adb', <String>['install', '-r', apkPath], Directory.current.path);
    await _run(
        'adb',
        <String>[
          'shell',
          'am',
          'start',
          '-n',
          '$_bundleName/$_bundleName.$_activityName'
        ],
        Directory.current.path);
    await Future<void>.delayed(const Duration(seconds: 10));
    final ProcessResult meminfoResult = await Process.run(
        'adb', <String>['shell', 'dumpsys', 'meminfo', _bundleName]);
    if (meminfoResult.exitCode != 0) {
      throw Exception('meminfo returned exit code: ${meminfoResult.exitCode}');
    }
    assert(meminfoResult.exitCode == 0);
    final RegExp regex = RegExp(r'TOTAL:\s+(\d+)');
    final int totalMemory =
        int.parse(regex.firstMatch(meminfoResult.stdout.toString()).group(1));
    return TaskResult.success(<String, dynamic>{
      'totalMemory': totalMemory,
    }, benchmarkScoreKeys: <String>[
      'totalMemory'
    ]);
  } catch (ex) {
    return TaskResult.failure(ex.toString());
  }
}

Future<void> main() async {
  task(_doTest);
}
