// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';
import 'run_android_engine_tests.dart';

String _impellerBackendMetadata({required String value}) =>
    '<meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="$value" />';

void _cleanGoldensDirectory(Directory directory) {
  if (!directory.existsSync()) {
    return;
  }
  for (final FileSystemEntity entity in directory.listSync()) {
    if (path.basename(entity.path) != 'README.md') {
      entity.deleteSync(recursive: true);
    }
  }
}

/// Runs the Android Hardware Smoke Test golden suite in CI.
Future<void> runAndroidHardwareSmokeTests({
  required ImpellerBackend backend,
  bool runInstrumented = false,
}) async {
  printProgress('Running Android Hardware Smoke Tests Shard (backend=${backend.name})');

  final String testDir = path.join('dev', 'integration_tests', 'android_hardware_smoke_test');

  await _regenerateAndroidWrappers(testDir);

  final String androidDir = path.join(testDir, 'android');
  final File androidManifestXml = const LocalFileSystem().file(
    path.join(androidDir, 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  final String androidManifestContents = androidManifestXml.readAsStringSync();

  final Directory destinationDir = const LocalFileSystem().directory(
    path.join(testDir, 'test_driver', 'goldens'),
  );

  try {
    _setAndroidManifestBackend(androidManifestXml, androidManifestContents, backend);

    // 1. Run driver tests to generate reference screenshots
    final bool success = await _runRetryLoop(testDir);
    if (!success) {
      return;
    }

    if (runInstrumented) {
      final String gradle = path.absolute(
        path.join(androidDir, io.Platform.isWindows ? 'gradlew.bat' : 'gradlew'),
      );

      // 2. Build and run the instrumented tests.
      await runCommand(gradle, <String>[
        ':app:connectedDebugAndroidTest',
        '-Pandroid.testInstrumentationRunnerArguments.class=com.example.android_hardware_smoke_test.FlutterActivityTest',
        '-s',
      ], workingDirectory: androidDir);
    }
  } on _InfrastructureException catch (e) {
    foundError(<String>[e.message]);
    io.exitCode = 2;
  } finally {
    // Restore original contents.
    androidManifestXml.writeAsStringSync(androidManifestContents);

    // Clean up copied goldens to keep Git worktree completely clean
    _cleanGoldensDirectory(destinationDir);
  }
}

Future<void> _regenerateAndroidWrappers(String testDir) async {
  await runCommand('flutter', <String>[
    'create',
    '--platform=android',
    '--no-overwrite',
    '.',
  ], workingDirectory: testDir);
}

void _setAndroidManifestBackend(File file, String contents, ImpellerBackend backend) {
  final impellerBackendMetadata = RegExp(_impellerBackendMetadata(value: '[^"]*'));
  if (!impellerBackendMetadata.hasMatch(contents)) {
    throw StateError(
      'Could not find io.flutter.embedding.android.ImpellerBackend meta-data tag inside AndroidManifest.xml',
    );
  }
  file.writeAsStringSync(
    contents.replaceFirst(impellerBackendMetadata, _impellerBackendMetadata(value: backend.name)),
  );
}

Future<bool> _runRetryLoop(String testDir) async {
  const maxAttempts = 2;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    // Clear logcat buffer before running
    await runCommand('adb', <String>['logcat', '-c']);

    final driveArgs = <String>[
      'drive',
      '--driver=test_driver/driver_test.dart',
      '--target=integration_test/integration_test_wrapper.dart',
      '--no-dds',
      '--no-enable-dart-profiling',
    ];

    if (attempt > 1) {
      driveArgs.add('--no-build');
    }

    final CommandResult result = await runCommand('flutter', driveArgs, workingDirectory: testDir);
    if (result.exitCode == 0) {
      return true;
    }

    io.stderr.writeln(
      'flutter drive failed with exit code ${result.exitCode} on attempt $attempt/$maxAttempts.',
    );

    final driverOutput = '${result.flattenedStdout}\n${result.flattenedStderr}';

    // Inspect logcat and driver output on failure to detect if an unrecoverable EGL
    // graphics pipeline collapse occurred (requires both logcat EGL error and blank image failure).
    final bool hasEglWarning = await _checkForTransientEglFailure(driverOutput);
    if (hasEglWarning) {
      if (attempt < maxAttempts) {
        io.stderr.writeln(
          'Attempt $attempt failed with EGL/graphics error. Retrying with clean engine cache...',
        );
        continue;
      }
      io.stderr.writeln(
        'INFRASTRUCTURE FAILURE: EGL / graphics driver pipeline collapsed on emulator after $maxAttempts attempts.',
      );
      throw _InfrastructureException(
        'INFRASTRUCTURE FAILURE: EGL / graphics driver pipeline collapsed on emulator after $maxAttempts attempts.',
      );
    }

    foundError(<String>[
      'Android Hardware Smoke Tests driver run failed with exit code ${result.exitCode}.',
    ]);
    return false;
  }

  return false;
}

class _InfrastructureException implements Exception {
  _InfrastructureException(this.message);
  final String message;
  @override
  String toString() => message;
}

Future<bool> _checkForTransientEglFailure(String driverOutput) async {
  try {
    final String logcatOutput = await runAndGetStdout('adb', <String>['logcat', '-d']).join('\n');
    final bool hasEglWarning =
        logcatOutput.contains('Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED') ||
        logcatOutput.contains('EGL_NOT_INITIALIZED') ||
        logcatOutput.contains('EGL_BAD_CONFIG');
    final bool hasRenderingError =
        driverOutput.contains('blank/empty') ||
        driverOutput.contains('BlankScreenshotException') ||
        driverOutput.contains('EglInitializationException');

    return hasEglWarning && hasRenderingError;
  } catch (e) {
    io.stderr.writeln('Warning: Failed to check logcat for EGL failure: $e');
    return false;
  }
}
