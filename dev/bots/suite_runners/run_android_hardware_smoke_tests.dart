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

    // Intentionally scope retries strictly to blank-display compositor wedges or EGL
    // initialization errors. General test assertion or golden pixel mismatch failures
    // must fail fast on attempt 1 so real visual regressions are not masked.
    final String? retryReason = await _detectRetryableFailureReason(
      '${result.stdout}\n${result.stderr}',
    );
    if (retryReason != null && attempt < maxAttempts) {
      // Restoring an emulator QuickBoot snapshot across a host renderer change can wedge
      // SurfaceFlinger into returning solid-black screencaps while offscreen app rendering
      // still works. Re-running `flutter drive --no-build` alone only restarts the app
      // process and cannot recover SurfaceFlinger, so restart Android userspace reactively
      // here (avoiding pre-flight restart overhead on healthy runs).
      io.stderr.writeln(
        'Attempt $attempt failed due to $retryReason. '
        'Restarting Android userspace before retry...',
      );
      await _restartAndroidUserspace();
      continue;
    }

    final failureSummary = retryReason != null
        ? 'Android Hardware Smoke Tests failed due to $retryReason after $maxAttempts attempts.'
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

/// Restarts Android userspace (`surfaceflinger` and `zygote`) via `adb shell stop` and
/// `adb shell start` to rebind display composition against the host emulator renderer.
///
/// Skips restarting without recording an error if the connected device does not support
/// `adb root` (such as a production `user`-build physical device).
Future<void> _restartAndroidUserspace() async {
  final _SubprocessResult rootResult = await _runAdb(<String>['root']);
  if (rootResult.exitCode != 0 ||
      '${rootResult.stdout}\n${rootResult.stderr}'.contains('cannot run as root')) {
    io.stderr.writeln(
      'Skipping Android userspace restart: adb root is not supported on this device.',
    );
    return;
  }

  await _runAdb(<String>['wait-for-device'], outputMode: OutputMode.print);

  // Clear sys.boot_completed before stopping userspace because `adb shell stop` does
  // not reset system properties, and polling would otherwise immediately read stale '1'.
  // Poll to survive transient 'device offline' states while adbd cycles after adb root.
  await _pollAdbUntil(<String>[
    'shell',
    'setprop',
    'sys.boot_completed',
    '0',
  ], description: 'sys.boot_completed reset');
  await _pollAdbUntil(
    <String>['shell', 'stop'],
    description: 'adb shell stop',
    outputMode: OutputMode.print,
  );
  await _pollAdbUntil(
    <String>['shell', 'start'],
    description: 'adb shell start',
    outputMode: OutputMode.print,
  );
  await _pollAdbUntil(
    <String>['shell', 'getprop', 'sys.boot_completed'],
    description: 'sys.boot_completed=1 after Android userspace restart',
    pollInterval: const Duration(seconds: 1),
    condition: (_SubprocessResult r) => r.stdout.trim() == '1',
  );

  await _runAdb(<String>['shell', 'input', 'keyevent', 'KEYCODE_WAKEUP']);
  await _runAdb(<String>['shell', 'wm', 'dismiss-keyguard']);
  // Allow the launcher surface to draw an initial frame after userspace comes back up.
  await Future<void>.delayed(const Duration(seconds: 2));
}

Future<void> _pollAdbUntil(
  List<String> arguments, {
  required String description,
  OutputMode outputMode = OutputMode.capture,
  Duration pollInterval = const Duration(milliseconds: 500),
  bool Function(_SubprocessResult result)? condition,
}) async {
  final stopwatch = Stopwatch()..start();
  Duration nextWarning = _adbSlowWarningInterval;
  while (true) {
    final _SubprocessResult result = await _runAdb(arguments, outputMode: outputMode);
    if (result.exitCode == 0 && (condition == null || condition(result))) {
      return;
    }
    if (stopwatch.elapsed >= nextWarning) {
      io.stderr.writeln(
        'Warning: Waiting for $description is taking longer than expected '
        '(${prettyPrintDuration(stopwatch.elapsed)} elapsed)...',
      );
      nextWarning += _adbSlowWarningInterval;
    }
    await Future<void>.delayed(pollInterval);
  }
}

Future<String?> _detectRetryableFailureReason(String driverOutput) async {
  final reasons = <String>[
    // Match blank-capture exceptions reported by driver_test.dart (errorBlankScreenshot
    // in constants.dart). Keep this substring in sync with both files.
    if (driverOutput.contains('Captured screenshot is blank/empty')) 'blank display capture',
  ];

  try {
    final _SubprocessResult logcatResult = await _runAdb(<String>['logcat', '-d']);
    final bool hasEglError =
        logcatResult.exitCode == 0 &&
        (logcatResult.stdout.contains('EGL_NOT_INITIALIZED') ||
            logcatResult.stdout.contains('EGL_BAD_CONFIG') ||
            (driverOutput.contains('EglInitializationException') &&
                logcatResult.stdout.contains(
                  'Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED',
                )));
    if (hasEglError) {
      reasons.add('EGL error in logcat');
    }
  } catch (e) {
    io.stderr.writeln('Warning: Failed to check logcat for EGL failure: $e');
  }

  return reasons.isEmpty ? null : reasons.join(' and ');
}
