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
import 'process.dart';

ProcessManager get processManager => context[ProcessManager];

/// A class that manages the creation of operating system processes. This
/// provides a lightweight wrapper around the underlying [Process] static
/// methods to allow the implementation of these methods to be mocked out or
/// decorated for testing or debugging purposes.
class ProcessManager {
  Future<Process> start(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       ProcessStartMode mode: ProcessStartMode.NORMAL}) {
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
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
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
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
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

  final FileSystemEntity _recordTo;
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
  RecordingProcessManager({FileSystemEntity recordTo})
      : _recordTo = recordTo ?? Directory.current {
    addShutdownHook(_onShutdown);
  }

  @override
  Future<Process> start(
      String executable,
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       ProcessStartMode mode: ProcessStartMode.NORMAL}) async {
    Process process = await _delegate.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
    );

    Map<String, dynamic> manifestEntry = _createManifestEntry(
      pid: process.pid,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      mode: mode,
    );
    _manifest.add(manifestEntry);

    _RecordingProcess result = new _RecordingProcess(
      manager: this,
      basename: _getBasename(process.pid, executable, arguments),
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
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) async {
    ProcessResult result = await _delegate.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );

    _manifest.add(_createManifestEntry(
      pid: result.pid,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    ));

    String basename = _getBasename(result.pid, executable, arguments);
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
      List<String> arguments,
      {String workingDirectory,
       Map<String, String> environment,
       Encoding stdoutEncoding: SYSTEM_ENCODING,
       Encoding stderrEncoding: SYSTEM_ENCODING}) {
    ProcessResult result = _delegate.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );

    _manifest.add(_createManifestEntry(
      pid: result.pid,
      executable: executable,
      arguments: arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    ));

    String basename = _getBasename(result.pid, executable, arguments);
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
      String executable,
      List<String> arguments,
      String workingDirectory,
      Map<String, String> environment,
      ProcessStartMode mode,
      Encoding stdoutEncoding,
      Encoding stderrEncoding,
  }) {
    Map<String, dynamic> entry = <String, dynamic>{};
    if (pid != null) entry['pid'] = pid;
    if (executable != null) entry['executable'] = executable;
    if (arguments != null) entry['arguments'] = arguments;
    if (workingDirectory != null) entry['workingDirectory'] = workingDirectory;
    if (environment != null) entry['environment'] = environment;
    if (mode != null) entry['mode'] = mode.toString();
    if (stdoutEncoding != null) entry['stdoutEncoding'] = stdoutEncoding.name;
    if (stderrEncoding != null) entry['stderrEncoding'] = stderrEncoding.name;
    return entry;
  }

  /// Returns a human-readable identifier for the specified executable.
  String _getBasename(int pid, String executable, List<String> arguments) {
    String index = new NumberFormat('000').format(_manifest.length - 1);
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
  /// will be killed (via `SIGTERM`) and have a `"timeout"` marker added to
  /// their manifest. If such processes *still* don't exit in a timely fashion,
  /// they'll have a `"doubleTimeout"` marker added to their manifest.
  Future<Null> _waitForRunningProcessesToExit() async {
    await _waitForRunningProcessesToExitWithTimeout(
      onTimeout: (int pid, Map<String, dynamic> manifestEntry) {
        manifestEntry['timeout'] = true;
        Process.killPid(pid);
      });
    // Now that we explicitly signalled the processes that timed out asking
    // then to shutdown, wait one more time for those processes to exit.
    await _waitForRunningProcessesToExitWithTimeout(
      onTimeout: (int pid, Map<String, dynamic> manifestEntry) {
        manifestEntry['doubleTimeout'] = true;
      });
  }

  Future<Null> _waitForRunningProcessesToExitWithTimeout({
    void onTimeout(int pid, Map<String, dynamic> manifestEntry),
  }) async {
    await Future.wait(new List<Future<int>>.from(_runningProcesses.values))
        .timeout(new Duration(milliseconds: 20), onTimeout: () {
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
    File manifestFile = await new File('${_tmpDir.path}/process-manifest.txt').create();
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
    if (await FileSystemEntity.type(_recordTo.path) == FileSystemEntityType.DIRECTORY) {
      zipFile = new File('${_recordTo.path}/$kDefaultRecordTo');
    } else {
      zipFile = new File(_recordTo.path);
      await new Directory(path.dirname(zipFile.path)).create(recursive: true);
    }

    // Resolve collisions.
    String basename = path.basename(zipFile.path);
    for (int i = 1; await zipFile.exists(); i++) {
      assert(await FileSystemEntity.isFile(zipFile.path));
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
