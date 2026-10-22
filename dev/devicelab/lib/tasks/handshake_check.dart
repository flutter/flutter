// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

const String _appName = 'handshake_check_app';

TaskFunction createHandshakeCheckTask({
  String? deviceIdOverride,
}) {
  return () async {
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }

    return inTempDir((Directory tempDirectory) async {
      final Directory packageDirectory = await createTestProject(_appName, tempDirectory);

      final options = <String>[
        '-d',
        deviceIdOverride!,
        '--no-android-gradle-daemon',
        '--no-publish-port',
        '--verbose',
        '--uninstall-first',
        '--debug',
      ];

      var handshakeFailed = false;

      await inDirectory<void>(packageDirectory, () async {
        final int runFlutterResult = await runFlutter(
          command: 'run',
          options: options,
          onLine: (String line, Process process) {
            if (line.contains('CERTIFICATE_VERIFY_FAILED')) {
              handshakeFailed = true;
            }
            if (line.contains('handshake finished')) {
              process.stdin.writeln('q');
            }
          },
        );
        if (runFlutterResult != 0) {
          print('Flutter run returned non-zero exit code: $runFlutterResult.');
        }
      });

      // Failure is a good outcome
      if (handshakeFailed) {
        return TaskResult.success(null);
      } else {
        return TaskResult.failure('Handshake failure not detected.');
      }
    });
  };
}

Future<int> runFlutter({
  required String command,
  required List<String> options,
  required void Function(String, Process) onLine,
}) async {
  final Process process = await startFlutter(command, options: options);

  final stdoutDone = Completer<void>();
  final stderrDone = Completer<void>();
  process.stdout.transform<String>(utf8.decoder).transform<String>(const LineSplitter()).listen((
    String line,
  ) {
    onLine(line, process);
    print('stdout: $line');
  }, onDone: stdoutDone.complete);

  process.stderr
      .transform<String>(utf8.decoder)
      .transform<String>(const LineSplitter())
      .listen((String line) => print('stderr: $line'), onDone: stderrDone.complete);

  await Future.wait<void>(<Future<void>>[stdoutDone.future, stderrDone.future]);
  final int exitCode = await process.exitCode;
  return exitCode;
}

final String _flutterBin = path.join(flutterDirectory.path, 'bin', 'flutter');

Future<Directory> createTestProject(String packageName, Directory tempDirectory) async {
  await exec(_flutterBin, <String>['create', packageName], workingDirectory: tempDirectory.path);

  final packageDirectory = Directory(path.join(tempDirectory.path, packageName));

  final mainDart = File(path.join(packageDirectory.path, 'lib', 'main.dart'));
  mainDart.writeAsStringSync('''
import 'package:material_ui/material_ui.dart';

import 'dart:io';
import 'dart:convert';

void main() async {
  final client = HttpClient();
  try {
    final rq = await client.getUrl(
      Uri.parse('https://dv-g3b-emudhra.we-have-a-problem.com/'),
    );
    final rs = await rq.close();
    print(await rs.transform(utf8.decoder).join());
  } catch(e, stackTrace) {
    print(e);
    print(stackTrace);
  } finally {
    client.close();
  }
  print('handshake finished');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Handshake Test'),
        ),
      ),
    );
  }
}
''');
  return packageDirectory;
}

Future<T> inTempDir<T>(Future<T> Function(Directory tempDirectory) fun) async {
  final Directory tempDirectory = dir(
    Directory.systemTemp.createTempSync().resolveSymbolicLinksSync(),
  );
  try {
    return await fun(tempDirectory);
  } finally {
    try {
      tempDirectory.deleteSync(recursive: true);
    } catch (_) {
      // Ignore failures to delete a temporary directory.
    }
  }
}
