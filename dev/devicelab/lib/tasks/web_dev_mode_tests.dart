// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:yaml_edit/yaml_edit.dart';

import '../framework/browser.dart';
import '../framework/devices.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

final Directory _editedFlutterGalleryWorkspaceDir = dir(
  path.join(Directory.systemTemp.path, 'gallery_workspace'),
);

final Directory _editedFlutterGalleryDir = dir(
  path.join(_editedFlutterGalleryWorkspaceDir.path, 'edited_flutter_gallery'),
);

final Directory flutterGalleryDir = dir(
  path.join(flutterDirectory.path, 'dev/integration_tests/flutter_gallery'),
);

const String kInitialStartupTime = 'InitialStartupTime';
const String kFirstRestartTime = 'FistRestartTime';
const String kFirstRecompileTime = 'FirstRecompileTime';
const String kSecondStartupTime = 'SecondStartupTime';
const String kSecondRestartTime = 'SecondRestartTime';

const String kWebServerDevice = 'web-server';

final RegExp servedAtPattern = RegExp('is being served at (.*)');
int hotRestartCount = 0;

Future<List<int>> launch({required bool isFirstRun}) async {
  final options = <String>[
    '--hot',
    '-d',
    kWebServerDevice,
    '--verbose',
    '--resident',
    '--target=lib/main.dart',
  ];
  final Process process = await startFlutter('run', options: options);

  final measurements = <int>[];

  final stdoutDone = Completer<void>();
  final stderrDone = Completer<void>();
  final waitForService = Completer<void>();
  final sw = Stopwatch()..start();
  Chrome? chrome;
  var restarted = false;
  process
    ..stdout
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(
          (String line) async {
            if (line.contains(servedAtPattern)) {
              final String url = servedAtPattern.firstMatch(line)!.group(1)!;
              chrome = await Chrome.launch(
                ChromeOptions(url: url, headless: true, silent: true, debugPort: 10000),
                onError: (String e) {},
              );
            }
            if (line.contains('DevHandler: Debug service listening on')) {
              waitForService.complete();
            }
            // non-dwds builds do not know when the browser is loaded so keep trying
            // until this succeeds.
            if (line.contains('Ignoring terminal input')) {
              unawaited(
                Future<void>.delayed(const Duration(seconds: 1)).then((void _) {
                  process.stdin.write(restarted ? 'q' : 'r');
                }),
              );
              return;
            }
            if (line.contains('Hot restart')) {
              unawaited(
                waitForService.future.then((_) {
                  // measure clean start-up time.
                  sw.stop();
                  measurements.add(sw.elapsedMilliseconds);
                  sw
                    ..reset()
                    ..start();
                  process.stdin.write('r');
                }),
              );
              return;
            }
            if (line.contains('Reloaded application')) {
              if (hotRestartCount == 0) {
                assert(isFirstRun);
                measurements.add(sw.elapsedMilliseconds);
                // Update the file and reload again.
                final File appDartSource = file(
                  path.join(_editedFlutterGalleryDir.path, 'lib/gallery/app.dart'),
                );
                appDartSource.writeAsStringSync(
                  appDartSource.readAsStringSync().replaceFirst(
                    "'Flutter Gallery'",
                    "'Updated Flutter Gallery'",
                  ),
                );
                sw
                  ..reset()
                  ..start();
                process.stdin.writeln('r');
                ++hotRestartCount;
              } else {
                restarted = true;
                measurements.add(sw.elapsedMilliseconds);
                // Quit after second hot restart.
                process.stdin.writeln('q');
              }
            }
            print('stdout: $line');
          },
          onDone: () {
            stdoutDone.complete();
          },
        )
    ..stderr
        .transform<String>(utf8.decoder)
        .transform<String>(const LineSplitter())
        .listen(
          (String line) {
            print('stderr: $line');
          },
          onDone: () {
            stderrDone.complete();
          },
        );

  await Future.wait<void>(<Future<void>>[stdoutDone.future, stderrDone.future]);
  await process.exitCode;
  chrome?.stop();
  return measurements;
}

TaskFunction createWebDevModeTest() {
  deviceOperatingSystem = DeviceOperatingSystem.webServer;
  return () async {
    final measurements = <String, int>{};
    await inDirectory<void>(flutterDirectory, () async {
      rmTree(_editedFlutterGalleryDir);
      mkdirs(_editedFlutterGalleryDir);
      recursiveCopy(flutterGalleryDir, _editedFlutterGalleryDir);

      final String rootPubspec = File(
        path.join(flutterDirectory.path, 'pubspec.yaml'),
      ).readAsStringSync();
      final yamlEditor = YamlEditor(rootPubspec);
      yamlEditor.update(<String>['workspace'], <String>['edited_flutter_gallery']);
      File(
        path.join(_editedFlutterGalleryDir.parent.path, 'pubspec.yaml'),
      ).writeAsStringSync(yamlEditor.toString());

      await inDirectory<void>(_editedFlutterGalleryDir, () async {
        await flutter('packages', options: <String>['get']);
        final List<int> firstMeasurements = await launch(isFirstRun: true);
        measurements.addAll(<String, int>{
          kInitialStartupTime: firstMeasurements[0],
          kFirstRecompileTime: firstMeasurements[1],
          kFirstRestartTime: firstMeasurements[2],
        });
        // Start `flutter run` again to make sure it loads from the previous
        // state. dev compilers loads up from previously compiled JavaScript.
        final List<int> secondMeasurements = await launch(isFirstRun: false);
        measurements.addAll(<String, int>{
          kSecondStartupTime: secondMeasurements[0],
          kSecondRestartTime: secondMeasurements[1],
        });
      });
    });
    if (hotRestartCount != 1) {
      return TaskResult.failure(null);
    }
    return TaskResult.success(
      measurements,
      benchmarkScoreKeys: <String>[
        kInitialStartupTime,
        kFirstRestartTime,
        kFirstRecompileTime,
        kSecondStartupTime,
        kSecondRestartTime,
      ],
    );
  };
}
