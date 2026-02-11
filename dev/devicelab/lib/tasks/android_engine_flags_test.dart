// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as path;

import '../framework/android_utils.dart';
import '../framework/framework.dart';
import '../framework/task_result.dart';
import '../framework/utils.dart';

typedef TestFunction = Future<TaskResult> Function();

// TODO(camsim99): set enable-dart-profiling to release ok. also go through all defaults or file an issue
TaskFunction androidEngineFlagsTest(String buildMode) {
  final isReleaseMode = buildMode == 'release';
  final List<TaskFunction> tests = [
    // _testInvalidFlag(buildMode),
    // if (isReleaseMode) _testIllegalFlagInReleaseMode(),
    _testCommandLineFlagPrecedence(buildMode),
  ];

  return () async {
    final List<TaskResult> results = [];
    for (final test in tests) {
      final TaskResult result = await test();
      results.add(result);
      if (result.failed) {
        return result;
      }
    }

    return TaskResult.success(null);
  };
}

TaskFunction _testInvalidFlag(String buildMode) {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Insert metadata with valid and invalid flags into AndroidManifest.xml');
      final metadataKeyPairs = <(String, String)>[
        (
          'io.flutter.embedding.android.AOTSharedLibraryName',
          'something/completely/and/totally/invalid.so',
        ),
        ('io.flutter.embedding.android.ImpellerLazyShaderInitialization', 'true'),
      ];
      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Run Flutter Android app with modified manifest');
      final foundInvalidAotLibraryLog = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter('run', options: <String>['--$buildMode', '--verbose']);
      });

      final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('CAMILLE :$line');
            if (line.contains(
              "Skipping unsafe AOT shared library name flag: something/completely/and/totally/invalid.so. Please ensure that the library is vetted and placed in your application's internal storage.",
            )) {
              foundInvalidAotLibraryLog.complete(true);
            }
          });

      section('Check that warning log for invalid AOT shared library name is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        foundInvalidAotLibraryLog.future,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      }

      section('Stop listening to STDOUT');
      await stdout.cancel();
      run.kill();

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

TaskFunction _testIllegalFlagInReleaseMode() {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Insert metadata only allowed in release mode for testing into AndroidManifest.xml');
      final metadataKeyPairs = <(String, String)>[
        ('io.flutter.embedding.android.UseTestFonts', 'true'),
      ];
      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Run Flutter Android app with modified manifest');
      final foundUseTestFontsLog = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter('run', options: <String>['--release', '--verbose']);
      });

      final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            if (line.contains(
              'Flag with metadata key io.flutter.embedding.android.UseTestFonts is not allowed in release builds and will be ignored if specified in the application manifest or via the command line.',
            )) {
              foundUseTestFontsLog.complete(true);
            }
          });

      section('Check that warning log for disallowed UseTestFonts flag is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        foundUseTestFontsLog.future,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      }

      section('Stop listening to STDOUT');
      await stdout.cancel();
      run.kill();

      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

// TODO(camsim99): Refactor this into common location if I can.
Future<int> getFreePort() async {
  var port = 0;
  final ServerSocket serverSocket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  port = serverSocket.port;
  await serverSocket.close();
  return port;
}

TaskFunction _testCommandLineFlagPrecedence2(String buildMode) {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Insert metadata for manifest VM service port into the manifest');
      const invalidAotSharedLibraryPath = 'something/completely/and/totally/invalid.so';
      final metadataKeyPairs = <(String, String)>[
        ('io.flutter.embedding.android.AOTSharedLibraryName', invalidAotSharedLibraryPath),
      ];

      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Run Flutter Android app with modified manifest and --vm-service-port=');
      const validAotSharedLibraryPath = 'data/data/$projectName/';
      final foundInvalidAotLibraryLog = Completer<bool>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter(
          'run',
          options: <String>[
            '--$buildMode',
            '--aot-shared-library-name=$invalidAotSharedLibraryPath',
            '--verbose',
          ],
        );
      });

      final StreamSubscription<void> stdout = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('CAMILLE :$line');
            if (line.contains(
              "Skipping unsafe AOT shared library name flag: something/completely/and/totally/invalid.so. Please ensure that the library is vetted and placed in your application's internal storage.",
            )) {
              foundInvalidAotLibraryLog.complete(true);
            }
          });

      section('Check that warning log for invalid AOT shared library name is in STDOUT');
      final Object result = await Future.any(<Future<Object>>[
        foundInvalidAotLibraryLog.future,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      }

      section('Stop listening to STDOUT');
      await stdout.cancel();
      run.kill();
      return TaskResult.success(null);
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}

TaskFunction _testCommandLineFlagPrecedence(String buildMode) {
  return () async {
    section('Create new Flutter Android app');
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'android_flutter_shell_args_test.',
    );
    const projectName = 'androidfluttershellargstest';

    try {
      await inDirectory(tempDir, () async {
        await flutter(
          'create',
          options: <String>['--platforms', 'android', '--org', 'io.flutter.devicelab', projectName],
        );
      });

      section('Create two assets files with different content for testing');
      const assetsFileName = 'my_asset.txt';

      final manifestAssetDir = Directory(path.join(tempDir.path, projectName, 'manifest_asset'));
      await manifestAssetDir.create();
      final manifestAssetFile = File(path.join(manifestAssetDir.path, assetsFileName));

      const manifestAssetFileContentStr = 'Content from manifest asset directory';
      await manifestAssetFile.writeAsString(manifestAssetFileContentStr);

      final commandLineAssetDir = Directory(
        path.join(tempDir.path, projectName, 'command_line_asset'),
      );
      await commandLineAssetDir.create();
      final commandLineAssetFile = File(path.join(commandLineAssetDir.path, assetsFileName));

      const commandLineAssetFileContentStr = 'Content from command line asset directory';
      await commandLineAssetFile.writeAsString(commandLineAssetFileContentStr);

      section('Insert metadata for manifest asset file into the manifest');
      final metadataKeyPairs = <(String, String)>[
        ('io.flutter.embedding.android.FlutterAssetsDir', manifestAssetDir.path),
      ];

      addMetadataToManifest(path.join(tempDir.path, projectName), metadataKeyPairs);

      section('Modify main.dart to load and print asset content');
      final mainFile = File(path.join(tempDir.path, projectName, 'lib', 'main.dart'));
      final String originalMainContent = await mainFile.readAsString();
      final String newMainContent = originalMainContent.replaceFirst('void main() {', '''
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  String assetContent = '';
  try {
    assetContent = await rootBundle.loadString($assetsFileName);
  } catch (e) {
    assetContent = 'Error loading asset: \$e';
  }
  print('Asset Content: \$assetContent');
        ''');

      await mainFile.writeAsString(newMainContent);

      section('Run Flutter Android app with modified manifest and --flutter-assets-dir');
      final assetsContentFoundCompleter = Completer<String>();
      late Process run;

      await inDirectory(path.join(tempDir.path, projectName), () async {
        run = await startFlutter(
          'run',
          options: <String>[
            '--$buildMode',
            '--flutter-assets-dir=${commandLineAssetDir.path}',
            '--verbose',
          ],
        );
      });
      run.stderr.forEach(print);
      final StreamSubscription<void> stdoutSubscription = run.stdout
          .transform<String>(utf8.decoder)
          .transform<String>(const LineSplitter())
          .listen((String line) {
            print('CAMILLE: $line');
            if (line.contains('Asset Content: ')) {
              assetsContentFoundCompleter.complete(
                line.substring(line.indexOf('Asset Content: ') + 'Asset Content: '.length),
              );
            }
          });

      section('Check that manifest asset content is in STDOUT');
      final Future<String> assetsContentFoundFuture = assetsContentFoundCompleter.future;
      final Object result = await Future.any(<Future<Object>>[
        assetsContentFoundFuture,
        run.exitCode,
      ]);

      if (result is int) {
        throw Exception('flutter run failed, exitCode=$result');
      }

      final String printedAssetContent = await assetsContentFoundFuture;
      late TaskResult taskResult;
      if (printedAssetContent == manifestAssetFileContentStr) {
        taskResult = TaskResult.success(null);
      } else if (printedAssetContent == commandLineAssetFileContentStr) {
        taskResult = TaskResult.failure(
          'Asset content defined on the command line did not take precedence over the manifest defined asset as expected.',
        );
      } else {
        taskResult = TaskResult.failure(
          'Neither asset file defined on the command line or the manifest was loaded correctly.',
        );
      }

      section('Kill the app');
      await stdoutSubscription.cancel();
      run.kill();
      await run.exitCode;

      return taskResult;
    } on TaskResult catch (taskResult) {
      return taskResult;
    } catch (e, stackTrace) {
      print('Task exception stack trace:\n$stackTrace');
      return TaskResult.failure(e.toString());
    } finally {
      rmTree(tempDir);
    }
  };
}
