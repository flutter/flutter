// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io' as io show IOSink, ProcessSignal, Stdout, StdoutException;

import 'package:flutter_tools/src/android/android_device.dart';
import 'package:flutter_tools/src/android/android_sdk.dart' show AndroidSdk;
import 'package:flutter_tools/src/application_package.dart';
import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/file_system.dart' hide IOSink;
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/platform.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/compile.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/globals.dart' as globals;
import 'package:flutter_tools/src/ios/devices.dart';
import 'package:flutter_tools/src/ios/simulators.dart';
import 'package:flutter_tools/src/project.dart';
import 'package:flutter_tools/src/runner/flutter_command.dart';
import 'package:mockito/mockito.dart';
import 'package:package_config/package_config.dart';
import 'package:process/process.dart';

import 'common.dart';

// TODO(fujino): replace FakePlatform.fromPlatform() with FakePlatform()
final Generator kNoColorTerminalPlatform = () {
  return FakePlatform.fromPlatform(
    const LocalPlatform()
  )..stdoutSupportsAnsi = false;
};

class MockApplicationPackageStore extends ApplicationPackageStore {
  MockApplicationPackageStore() : super(
    android: AndroidApk(
      id: 'io.flutter.android.mock',
      file: globals.fs.file('/mock/path/to/android/SkyShell.apk'),
      versionCode: 1,
      launchActivity: 'io.flutter.android.mock.MockActivity',
    ),
    iOS: BuildableIOSApp(MockIosProject(), MockIosProject.bundleId, MockIosProject.appBundleName),
  );
}

class MockApplicationPackageFactory extends Mock implements ApplicationPackageFactory {
  final MockApplicationPackageStore _store = MockApplicationPackageStore();

  @override
  Future<ApplicationPackage> getPackageForPlatform(
    TargetPlatform platform, {
    BuildInfo buildInfo,
    File applicationBinary,
  }) async {
    return _store.getPackageForPlatform(platform, buildInfo);
  }
}

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
typedef ProcessFactory = Process Function(List<String> command);

/// A ProcessManager that starts Processes by delegating to a ProcessFactory.
class MockProcessManager extends Mock implements ProcessManager {
  ProcessFactory processFactory = (List<String> commands) => MockProcess();
  bool canRunSucceeds = true;
  bool runSucceeds = true;
  List<String> commands;

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
ProcessFactory flakyProcessFactory({
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
      return MockProcess();
    }
    if (flakesLeft == 0) {
      return MockProcess(
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
    return MockProcess(
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
  final Process process = MockBasicProcess();

  when(process.stdout).thenAnswer((_) => stdoutStream);
  when(process.stderr).thenAnswer((_) => stderrStream);
  when(process.exitCode).thenAnswer((_) => Future<int>.value(exitCode));
  return process;
}

class MockBasicProcess extends Mock implements Process {}

/// A process that exits successfully with no output and ignores all input.
class MockProcess extends Mock implements Process {
  MockProcess({
    this.pid = 1,
    Future<int> exitCode,
    Stream<List<int>> stdin,
    this.stdout = const Stream<List<int>>.empty(),
    this.stderr = const Stream<List<int>>.empty(),
  }) : exitCode = exitCode ?? Future<int>.value(0),
       stdin = stdin as IOSink ?? MemoryIOSink();

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

/// A fake process implementation which can be provided all necessary values.
class FakeProcess implements Process {
  FakeProcess({
    this.pid = 1,
    Future<int> exitCode,
    IOSink stdin,
    this.stdout = const Stream<List<int>>.empty(),
    this.stderr = const Stream<List<int>>.empty(),
  }) : exitCode = exitCode ?? Future<int>.value(0),
       stdin = stdin ?? MemoryIOSink();

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

  @override
  bool kill([io.ProcessSignal signal = io.ProcessSignal.sigterm]) {
    return true;
  }
}

/// A process that prompts the user to proceed, then asynchronously writes
/// some lines to stdout before it exits.
class PromptingProcess implements Process {
  PromptingProcess({
    bool stdinError = false,
  }) : _stdin = CompleterIOSink(throwOnAdd: stdinError);

  Future<void> showPrompt(String prompt, List<String> outputLines) async {
    try {
      _stdoutController.add(utf8.encode(prompt));
      final List<int> bytesOnStdin = await _stdin.future;
      // Echo stdin to stdout.
      _stdoutController.add(bytesOnStdin);
      if (bytesOnStdin.isNotEmpty && bytesOnStdin[0] == utf8.encode('y')[0]) {
        for (final String line in outputLines) {
          _stdoutController.add(utf8.encode('$line\n'));
        }
      }
    } finally {
      await _stdoutController.close();
    }
  }

  final StreamController<List<int>> _stdoutController = StreamController<List<int>>();
  final CompleterIOSink _stdin;

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
  CompleterIOSink({
    this.throwOnAdd = false,
  });

  final bool throwOnAdd;

  final Completer<List<int>> _completer = Completer<List<int>>();

  Future<List<int>> get future => _completer.future;

  @override
  void add(List<int> data) {
    if (!_completer.isCompleted) {
      // When throwOnAdd is true, complete with empty so any expected output
      // doesn't appear.
      _completer.complete(throwOnAdd ? <int>[] : data);
    }
    if (throwOnAdd) {
      throw Exception('CompleterIOSink Error');
    }
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
  Future<void> addStream(Stream<List<int>> stream) {
    final Completer<void> completer = Completer<void>();
    StreamSubscription<List<int>> sub;
    sub = stream.listen(
      (List<int> data) {
        try {
          add(data);
        // Catches all exceptions to propagate them to the completer.
        } catch (err, stack) { // ignore: avoid_catches_without_on_clauses
          sub.cancel();
          completer.completeError(err, stack);
        }
      },
      onError: completer.completeError,
      onDone: completer.complete,
      cancelOnError: true,
    );
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
  void writeln([ Object obj = '' ]) {
    add(encoding.encode('$obj\n'));
  }

  @override
  void writeAll(Iterable<dynamic> objects, [ String separator = '' ]) {
    bool addSeparator = false;
    for (final dynamic object in objects) {
      if (addSeparator) {
        write(separator);
      }
      write(object);
      addSeparator = true;
    }
  }

  @override
  void addError(dynamic error, [ StackTrace stackTrace ]) {
    throw UnimplementedError();
  }

  @override
  Future<void> get done => close();

  @override
  Future<void> close() async { }

  @override
  Future<void> flush() async { }
}

class MemoryStdout extends MemoryIOSink implements io.Stdout {
  @override
  bool get hasTerminal => _hasTerminal;
  set hasTerminal(bool value) {
    assert(value != null);
    _hasTerminal = value;
  }
  bool _hasTerminal = true;

  @override
  io.IOSink get nonBlocking => this;

  @override
  bool get supportsAnsiEscapes => _supportsAnsiEscapes;
  set supportsAnsiEscapes(bool value) {
    assert(value != null);
    _supportsAnsiEscapes = value;
  }
  bool _supportsAnsiEscapes = true;

  @override
  int get terminalColumns {
    if (_terminalColumns != null) {
      return _terminalColumns;
    }
    throw const io.StdoutException('unspecified mock value');
  }
  set terminalColumns(int value) => _terminalColumns = value;
  int _terminalColumns;

  @override
  int get terminalLines {
    if (_terminalLines != null) {
      return _terminalLines;
    }
    throw const io.StdoutException('unspecified mock value');
  }
  set terminalLines(int value) => _terminalLines = value;
  int _terminalLines;
}

/// A Stdio that collects stdout and supports simulated stdin.
class MockStdio extends Stdio {
  final MemoryStdout _stdout = MemoryStdout();
  final MemoryIOSink _stderr = MemoryIOSink();
  final StreamController<List<int>> _stdin = StreamController<List<int>>();

  @override
  MemoryStdout get stdout => _stdout;

  @override
  MemoryIOSink get stderr => _stderr;

  @override
  Stream<List<int>> get stdin => _stdin.stream;

  void simulateStdin(String line) {
    _stdin.add(utf8.encode('$line\n'));
  }

  List<String> get writtenToStdout => _stdout.writes.map<String>(_stdout.encoding.decode).toList();
  List<String> get writtenToStderr => _stderr.writes.map<String>(_stderr.encoding.decode).toList();
}

class FakePollingDeviceDiscovery extends PollingDeviceDiscovery {
  FakePollingDeviceDiscovery() : super('mock');

  final List<Device> _devices = <Device>[];
  final StreamController<Device> _onAddedController = StreamController<Device>.broadcast();
  final StreamController<Device> _onRemovedController = StreamController<Device>.broadcast();

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    lastPollingTimeout = timeout;
    return _devices;
  }

  Duration lastPollingTimeout;

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;

  void addDevice(Device device) {
    _devices.add(device);
    _onAddedController.add(device);
  }

  void _removeDevice(Device device) {
    _devices.remove(device);
    _onRemovedController.add(device);
  }

  void setDevices(List<Device> devices) {
    while(_devices.isNotEmpty) {
      _removeDevice(_devices.first);
    }
    devices.forEach(addDevice);
  }

  @override
  Stream<Device> get onAdded => _onAddedController.stream;

  @override
  Stream<Device> get onRemoved => _onRemovedController.stream;
}

class LongPollingDeviceDiscovery extends PollingDeviceDiscovery {
  LongPollingDeviceDiscovery() : super('forever');

  final Completer<List<Device>> _completer = Completer<List<Device>>();

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    return _completer.future;
  }

  @override
  Future<void> stopPolling() async {
    _completer.complete();
  }

  @override
  Future<void> dispose() async {
    _completer.complete();
  }

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;
}

class ThrowingPollingDeviceDiscovery extends PollingDeviceDiscovery {
  ThrowingPollingDeviceDiscovery() : super('throw');

  @override
  Future<List<Device>> pollingGetDevices({ Duration timeout }) async {
    throw const ProcessException('fake-discovery', <String>[]);
  }

  @override
  bool get supportsPlatform => true;

  @override
  bool get canListAnything => true;
}

class MockIosProject extends Mock implements IosProject {
  static const String bundleId = 'com.example.test';
  static const String appBundleName = 'My Super Awesome App.app';

  @override
  Future<String> productBundleIdentifier(BuildInfo buildInfo) async => bundleId;

  @override
  Future<String> hostAppBundleName(BuildInfo buildInfo) async => appBundleName;
}

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

class MockIOSSimulator extends Mock implements IOSSimulator {
  @override
  Future<TargetPlatform> get targetPlatform async => TargetPlatform.ios;

  @override
  bool isSupported() => true;

  @override
  bool isSupportedForProject(FlutterProject flutterProject) => true;
}

void applyMocksToCommand(FlutterCommand command) {
  command.applicationPackages = MockApplicationPackageStore();
}

/// Common functionality for tracking mock interaction.
class BasicMock {
  final List<String> messages = <String>[];

  void expectMessages(List<String> expectedMessages) {
    final List<String> actualMessages = List<String>.of(messages);
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

class MockResidentCompiler extends BasicMock implements ResidentCompiler {
  @override
  void accept() { }

  @override
  Future<CompilerOutput> reject() async { return null; }

  @override
  void reset() { }

  @override
  Future<dynamic> shutdown() async { }

  @override
  Future<CompilerOutput> compileExpression(
    String expression,
    List<String> definitions,
    List<String> typeDefinitions,
    String libraryUri,
    String klass,
    bool isStatic,
  ) async {
    return null;
  }

  @override
  Future<CompilerOutput> compileExpressionToJs(
    String libraryUri,
    int line,
    int column,
    Map<String, String> jsModules,
    Map<String, String> jsFrameValues,
    String moduleName,
    String expression,
  ) async {
    return null;
  }

  @override
  Future<CompilerOutput> recompile(Uri mainPath, List<Uri> invalidatedFiles, {
    String outputPath,
    PackageConfig packageConfig,
    bool suppressErrors = false,
  }) async {
    globals.fs.file(outputPath).createSync(recursive: true);
    globals.fs.file(outputPath).writeAsStringSync('compiled_kernel_output');
    return CompilerOutput(outputPath, 0, <Uri>[]);
  }

  @override
  void addFileSystemRoot(String root) { }
}

/// A fake implementation of [ProcessResult].
class FakeProcessResult implements ProcessResult {
  FakeProcessResult({
    this.exitCode = 0,
    this.pid = 1,
    this.stderr,
    this.stdout,
  });

  @override
  final int exitCode;

  @override
  final int pid;

  @override
  final dynamic stderr;

  @override
  final dynamic stdout;

  @override
  String toString() => stdout?.toString() ?? stderr?.toString() ?? runtimeType.toString();
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

class MockDevToolsServer extends Mock implements HttpServer {}
class MockInternetAddress extends Mock implements InternetAddress {}

class AlwaysTrueBotDetector implements BotDetector {
  const AlwaysTrueBotDetector();

  @override
  Future<bool> get isRunningOnBot async => true;
}


class AlwaysFalseBotDetector implements BotDetector {
  const AlwaysFalseBotDetector();

  @override
  Future<bool> get isRunningOnBot async => false;
}
