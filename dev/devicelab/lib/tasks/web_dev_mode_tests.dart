// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/framework.dart';
import '../framework/utils.dart';

final Directory _editedFlutterGalleryDir = dir(path.join(Directory.systemTemp.path, 'edited_flutter_gallery'));
final Directory flutterGalleryDir = dir(path.join(flutterDirectory.path, 'examples/flutter_gallery'));

TaskFunction createWebDevModeTest() {
  return () async {
    final List<String> options = <String>[
      '--hot', '-d', 'chrome', '--verbose', '--resident', '--target=lib/main.dart',
    ];
    int hotRestartCount = 0;
    final Set<String> beforeChromeProcesses = await _collectChromeProccesses();
    try {
      await inDirectory<void>(flutterDirectory, () async {
        rmTree(_editedFlutterGalleryDir);
        mkdirs(_editedFlutterGalleryDir);
        recursiveCopy(flutterGalleryDir, _editedFlutterGalleryDir);
        await inDirectory<void>(_editedFlutterGalleryDir, () async {
          {
            final Process packagesGet = await startProcess(
                path.join(flutterDirectory.path, 'bin', 'flutter'),
                <String>['packages', 'get'],
                environment: <String, String>{
                  'FLUTTER_WEB': 'true',
                },
            );
            await packagesGet.exitCode;
            final Process process = await startProcess(
                path.join(flutterDirectory.path, 'bin', 'flutter'),
                flutterCommandArgs('run', options),
                environment: <String, String>{
                  'FLUTTER_WEB': 'true',
                },
            );

            final Completer<void> stdoutDone = Completer<void>();
            final Completer<void> stderrDone = Completer<void>();
            process.stdout
                .transform<String>(utf8.decoder)
                .transform<String>(const LineSplitter())
                .listen((String line) {
              if (line.contains('To hot restart')) {
                process.stdin.write('R');
              }
              if (line.contains('Restarted')) {
                if (hotRestartCount == 0) {
                  // Update the file and reload again.
                  final File appDartSource = file(path.join(
                      _editedFlutterGalleryDir.path, 'lib/gallery/app.dart',
                  ));
                  appDartSource.writeAsStringSync(
                      appDartSource.readAsStringSync().replaceFirst(
                          "'Flutter Gallery'", "'Updated Flutter Gallery'",
                      )
                  );
                  process.stdin.writeln('R');
                  ++hotRestartCount;
                } else {
                  // Quit after second hot restart.
                  process.stdin.writeln('q');
                }
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

            await Future.wait<void>(<Future<void>>[
              stdoutDone.future,
              stderrDone.future,
            ]);
            await process.exitCode;

          }

          // Start `flutter run` again to make sure it loads from the previous
          // state. dev compilers loads up from previously compiled JavaScript.
          {
            final Process process = await startProcess(
                path.join(flutterDirectory.path, 'bin', 'flutter'),
                flutterCommandArgs('run', options),
                environment: <String, String>{
                  'FLUTTER_WEB': 'true',
                },
            );
            final Completer<void> stdoutDone = Completer<void>();
            final Completer<void> stderrDone = Completer<void>();
            process.stdout
                .transform<String>(utf8.decoder)
                .transform<String>(const LineSplitter())
                .listen((String line) {
              if (line.contains('To hot restart')) {
                process.stdin.write('R');
              }
              if (line.contains('Restarted')) {
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

            await Future.wait<void>(<Future<void>>[
              stdoutDone.future,
              stderrDone.future,
            ]);
            await process.exitCode;
          }
        });
      });
    } finally {
      final Set<String> afterChromeProcesses = await _collectChromeProccesses();
      final Set<String> newProcesses = afterChromeProcesses.difference(beforeChromeProcesses);
      for (String processId in newProcesses) {
        await Process.run('kill', <String>[processId, '-9']);
      }
    }
    if (hotRestartCount != 1) {
      return TaskResult.failure(null);
    }
    return TaskResult.success(null);
  };
}

/// Collect chrome processes so the test doesn't leak if it exists prematurely.
Future<Set<String>> _collectChromeProccesses() async {
  final Set<String> result = <String>{};
  if (Platform.isMacOS || Platform.isLinux) {
    final Process ps = await Process.start('ps', <String>['aux']);
    final Process grep = await Process.start('grep', <String>[Platform.isMacOS ? 'Chrome' : 'chrome']);
    final Process awk = await Process.start('awk', <String>['{ print \$2 }']);
    grep.stdout.pipe(awk.stdin);
    ps.stdout.pipe(grep.stdin);
    awk.stdout
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .listen(result.add);
    await awk.exitCode;
  } else if (Platform.isWindows) {
    // TODO(jonahwilliams): collect windows processes.
  }
  return result;
}
