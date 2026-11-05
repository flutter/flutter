// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:core' hide print;
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';
import 'run_android_engine_tests.dart';

typedef _SubprocessResult = ({int exitCode, String stdout, String stderr});

const Duration _adbSlowWarningInterval = Duration(seconds: 30);

Future<_SubprocessResult> _runAdb(
  List<String> arguments, {
  OutputMode outputMode = OutputMode.capture,
}) => _runUncheckedSubprocess(
  'adb',
  arguments,
  outputMode: outputMode,
  slowWarningInterval: _adbSlowWarningInterval,
);

/// Runs [executable] without recording a shard error via [foundError] on
/// non-zero exit codes, decoding output with malformed UTF-8 tolerance so
/// native crash tombstones in `adb logcat` do not throw [FormatException].
Future<_SubprocessResult> _runUncheckedSubprocess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  OutputMode outputMode = OutputMode.print,
  Duration? slowWarningInterval,
}) async {
  final String relativeWorkingDir = path.relative(workingDirectory ?? io.Directory.current.path);
  final commandDescription =
      '${path.relative(executable, from: workingDirectory)} ${arguments.join(' ')}';
  if (dryRun) {
    printProgress('|> $executable ${arguments.join(' ')}');
    return (exitCode: 0, stdout: '', stderr: '');
  }

  print('RUNNING: cd $cyan$relativeWorkingDir$reset; $green$commandDescription$reset');
  final time = Stopwatch()..start();
  final io.Process process = await io.Process.start(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );

  final Timer? slowWarningTimer = slowWarningInterval == null
      ? null
      : Timer.periodic(slowWarningInterval, (_) {
          io.stderr.writeln(
            'Warning: "$commandDescription" is taking longer than expected '
            '(${prettyPrintDuration(time.elapsed)} elapsed)...',
          );
        });

  final Future<String> savedStdout = _collectProcessStream(process.stdout, outputMode: outputMode);
  final Future<String> savedStderr = _collectProcessStream(process.stderr, outputMode: outputMode);

  final int exitCode;
  try {
    exitCode = await process.exitCode;
  } finally {
    slowWarningTimer?.cancel();
  }

  final _SubprocessResult result = (
    exitCode: exitCode,
    stdout: await savedStdout,
    stderr: await savedStderr,
  );
  print(
    'ELAPSED TIME: ${prettyPrintDuration(time.elapsed)} for $green$commandDescription$reset in $cyan$relativeWorkingDir$reset',
  );
  return result;
}

Future<String> _collectProcessStream(Stream<List<int>> stream, {required OutputMode outputMode}) {
  return stream
      .transform<String>(const Utf8Decoder(allowMalformed: true))
      .transform(const LineSplitter())
      .map<String>((String line) {
        switch (outputMode) {
          case OutputMode.print:
            print(line);
          case OutputMode.capture:
            break;
        }
        return line;
      })
      .join('\n');
}

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

    // 1. Run driver tests to generate or verify reference screenshots.
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
  } finally {
    // Restore original contents.
    androidManifestXml.writeAsStringSync(androidManifestContents);

    // Clean up copied goldens to keep Git worktree completely clean.
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
    // Clear logcat using an unchecked subprocess so a transient offline device on attempt 1
    // does not call foundError and poison the global shard status.
    await _runAdb(<String>['logcat', '-c'], outputMode: OutputMode.print);

    final driveArgs = <String>[
      'drive',
      '--driver=test_driver/driver_test.dart',
      '--target=integration_test/integration_test_wrapper.dart',
      '--no-dds',
      '--no-enable-dart-profiling',
      if (attempt > 1) '--no-build',
    ];

    // Run without automatic exit-code error recording so a transient failure on attempt 1
    // does not set global hasError before the retry attempt has a chance to pass.
    final _SubprocessResult result = await _runUncheckedSubprocess(
      'flutter',
      driveArgs,
      workingDirectory: testDir,
    );
    if (result.exitCode == 0) {
      return true;
    }

    io.stderr.writeln(
      'flutter drive failed with exit code ${result.exitCode} on attempt $attempt/$maxAttempts.',
    );

    final bool hasEglWarning = await _checkForTransientEglFailure(
      '${result.stdout}\n${result.stderr}',
    );
    if (hasEglWarning && attempt < maxAttempts) {
      io.stderr.writeln(
        'Attempt $attempt failed with EGL/graphics error. Retrying with clean engine cache...',
      );
      continue;
    }

    final failureSummary = hasEglWarning
        ? 'INFRASTRUCTURE FAILURE: EGL / graphics driver pipeline collapsed on emulator after $maxAttempts attempts.'
        : 'Android Hardware Smoke Tests driver run failed with exit code ${result.exitCode}.';
    foundError(<String>[
      failureSummary,
      'Command: flutter ${driveArgs.join(' ')}',
      'Working directory: ${path.absolute(testDir)}',
    ]);
    return false;
  }

  return false;
}

Future<bool> _checkForTransientEglFailure(String driverOutput) async {
  try {
    final _SubprocessResult logcatResult = await _runAdb(<String>['logcat', '-d']);
    if (logcatResult.exitCode != 0) {
      return false;
    }
    final bool hasEglWarning =
        logcatResult.stdout.contains('Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED') ||
        logcatResult.stdout.contains('EGL_NOT_INITIALIZED') ||
        logcatResult.stdout.contains('EGL_BAD_CONFIG');
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
