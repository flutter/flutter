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

const String _packageName = 'package_with_native_assets';

const List<String> _buildModes = <String>['debug', 'profile', 'release'];

TaskFunction createNativeAssetsTest({
  String? deviceIdOverride,
  bool checkAppRunningOnLocalDevice = true,
  bool isIosSimulator = false,
}) {
  return () async {
    if (deviceIdOverride == null) {
      final Device device = await devices.workingDevice;
      await device.unlock();
      deviceIdOverride = device.deviceId;
    }

    for (final String buildMode in _buildModes) {
      if (buildMode != 'debug' && isIosSimulator) {
        continue;
      }
      final TaskResult buildModeResult = await inTempDir((Directory tempDirectory) async {
        final Directory packageDirectory = await createTestProject(_packageName, tempDirectory);
        final Directory exampleDirectory = dir(
          packageDirectory.uri.resolve('example/').toFilePath(),
        );

        final List<String> options = <String>[
          '-d',
          deviceIdOverride!,
          '--no-android-gradle-daemon',
          '--no-publish-port',
          '--verbose',
          '--uninstall-first',
          '--$buildMode',
        ];
        int transitionCount = 0;
        bool done = false;
        bool error = false;

        await inDirectory<void>(exampleDirectory, () async {
          final int runFlutterResult = await runFlutter(
            command: 'run',
            options: options,
            onLine: (String line, Process process) {
              error |= line.contains('EXCEPTION CAUGHT BY WIDGETS LIBRARY');
              error |= line.contains("Invalid argument(s): Couldn't resolve native function 'sum'");
              if (done) {
                return;
              }
              switch (transitionCount) {
                case 0:
                  if (!line.contains('Flutter run key commands.')) {
                    return;
                  }
                  if (buildMode == 'debug') {
                    // Do a hot reload diff on the initial dill file.
                    process.stdin.writeln('r');
                  } else {
                    done = true;
                    process.stdin.writeln('q');
                  }
                case 1:
                  if (!line.contains('Reloaded')) {
                    return;
                  }
                  process.stdin.writeln('R');
                case 2:
                  // Do a hot restart, pushing a new complete dill file.
                  if (!line.contains('Restarted application')) {
                    return;
                  }
                  // Do another hot reload, pushing a diff to the second dill file.
                  process.stdin.writeln('r');
                case 3:
                  if (!line.contains('Reloaded')) {
                    return;
                  }
                  done = true;
                  process.stdin.writeln('q');
              }
              transitionCount += 1;
            },
          );
          if (runFlutterResult != 0) {
            print('Flutter run returned non-zero exit code: $runFlutterResult.');
          }
        });

        final int expectedNumberOfTransitions = buildMode == 'debug' ? 4 : 1;
        if (transitionCount != expectedNumberOfTransitions) {
          return TaskResult.failure(
            'Did not get expected number of transitions: $transitionCount '
            '(expected $expectedNumberOfTransitions)',
          );
        }
        if (error) {
          return TaskResult.failure('Error during hot reload or hot restart.');
        }

        if (buildMode == _buildModes.last) {
          // Only run integration tests once.
          done = false;
          final int integrationTestResult = await inDirectory<int>(exampleDirectory, () async {
            return runFlutter(
              command: 'test',
              options: <String>['integration_test', '-d', deviceIdOverride!],
              onLine: (String line, Process _) {
                if (line.contains('All tests passed!')) {
                  done = true;
                }
              },
            );
          });
          if (!done && integrationTestResult != 0) {
            return TaskResult.failure('flutter test integration test failed');
          }
        }

        return TaskResult.success(null);
      });
      if (buildModeResult.failed) {
        return buildModeResult;
      }
    }
    return TaskResult.success(null);
  };
}

Future<int> runFlutter({
  required String command,
  required List<String> options,
  required void Function(String, Process) onLine,
}) async {
  final Process process = await startFlutter(command, options: options);

  final Completer<void> stdoutDone = Completer<void>();
  final Completer<void> stderrDone = Completer<void>();
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
  await exec(_flutterBin, <String>[
    'create',
    '--no-pub',
    '--template=package_ffi',
    packageName,
  ], workingDirectory: tempDirectory.path);

  final Directory packageDirectory = Directory(path.join(tempDirectory.path, packageName));
  await _pinDependencies(File(path.join(packageDirectory.path, 'pubspec.yaml')));
  await _pinDependencies(File(path.join(packageDirectory.path, 'example', 'pubspec.yaml')));

  await _addIntegrationTest(packageDirectory.uri.resolve('example/'), _packageName);

  await exec(_flutterBin, <String>['pub', 'get'], workingDirectory: packageDirectory.path);

  return packageDirectory;
}

Future<void> _pinDependencies(File pubspecFile) async {
  final String oldPubspec = await pubspecFile.readAsString();
  final String newPubspec = oldPubspec.replaceAll(': ^', ': ');
  await pubspecFile.writeAsString(newPubspec);
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

Future<void> _addIntegrationTest(Uri exampleDirectory, String packageName) async {
  await exec(_flutterBin, <String>[
    'pub',
    'add',
    'dev:integration_test:{"sdk":"flutter"}',
  ], workingDirectory: exampleDirectory.toFilePath());

  final Uri integrationTestPath = exampleDirectory.resolve('integration_test/my_test.dart');
  final File integrationTestFile = File.fromUri(integrationTestPath);
  integrationTestFile
    ..createSync(recursive: true)
    ..writeAsStringSync('''
import 'package:flutter_test/flutter_test.dart';
import 'package:${packageName}_example/main.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('end-to-end test', () {
    testWidgets('invoke native code', (tester) async {
      // Load app widget.
      await tester.pumpWidget(const MyApp());

      // Verify the native function was called.
      expect(find.text('sum(1, 2) = 3'), findsOneWidget);
    });
  });
}
''');
}
