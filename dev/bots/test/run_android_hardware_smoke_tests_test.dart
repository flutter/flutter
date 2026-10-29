// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:file/file.dart';
import 'package:file/memory.dart';
import 'package:path/path.dart' as path;

import '../run_command.dart';
import '../suite_runners/run_android_engine_tests.dart';
import '../suite_runners/run_android_hardware_smoke_tests.dart';
import '../utils.dart';
import 'common.dart';

MemoryFileSystem _createFakeSmokeFileSystem() {
  final fs = MemoryFileSystem();
  final String testDir = path.join('dev', 'integration_tests', 'android_hardware_smoke_test');
  final File manifest = fs.file(
    path.join(testDir, 'android', 'app', 'src', 'main', 'AndroidManifest.xml'),
  )..createSync(recursive: true);
  manifest.writeAsStringSync('''
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
  <application>
    <meta-data android:name="io.flutter.embedding.android.ImpellerBackend" android:value="vulkan" />
  </application>
</manifest>
''');
  final Directory goldensDir = fs.directory(path.join(testDir, 'test_driver', 'goldens'))
    ..createSync(recursive: true);
  goldensDir.childFile('README.md').writeAsStringSync('keep');
  goldensDir.childFile('generated.png').writeAsStringSync('delete');
  return fs;
}

void main() {
  final PrintCallback originalPrint = print;

  setUp(() {
    print = (Object? _) {};
    resetErrorStatus();
  });

  tearDown(() {
    print = originalPrint;
    resetErrorStatus();
  });

  group('hasFatalEglLogcatError', () {
    test('ignores benign HWUI warnings on SwiftShader emulators', () {
      const benignLogcat = '''
10-28 14:32:10.123  1234  1256 W HWUI    : Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED, retrying without...
10-28 14:32:10.124  1234  1256 W HWUI    : Failed to initialize 101010-2 format, error = EGL_SUCCESS
10-28 14:32:10.125  1234  1234 W HWUI    : Unknown dataspace 0
10-28 14:32:12.800  1234  1234 I Choreographer: Skipped 45 frames!
10-28 14:32:12.801  1234  1256 I HWUI    : Davey! duration=920ms; Flags=1
''';
      expect(hasFatalEglLogcatError(benignLogcat), isFalse);
    });

    test('matches fatal EGL initialization and surface errors', () {
      expect(
        hasFatalEglLogcatError('E libEGL  : eglInitialize:145 error 3001 (EGL_NOT_INITIALIZED)'),
        isTrue,
      );
      expect(
        hasFatalEglLogcatError('E OpenGLRenderer: Failed to choose config: EGL_BAD_CONFIG'),
        isTrue,
      );
      expect(
        hasFatalEglLogcatError('F HWUI    : Failed to create EGLSurface for window, eglErr=12299'),
        isTrue,
      );
      expect(hasFatalEglLogcatError('E FlutterJNI: Context lost: EGL_CONTEXT_LOST'), isTrue);
      expect(
        hasFatalEglLogcatError('E EGL_emulation: Failed to establish connection with the host'),
        isTrue,
      );
      expect(
        hasFatalEglLogcatError('W libEGL  : eglInitialize(0x72dd4ec030) failed (EGL_SUCCESS)'),
        isTrue,
      );
      expect(hasFatalEglLogcatError('E MESA    : vulkan: Failed to get host connection'), isTrue);
      expect(
        hasFatalEglLogcatError(
          'E flutter : [ERROR:flutter/impeller/renderer/backend/vulkan/context_vk.cc(262)] Could not create Vulkan instance: ErrorDeviceLost',
        ),
        isTrue,
      );
      expect(
        hasFatalEglLogcatError(
          'F flutter : [FATAL:flutter/shell/platform/android/platform_view_android.cc(162)] Check failed: android_context_->IsValid(). Could not create surface from invalid Android context.',
        ),
        isTrue,
      );
    });
  });

  group('runAndroidHardwareSmokeTests', () {
    test('restarts Android userspace and recovers without setting hasError when attempt 1 hits blank screenshot', () async {
      final MemoryFileSystem fs = _createFakeSmokeFileSystem();
      final recordedCommands = <String>[];
      var driveAttempt = 0;
      var bootPolls = 0;

      await runAndroidHardwareSmokeTests(
        backend: ImpellerBackend.opengles,
        fileSystem: fs,
        delay: (Duration _) async {},
        commandRunner:
            (
              String exe,
              List<String> args, {
              String? workingDirectory,
              bool allowNonZeroExit = false,
              OutputMode outputMode = OutputMode.print,
              void Function(String line, void Function() killProcess)? onLine,
            }) async {
              final cmd = '$exe ${args.join(' ')}';
              recordedCommands.add(cmd);
              if (exe == 'flutter' && args.first == 'drive') {
                driveAttempt++;
                expect(allowNonZeroExit, isTrue);
                if (driveAttempt == 1) {
                  return CommandResult.test(
                    exitCode: 1,
                    flattenedStdout: 'Captured screenshot is blank/empty after 3 attempts.',
                  );
                }
                return CommandResult.test(exitCode: 0, flattenedStdout: 'All tests passed!');
              }
              if (cmd == 'adb shell getprop sys.boot_completed') {
                bootPolls++;
                return CommandResult.test(
                  exitCode: 0,
                  flattenedStdout: bootPolls >= 2 ? '1\n' : '0\n',
                );
              }
              return CommandResult.test(exitCode: 0, flattenedStdout: '');
            },
      );

      expect(driveAttempt, 2);
      expect(hasError, isFalse);
      expect(
        recordedCommands,
        containsAllInOrder(<String>[
          'flutter drive --driver=test_driver/driver_test.dart --target=integration_test/integration_test_wrapper.dart --no-dds --no-enable-dart-profiling',
          'adb root',
          'adb wait-for-device',
          'adb shell setprop sys.boot_completed 0',
          'adb shell stop',
          'adb shell start',
          'adb shell getprop sys.boot_completed',
          'adb shell getprop sys.boot_completed',
          'flutter drive --driver=test_driver/driver_test.dart --target=integration_test/integration_test_wrapper.dart --no-dds --no-enable-dart-profiling --no-build',
        ]),
      );

      // Verify manifest restoration and golden directory cleanup.
      final String manifestPath = path.join(
        'dev',
        'integration_tests',
        'android_hardware_smoke_test',
        'android',
        'app',
        'src',
        'main',
        'AndroidManifest.xml',
      );
      expect(fs.file(manifestPath).readAsStringSync(), contains('android:value="vulkan"'));
      final String goldensPath = path.join(
        'dev',
        'integration_tests',
        'android_hardware_smoke_test',
        'test_driver',
        'goldens',
      );
      expect(fs.file(path.join(goldensPath, 'README.md')).existsSync(), isTrue);
      expect(fs.file(path.join(goldensPath, 'generated.png')).existsSync(), isFalse);
    });

    test('records error when retryable failure persists across all attempts', () async {
      final MemoryFileSystem fs = _createFakeSmokeFileSystem();
      var driveAttempt = 0;

      await runAndroidHardwareSmokeTests(
        backend: ImpellerBackend.vulkan,
        fileSystem: fs,
        delay: (Duration _) async {},
        commandRunner:
            (
              String exe,
              List<String> args, {
              String? workingDirectory,
              bool allowNonZeroExit = false,
              OutputMode outputMode = OutputMode.print,
              void Function(String line, void Function() killProcess)? onLine,
            }) async {
              final cmd = '$exe ${args.join(' ')}';
              if (exe == 'flutter' && args.first == 'drive') {
                driveAttempt++;
                return CommandResult.test(
                  exitCode: 1,
                  flattenedStdout: 'Captured screenshot is blank/empty after 3 attempts.',
                );
              }
              if (cmd == 'adb shell getprop sys.boot_completed') {
                return CommandResult.test(exitCode: 0, flattenedStdout: '1\n');
              }
              return CommandResult.test(exitCode: 0, flattenedStdout: '');
            },
      );

      expect(driveAttempt, 2);
      expect(hasError, isTrue);
    });

    test('fails fast on attempt 1 without retry on golden mismatch despite EGL_SWAP_BEHAVIOR_PRESERVED', () async {
      final MemoryFileSystem fs = _createFakeSmokeFileSystem();
      final recordedCommands = <String>[];
      var driveAttempt = 0;

      await runAndroidHardwareSmokeTests(
        backend: ImpellerBackend.vulkan,
        fileSystem: fs,
        delay: (Duration _) async {},
        commandRunner:
            (
              String exe,
              List<String> args, {
              String? workingDirectory,
              bool allowNonZeroExit = false,
              OutputMode outputMode = OutputMode.print,
              void Function(String line, void Function() killProcess)? onLine,
            }) async {
              final cmd = '$exe ${args.join(' ')}';
              recordedCommands.add(cmd);
              if (exe == 'flutter' && args.first == 'drive') {
                driveAttempt++;
                return CommandResult.test(
                  exitCode: 1,
                  flattenedStdout: 'Expected: golden image match\nActual: does not match',
                );
              }
              if (cmd == 'adb logcat -d') {
                return CommandResult.test(
                  exitCode: 0,
                  flattenedStdout: 'W/HWUI: Failed to choose config with EGL_SWAP_BEHAVIOR_PRESERVED, retrying without...',
                );
              }
              return CommandResult.test(exitCode: 0, flattenedStdout: '');
            },
      );

      expect(driveAttempt, 1);
      expect(hasError, isTrue);
      expect(recordedCommands, isNot(contains('adb shell stop')));
    });

    test('skips userspace restart cleanly on non-root production devices', () async {
      final MemoryFileSystem fs = _createFakeSmokeFileSystem();
      final recordedCommands = <String>[];
      var driveAttempt = 0;

      await runAndroidHardwareSmokeTests(
        backend: ImpellerBackend.vulkan,
        fileSystem: fs,
        delay: (Duration _) async {},
        commandRunner:
            (
              String exe,
              List<String> args, {
              String? workingDirectory,
              bool allowNonZeroExit = false,
              OutputMode outputMode = OutputMode.print,
              void Function(String line, void Function() killProcess)? onLine,
            }) async {
              final cmd = '$exe ${args.join(' ')}';
              recordedCommands.add(cmd);
              if (exe == 'flutter' && args.first == 'drive') {
                driveAttempt++;
                if (driveAttempt == 1) {
                  return CommandResult.test(
                    exitCode: 1,
                    flattenedStdout: 'Captured screenshot is blank/empty after 3 attempts.',
                  );
                }
                return CommandResult.test(exitCode: 0, flattenedStdout: 'All tests passed!');
              }
              if (cmd == 'adb root') {
                return CommandResult.test(
                  exitCode: 0,
                  flattenedStdout: 'adbd cannot run as root in production builds\n',
                );
              }
              return CommandResult.test(exitCode: 0, flattenedStdout: '');
            },
      );

      expect(driveAttempt, 2);
      expect(hasError, isFalse);
      expect(recordedCommands, contains('adb root'));
      expect(recordedCommands, isNot(contains('adb shell stop')));
    });

    test('terminates hung flutter drive when target app crashes during EGL startup and recovers on attempt 2', () async {
      final MemoryFileSystem fs = _createFakeSmokeFileSystem();
      final recordedCommands = <String>[];
      var driveAttempt = 0;
      var killedHungDrive = false;

      await runAndroidHardwareSmokeTests(
        backend: ImpellerBackend.opengles,
        fileSystem: fs,
        delay: (Duration _) async {},
        commandRunner:
            (
              String exe,
              List<String> args, {
              String? workingDirectory,
              bool allowNonZeroExit = false,
              OutputMode outputMode = OutputMode.print,
              void Function(String line, void Function() killProcess)? onLine,
            }) async {
              final cmd = '$exe ${args.join(' ')}';
              recordedCommands.add(cmd);
              if (exe == 'flutter' && args.first == 'drive') {
                driveAttempt++;
                if (driveAttempt == 1) {
                  onLine!('Connecting to the VM Service is taking longer than expected...\n', () {
                    killedHungDrive = true;
                  });
                  await Future<void>.delayed(Duration.zero);
                  expect(killedHungDrive, isTrue);
                  // Even if flutter_tools catches a termination signal and exits 0,
                  // terminatedDeadDrive must still treat the attempt as failed.
                  return CommandResult.test(exitCode: 0, flattenedStderr: '');
                }
                return CommandResult.test(exitCode: 0, flattenedStdout: 'All tests passed!');
              }
              if (cmd == 'adb shell pidof com.example.android_hardware_smoke_test') {
                return CommandResult.test(exitCode: 1, flattenedStdout: '');
              }
              if (cmd == 'adb logcat -d') {
                return CommandResult.test(
                  exitCode: 0,
                  flattenedStdout:
                      'E EGL_emulation: Failed to establish connection with the host\n'
                      'W libEGL  : eglInitialize(0x72dd4ec030) failed (EGL_SUCCESS)\n',
                );
              }
              if (cmd == 'adb shell getprop sys.boot_completed') {
                return CommandResult.test(exitCode: 0, flattenedStdout: '1\n');
              }
              return CommandResult.test(exitCode: 0, flattenedStdout: '');
            },
      );

      expect(killedHungDrive, isTrue);
      expect(driveAttempt, 2);
      expect(hasError, isFalse);
      expect(recordedCommands, contains('adb shell pidof com.example.android_hardware_smoke_test'));
      expect(recordedCommands, contains('adb shell stop'));
    });
  });
}
