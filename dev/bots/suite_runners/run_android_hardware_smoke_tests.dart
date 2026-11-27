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

typedef _DriveAttemptResult = ({int exitCode, String output, bool terminatedDeadDrive});

const Duration _adbSlowWarningInterval = Duration(seconds: 30);

/// Runs `adb` with [arguments] without recording a shard failure via [foundError]
/// on non-zero exit codes, emitting periodic warnings if `adb` stalls.
Future<CommandResult> _runAdb(
  List<String> arguments, {
  OutputMode outputMode = OutputMode.capture,
}) async {
  final commandDescription = 'adb ${arguments.join(' ')}';
  final stopwatch = Stopwatch()..start();
  final Timer? slowWarningTimer = dryRun
      ? null
      : Timer.periodic(_adbSlowWarningInterval, (_) {
          io.stderr.writeln(
            'Warning: "$commandDescription" is taking longer than expected '
            '(${prettyPrintDuration(stopwatch.elapsed)} elapsed)...',
          );
        });
  try {
    return await runCommand(
      'adb',
      arguments,
      expectedExit: ExpectedExit.any,
      outputMode: outputMode,
    );
  } finally {
    slowWarningTimer?.cancel();
  }
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
    // Clear logcat with ExpectedExit.any so a transient offline device on attempt 1
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

    final _DriveAttemptResult result = await _runFlutterDrive(testDir, driveArgs);
    // Also check !terminatedDeadDrive because flutter_tools can catch SIGTERM and exit 0.
    if (result.exitCode == 0 && !result.terminatedDeadDrive) {
      return true;
    }

    if (result.terminatedDeadDrive) {
      io.stderr.writeln(
        'flutter drive was terminated after target app crash on attempt $attempt/$maxAttempts '
        '(exit code ${result.exitCode}).',
      );
    } else {
      io.stderr.writeln(
        'flutter drive failed with exit code ${result.exitCode} on attempt $attempt/$maxAttempts.',
      );
    }

    final String? retryReason = await _detectRetryableFailureReason(result);
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

/// Runs `flutter drive` without automatic exit-code error recording, terminating the driver
/// process immediately if the target app crashes during native graphics startup while Dart VM
/// service connection stalls against the closed `adb forward` port.
Future<_DriveAttemptResult> _runFlutterDrive(String testDir, List<String> driveArgs) async {
  const slowVmConnectPatterns = <String>[
    'It is taking an unusually long time to connect to the VM',
    'Connecting to the VM Service is taking longer than expected',
    'Still attempting to connect to the VM Service',
    'Exception attempting to connect to the VM Service',
  ];

  var checkingTargetProcess = false;
  var terminatedDeadDrive = false;

  Future<void> killDriveIfTargetExited(io.Process process) async {
    if (terminatedDeadDrive || checkingTargetProcess) {
      return;
    }
    checkingTargetProcess = true;
    try {
      final CommandResult pidResult = await _runAdb(<String>[
        'shell',
        'pidof',
        'com.example.android_hardware_smoke_test',
      ]);
      final String pidStdout = pidResult.flattenedStdout ?? '';
      if (!terminatedDeadDrive && (pidResult.exitCode != 0 || pidStdout.trim().isEmpty)) {
        terminatedDeadDrive = true;
        io.stderr.writeln(
          'Target process com.example.android_hardware_smoke_test exited while '
          'FlutterDriver was connecting. Terminating hung flutter drive...',
        );
        // Send SIGKILL on POSIX because flutter_tools catches SIGTERM and exits 0.
        if (io.Platform.isWindows) {
          process.kill();
        } else {
          process.kill(io.ProcessSignal.sigkill);
        }
      }
    } catch (e) {
      io.stderr.writeln('Warning: Failed to check if target process is alive: $e');
    } finally {
      checkingTargetProcess = false;
    }
  }

  void onDriveOutputLine(String line, io.Process process) {
    if (slowVmConnectPatterns.any(line.contains)) {
      unawaited(killDriveIfTargetExited(process));
    }
  }

  final CommandResult result = await runCommand(
    'flutter',
    driveArgs,
    workingDirectory: testDir,
    expectedExit: ExpectedExit.any,
    outputListener: onDriveOutputLine,
    stderrListener: onDriveOutputLine,
  );
  return (
    exitCode: result.exitCode,
    output: '${result.flattenedStdout ?? ''}\n${result.flattenedStderr ?? ''}',
    terminatedDeadDrive: terminatedDeadDrive,
  );
}

/// Restarts Android userspace (`surfaceflinger` and `zygote`) via `adb shell stop` and
/// `adb shell start` to rebind display composition against the host emulator renderer.
///
/// Skips restarting without recording an error if the connected device does not support
/// `adb root` (such as a production `user`-build physical device).
Future<void> _restartAndroidUserspace() async {
  final CommandResult rootResult = await _runAdb(<String>['root']);
  final rootOutput = '${rootResult.flattenedStdout ?? ''}\n${rootResult.flattenedStderr ?? ''}';
  if (rootResult.exitCode != 0 || rootOutput.contains('cannot run as root')) {
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
  await _runAdb(<String>['shell', 'stop'], outputMode: OutputMode.print);
  await _runAdb(<String>['shell', 'start'], outputMode: OutputMode.print);
  await _pollAdbUntil(
    <String>['shell', 'getprop', 'sys.boot_completed'],
    description: 'sys.boot_completed=1 after Android userspace restart',
    pollInterval: const Duration(seconds: 1),
    condition: (CommandResult r) => (r.flattenedStdout ?? '').trim() == '1',
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
  bool Function(CommandResult result)? condition,
}) async {
  if (dryRun) {
    await _runAdb(arguments, outputMode: outputMode);
    return;
  }
  final stopwatch = Stopwatch()..start();
  Duration nextWarning = _adbSlowWarningInterval;
  while (true) {
    final CommandResult result = await _runAdb(arguments, outputMode: outputMode);
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

/// Returns a human-readable retry reason when [result] or `adb logcat` indicates a
/// blank-display compositor wedge, fatal graphics initialization error, or early target
/// app crash during VM service connection, or `null` if the failure is non-retryable.
///
/// Retries are intentionally scoped to these transient infrastructure failures so general
/// test assertion or golden pixel mismatch failures fail fast on attempt 1 without masking
/// real visual regressions.
Future<String?> _detectRetryableFailureReason(_DriveAttemptResult result) async {
  final reasons = <String>[
    if (result.terminatedDeadDrive) 'target app crash during VM service connection',
    // Match errorBlankScreenshot in android_hardware_smoke_test/lib/constants.dart
    // (duplicated here because standalone Dart package tests_on_bots cannot import
    // Flutter app packages).
    if (result.output.contains('Captured screenshot is blank/empty')) 'blank display capture',
  ];

  // Inspect logcat directly so fatal graphics errors are reported both when flutter drive
  // disconnects before Dart surfaces a test exception and alongside blank captures or crashes.
  try {
    final CommandResult logcatResult = await _runAdb(<String>['logcat', '-d']);
    final String? fatalError = logcatResult.exitCode == 0
        ? _firstFatalGraphicsLogcatError(logcatResult.flattenedStdout ?? '')
        : null;
    if (fatalError != null) {
      reasons.add('fatal graphics error in logcat ($fatalError)');
    }
  } catch (e) {
    io.stderr.writeln('Warning: Failed to check logcat for EGL failure: $e');
  }

  return reasons.isEmpty ? null : reasons.join(' and ');
}

/// Returns the first unrecoverable EGL, Vulkan, or host-pipe graphics initialization error
/// matched in [logcatOutput], ignoring benign Android HWUI capability-probe warnings.
// Keep in sync with isFatalGraphicsPipelineError in FlutterActivityTest.kt.
String? _firstFatalGraphicsLogcatError(String logcatOutput) {
  const fatalPatterns = <String>[
    'EGL_NOT_INITIALIZED',
    'EGL_BAD_ALLOC',
    'EGL_BAD_CONFIG',
    'EGL_BAD_CONTEXT',
    'EGL_BAD_DISPLAY',
    'EGL_BAD_NATIVE_WINDOW',
    'EGL_BAD_SURFACE',
    'EGL_CONTEXT_LOST',
    'Failed to create EGLSurface',
    'Failed to initialize EGL',
    'Unable to initialize EGL',
    'Failed to establish connection with the host',
    'vulkan: Failed to get host connection',
    'Could not create Vulkan instance',
    'Could not create surface from invalid Android context',
  ];

  for (final String line in LineSplitter.split(logcatOutput)) {
    if (line.contains('eglInitialize(') && line.contains(') failed (')) {
      return 'eglInitialize failed';
    }
    // Ignore Android HWUI capability-probe warnings logged unconditionally during normal
    // display initialization on SwiftShader and headless emulators.
    if (line.contains('EGL_SWAP_BEHAVIOR_PRESERVED') || line.contains('error = EGL_SUCCESS')) {
      continue;
    }
    final String? matchedPattern = fatalPatterns.where(line.contains).firstOrNull;
    if (matchedPattern != null) {
      return matchedPattern;
    }
  }
  return null;
}
