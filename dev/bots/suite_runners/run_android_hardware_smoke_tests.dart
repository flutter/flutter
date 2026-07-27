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

    // 1. Run driver tests to generate reference screenshots (with retry loop)
    final bool success = await _runRetryLoop(testDir);
    if (!success) {
      foundError(<String>['Android Hardware Smoke Tests driver run failed after 3 attempts.']);
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
  } finally {
    // Restore original contents.
    androidManifestXml.writeAsStringSync(androidManifestContents);
    try {
      await _deleteRetryAttemptSetting();
    } catch (e) {
      io.stderr.writeln('Warning: Failed to delete retry attempt setting: $e');
    }

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
  var attempt = 1;
  const maxAttempts = 3;

  while (attempt <= maxAttempts) {
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

    await _setRetryAttemptSetting(attempt - 1);

    final Command command = await startCommand('flutter', driveArgs, workingDirectory: testDir);
    final int exitCode = await command.process.exitCode;
    if (exitCode == 0) {
      return true;
    }

    io.stderr.writeln(
      'flutter drive failed with exit code $exitCode on attempt $attempt/$maxAttempts.',
    );

    // Inspect the process logcat on failure to detect if a transient EGL/graphics context
    // negotiation error occurred during startup, enabling a safe activity/process level retry.
    final bool hasEglWarning = await _checkForTransientEglFailure();
    if (hasEglWarning) {
      io.stderr.writeln('Detected EGL initialization/warning in logcat. Retrying...');
    } else {
      io.stderr.writeln('No transient EGL failure detected in logcat.');
      if (attempt == maxAttempts) {
        break;
      }
      foundError(<String>[
        'flutter drive failed on attempt $attempt with exit code $exitCode and no transient EGL warning was found in logcat.',
      ]);
      return false;
    }

    attempt++;
  }
  return false;
}

Future<void> _setRetryAttemptSetting(int attemptIndex) async {
  await runCommand('adb', <String>[
    'shell',
    'settings',
    'put',
    'global',
    'smoke_test_retry_attempt',
    '$attemptIndex',
  ]);
}

Future<void> _deleteRetryAttemptSetting() async {
  await runCommand('adb', <String>[
    'shell',
    'settings',
    'delete',
    'global',
    'smoke_test_retry_attempt',
  ]);
}

Future<bool> _checkForTransientEglFailure() async {
  final String logcatOutput = await runAndGetStdout('adb', <String>['logcat', '-d']).join('\n');
  return logcatOutput.contains('Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED') ||
      logcatOutput.contains('Failed to initialize 101010-2 format');
}
