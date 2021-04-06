// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:io' as io show IOSink, ProcessSignal, Stdout, StdoutException;

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/build_info.dart';
import 'package:flutter_tools/src/build_system/build_system.dart';
import 'package:flutter_tools/src/bundle.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

/// A fake implementation of the [DeviceLogReader].
class FakeDeviceLogReader extends DeviceLogReader {
  @override
  String get name => 'FakeLogReader';

  StreamController<String> _cachedLinesController;

  final List<String> _lineQueue = <String>[];
  StreamController<String> get _linesController {
    _cachedLinesController ??= StreamController<String>
      .broadcast(onListen: () {
        _lineQueue.forEach(_linesController.add);
        _lineQueue.clear();
     });
    return _cachedLinesController;
  }

  @override
  Stream<String> get logLines => _linesController.stream;

  void addLine(String line) {
    if (_linesController.hasListener) {
      _linesController.add(line);
    } else {
      _lineQueue.add(line);
    }
  }

  @override
  Future<void> dispose() async {
    _lineQueue.clear();
    await _linesController.close();
  }
}

/// Environment with DYLD_LIBRARY_PATH=/path/to/libraries
class FakeDyldEnvironmentArtifact extends ArtifactSet {
  FakeDyldEnvironmentArtifact() : super(DevelopmentArtifact.iOS);
  @override
  Map<String, String> get environment => <String, String>{
    'DYLD_LIBRARY_PATH': '/path/to/libraries'
  };

  @override
  Future<bool> isUpToDate(FileSystem fileSystem) => Future<bool>.value(true);

  @override
  String get name => 'fake';

  @override
  Future<void> update(ArtifactUpdater artifactUpdater, Logger logger, FileSystem fileSystem, OperatingSystemUtils operatingSystemUtils) async {
  }
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

  void clear() {
    writes.clear();
  }

  String getAndClear() {
    final String result = utf8.decode(writes.expand((List<int> l) => l).toList());
    clear();
    return result;
  }
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
class FakeStdio extends Stdio {
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

class FakePlistParser implements PlistParser {
  final Map<String, dynamic> _underlyingValues = <String, String>{};

  void setProperty(String key, dynamic value) {
    _underlyingValues[key] = value;
  }

  @override
  Map<String, dynamic> parseFile(String plistFilePath) {
    return _underlyingValues;
  }

  @override
  String getValueFromFile(String plistFilePath, String key) {
    return _underlyingValues[key] as String;
  }
}

class FakeBotDetector implements BotDetector {
  const FakeBotDetector(bool isRunningOnBot)
      : _isRunningOnBot = isRunningOnBot;

  @override
  Future<bool> get isRunningOnBot async => _isRunningOnBot;

  final bool _isRunningOnBot;
}

class FakePub extends Fake implements Pub {
  @override
  Future<void> get({
    PubContext context,
    String directory,
    bool skipIfAbsent = false,
    bool upgrade = false,
    bool offline = false,
    bool generateSyntheticPackage = false,
    String flutterRootOverride,
    bool checkUpToDate = false,
  }) async { }
}

class FakeFlutterVersion implements FlutterVersion {
  FakeFlutterVersion({
    this.channel = 'unknown',
    this.dartSdkVersion = '12',
    this.engineRevision = 'abcdefghijklmnopqrstuvwxyz',
    this.engineRevisionShort = 'abcde',
    this.repositoryUrl = 'https://github.com/flutter/flutter.git',
    this.frameworkVersion = '0.0.0',
    this.frameworkRevision = '11111111111111111111',
    this.frameworkRevisionShort = '11111',
    this.frameworkAge = '0 hours ago',
    this.frameworkCommitDate = '12/01/01',
    this.gitTagVersion = const GitTagVersion.unknown(),
  });

  bool get didFetchTagsAndUpdate => _didFetchTagsAndUpdate;
  bool _didFetchTagsAndUpdate = false;

  bool get didCheckFlutterVersionFreshness => _didCheckFlutterVersionFreshness;
  bool _didCheckFlutterVersionFreshness = false;

  @override
  final String channel;

  @override
  final String dartSdkVersion;

  @override
  final String engineRevision;

  @override
  final String engineRevisionShort;

  @override
  final String repositoryUrl;

  @override
  final String frameworkVersion;

  @override
  final String frameworkRevision;

  @override
  final String frameworkRevisionShort;

  @override
  final String frameworkAge;

  @override
  final String frameworkCommitDate;

  @override
  String get frameworkDate => frameworkCommitDate;

  @override
  final GitTagVersion gitTagVersion;

  @override
  void fetchTagsAndUpdate() {
    _didFetchTagsAndUpdate = true;
  }

  @override
  Future<void> checkFlutterVersionFreshness() async {
    _didCheckFlutterVersionFreshness = true;
  }

  @override
  bool checkRevisionAncestry({String tentativeDescendantRevision, String tentativeAncestorRevision}) {
    throw UnimplementedError();
  }

  @override
  Future<void> ensureVersionFile() async { }

  @override
  String getBranchName({bool redactUnknownBranches = false}) {
    return 'master';
  }

  @override
  String getVersionString({bool redactUnknownBranches = false}) {
    return 'v0.0.0';
  }

  @override
  Map<String, Object> toJson() {
    return <String, Object>{};
  }
}

// A test implementation of [FeatureFlags] that allows enabling without reading
// config. If not otherwise specified, all values default to false.
class TestFeatureFlags implements FeatureFlags {
  TestFeatureFlags({
    this.isLinuxEnabled = false,
    this.isMacOSEnabled = false,
    this.isWebEnabled = false,
    this.isWindowsEnabled = false,
    this.isSingleWidgetReloadEnabled = false,
    this.isAndroidEnabled = true,
    this.isIOSEnabled = true,
    this.isFuchsiaEnabled = false,
    this.areCustomDevicesEnabled = false,
    this.isExperimentalInvalidationStrategyEnabled = false,
    this.isWindowsUwpEnabled = false,
  });

  @override
  final bool isLinuxEnabled;

  @override
  final bool isMacOSEnabled;

  @override
  final bool isWebEnabled;

  @override
  final bool isWindowsEnabled;

  @override
  final bool isSingleWidgetReloadEnabled;

  @override
  final bool isAndroidEnabled;

  @override
  final bool isIOSEnabled;

  @override
  final bool isFuchsiaEnabled;

  @override
  final bool areCustomDevicesEnabled;

  @override
  final bool isExperimentalInvalidationStrategyEnabled;

  @override
  final bool isWindowsUwpEnabled;

  @override
  bool isEnabled(Feature feature) {
    switch (feature) {
      case flutterWebFeature:
        return isWebEnabled;
      case flutterLinuxDesktopFeature:
        return isLinuxEnabled;
      case flutterMacOSDesktopFeature:
        return isMacOSEnabled;
      case flutterWindowsDesktopFeature:
        return isWindowsEnabled;
      case singleWidgetReload:
        return isSingleWidgetReloadEnabled;
      case flutterAndroidFeature:
        return isAndroidEnabled;
      case flutterIOSFeature:
        return isIOSEnabled;
      case flutterFuchsiaFeature:
        return isFuchsiaEnabled;
      case flutterCustomDevicesFeature:
        return areCustomDevicesEnabled;
      case experimentalInvalidationStrategy:
        return isExperimentalInvalidationStrategyEnabled;
      case windowsUwpEmbedding:
        return isWindowsUwpEnabled;
    }
    return false;
  }
}

class FakeStatusLogger extends DelegatingLogger {
  FakeStatusLogger(Logger delegate) : super(delegate);

  Status status;

  @override
  Status startProgress(String message, {Duration timeout, String progressId, bool multilineOutput = false, bool includeTiming = true, int progressIndicatorPadding = kDefaultStatusPadding}) {
    return status;
  }
}

class TestBuildSystem implements BuildSystem {
  /// Create a [BuildSystem] instance that returns the provided results in order.
  TestBuildSystem.list(this._results, [this._onRun])
    : _exception = null,
      _singleResult = null;

  /// Create a [BuildSystem] instance that returns the provided result for every build
  /// and buildIncremental request.
  TestBuildSystem.all(this._singleResult, [this._onRun])
    : _exception = null,
      _results = <BuildResult>[];

  /// Create a [BuildSystem] instance that always throws the provided error for every build
  /// and buildIncremental request.
  TestBuildSystem.error(this._exception)
    : _singleResult = null,
      _results = <BuildResult>[],
      _onRun = null;

  final List<BuildResult> _results;
  final BuildResult _singleResult;
  final dynamic _exception;
  final void Function(Target target, Environment environment) _onRun;
  int _nextResult = 0;

  @override
  Future<BuildResult> build(Target target, Environment environment, {BuildSystemConfig buildSystemConfig = const BuildSystemConfig()}) async {
    if (_onRun != null) {
      _onRun(target, environment);
    }
    if (_exception != null) {
      throw _exception;
    }
    if (_singleResult != null) {
      return _singleResult;
    }
    if (_nextResult >= _results.length) {
      throw StateError('Unexpected build request of ${target.name}');
    }
    return _results[_nextResult++];
  }

  @override
  Future<BuildResult> buildIncremental(Target target, Environment environment, BuildResult previousBuild) async {
    if (_onRun != null) {
      _onRun(target, environment);
    }
    if (_exception != null) {
      throw _exception;
    }
    if (_singleResult != null) {
      return _singleResult;
    }
    if (_nextResult >= _results.length) {
      throw StateError('Unexpected buildIncremental request of ${target.name}');
    }
    return _results[_nextResult++];
  }
}

class FakeBundleBuilder extends Fake implements BundleBuilder {
  @override
  Future<void> build({
    TargetPlatform platform,
    BuildInfo buildInfo,
    String mainPath,
    String manifestPath = defaultManifestPath,
    String applicationKernelFilePath,
    String depfilePath,
    String assetDirPath,
    bool trackWidgetCreation = false,
    List<String> extraFrontEndOptions = const <String>[],
    List<String> extraGenSnapshotOptions = const <String>[],
    List<String> fileSystemRoots,
    String fileSystemScheme,
    bool treeShakeIcons
  }) => Future<void>.value();
}
