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

final Directory _editedFlutterGalleryDir = dir(path.join(Directory.systemTemp.path, 'edited_flutter_gallery'));
final Directory flutterGalleryDir = dir(path.join(flutterDirectory.path, 'dev/integration_tests/flutter_gallery'));
const String kSourceLine = 'fontSize: (orientation == Orientation.portrait) ? 32.0 : 24.0';
const String kReplacementLine = 'fontSize: (orientation == Orientation.portrait) ? 34.0 : 24.0';

TaskFunction createHotModeTest({String? deviceIdOverride, Map<String, String>? environment}) {
  // This file is modified during the test and needs to be restored at the end.
  final File flutterFrameworkSource = file(path.join(
    flutterDirectory.path, 'packages/flutter/lib/src/widgets/framework.dart',
  ));
  final String oldContents = flutterFrameworkSource.readAsStringSync();
  return () async {
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }
    final File benchmarkFile = file(path.join(_editedFlutterGalleryDir.path, 'hot_benchmark.json'));
    rm(benchmarkFile);
    final List<String> options = <String>[
      '--hot', '-d', deviceIdOverride!, '--benchmark', '--resident',  '--no-android-gradle-daemon', '--no-publish-port', '--verbose',
    ];
    int hotReloadCount = 0;
    late Map<String, dynamic> smallReloadData;
    late Map<String, dynamic> mediumReloadData;
    late Map<String, dynamic> largeReloadData;
    late Map<String, dynamic> freshRestartReloadsData;


    await inDirectory<void>(flutterDirectory, () async {
      rmTree(_editedFlutterGalleryDir);
      mkdirs(_editedFlutterGalleryDir);
      recursiveCopy(flutterGalleryDir, _editedFlutterGalleryDir);

      try {
        await inDirectory<void>(_editedFlutterGalleryDir, () async {
          smallReloadData = await captureReloadData(options, environment, benchmarkFile, (String line, Process process) {
            if (!line.contains('Reloaded ')) {
              return;
            }
            if (hotReloadCount == 0) {
              // Update a file for 2 library invalidation.
              final File appDartSource = file(path.join(
                _editedFlutterGalleryDir.path, 'lib/gallery/app.dart',
              ));
              appDartSource.writeAsStringSync(
                appDartSource.readAsStringSync().replaceFirst(
                  "'Flutter Gallery'", "'Updated Flutter Gallery'",
                ));
              process.stdin.writeln('r');
              hotReloadCount += 1;
            } else {
              process.stdin.writeln('q');
            }
          });

          mediumReloadData = await captureReloadData(options, environment, benchmarkFile, (String line, Process process) {
            if (!line.contains('Reloaded ')) {
              return;
            }
            if (hotReloadCount == 1) {
              // Update a file for ~50 library invalidation.
              final File appDartSource = file(path.join(
                _editedFlutterGalleryDir.path, 'lib/demo/calculator/home.dart',
              ));
              appDartSource.writeAsStringSync(
                appDartSource.readAsStringSync().replaceFirst(kSourceLine, kReplacementLine)
              );
              process.stdin.writeln('r');
              hotReloadCount += 1;
            } else {
              process.stdin.writeln('q');
            }
          });

          largeReloadData = await captureReloadData(options, environment, benchmarkFile, (String line, Process process) {
            if (!line.contains('Reloaded ')) {
              return;
            }
            if (hotReloadCount == 2) {
              // Trigger a framework invalidation (370 libraries) without modifying the source
              flutterFrameworkSource.writeAsStringSync(
                '${flutterFrameworkSource.readAsStringSync()}\n'
              );
              process.stdin.writeln('r');
              hotReloadCount += 1;
            } else {
              process.stdin.writeln('q');
            }
          });

          // Start `flutter run` again to make sure it loads from the previous
          // state. Frontend loads up from previously generated kernel files.
          {
            final Process process = await startProcess(
                path.join(flutterDirectory.path, 'bin', 'flutter'),
                flutterCommandArgs('run', options),
                environment: environment,
            );
            final Completer<void> stdoutDone = Completer<void>();
            final Completer<void> stderrDone = Completer<void>();
            process.stdout
                .transform<String>(utf8.decoder)
                .transform<String>(const LineSplitter())
                .listen((String line) {
              if (line.contains('Reloaded ')) {
                process.stdin.writeln('q');
              }
              print('stdout: $line');
            }, onDone: () {
              stdoutDone.complete();
            });
            process.stderr
                .transform<String>(utf8.decoder)
                .transform<String>(const LineSplitter())
                .listen((String line) {
              print('stderr: $line');
            }, onDone: () {
              stderrDone.complete();
            });

            await Future.wait<void>(
                <Future<void>>[stdoutDone.future, stderrDone.future]);
            await process.exitCode;

            freshRestartReloadsData =
                json.decode(benchmarkFile.readAsStringSync()) as Map<String, dynamic>;
          }
        });
      } finally {
        flutterFrameworkSource.writeAsStringSync(oldContents);
      }
    });

    return TaskResult.success(
      <String, dynamic> {
        // ignore: avoid_dynamic_calls
        'hotReloadInitialDevFSSyncMilliseconds': smallReloadData['hotReloadInitialDevFSSyncMilliseconds'][0],
        // ignore: avoid_dynamic_calls
        'hotRestartMillisecondsToFrame': smallReloadData['hotRestartMillisecondsToFrame'][0],
        // ignore: avoid_dynamic_calls
        'hotReloadMillisecondsToFrame' : smallReloadData['hotReloadMillisecondsToFrame'][0],
        // ignore: avoid_dynamic_calls
        'hotReloadDevFSSyncMilliseconds': smallReloadData['hotReloadDevFSSyncMilliseconds'][0],
        // ignore: avoid_dynamic_calls
        'hotReloadFlutterReassembleMilliseconds': smallReloadData['hotReloadFlutterReassembleMilliseconds'][0],
        // ignore: avoid_dynamic_calls
        'hotReloadVMReloadMilliseconds': smallReloadData['hotReloadVMReloadMilliseconds'][0],
        // ignore: avoid_dynamic_calls
        'hotReloadMillisecondsToFrameAfterChange' : smallReloadData['hotReloadMillisecondsToFrame'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadDevFSSyncMillisecondsAfterChange': smallReloadData['hotReloadDevFSSyncMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadFlutterReassembleMillisecondsAfterChange': smallReloadData['hotReloadFlutterReassembleMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadVMReloadMillisecondsAfterChange': smallReloadData['hotReloadVMReloadMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadInitialDevFSSyncAfterRelaunchMilliseconds' : freshRestartReloadsData['hotReloadInitialDevFSSyncMilliseconds'][0],
        // ignore: avoid_dynamic_calls
        'hotReloadMillisecondsToFrameAfterMediumChange' : mediumReloadData['hotReloadMillisecondsToFrame'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadDevFSSyncMillisecondsAfterMediumChange': mediumReloadData['hotReloadDevFSSyncMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadFlutterReassembleMillisecondsAfterMediumChange': mediumReloadData['hotReloadFlutterReassembleMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadVMReloadMillisecondsAfterMediumChange': mediumReloadData['hotReloadVMReloadMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadMillisecondsToFrameAfterLargeChange' : largeReloadData['hotReloadMillisecondsToFrame'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadDevFSSyncMillisecondsAfterLargeChange': largeReloadData['hotReloadDevFSSyncMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadFlutterReassembleMillisecondsAfterLargeChange': largeReloadData['hotReloadFlutterReassembleMilliseconds'][1],
        // ignore: avoid_dynamic_calls
        'hotReloadVMReloadMillisecondsAfterLargeChange': largeReloadData['hotReloadVMReloadMilliseconds'][1],
      },
      benchmarkScoreKeys: <String>[
        'hotReloadInitialDevFSSyncMilliseconds',
        'hotRestartMillisecondsToFrame',
        'hotReloadMillisecondsToFrame',
        'hotReloadDevFSSyncMilliseconds',
        'hotReloadFlutterReassembleMilliseconds',
        'hotReloadVMReloadMilliseconds',
        'hotReloadMillisecondsToFrameAfterChange',
        'hotReloadDevFSSyncMillisecondsAfterChange',
        'hotReloadFlutterReassembleMillisecondsAfterChange',
        'hotReloadVMReloadMillisecondsAfterChange',
        'hotReloadInitialDevFSSyncAfterRelaunchMilliseconds',
        'hotReloadMillisecondsToFrameAfterMediumChange',
        'hotReloadDevFSSyncMillisecondsAfterMediumChange',
        'hotReloadFlutterReassembleMillisecondsAfterMediumChange',
        'hotReloadVMReloadMillisecondsAfterMediumChange',
        'hotReloadMillisecondsToFrameAfterLargeChange',
        'hotReloadDevFSSyncMillisecondsAfterLargeChange',
        'hotReloadFlutterReassembleMillisecondsAfterLargeChange',
        'hotReloadVMReloadMillisecondsAfterLargeChange',
      ],
    );
  };
}

Future<Map<String, dynamic>> captureReloadData(
  List<String> options,
  Map<String, String>? environment,
  File benchmarkFile,
  void Function(String, Process) onLine,
) async {
  final Process process = await startProcess(
    path.join(flutterDirectory.path, 'bin', 'flutter'),
    flutterCommandArgs('run', options),
    environment: environment,
  );

  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();
  process.stdout
    .transform<String>(utf8.decoder)
    .transform<String>(const LineSplitter())
    .listen((String line) {
      onLine(line, process);
      print('stdout: $line');
    }, onDone: stdoutDone.complete);

  process.stderr
    .transform<String>(utf8.decoder)
    .transform<String>(const LineSplitter())
    .listen(
      (String line) => print('stderr: $line'),
      onDone: stderrDone.complete,
    );

  await Future.wait<void>(<Future<void>>[stdoutDone.future, stderrDone.future]);
  await process.exitCode;
  final Map<String, dynamic> result = json.decode(benchmarkFile.readAsStringSync()) as Map<String, dynamic>;
  benchmarkFile.deleteSync();
  return result;
}
