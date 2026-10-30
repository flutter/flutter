// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:file/file.dart';
import 'package:file/local.dart';
import 'package:meta/meta.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../utils.dart';
import 'run_android_engine_tests.dart';

/// Signature for executing text-output commands in [runAndroidHardwareSmokeTests].
@visibleForTesting
typedef SmokeCommandRunner = Future<CommandResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool allowNonZeroExit,
  OutputMode outputMode,
  void Function(String line, void Function() killProcess)? onLine,
});

/// Signature for asynchronous delays in [runAndroidHardwareSmokeTests].
@visibleForTesting
typedef SmokeDelay = Future<void> Function(Duration duration);

Future<CommandResult> _defaultCommandRunner(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
  bool allowNonZeroExit = false,
  OutputMode outputMode = OutputMode.print,
  void Function(String line, void Function() killProcess)? onLine,
}) {
  final void Function(String, io.Process)? listener = onLine == null
      ? null
      : (String line, io.Process process) =>
            onLine(line, () => process.kill(io.ProcessSignal.sigkill));
  return runCommand(
    executable,
    arguments,
    workingDirectory: workingDirectory,
    allowNonZeroExit: allowNonZeroExit,
    outputMode: outputMode,
    outputListener: listener,
    stderrListener: listener,
  );
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
  @visibleForTesting FileSystem fileSystem = const LocalFileSystem(),
  @visibleForTesting SmokeCommandRunner commandRunner = _defaultCommandRunner,
  @visibleForTesting SmokeDelay delay = Future<void>.delayed,
}) async {
  printProgress('Running Android Hardware Smoke Tests Shard (backend=${backend.name})');

  final String testDir = path.join('dev', 'integration_tests', 'android_hardware_smoke_test');

  await _regenerateAndroidWrappers(testDir, commandRunner);

  final String androidDir = path.join(testDir, 'android');
  final File androidManifestXml = fileSystem.file(
    path.join(androidDir, 'app', 'src', 'main', 'AndroidManifest.xml'),
  );
  final String androidManifestContents = androidManifestXml.readAsStringSync();

  final Directory destinationDir = fileSystem.directory(
    path.join(testDir, 'test_driver', 'goldens'),
  );

  try {
    _setAndroidManifestBackend(androidManifestXml, androidManifestContents, backend);

    // 1. Run driver tests to generate or verify reference screenshots.
    final bool success = await _runRetryLoop(testDir, commandRunner: commandRunner, delay: delay);
    if (!success) {
      return;
    }

    if (runInstrumented) {
      final String gradle = path.absolute(
        path.join(androidDir, io.Platform.isWindows ? 'gradlew.bat' : 'gradlew'),
      );

      // 2. Build and run the instrumented tests.
      await commandRunner(gradle, <String>[
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

Future<void> _regenerateAndroidWrappers(String testDir, SmokeCommandRunner commandRunner) async {
  await commandRunner('flutter', <String>[
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

Future<bool> _runRetryLoop(
  String testDir, {
  required SmokeCommandRunner commandRunner,
  required SmokeDelay delay,
}) async {
  const maxAttempts = 2;

  for (var attempt = 1; attempt <= maxAttempts; attempt++) {
    await commandRunner('adb', <String>['logcat', '-c']);

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

    // If the app crashes during native EGL or Vulkan surface creation right after logging
    // its Dart VM service URI, either flutter_tools (_vmServiceConnector) or FlutterDriver.connect()
    // loops indefinitely against the closed adb forward port. Check whether the target process is
    // still alive when VM connect stalls so hung driver processes terminate immediately rather than
    // exhausting the shard timeout.
    var checkingTargetProcess = false;
    var terminatedDeadDrive = false;
    void checkTargetAliveOnSlowVmConnect(String line, void Function() killProcess) {
      final bool isSlowVmConnect =
          line.contains('It is taking an unusually long time to connect to the VM') ||
          line.contains('Connecting to the VM Service is taking longer than expected') ||
          line.contains('Still attempting to connect to the VM Service') ||
          line.contains('Exception attempting to connect to the VM Service');
      if (terminatedDeadDrive || checkingTargetProcess || !isSlowVmConnect) {
        return;
      }
      checkingTargetProcess = true;
      unawaited(() async {
        try {
          final CommandResult pidResult = await commandRunner(
            'adb',
            <String>['shell', 'pidof', 'com.example.android_hardware_smoke_test'],
            allowNonZeroExit: true,
            outputMode: OutputMode.capture,
          );
          if (!terminatedDeadDrive &&
              (pidResult.exitCode != 0 || (pidResult.flattenedStdout ?? '').trim().isEmpty)) {
            terminatedDeadDrive = true;
            io.stderr.writeln(
              'Target process com.example.android_hardware_smoke_test exited while '
              'FlutterDriver was connecting. Terminating hung flutter drive...',
            );
            killProcess();
          }
        } catch (e) {
          io.stderr.writeln('Warning: Failed to check if target process is alive: $e');
        } finally {
          checkingTargetProcess = false;
        }
      }());
    }

    // Use allowNonZeroExit so a transient failure on attempt 1 does not record a
    // permanent global error before the retry attempt has a chance to pass.
    final CommandResult result = await commandRunner(
      'flutter',
      driveArgs,
      workingDirectory: testDir,
      allowNonZeroExit: true,
      onLine: checkTargetAliveOnSlowVmConnect,
    );
    // Also check !terminatedDeadDrive because flutter_tools can catch SIGTERM and exit 0.
    if (result.exitCode == 0 && !terminatedDeadDrive) {
      return true;
    }

    io.stderr.writeln(
      'flutter drive failed with exit code ${result.exitCode} on attempt $attempt/$maxAttempts.',
    );

    final driverOutput = '${result.flattenedStdout ?? ''}\n${result.flattenedStderr ?? ''}';

    // Intentionally scope retries strictly to blank-display compositor wedges and fatal
    // EGL initialization errors. General test assertion or golden pixel mismatch failures
    // must fail fast on attempt 1 so real visual regressions are not masked.
    final bool isRetryableFailure = await _isRetryableDisplayOrEglFailure(
      driverOutput,
      commandRunner: commandRunner,
    );
    if (isRetryableFailure) {
      if (attempt < maxAttempts) {
        // Restoring an emulator QuickBoot snapshot across a host renderer change can wedge
        // SurfaceFlinger into returning solid-black screencaps while offscreen app rendering
        // still works. Re-running `flutter drive --no-build` alone only restarts the app
        // Activity and cannot recover SurfaceFlinger, so restart Android userspace reactively
        // here (avoiding pre-flight restart overhead on healthy runs).
        io.stderr.writeln(
          'Attempt $attempt failed due to blank display capture or fatal EGL error. '
          'Restarting Android userspace before retry...',
        );
        await _restartAndroidUserspace(commandRunner: commandRunner, delay: delay);
        continue;
      }
      foundError(<String>[
        'Android Hardware Smoke Tests failed due to emulator display compositor or EGL pipeline failure after $maxAttempts attempts.',
        'Command: flutter ${driveArgs.join(' ')}',
        'Working directory: ${path.absolute(testDir)}',
      ]);
      return false;
    }

    foundError(<String>[
      'Android Hardware Smoke Tests driver run failed with exit code ${result.exitCode}.',
      'Command: flutter ${driveArgs.join(' ')}',
      'Working directory: ${path.absolute(testDir)}',
    ]);
    return false;
  }

  throw StateError('Unreachable');
}

/// Restarts Android userspace (`surfaceflinger` and `zygote`) via `adb shell stop` and
/// `adb shell start` to rebind display composition against the host emulator renderer.
///
/// Returns `false` without recording an error if the connected device does not support
/// `adb root` (such as a production `user`-build physical device).
Future<bool> _restartAndroidUserspace({
  required SmokeCommandRunner commandRunner,
  required SmokeDelay delay,
}) async {
  Future<CommandResult> runAdb(List<String> args, {OutputMode outputMode = OutputMode.capture}) {
    return commandRunner('adb', args, allowNonZeroExit: true, outputMode: outputMode);
  }

  final CommandResult rootResult = await runAdb(<String>['root']);
  final rootOutput = '${rootResult.flattenedStdout ?? ''}\n${rootResult.flattenedStderr ?? ''}';
  if (rootResult.exitCode != 0 || rootOutput.contains('cannot run as root')) {
    io.stderr.writeln(
      'Skipping Android userspace restart: adb root is not supported on this device.',
    );
    return false;
  }

  await runAdb(<String>['wait-for-device'], outputMode: OutputMode.print);

  // Clear sys.boot_completed before stopping userspace because `adb shell stop` does
  // not reset system properties, and polling would otherwise immediately read stale '1'.
  await runAdb(<String>['shell', 'setprop', 'sys.boot_completed', '0']);
  await runAdb(<String>['shell', 'stop'], outputMode: OutputMode.print);
  await runAdb(<String>['shell', 'start'], outputMode: OutputMode.print);

  const maxBootPolls = 60;
  var booted = false;
  for (var poll = 0; poll < maxBootPolls; poll++) {
    final CommandResult propResult = await runAdb(<String>[
      'shell',
      'getprop',
      'sys.boot_completed',
    ]);
    if (propResult.exitCode == 0 && (propResult.flattenedStdout ?? '').trim() == '1') {
      booted = true;
      break;
    }
    await delay(const Duration(seconds: 1));
  }

  if (!booted) {
    io.stderr.writeln(
      'Warning: Timed out waiting for sys.boot_completed=1 after restarting Android userspace.',
    );
    return false;
  }

  await runAdb(<String>['shell', 'input', 'keyevent', 'KEYCODE_WAKEUP']);
  await runAdb(<String>['shell', 'wm', 'dismiss-keyguard']);
  // Allow the launcher surface to draw an initial frame after userspace comes back up.
  await delay(const Duration(seconds: 2));
  return true;
}

Future<bool> _isRetryableDisplayOrEglFailure(
  String driverOutput, {
  required SmokeCommandRunner commandRunner,
}) async {
  // Match blank-capture and EGL exceptions reported by driver_test.dart (errorBlankScreenshot
  // in constants.dart) or FlutterActivityTest.kt. Keep these substrings in sync with both files.
  final bool hasBlankOrEglTestError =
      driverOutput.contains('Captured screenshot is blank/empty') ||
      driverOutput.contains('BlankScreenshotException') ||
      driverOutput.contains('EglInitializationException');
  if (hasBlankOrEglTestError) {
    return true;
  }

  // Fall back to inspecting logcat directly in case a fatal EGL failure crashed the app or
  // disconnected flutter drive before Dart could surface a structured test exception.
  try {
    final CommandResult logcatResult = await commandRunner(
      'adb',
      <String>['logcat', '-d'],
      allowNonZeroExit: true,
      outputMode: OutputMode.capture,
    );
    if (logcatResult.exitCode != 0) {
      return false;
    }
    return hasFatalEglLogcatError(logcatResult.flattenedStdout ?? '');
  } catch (e) {
    io.stderr.writeln('Warning: Failed to check logcat for EGL failure: $e');
    return false;
  }
}

/// Returns whether [logcatOutput] contains an unrecoverable EGL, Vulkan, or host-pipe
/// graphics initialization error, ignoring benign Android HWUI capability-probe warnings.
// Keep in sync with GraphicsErrorLogFilter.kt.
@visibleForTesting
bool hasFatalEglLogcatError(String logcatOutput) {
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
    // Ignore Android HWUI capability-probe warnings logged unconditionally during normal
    // display initialization on SwiftShader and headless emulators. Match 'error = EGL_SUCCESS'
    // specifically so real libEGL 'eglInitialize(...) failed (EGL_SUCCESS)' failures are not masked.
    if (line.contains('EGL_SWAP_BEHAVIOR_PRESERVED') || line.contains('error = EGL_SUCCESS')) {
      continue;
    }
    if (line.contains('eglInitialize(') && line.contains(') failed (')) {
      return true;
    }
    for (final pattern in fatalPatterns) {
      if (line.contains(pattern)) {
        return true;
      }
    }
  }
  return false;
}
