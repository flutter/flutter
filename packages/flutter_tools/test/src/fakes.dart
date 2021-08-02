// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io show IOSink, ProcessSignal, Stdout, StdoutException;

import 'package:flutter_tools/src/base/bot_detector.dart';
import 'package:flutter_tools/src/base/file_system.dart';
import 'package:flutter_tools/src/base/io.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/features.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
import 'package:flutter_tools/src/version.dart';
import 'package:test/fake.dart';

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
    Future<int>? exitCode,
    IOSink? stdin,
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
    late StreamSubscription<List<int>> sub;
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
  void write(Object? obj) {
    add(encoding.encode('$obj'));
  }

  @override
  void writeln([ Object? obj = '' ]) {
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
  void addError(dynamic error, [ StackTrace? stackTrace ]) {
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
      return _terminalColumns!;
    }
    throw const io.StdoutException('unspecified mock value');
  }
  set terminalColumns(int value) => _terminalColumns = value;
  int? _terminalColumns;

  @override
  int get terminalLines {
    if (_terminalLines != null) {
      return _terminalLines!;
    }
    throw const io.StdoutException('unspecified mock value');
  }
  set terminalLines(int value) => _terminalLines = value;
  int? _terminalLines;
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
      case windowsUwpEmbedding:
        return isWindowsUwpEnabled;
    }
    return false;
  }
}

class FakeStatusLogger extends DelegatingLogger {
  FakeStatusLogger(Logger delegate) : super(delegate);

  late Status status;

  @override
  Status startProgress(String message, {
    String? progressId,
    bool multilineOutput = false,
    int progressIndicatorPadding = kDefaultStatusPadding,
  }) => status;
}

class FakeOperatingSystemUtils extends Fake implements OperatingSystemUtils {
  FakeOperatingSystemUtils({this.hostPlatform = HostPlatform.linux_x64});

  final List<List<String>> chmods = <List<String>>[];

  @override
  void makeExecutable(File file) { }

  @override
  HostPlatform hostPlatform = HostPlatform.linux_x64;

  @override
  void chmod(FileSystemEntity entity, String mode) {
    chmods.add(<String>[entity.path, mode]);
  }

  @override
  File? which(String execName) => null;

  @override
  List<File> whichAll(String execName) => <File>[];

  @override
  void unzip(File file, Directory targetDirectory) { }

  @override
  void unpack(File gzippedTarFile, Directory targetDirectory) { }

  @override
  Stream<List<int>> gzipLevel1Stream(Stream<List<int>> stream) => stream;

  @override
  String get name => 'fake OS name and version';

  @override
  String get pathVarSeparator => ';';

  @override
  Future<int> findFreePort({bool ipv6 = false}) async => 12345;
}

class FakeStopwatch implements Stopwatch {
  @override
  bool get isRunning => _isRunning;
  bool _isRunning = false;

  @override
  void start() => _isRunning = true;

  @override
  void stop() => _isRunning = false;

  @override
  Duration elapsed = Duration.zero;

  @override
  int get elapsedMicroseconds => elapsed.inMicroseconds;

  @override
  int get elapsedMilliseconds => elapsed.inMilliseconds;

  @override
  int get elapsedTicks => elapsed.inMilliseconds;

  @override
  int get frequency => 1000;

  @override
  void reset() {
    _isRunning = false;
    elapsed = Duration.zero;
  }

  @override
  String toString() => '$runtimeType $elapsed $isRunning';
}

class FakeStopwatchFactory implements StopwatchFactory {
  FakeStopwatchFactory({
    Stopwatch? stopwatch,
    Map<String, Stopwatch>? stopwatches
  }) : stopwatches = <String, Stopwatch>{
         if (stopwatches != null) ...stopwatches,
         if (stopwatch != null) '': stopwatch,
       };

  Map<String, Stopwatch> stopwatches;

  @override
  Stopwatch createStopwatch([String name = '']) {
    return stopwatches[name] ?? FakeStopwatch();
  }
}
