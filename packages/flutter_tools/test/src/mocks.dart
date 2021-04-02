// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:convert';

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart' show AndroidSdk;
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/globals_null_migrated.dart' as globals;
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';

import 'fakes.dart';

/// An SDK installation with several SDK levels (19, 22, 23).
class MockAndroidSdk extends Mock implements AndroidSdk {
  static Directory createSdkDirectory({
    bool withAndroidN = false,
    bool withSdkManager = true,
    bool withPlatformTools = true,
    bool withBuildTools = true,
  }) {
    final Directory dir = globals.fs.systemTempDirectory.createTempSync('flutter_mock_android_sdk.');
    final String exe = globals.platform.isWindows ? '.exe' : '';
    final String bat = globals.platform.isWindows ? '.bat' : '';

    _createDir(dir, 'licenses');

    if (withPlatformTools) {
      _createSdkFile(dir, 'platform-tools/adb$exe');
    }

    if (withBuildTools) {
      _createSdkFile(dir, 'build-tools/19.1.0/aapt$exe');
      _createSdkFile(dir, 'build-tools/22.0.1/aapt$exe');
      _createSdkFile(dir, 'build-tools/23.0.2/aapt$exe');
      if (withAndroidN) {
        _createSdkFile(dir, 'build-tools/24.0.0-preview/aapt$exe');
      }
    }

    _createSdkFile(dir, 'platforms/android-22/android.jar');
    _createSdkFile(dir, 'platforms/android-23/android.jar');
    if (withAndroidN) {
      _createSdkFile(dir, 'platforms/android-N/android.jar');
      _createSdkFile(dir, 'platforms/android-N/build.prop', contents: _buildProp);
    }

    if (withSdkManager) {
      _createSdkFile(dir, 'tools/bin/sdkmanager$bat');
    }

    return dir;
  }

  static void _createSdkFile(Directory dir, String filePath, { String contents }) {
    final File file = dir.childFile(filePath);
    file.createSync(recursive: true);
    if (contents != null) {
      file.writeAsStringSync(contents, flush: true);
    }
  }

  static void _createDir(Directory dir, String path) {
    final Directory directory = globals.fs.directory(globals.fs.path.join(dir.path, path));
    directory.createSync(recursive: true);
  }

  static const String _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
}

/// A strategy for creating Process objects from a list of commands.
typedef _ProcessFactory = Process Function(List<String> command);

/// A ProcessManager that starts Processes by delegating to a ProcessFactory.
class MockProcessManager extends Mock implements ProcessManager {
  _ProcessFactory processFactory = _defaulProcessFactory;
  bool canRunSucceeds = true;
  bool runSucceeds = true;
  List<String> commands;

  static Process _defaulProcessFactory(List<String> commands) => FakeProcess();

  @override
  bool canRun(dynamic command, { String workingDirectory }) => canRunSucceeds;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) {
    final List<String> commands = command.cast<String>();
    if (!runSucceeds) {
      final String executable = commands[0];
      final List<String> arguments = commands.length > 1 ? commands.sublist(1) : <String>[];
      throw ProcessException(executable, arguments);
    }

    this.commands = commands;
    return Future<Process>.value(processFactory(commands));
  }
}

/// A function that generates a process factory that gives processes that fail
/// a given number of times before succeeding. The returned processes will
/// fail after a delay if one is supplied.
_ProcessFactory flakyProcessFactory({
  int flakes,
  bool Function(List<String> command) filter,
  Duration delay,
  Stream<List<int>> Function() stdout,
  Stream<List<int>> Function() stderr,
}) {
  int flakesLeft = flakes;
  stdout ??= () => const Stream<List<int>>.empty();
  stderr ??= () => const Stream<List<int>>.empty();
  return (List<String> command) {
    if (filter != null && !filter(command)) {
      return FakeProcess();
    }
    if (flakesLeft == 0) {
      return FakeProcess(
        exitCode: Future<int>.value(0),
        stdout: stdout(),
        stderr: stderr(),
      );
    }
    flakesLeft = flakesLeft - 1;
    Future<int> exitFuture;
    if (delay == null) {
      exitFuture = Future<int>.value(-9);
    } else {
      exitFuture = Future<int>.delayed(delay, () => Future<int>.value(-9));
    }
    return FakeProcess(
      exitCode: exitFuture,
      stdout: stdout(),
      stderr: stderr(),
    );
  };
}

/// Creates a mock process that returns with the given [exitCode], [stdout] and [stderr].
Process createMockProcess({ int exitCode = 0, String stdout = '', String stderr = '' }) {
  final Stream<List<int>> stdoutStream = Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stdout),
  ]);
  final Stream<List<int>> stderrStream = Stream<List<int>>.fromIterable(<List<int>>[
    utf8.encode(stderr),
  ]);
  final Process process = _MockBasicProcess();

  when(process.stdout).thenAnswer((_) => stdoutStream);
  when(process.stderr).thenAnswer((_) => stderrStream);
  when(process.exitCode).thenAnswer((_) => Future<int>.value(exitCode));
  return process;
}

class _MockBasicProcess extends Mock implements Process {}

class MockAndroidDevice extends Mock implements AndroidDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;

  @override
  bool isSupported() => true;

  @override
  bool get supportsHotRestart => true;

  @override
  bool get supportsFlutterExit => false;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;
}

class MockIOSDevice extends Mock implements IOSDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;
}

class MockStdIn extends Mock implements IOSink {
  final StringBuffer stdInWrites = StringBuffer();

  String getAndClear() {
    final String result = stdInWrites.toString();
    stdInWrites.clear();
    return result;
  }

  @override
  void write([ Object o = '' ]) {
    stdInWrites.write(o);
  }

  @override
  void writeln([ Object o = '' ]) {
    stdInWrites.writeln(o);
  }
}

class MockStream extends Mock implements Stream<List<int>> {}
