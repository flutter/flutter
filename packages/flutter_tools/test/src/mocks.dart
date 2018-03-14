// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show IOSink;

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart' show AndroidSdk;
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/devfs.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';
import 'package:process/process.dart';
import 'package:test/test.dart';

class MockApplicationPackageStore extends ApplicationPackageStore {
  MockApplicationPackageStore() : super(
    android: new AndroidApk(
      id: 'io.flutter.android.mock',
      apkPath: '/mock/path/to/android/SkyShell.apk',
      launchActivity: 'io.flutter.android.mock.MockActivity'
    ),
    iOS: new BuildableIOSApp(
      appDirectory: '/mock/path/to/iOS/SkyShell.app',
      projectBundleId: 'io.flutter.ios.mock'
    )
  );
}

/// An SDK installation with several SDK levels (19, 22, 23).
class MockAndroidSdk extends Mock implements AndroidSdk {
  static Directory createSdkDirectory({
    bool withAndroidN: false,
    String withNdkDir,
    bool withNdkSysroot: false,
    bool withSdkManager: true,
  }) {
    final Directory dir = fs.systemTempDirectory.createTempSync('android-sdk');

    _createSdkFile(dir, 'platform-tools/adb');

    _createSdkFile(dir, 'build-tools/19.1.0/aapt');
    _createSdkFile(dir, 'build-tools/22.0.1/aapt');
    _createSdkFile(dir, 'build-tools/23.0.2/aapt');
    if (withAndroidN)
      _createSdkFile(dir, 'build-tools/24.0.0-preview/aapt');

    _createSdkFile(dir, 'platforms/android-22/android.jar');
    _createSdkFile(dir, 'platforms/android-23/android.jar');
    if (withAndroidN) {
      _createSdkFile(dir, 'platforms/android-N/android.jar');
      _createSdkFile(dir, 'platforms/android-N/build.prop', contents: _buildProp);
    }

    if (withSdkManager)
      _createSdkFile(dir, 'tools/bin/sdkmanager');

    if (withNdkDir != null) {
      final String ndkCompiler = fs.path.join(
          'ndk-bundle',
          'toolchains',
          'arm-linux-androideabi-4.9',
          'prebuilt',
          withNdkDir,
          'bin',
          'arm-linux-androideabi-gcc');
      _createSdkFile(dir, ndkCompiler);
    }
    if (withNdkSysroot) {
      final String armPlatform =
          fs.path.join('ndk-bundle', 'platforms', 'android-9', 'arch-arm');
      _createDir(dir, armPlatform);
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
    final Directory directory = fs.directory(fs.path.join(dir.path, path));
    directory.createSync(recursive: true);
  }

  static const String _buildProp = r'''
ro.build.version.incremental=1624448
ro.build.version.sdk=24
ro.build.version.codename=REL
''';
}

/// A strategy for creating Process objects from a list of commands.
typedef Process ProcessFactory(List<String> command);

/// A ProcessManager that starts Processes by delegating to a ProcessFactory.
class MockProcessManager implements ProcessManager {
  ProcessFactory processFactory = (List<String> commands) => new MockProcess();
  bool succeed = true;
  List<String> commands;

  @override
  bool canRun(dynamic command, { String workingDirectory }) => succeed;

  @override
  Future<Process> start(
    List<dynamic> command, {
    String workingDirectory,
    Map<String, String> environment,
    bool includeParentEnvironment: true,
    bool runInShell: false,
    ProcessStartMode mode: ProcessStartMode.NORMAL,
  }) {
    if (!succeed) {
      final String executable = command[0];
      final List<String> arguments = command.length > 1 ? command.sublist(1) : <String>[];
      throw new ProcessException(executable, arguments);
    }

    commands = command;
    return new Future<Process>.value(processFactory(command));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// A process that exits successfully with no output and ignores all input.
class MockProcess extends Mock implements Process {
  MockProcess({
    this.pid: 1,
    Future<int> exitCode,
    Stream<List<int>> stdin,
    this.stdout: const Stream<List<int>>.empty(),
    this.stderr: const Stream<List<int>>.empty(),
  }) : exitCode = exitCode ?? new Future<int>.value(0),
       stdin = stdin ?? new MemoryIOSink();

  @override
  final int pid;

  @override
  final Future<int> exitCode;

  @override
  final io.IOSink stdin;

  @override
  final Stream<List<int>> stdout;

  @override
  final Stream<List<int>> stderr;
}

/// A process that prompts the user to proceed, then asynchronously writes
/// some lines to stdout before it exits.
class PromptingProcess implements Process {
  Future<Null> showPrompt(String prompt, List<String> outputLines) async {
    _stdoutController.add(utf8.encode(prompt));
    final List<int> bytesOnStdin = await _stdin.future;
    // Echo stdin to stdout.
    _stdoutController.add(bytesOnStdin);
    if (bytesOnStdin[0] == utf8.encode('y')[0]) {
      for (final String line in outputLines)
        _stdoutController.add(utf8.encode('$line\n'));
    }
    await _stdoutController.close();
  }

  final StreamController<List<int>> _stdoutController = new StreamController<List<int>>();
  final CompleterIOSink _stdin = new CompleterIOSink();

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => const Stream<List<int>>.empty();

  @override
  IOSink get stdin => _stdin;

  @override
  Future<int> get exitCode async {
    await _stdoutController.done;
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

/// An IOSink that completes a future with the first line written to it.
class CompleterIOSink extends MemoryIOSink {
  final Completer<List<int>> _completer = new Completer<List<int>>();

  Future<List<int>> get future => _completer.future;

  @override
  void add(List<int> data) {
    if (!_completer.isCompleted)
      _completer.complete(data);
    super.add(data);
  }
}

/// An IOSink that collects whatever is written to it.
class MemoryIOSink implements IOSink {
  @override
  Encoding encoding = utf8;

  final List<List<int>> writes = <List<int>>[];

  @override
  void add(List<int> data) {
    writes.add(data);
  }

  @override
  Future<Null> addStream(Stream<List<int>> stream) {
    final Completer<Null> completer = new Completer<Null>();
    stream.listen((List<int> data) {
      add(data);
    }).onDone(() => completer.complete(null));
    return completer.future;
  }

  @override
  void writeCharCode(int charCode) {
    add(<int>[charCode]);
  }

  @override
  void write(Object obj) {
    add(encoding.encode('$obj'));
  }

  @override
  void writeln([Object obj = '']) {
    add(encoding.encode('$obj\n'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    bool addSeparator = false;
    for (dynamic object in objects) {
      if (addSeparator) {
        write(separator);
      }
      write(object);
      addSeparator = true;
    }
  }

  @override
  void addError(dynamic error, [StackTrace stackTrace]) {
    throw new UnimplementedError();
  }

  @override
  Future<Null> get done => close();

  @override
  Future<Null> close() async => null;

  @override
  Future<Null> flush() async => null;
}

/// A Stdio that collects stdout and supports simulated stdin.
class MockStdio extends Stdio {
  final MemoryIOSink _stdout = new MemoryIOSink();
  final StreamController<List<int>> _stdin = new StreamController<List<int>>();

  @override
  IOSink get stdout => _stdout;

  @override
  Stream<List<int>> get stdin => _stdin.stream;

  void simulateStdin(String line) {
    _stdin.add(utf8.encode('$line\n'));
  }

  List<String> get writtenToStdout => _stdout.writes.map(_stdout.encoding.decode).toList();
}

class MockPollingDeviceDiscovery extends PollingDeviceDiscovery {
  final List<Device> _devices = <Device>[];
  final StreamController<Device> _onAddedController = new StreamController<Device>.broadcast();
  final StreamController<Device> _onRemovedController = new StreamController<Device>.broadcast();

  MockPollingDeviceDiscovery() : super('mock');

  @override
  Future<List<Device>> pollingGetDevices() async => _devices;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  void addDevice(MockAndroidDevice device) {
    _devices.add(device);

    _onAddedController.add(device);
  }

  @override
  Future<List<Device>> get devices async => _devices;

  @override
  Stream<Device> get onAdded => _onAddedController.stream;

  @override
  Stream<Device> get onRemoved => _onRemovedController.stream;
}

class MockAndroidDevice extends Mock implements AndroidDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.android_arm;

  @override
  bool isSupported() => true;
}

class MockIOSDevice extends Mock implements IOSDevice {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  bool isSupported() => true;
}

class MockIOSSimulator extends Mock implements IOSSimulator {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  bool isSupported() => true;
}

class MockDeviceLogReader extends DeviceLogReader {
  @override
  String get name => 'MockLogReader';

  final StreamController<String> _linesController = new StreamController<String>.broadcast();

  @override
  Stream<String> get logLines => _linesController.stream;

  void addLine(String line) => _linesController.add(line);

  void dispose() {
    _linesController.close();
  }
}

void applyMocksToCommand(FlutterCommand command) {
  command
    ..applicationPackages = new MockApplicationPackageStore();
}

/// Common functionality for tracking mock interaction
class BasicMock {
  final List<String> messages = <String>[];

  void expectMessages(List<String> expectedMessages) {
    final List<String> actualMessages = new List<String>.from(messages);
    messages.clear();
    expect(actualMessages, unorderedEquals(expectedMessages));
  }

  bool contains(String match) {
    print('Checking for `$match` in:');
    print(messages);
    final bool result = messages.contains(match);
    messages.clear();
    return result;
  }
}

class MockDevFSOperations extends BasicMock implements DevFSOperations {
  Map<Uri, DevFSContent> devicePathToContent = <Uri, DevFSContent>{};

  @override
  Future<Uri> create(String fsName) async {
    messages.add('create $fsName');
    return Uri.parse('file:///$fsName');
  }

  @override
  Future<dynamic> destroy(String fsName) async {
    messages.add('destroy $fsName');
  }

  @override
  Future<dynamic> writeFile(String fsName, Uri deviceUri, DevFSContent content) async {
    messages.add('writeFile $fsName $deviceUri');
    devicePathToContent[deviceUri] = content;
  }

  @override
  Future<dynamic> deleteFile(String fsName, Uri deviceUri) async {
    messages.add('deleteFile $fsName $deviceUri');
    devicePathToContent.remove(deviceUri);
  }
}
