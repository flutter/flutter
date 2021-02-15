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
import 'package:flutter_tools/src/cache.dart';
import 'package:flutter_tools/src/convert.dart';
import 'package:flutter_tools/src/dart/pub.dart';
import 'package:flutter_tools/src/device.dart';
import 'package:flutter_tools/src/ios/plist_parser.dart';
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
