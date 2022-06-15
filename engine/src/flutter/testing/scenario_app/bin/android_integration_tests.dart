// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:args/args.dart';
import 'package:path/path.dart';
import 'package:process/process.dart';
import 'package:skia_gold_client/skia_gold_client.dart';

import 'utils/logs.dart';
import 'utils/process_manager_extension.dart';
import 'utils/screenshot_transformer.dart';

const int tcpPort = 3001;

void main(List<String> args) async {
  const ProcessManager pm = LocalProcessManager();
  final ArgParser parser = ArgParser()
    ..addOption('adb', help: 'absolute path to the adb tool', mandatory: true)
    ..addOption('out-dir', help: 'out directory', mandatory: true);

  final ArgResults results = parser.parse(args);
  final Directory outDir = Directory(results['out-dir']);
  final File adb = File(results['adb']);

  if (!outDir.existsSync()) {
    panic(<String>['out-dir does not exist: $outDir', 'make sure to build the selected engine variant']);
  }

  if (!adb.existsSync()) {
    panic(<String>['cannot find adb: $adb', 'make sure to run gclient sync']);
  }

  final String scenarioAppPath = join(outDir.path, 'scenario_app');
  final String logcatPath = join(scenarioAppPath, 'logcat.txt');
  final String screenshotPath = join(scenarioAppPath, 'screenshots');
  final String apkOutPath = join(scenarioAppPath, 'app', 'outputs', 'apk');
  final File testApk = File(join(apkOutPath, 'androidTest', 'debug', 'app-debug-androidTest.apk'));
  final File appApk = File(join(apkOutPath, 'debug', 'app-debug.apk'));

  if (!testApk.existsSync()) {
    panic(<String>['test apk does not exist: ${testApk.path}', 'make sure to build the selected engine variant']);
  }

  if (!appApk.existsSync()) {
    panic(<String>['app apk does not exist: ${appApk.path}', 'make sure to build the selected engine variant']);
  }

  // Start a TCP socket in the host, and forward it to the device that runs the tests.
  // This allows the test process to start a connection with the host, and write the bytes
  // for the screenshots.
  // On LUCI, the host uploads the screenshots to Skia Gold.
  SkiaGoldClient? skiaGoldClient;
  late  ServerSocket server;
  final List<Future<void>> pendingComparisons = <Future<void>>[];
  await step('Starting server...', () async {
    server = await ServerSocket.bind(InternetAddress.anyIPv4, tcpPort);
    stdout.writeln('listening on host ${server.address.address}:${server.port}');
    server.listen((Socket client) {
      stdout.writeln('client connected ${client.remoteAddress.address}:${client.remotePort}');
      client.transform(const ScreenshotBlobTransformer()).listen((Screenshot screenshot) {
        final String fileName = screenshot.filename;
        final Uint8List fileContent = screenshot.fileContent;
        log('host received ${fileContent.lengthInBytes} bytes for screenshot `$fileName`');
        assert(skiaGoldClient != null, 'expected Skia Gold client');
        late File goldenFile;
        try {
          goldenFile = File(join(screenshotPath, fileName))..writeAsBytesSync(fileContent, flush: true);
        } on FileSystemException catch (err) {
          panic(<String>['failed to create screenshot $fileName: ${err.toString()}']);
        }
        log('wrote ${goldenFile.absolute.path}');
        if (isSkiaGoldClientAvailable) {
          final Future<void> comparison = skiaGoldClient!
            .addImg(fileName, goldenFile, screenshotSize: fileContent.lengthInBytes)
            .catchError((dynamic err) {
              panic(<String>['skia gold comparison failed: ${err.toString()}']);
            });
          pendingComparisons.add(comparison);
        }
      },
      onError: (dynamic err) {
        panic(<String>['error while receiving bytes: ${err.toString()}']);
      },
      cancelOnError: true);
    });
  });

  late Process logcatProcess;
  late Future<int> logcatProcessExitCode;

  final IOSink logcat = File(logcatPath).openWrite();
  try {
    await step('Creating screenshot directory...', () async {
      Directory(screenshotPath).createSync(recursive: true);
    });

    await step('Starting logcat...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'logcat', '-c']);
      if (exitCode != 0) {
        panic(<String>['could not clear logs']);
      }
      logcatProcess = await pm.start(<String>[adb.path, 'logcat', '-T', '1']);
      logcatProcessExitCode = pipeProcessStreams(logcatProcess, out: logcat);
    });

    await step('Configuring emulator...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'shell',
        'settings',
        'put',
        'secure',
        'immersive_mode_confirmations',
        'confirmed',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not configure emulator']);
      }
    });

    await step('Get API level of connected device...', () async {
      final ProcessResult apiLevelProcessResult = await pm.run(<String>[adb.path, 'shell', 'getprop', 'ro.build.version.sdk']);
      if (apiLevelProcessResult.exitCode != 0) {
        panic(<String>['could not get API level of the connected device']);
      }
      final String connectedDeviceAPILevel = (apiLevelProcessResult.stdout as String).trim();
      log('using API level $connectedDeviceAPILevel');
      skiaGoldClient = SkiaGoldClient(
        outDir,
        dimensions: <String, String>{
          'AndroidAPILevel': connectedDeviceAPILevel,
        },
      );
    });

    await step('Skia Gold auth...', () async {
      if (isSkiaGoldClientAvailable) {
        await skiaGoldClient!.auth();
        log('skia gold client is available');
      } else {
        log('skia gold client is unavailable');
      }
    });

    await step('Reverse port...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'reverse', 'tcp:3000', 'tcp:$tcpPort']);
      if (exitCode != 0) {
        panic(<String>['could not forward port']);
      }
    });

    await step('Installing app APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'install', appApk.path]);
      if (exitCode != 0) {
        panic(<String>['could not install app apk']);
      }
    });

    await step('Installing test APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'install', testApk.path]);
      if (exitCode != 0) {
        panic(<String>['could not install test apk']);
      }
    });

    await step('Running instrumented tests...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'shell',
        'am',
        'instrument',
        '-w', 'dev.flutter.scenarios.test/dev.flutter.TestRunner',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not install test apk']);
      }
    });
  } finally {
    await server.close();

    await step('Remove reverse port...', () async {
      final int exitCode = await pm.runAndForward(<String>[
        adb.path,
        'reverse',
        '--remove', 'tcp:3000',
      ]);
      if (exitCode != 0) {
        panic(<String>['could not unforward port']);
      }
    });

    await step('Uinstalling app APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'uninstall', 'dev.flutter.scenarios']);
      if (exitCode != 0) {
        panic(<String>['could not uninstall app apk']);
      }
    });

    await step('Uinstalling test APK...', () async {
      final int exitCode = await pm.runAndForward(<String>[adb.path, 'uninstall', 'dev.flutter.scenarios.test']);
      if (exitCode != 0) {
        panic(<String>['could not uninstall app apk']);
      }
    });

    await step('Killing logcat process...', () async {
      final bool delivered = logcatProcess.kill(ProcessSignal.sigkill);
      assert(delivered);
      await logcatProcessExitCode;
    });

    await step('Wait for Skia gold comparisons...', () async {
      await Future.wait(pendingComparisons);
    });

    await step('Flush logcat...', () async {
      await logcat.flush();
    });

    exit(0);
  }
}
