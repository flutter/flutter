// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_devicelab/common.dart';
import 'package:flutter_devicelab/framework/devices.dart';
import 'package:flutter_devicelab/framework/framework.dart';
import 'package:flutter_devicelab/framework/task_result.dart';
import 'package:flutter_devicelab/framework/utils.dart';
import 'package:path/path.dart' as path;

void generateMain(Directory appDir, String sentinel) {
  final String mainCode = '''
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_driver/driver_extension.dart';

class ReassembleListener extends StatefulWidget {
  const ReassembleListener({Key key, this.child})
      : super(key: key);

  final Widget child;

  @override
  _ReassembleListenerState createState() => _ReassembleListenerState();
}

class _ReassembleListenerState extends State<ReassembleListener> {
  @override
  initState() {
    super.initState();
    print('$sentinel');
  }

  @override
  void reassemble() {
    super.reassemble();
    print('$sentinel');
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() {
  runApp(
    ReassembleListener(
      child: Text(
        'Hello, word!',
        textDirection: TextDirection.rtl,
      )
    )
  );
}
''';
  File(path.join(appDir.path, 'lib', 'fuchsia_main.dart'))
    .writeAsStringSync(mainCode, flush: true);
}

void main() {
  deviceOperatingSystem = DeviceOperatingSystem.fuchsia;

  task(() async {
    section('Checking environment variables');

    if (Platform.environment['FUCHSIA_SSH_CONFIG'] == null &&
        Platform.environment['FUCHSIA_BUILD_DIR'] == null) {
      throw Exception('No FUCHSIA_SSH_CONFIG or FUCHSIA_BUILD_DIR set');
    }

    final String flutterBinary = path.join(flutterDirectory.path, 'bin', 'flutter');

    section('Downloading Fuchsia SDK and flutter runner');

    // Download the Fuchsia SDK.
    final int precacheResult = await exec(
      flutterBinary,
      <String>[
        'precache',
        '--fuchsia',
        '--flutter_runner',
      ]
    );

    if (precacheResult != 0) {
      throw Exception('flutter precache failed with exit code $precacheResult');
    }

    final Directory fuchsiaToolDirectory =
      Directory(path.join(flutterDirectory.path, 'bin', 'cache', 'artifacts', 'fuchsia', 'tools'));
    if (!fuchsiaToolDirectory.existsSync()) {
      throw Exception('Expected Fuchsia tool directory at ${fuchsiaToolDirectory.path}');
    }

    final Device device = await devices.workingDevice;
    final Directory appDir = dir(path.join(
      flutterDirectory.path,
      'dev',
      'integration_tests',
      'ui',
    ));

    await inDirectory(appDir, () async {
      final Random random = Random();
      final Map<String, Completer<void>> sentinelMessage = <String, Completer<void>>{
        'sentinel-${random.nextInt(1<<32)}': Completer<void>(),
        'sentinel-${random.nextInt(1<<32)}': Completer<void>(),
      };

      late Process runProcess;
      late Process logsProcess;

      try {
        section('Creating lib/fuchsia_main.dart');

        generateMain(appDir, sentinelMessage.keys.toList()[0]);

        section('Launching `flutter run` in ${appDir.path}');

        runProcess = await startProcess(
          flutterBinary,
          <String>[
            'run',
            '--suppress-analytics',
            '-d', device.deviceId,
            '-t', 'lib/fuchsia_main.dart',
          ],
          isBot: false, // We just want to test the output, not have any debugging info.
        );

        logsProcess = await startProcess(
          flutterBinary,
          <String>['logs', '--suppress-analytics', '-d', device.deviceId],
          isBot: false, // We just want to test the output, not have any debugging info.
        );

        Future<dynamic> eventOrExit(Future<void> event) {
          return Future.any<dynamic>(<Future<dynamic>>[
            event,
            runProcess.exitCode,
            logsProcess.exitCode,
          ]);
        }

        logsProcess.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String log) {
            print('logs:stdout: $log');
            for (final String sentinel in sentinelMessage.keys) {
              if (log.contains(sentinel)) {
                if (sentinelMessage[sentinel]!.isCompleted) {
                  throw Exception(
                    'Expected a single `$sentinel` message in the device log, but found more than one'
                  );
                }
                sentinelMessage[sentinel]!.complete();
                break;
              }
            }
          });

        final Completer<void> hotReloadCompleter = Completer<void>();
        final Completer<void> reloadedCompleter = Completer<void>();
        final RegExp observatoryRegexp = RegExp('An Observatory debugger and profiler on .+ is available at');
        runProcess.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('run:stdout: $line');
            if (observatoryRegexp.hasMatch(line)) {
              hotReloadCompleter.complete();
            } else if (line.contains('Reloaded')) {
              reloadedCompleter.complete();
            }
          });

        final List<String> runStderr = <String>[];
        runProcess.stderr
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            runStderr.add(line);
            print('run:stderr: $line');
          });

        section('Waiting for hot reload availability');
        await eventOrExit(hotReloadCompleter.future);

        section('Waiting for Dart VM');
        // Wait for the first message in the log from the Dart VM.
        await eventOrExit(sentinelMessage.values.toList()[0].future);

        // Change the dart file.
        generateMain(appDir, sentinelMessage.keys.toList()[1]);

        section('Hot reload');
        runProcess.stdin.write('r');
        unawaited(runProcess.stdin.flush());
        await eventOrExit(reloadedCompleter.future);

        section('Waiting for Dart VM');
        // Wait for the second message in the log from the Dart VM.
        await eventOrExit(sentinelMessage.values.toList()[1].future);

        section('Quitting flutter run');

        runProcess.stdin.write('q');
        unawaited(runProcess.stdin.flush());

        final int runExitCode = await runProcess.exitCode;
        if (runExitCode != 0 || runStderr.isNotEmpty) {
          throw Exception(
            'flutter run exited with code $runExitCode and errors: ${runStderr.join('\n')}.'
          );
        }
      } finally {
        runProcess.kill();
        logsProcess.kill();
        File(path.join(appDir.path, 'lib', 'fuchsia_main.dart')).deleteSync();
      }

      for (final String sentinel in sentinelMessage.keys) {
        if (!sentinelMessage[sentinel]!.isCompleted) {
          throw Exception('Expected $sentinel in the device logs.');
        }
      }
    });

    return TaskResult.success(null);
  });
}
