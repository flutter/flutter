// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_devicelab/framework/ios.dart';
import 'package:path/path.dart' as path;

import '../framework/adb.dart';
import '../framework/framework.dart';
import '../framework/utils.dart';

final Directory _editedFlutterGalleryDir = dir(path.join(Directory.systemTemp.path, 'edited_flutter_gallery'));
final Directory flutterGalleryDir = dir(path.join(flutterDirectory.path, 'examples/flutter_gallery'));

TaskFunction createHotModeTest() {
  return () async {
    final Device device = await devices.workingDevice;
    await device.unlock();
    final File benchmarkFile = file(path.join(_editedFlutterGalleryDir.path, 'hot_benchmark.json'));
    rm(benchmarkFile);
    final List<String> options = <String>[
      '--hot', '-d', device.deviceId, '--benchmark', '--verbose', '--resident'
    ];
    setLocalEngineOptionIfNecessary(options);
    int hotReloadCount = 0;
    Map<String, dynamic> twoReloadsData;
    Map<String, dynamic> freshRestartReloadsData;
    await inDirectory<void>(flutterDirectory, () async {
      rmTree(_editedFlutterGalleryDir);
      mkdirs(_editedFlutterGalleryDir);
      recursiveCopy(flutterGalleryDir, _editedFlutterGalleryDir);
      await inDirectory<void>(_editedFlutterGalleryDir, () async {
        if (deviceOperatingSystem == DeviceOperatingSystem.ios)
          await prepareProvisioningCertificates(_editedFlutterGalleryDir.path);
        {
          final Process process = await startProcess(
              path.join(flutterDirectory.path, 'bin', 'flutter'),
              <String>['run']..addAll(options),
              environment: null
          );

          final Completer<void> stdoutDone = Completer<void>();
          final Completer<void> stderrDone = Completer<void>();
          process.stdout
              .transform<String>(utf8.decoder)
              .transform<String>(const LineSplitter())
              .listen((String line) {
            if (line.contains('\] Reloaded ')) {
              if (hotReloadCount == 0) {
                // Update the file and reload again.
                final File appDartSource = file(path.join(
                    _editedFlutterGalleryDir.path, 'lib/gallery/app.dart'
                ));
                appDartSource.writeAsStringSync(
                    appDartSource.readAsStringSync().replaceFirst(
                        "'Flutter Gallery'", "'Updated Flutter Gallery'"
                    )
                );
                process.stdin.writeln('r');
                ++hotReloadCount;
              } else {
                // Quit after second hot reload.
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

          await Future.wait<void>(
              <Future<void>>[stdoutDone.future, stderrDone.future]);
          await process.exitCode;

          twoReloadsData = json.decode(benchmarkFile.readAsStringSync());
        }
        benchmarkFile.deleteSync();

        // Start `flutter run` again to make sure it loads from the previous
        // state. Frontend loads up from previously generated kernel files.
        {
          final Process process = await startProcess(
              path.join(flutterDirectory.path, 'bin', 'flutter'),
              <String>['run']..addAll(options),
              environment: null
          );
          final Completer<void> stdoutDone = Completer<void>();
          final Completer<void> stderrDone = Completer<void>();
          process.stdout
              .transform<String>(utf8.decoder)
              .transform<String>(const LineSplitter())
              .listen((String line) {
            if (line.contains('\] Reloaded ')) {
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
              json.decode(benchmarkFile.readAsStringSync());
        }
      });
    });



    return TaskResult.success(
      <String, dynamic> {
        'hotReloadInitialDevFSSyncMilliseconds': twoReloadsData['hotReloadInitialDevFSSyncMilliseconds'][0],
        'hotRestartMillisecondsToFrame': twoReloadsData['hotRestartMillisecondsToFrame'][0],
        'hotReloadMillisecondsToFrame' : twoReloadsData['hotReloadMillisecondsToFrame'][0],
        'hotReloadDevFSSyncMilliseconds': twoReloadsData['hotReloadDevFSSyncMilliseconds'][0],
        'hotReloadFlutterReassembleMilliseconds': twoReloadsData['hotReloadFlutterReassembleMilliseconds'][0],
        'hotReloadVMReloadMilliseconds': twoReloadsData['hotReloadVMReloadMilliseconds'][0],
        'hotReloadMillisecondsToFrameAfterChange' : twoReloadsData['hotReloadMillisecondsToFrame'][1],
        'hotReloadDevFSSyncMillisecondsAfterChange': twoReloadsData['hotReloadDevFSSyncMilliseconds'][1],
        'hotReloadFlutterReassembleMillisecondsAfterChange': twoReloadsData['hotReloadFlutterReassembleMilliseconds'][1],
        'hotReloadVMReloadMillisecondsAfterChange': twoReloadsData['hotReloadVMReloadMilliseconds'][1],
        'hotReloadInitialDevFSSyncAfterRelaunchMilliseconds' : freshRestartReloadsData['hotReloadInitialDevFSSyncMilliseconds'][0],
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
      ]
    );
  };
}
