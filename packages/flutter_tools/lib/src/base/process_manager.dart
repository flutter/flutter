// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;

import 'context.dart';
import 'os.dart';
import 'process.dart';

ProcessManager get processManager => context[ProcessManager];

const String _kManifestName = 'MANIFEST.txt';

bool _areListsEqual/*<T>*/(List<dynamic/*=T*/> list1, List<dynamic/*=T*/> list2) {
  int i = 0;
  return list1 != null
      && list2 != null
      && list1.length == list2.length
      && list1.every((dynamic element) => element == list2[i++]);
}

/// A class that manages the creation of operating system processes. This
/// provides a lightweight wrapper around the underlying [Process] static
/// methods to allow the implementation of these methods to be mocked out or
/// decorated for testing or debugging purposes.
class ProcessManager {
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    ProcessStartMode mode: ProcessStartMode.NORMAL,
  }) {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
    );
  }

  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
  }) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
  }) {
    return Process.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    return Process.killPid(pid, signal);
  }
}

/// A [ProcessManager] implementation that decorates the standard behavior by
/// recording all process invocation activity (including the stdout and stderr
/// of the associated processes) and serializing that recording to a ZIP file
/// when the Flutter tools process exits.
class RecordingProcessManager implements ProcessManager {
  static const String kDefaultRecordTo = 'recording.zip';
  static const List<String> _kSkippableExecutables = const <String>[
    'env',
    'xcrun',
  ];

  final String _recordTo;
  final ProcessManager _delegate = new ProcessManager();
  final Directory _tmpDir = Directory.systemTemp.createTempSync('flutter_tools_');
  final List<Map<String, dynamic>> _manifest = <Map<String, dynamic>>[];
  final Map<int, Future<int>> _runningProcesses = <int, Future<int>>{};

  /// Constructs a new `RecordingProcessManager` that will record all process
  /// invocations and serialize them to the a ZIP file at the specified
  /// [recordTo] location.
  ///
  /// If [recordTo] is a directory, a ZIP file named
  /// [kDefaultRecordTo](`recording.zip`) will be created in the specified
  /// directory.
  ///
  /// If [recordTo] is a file (or doesn't exist), it is taken to be the name
  /// of the ZIP file that will be created, and the containing folder will be
  /// created as needed.
  RecordingProcessManager(this._recordTo) {
    addShutdownHook(_onShutdown);
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    ProcessStartMode mode: ProcessStartMode.NORMAL,
  }) async {
    Process process = await _delegate.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
    );

    String basename = _getBasename(process.pid, executable, arguments);
    Map<String, dynamic> manifestEntry = _createManifestEntry(
      pid: process.pid,
      basename: basename,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
    );
    _manifest.add(manifestEntry);

    _RecordingProcess result = new _RecordingProcess(
      manager: this,
      basename: basename,
      delegate: process,
    );
    await result.startRecording();
    _runningProcesses[process.pid] = result.exitCode.then((int exitCode) {
      _runningProcesses.remove(process.pid);
      manifestEntry['exitCode'] = exitCode;
    });

    return result;
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
  }) async {
    ProcessResult result = await _delegate.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );

    String basename = _getBasename(result.pid, executable, arguments);
    _manifest.add(_createManifestEntry(
      pid: result.pid,
      basename: basename,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
      exitCode: result.exitCode,
    ));

    await _recordData(result.stdout, stdoutEncoding, '$basename.stdout');
    await _recordData(result.stderr, stderrEncoding, '$basename.stderr');

    return result;
  }

  Future<Null> _recordData(dynamic data, Encoding encoding, String basename) async {
    String path = '${_tmpDir.path}/$basename';
    File file = await new File(path).create();
    RandomAccessFile recording = await file.open(mode: FileMode.WRITE);
    try {
      if (encoding == null)
        await recording.writeFrom(data);
      else
        await recording.writeString(data, encoding: encoding);
      await recording.flush();
    } finally {
      await recording.close();
    }
  }

  @override
  ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
  }) {
    ProcessResult result = _delegate.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );

    String basename = _getBasename(result.pid, executable, arguments);
    _manifest.add(_createManifestEntry(
      pid: result.pid,
      basename: basename,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
      exitCode: result.exitCode,
    ));

    _recordDataSync(result.stdout, stdoutEncoding, '$basename.stdout');
    _recordDataSync(result.stderr, stderrEncoding, '$basename.stderr');

    return result;
  }

  void _recordDataSync(dynamic data, Encoding encoding, String basename) {
    String path = '${_tmpDir.path}/$basename';
    File file = new File(path)..createSync();
    RandomAccessFile recording = file.openSync(mode: FileMode.WRITE);
    try {
      if (encoding == null)
        recording.writeFromSync(data);
      else
        recording.writeStringSync(data, encoding: encoding);
      recording.flushSync();
    } finally {
      recording.closeSync();
    }
  }

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    return _delegate.killPid(pid, signal);
  }

  /// Creates a JSON-encodable manifest entry representing the specified
  /// process invocation.
  Map<String, dynamic> _createManifestEntry({
    int pid,
    String basename,
    String executable,
    List<String> arguments,
    String workingDirectory,
    Map<String, String> environment,
    ProcessStartMode mode,
    Encoding stdoutEncoding,
    Encoding stderrEncoding,
    int exitCode,
  }) {
    return new _ManifestEntryBuilder()
      .add('pid', pid)
      .add('basename', basename)
      .add('executable', executable)
      .add('arguments', arguments)
      .add('workingDirectory', workingDirectory)
      .add('environment', environment)
      .add('mode', mode, () => mode.toString())
      .add('stdoutEncoding', stdoutEncoding, () => stdoutEncoding.name)
      .add('stderrEncoding', stderrEncoding, () => stderrEncoding.name)
      .add('exitCode', exitCode)
      .entry;
  }

  /// Returns a human-readable identifier for the specified executable.
  String _getBasename(int pid, String executable, List<String> arguments) {
    String index = new NumberFormat('000').format(_manifest.length);
    String identifier = path.basename(executable);
    if (_kSkippableExecutables.contains(identifier)
        && arguments != null
        && arguments.isNotEmpty) {
      identifier = path.basename(arguments.first);
    }
    return '$index.$identifier.$pid';
  }

  /// Invoked when the outermost executable process is about to shutdown
  /// safely. This saves our recording to a ZIP file at the location specified
  /// in the [new RecordingProcessManager] constructor.
  Future<Null> _onShutdown() async {
    await _waitForRunningProcessesToExit();
    await _writeManifestToDisk();
    await _saveRecording();
    await _tmpDir.delete(recursive: true);
  }

  /// Waits for all running processes to exit, and records their exit codes in
  /// the process manifest. Any process that doesn't exit in a timely fashion
  /// will have a `"daemon"` marker added to its manifest and be signalled with
  /// `SIGTERM`. If such processes *still* don't exit in a timely fashion after
  /// being signalled, they'll have a `"notResponding"` marker added to their
  /// manifest.
  Future<Null> _waitForRunningProcessesToExit() async {
    await _waitForRunningProcessesToExitWithTimeout(
      onTimeout: (int pid, Map<String, dynamic> manifestEntry) {
        manifestEntry['daemon'] = true;
        Process.killPid(pid);
      });
    // Now that we explicitly signalled the processes that timed out asking
    // them to shutdown, wait one more time for those processes to exit.
    await _waitForRunningProcessesToExitWithTimeout(
      onTimeout: (int pid, Map<String, dynamic> manifestEntry) {
        manifestEntry['notResponding'] = true;
      });
  }

  Future<Null> _waitForRunningProcessesToExitWithTimeout({
    void onTimeout(int pid, Map<String, dynamic> manifestEntry),
  }) async {
    await Future.wait(new List<Future<int>>.from(_runningProcesses.values))
        .timeout(const Duration(milliseconds: 20), onTimeout: () {
          _runningProcesses.forEach((int pid, Future<int> future) {
            Map<String, dynamic> manifestEntry = _manifest
                .firstWhere((Map<String, dynamic> entry) => entry['pid'] == pid);
            onTimeout(pid, manifestEntry);
          });
        });
  }

  /// Writes our process invocation manifest to disk in our temp folder.
  Future<Null> _writeManifestToDisk() async {
    JsonEncoder encoder = new JsonEncoder.withIndent('  ');
    String encodedManifest = encoder.convert(_manifest);
    File manifestFile = await new File('${_tmpDir.path}/$_kManifestName').create();
    await manifestFile.writeAsString(encodedManifest, flush: true);
  }

  /// Saves our recording to a ZIP file at the specified location.
  Future<Null> _saveRecording() async {
    File zipFile = await _createZipFile();
    List<int> zipData = await _getRecordingZipBytes();
    await zipFile.writeAsBytes(zipData);
  }

  /// Creates our recording ZIP file at the location specified
  /// in the [new RecordingProcessManager] constructor.
  Future<File> _createZipFile() async {
    File zipFile;
    String recordTo = _recordTo ?? Directory.current.path;
    if (FileSystemEntity.typeSync(recordTo) == FileSystemEntityType.DIRECTORY) {
      zipFile = new File('$recordTo/$kDefaultRecordTo');
    } else {
      zipFile = new File(recordTo);
      await new Directory(path.dirname(zipFile.path)).create(recursive: true);
    }

    // Resolve collisions.
    String basename = path.basename(zipFile.path);
    for (int i = 1; zipFile.existsSync(); i++) {
      assert(FileSystemEntity.isFileSync(zipFile.path));
      String disambiguator = new NumberFormat('00').format(i);
      String newBasename = basename;
      if (basename.contains('.')) {
        List<String> parts = basename.split('.');
        parts[parts.length - 2] += '-$disambiguator';
        newBasename = parts.join('.');
      } else {
        newBasename += '-$disambiguator';
      }
      zipFile = new File(path.join(path.dirname(zipFile.path), newBasename));
    }

    return await zipFile.create();
  }

  /// Gets the bytes of our ZIP file recording.
  Future<List<int>> _getRecordingZipBytes() async {
    Archive archive = new Archive();
    Stream<FileSystemEntity> files = _tmpDir.list(recursive: true)
        .where((FileSystemEntity entity) => FileSystemEntity.isFileSync(entity.path));
    List<Future<dynamic>> addAllFilesToArchive = <Future<dynamic>>[];
    await files.forEach((FileSystemEntity entity) {
      File file = entity;
      Future<dynamic> readAsBytes = file.readAsBytes();
      addAllFilesToArchive.add(readAsBytes.then((List<int> data) {
        archive.addFile(new ArchiveFile.noCompress(
          path.basename(file.path), data.length, data));
      }));
    });

    await Future.wait(addAllFilesToArchive);
    return new ZipEncoder().encode(archive);
  }
}

/// A lightweight class that provides a builder pattern for building a
/// manifest entry.
class _ManifestEntryBuilder {
  Map<String, dynamic> entry = <String, dynamic>{};

  /// Adds the specified key/value pair to the manifest entry iff the value
  /// is non-null. If [jsonValue] is specified, its value will be used instead
  /// of the raw value.
  _ManifestEntryBuilder add(String name, dynamic value, [dynamic jsonValue()]) {
    if (value != null)
      entry[name] = jsonValue == null ? value : jsonValue();
    return this;
  }
}

/// A [Process] implementation that records `stdout` and `stderr` stream events
/// to disk before forwarding them on to the underlying stream listener.
class _RecordingProcess implements Process {
  final Process delegate;
  final String basename;
  final RecordingProcessManager manager;

  bool _started = false;

  StreamController<List<int>> _stdoutController = new StreamController<List<int>>();
  StreamController<List<int>> _stderrController = new StreamController<List<int>>();

  _RecordingProcess({this.manager, this.basename, this.delegate});

  Future<Null> startRecording() async {
    assert(!_started);
    _started = true;
    await Future.wait(<Future<Null>>[
      _recordStream(delegate.stdout, _stdoutController, 'stdout'),
      _recordStream(delegate.stderr, _stderrController, 'stderr'),
    ]);
  }

  Future<Null> _recordStream(
    Stream<List<int>> stream,
    StreamController<List<int>> controller,
    String suffix,
  ) async {
    String path = '${manager._tmpDir.path}/$basename.$suffix';
    File file = await new File(path).create();
    RandomAccessFile recording = await file.open(mode: FileMode.WRITE);
    stream.listen(
      (List<int> data) {
        // Write synchronously to guarantee that the order of data
        // within our recording is preserved across stream notifications.
        recording.writeFromSync(data);
        // Flush immediately so that if the program crashes, forensic
        // data from the recording won't be lost.
        recording.flushSync();
        controller.add(data);
      },
      onError: (dynamic error, StackTrace stackTrace) {
        recording.closeSync();
        controller.addError(error, stackTrace);
      },
      onDone: () {
        recording.closeSync();
        controller.close();
      },
    );
  }

  @override
  Future<int> get exitCode => delegate.exitCode;

  @override
  set exitCode(Future<int> exitCode) => delegate.exitCode = exitCode;

  @override
  Stream<List<int>> get stdout {
    assert(_started);
    return _stdoutController.stream;
  }

  @override
  Stream<List<int>> get stderr {
    assert(_started);
    return _stderrController.stream;
  }

  @override
  IOSink get stdin {
    // We don't currently support recording `stdin`.
    return delegate.stdin;
  }

  @override
  int get pid => delegate.pid;

  @override
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) => delegate.kill(signal);
}

/// A [ProcessManager] implementation that mocks out all process invocations
/// by replaying a previously-recorded series of invocations, throwing an
/// exception if the requested invocations substantively differ in any way
/// from those in the recording.
///
/// Recordings are expected to be of the form produced by
/// [RecordingProcessManager]. Namely, this includes:
///
/// - a [_kManifestName](manifest file) encoded as UTF-8 JSON that lists all
///   invocations in order, along with the following metadata for each
///   invocation:
///   - `pid` (required): The process id integer.
///   - `basename` (required): A string specifying the base filename from which
///     the incovation's `stdout` and `stderr` files can be located.
///   - `executable` (required): A string specifying the path to the executable
///     command that kicked off the process.
///   - `arguments` (required): A list of strings that were passed as arguments
///     to the executable.
///   - `workingDirectory` (required): The current working directory from which
///     the process was spawned.
///   - `environment` (required): A map from string environment variable keys
///     to their corresponding string values.
///   - `mode` (optional): A string specifying the [ProcessStartMode].
///   - `stdoutEncoding` (optional): The name of the encoding scheme that was
///     used in the `stdout` file. If unspecified, then the file was written
///     as binary data.
///   - `stderrEncoding` (optional): The name of the encoding scheme that was
///     used in the `stderr` file. If unspecified, then the file was written
///     as binary data.
///   - `exitCode` (required): The exit code of the process, or null if the
///     process was not responding.
///   - `daemon` (optional): A boolean indicating that the process is to stay
///     resident during the entire lifetime of the master Flutter tools process.
/// - a `stdout` file for each process invocation. The location of this file
///   can be derived from the `basename` manifest property like so:
///   `'$basename.stdout'`.
/// - a `stderr` file for each process invocation. The location of this file
///   can be derived from the `basename` manifest property like so:
///   `'$basename.stderr'`.
class ReplayProcessManager implements ProcessManager {
  final List<Map<String, dynamic>> _manifest;
  final Directory _dir;

  ReplayProcessManager._(this._manifest, this._dir);

  /// Creates a new `ReplayProcessManager` capable of replaying a recording at
  /// the specified location.
  ///
  /// If [location] represents a file, it will be treated like a recording
  /// ZIP file. If it points to a directory, it will be treated like an
  /// unzipped recording. If [location] points to a non-existent file or
  /// directory, an [ArgumentError] will be thrown.
  static Future<ReplayProcessManager> create(String location) async {
    Directory dir;
    switch (FileSystemEntity.typeSync(location)) {
      case FileSystemEntityType.FILE:
        dir = await Directory.systemTemp.createTemp('flutter_tools_');
        os.unzip(new File(location), dir);
        addShutdownHook(() async {
          await dir.delete(recursive: true);
        });
        break;
      case FileSystemEntityType.DIRECTORY:
        dir = new Directory(location);
        break;
      case FileSystemEntityType.NOT_FOUND:
        throw new ArgumentError.value(location, 'location', 'Does not exist');
    }

    File manifestFile = new File(path.join(dir.path, _kManifestName));
    if (!manifestFile.existsSync()) {
      // We use the existence of the manifest as a proxy for this being a
      // valid replay directory. Namely, we don't validate the structure of the
      // JSON within the manifest, and we don't validate the existence of
      // all stdout and stderr files referenced in the manifest.
      throw new ArgumentError.value(location, 'location',
          'Does not represent a valid recording (it does not '
          'contain $_kManifestName).');
    }

    String content = await manifestFile.readAsString();
    try {
      List<Map<String, dynamic>> manifest = new JsonDecoder().convert(content);
      return new ReplayProcessManager._(manifest, dir);
    } on FormatException catch (e) {
      throw new ArgumentError('$_kManifestName is not a valid JSON file: $e');
    }
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    ProcessStartMode mode: ProcessStartMode.NORMAL,
  }) async {
    Map<String, dynamic> entry = _popEntry(executable, arguments, mode: mode);
    _ReplayProcessResult result = await _ReplayProcessResult.create(
        executable, arguments, _dir, entry);
    return result.asProcess(entry['daemon'] ?? false);
  }

  @override
  Future<ProcessResult> run(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
  }) async {
    Map<String, dynamic> entry = _popEntry(executable, arguments,
        stdoutEncoding: stdoutEncoding, stderrEncoding: stderrEncoding);
    return await _ReplayProcessResult.create(
        executable, arguments, _dir, entry);
  }

  @override
  ProcessResult runSync(
    String executable,
    List<String> arguments, {
    String workingDirectory,
    Map<String, String> environment,
    Encoding stdoutEncoding: SYSTEM_ENCODING,
    Encoding stderrEncoding: SYSTEM_ENCODING,
  }) {
    Map<String, dynamic> entry = _popEntry(executable, arguments,
        stdoutEncoding: stdoutEncoding, stderrEncoding: stderrEncoding);
    return _ReplayProcessResult.createSync(
        executable, arguments, _dir, entry);
  }

  /// Finds and returns the next entry in the process manifest that matches
  /// the specified process arguments. Once found, it marks the manifest entry
  /// as having been invoked and thus not eligible for invocation again.
  Map<String, dynamic> _popEntry(String executable, List<String> arguments, {
    ProcessStartMode mode,
    Encoding stdoutEncoding,
    Encoding stderrEncoding,
  }) {
    Map<String, dynamic> entry = _manifest.firstWhere(
      (Map<String, dynamic> entry) {
        // Ignore workingDirectory & environment, as they could
        // yield false negatives.
        return entry['executable'] == executable
            && _areListsEqual(entry['arguments'], arguments)
            && entry['mode'] == mode?.toString()
            && entry['stdoutEncoding'] == stdoutEncoding?.name
            && entry['stderrEncoding'] == stderrEncoding?.name
            && !(entry['invoked'] ?? false);
      },
      orElse: () => null,
    );

    if (entry == null)
      throw new ProcessException(executable, arguments, 'No matching invocation found');

    entry['invoked'] = true;
    return entry;
  }

  @override
  bool killPid(int pid, [ProcessSignal signal = ProcessSignal.SIGTERM]) {
    throw new UnsupportedError(
        "$runtimeType.killPid() has not been implemented because at the time "
        "of its writing, it wasn't needed. If you're hitting this error, you "
        "should implement it.");
  }
}

/// A [ProcessResult] implementation that derives its data from a recording
/// fragment.
class _ReplayProcessResult implements ProcessResult {
  @override
  final int pid;

  @override
  final int exitCode;

  @override
  final dynamic stdout;

  @override
  final dynamic stderr;

  _ReplayProcessResult._({this.pid, this.exitCode, this.stdout, this.stderr});

  static Future<_ReplayProcessResult> create(
    String executable,
    List<String> arguments,
    Directory dir,
    Map<String, dynamic> entry,
  ) async {
    String basePath = path.join(dir.path, entry['basename']);
    try {
      return new _ReplayProcessResult._(
        pid: entry['pid'],
        exitCode: entry['exitCode'],
        stdout: await _getData('$basePath.stdout', entry['stdoutEncoding']),
        stderr: await _getData('$basePath.stderr', entry['stderrEncoding']),
      );
    } catch (e) {
      throw new ProcessException(executable, arguments, e.toString());
    }
  }

  static Future<dynamic> _getData(String path, String encoding) async {
    File file = new File(path);
    return encoding == null
        ? await file.readAsBytes()
        : await file.readAsString(encoding: _getEncodingByName(encoding));
  }

  static _ReplayProcessResult createSync(
    String executable,
    List<String> arguments,
    Directory dir,
    Map<String, dynamic> entry,
  ) {
    String basePath = path.join(dir.path, entry['basename']);
    try {
      return new _ReplayProcessResult._(
        pid: entry['pid'],
        exitCode: entry['exitCode'],
        stdout: _getDataSync('$basePath.stdout', entry['stdoutEncoding']),
        stderr: _getDataSync('$basePath.stderr', entry['stderrEncoding']),
      );
    } catch (e) {
      throw new ProcessException(executable, arguments, e.toString());
    }
  }

  static dynamic _getDataSync(String path, String encoding) {
    File file = new File(path);
    return encoding == null
        ? file.readAsBytesSync()
        : file.readAsStringSync(encoding: _getEncodingByName(encoding));
  }

  static Encoding _getEncodingByName(String encoding) {
    if (encoding == 'system')
      return const SystemEncoding();
    else if (encoding != null)
      return Encoding.getByName(encoding);
    return null;
  }

  Process asProcess(bool daemon) {
    assert(stdout is List<int>);
    assert(stderr is List<int>);
    return new _ReplayProcess(this, daemon);
  }
}

/// A [Process] implementation derives its data from a recording fragment.
class _ReplayProcess implements Process {
  @override
  final int pid;

  final List<int> _stdout;
  final List<int> _stderr;
  final StreamController<List<int>> _stdoutController;
  final StreamController<List<int>> _stderrController;
  final int _exitCode;
  final Completer<int> _exitCodeCompleter;

  _ReplayProcess(_ReplayProcessResult result, bool daemon)
      : pid = result.pid,
        _stdout = result.stdout,
        _stderr = result.stderr,
        _stdoutController = new StreamController<List<int>>(),
        _stderrController = new StreamController<List<int>>(),
        _exitCode = result.exitCode,
        _exitCodeCompleter = new Completer<int>() {
    // Don't flush our stdio streams until we reach the outer event loop. This
    // is necessary because some of our process invocations transform the stdio
    // streams into broadcast streams (e.g. DeviceLogReader implementations),
    // and delaying our stdio stream production until we reach the outer event
    // loop allows all code running in the microtask loop to register as
    // listeners on these streams before we flush them.
    //
    // TODO(tvolkert): Once https://github.com/flutter/flutter/issues/7166 is
    //                 resolved, running on the outer event loop should be
    //                 sufficient (as described above), and we should switch to
    //                 Duration.ZERO. In the meantime, native file I/O
    //                 operations are causing a Duration.ZERO callback here to
    //                 run before our ProtocolDiscovery instantiation, and thus,
    //                 we flush our stdio streams before our protocol discovery
    //                 is listening on them (causing us to timeout waiting for
    //                 the observatory port discovery).
    new Timer(const Duration(milliseconds: 50), () {
      _stdoutController.add(_stdout);
      _stderrController.add(_stderr);
      if (!daemon)
        kill();
    });
  }

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  set exitCode(Future<int> exitCode) => throw new UnsupportedError('set exitCode');

  @override
  IOSink get stdin => throw new UnimplementedError();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.SIGTERM]) {
    if (!_exitCodeCompleter.isCompleted) {
      _stdoutController.close();
      _stderrController.close();
      _exitCodeCompleter.complete(_exitCode);
      return true;
    }
    return false;
  }
}
