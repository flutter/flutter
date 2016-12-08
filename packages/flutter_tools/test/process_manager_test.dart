// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_tools/src/base/context.dart';
import 'package:flutter_tools/src/base/logger.dart';
import 'package:flutter_tools/src/base/os.dart';
import 'package:flutter_tools/src/base/process.dart';
import 'package:flutter_tools/src/base/process_manager.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

typedef bool Predicate<T>(T item);

/// Decodes a UTF8-encoded byte array into a list of Strings, where each list
/// entry represents a line of text.
List<String> _decode(List<int> data) =>
    const LineSplitter().convert(UTF8.decode(data));

/// Consumes and returns an entire stream of bytes.
Future<List<int>> _consume(Stream<List<int>> stream) =>
    stream.expand((List<int> data) => data).toList();

void main() {
  group('RecordingProcessManager', () {
    Directory tmp;
    ProcessManager manager;

    setUp(() {
      tmp = Directory.systemTemp.createTempSync('flutter_tools_');
      manager = new RecordingProcessManager(tmp.path);
    });

    tearDown(() {
      tmp.deleteSync(recursive: true);
    });

    test('start', () async {
      Process process = await manager.start('echo', <String>['foo']);
      int pid = process.pid;
      int exitCode = await process.exitCode;
      List<int> stdout = await _consume(process.stdout);
      List<int> stderr = await _consume(process.stderr);
      expect(exitCode, 0);
      expect(_decode(stdout), <String>['foo']);
      expect(stderr, isEmpty);

      // Force the recording to be written to disk.
      await runShutdownHooks();

      _Recording recording = _Recording.readFrom(tmp);
      expect(recording.manifest, hasLength(1));
      Map<String, dynamic> entry = recording.manifest.first;
      expect(entry['pid'], pid);
      expect(entry['exitCode'], exitCode);
      expect(recording.stdoutForEntryAt(0), stdout);
      expect(recording.stderrForEntryAt(0), stderr);
    });

    test('run', () async {
      ProcessResult result = await manager.run('echo', <String>['bar']);
      int pid = result.pid;
      int exitCode = result.exitCode;
      String stdout = result.stdout;
      String stderr = result.stderr;
      expect(exitCode, 0);
      expect(stdout, 'bar\n');
      expect(stderr, isEmpty);

      // Force the recording to be written to disk.
      await runShutdownHooks();

      _Recording recording = _Recording.readFrom(tmp);
      expect(recording.manifest, hasLength(1));
      Map<String, dynamic> entry = recording.manifest.first;
      expect(entry['pid'], pid);
      expect(entry['exitCode'], exitCode);
      expect(recording.stdoutForEntryAt(0), stdout);
      expect(recording.stderrForEntryAt(0), stderr);
    });

    test('runSync', () async {
      ProcessResult result = manager.runSync('echo', <String>['baz']);
      int pid = result.pid;
      int exitCode = result.exitCode;
      String stdout = result.stdout;
      String stderr = result.stderr;
      expect(exitCode, 0);
      expect(stdout, 'baz\n');
      expect(stderr, isEmpty);

      // Force the recording to be written to disk.
      await runShutdownHooks();

      _Recording recording = _Recording.readFrom(tmp);
      expect(recording.manifest, hasLength(1));
      Map<String, dynamic> entry = recording.manifest.first;
      expect(entry['pid'], pid);
      expect(entry['exitCode'], exitCode);
      expect(recording.stdoutForEntryAt(0), stdout);
      expect(recording.stderrForEntryAt(0), stderr);
    });
  });

  group('ReplayProcessManager', () {
    ProcessManager manager;

    setUp(() async {
      await runInMinimalContext(() async {
        Directory dir = new Directory('test/data/process_manager/replay');
        manager = await ReplayProcessManager.create(dir.path);
      });
    });

    tearDown(() async {
      // Allow the replay manager to clean up
      await runShutdownHooks();
    });

    test('start', () async {
      Process process = await manager.start('sing', <String>['ppap']);
      int exitCode = await process.exitCode;
      List<int> stdout = await _consume(process.stdout);
      List<int> stderr = await _consume(process.stderr);
      expect(process.pid, 100);
      expect(exitCode, 0);
      expect(_decode(stdout), <String>['I have a pen', 'I have a pineapple']);
      expect(_decode(stderr), <String>['Uh, pineapple pen']);
    });

    test('run', () async {
      ProcessResult result = await manager.run('dance', <String>['gangnam-style']);
      expect(result.pid, 101);
      expect(result.exitCode, 2);
      expect(result.stdout, '');
      expect(result.stderr, 'No one can dance like Psy\n');
    });

    test('runSync', () {
      ProcessResult result = manager.runSync('dance', <String>['gangnam-style']);
      expect(result.pid, 101);
      expect(result.exitCode, 2);
      expect(result.stdout, '');
      expect(result.stderr, 'No one can dance like Psy\n');
    });
  });
}

Future<Null> runInMinimalContext(Future<dynamic> method()) async {
  AppContext context = new AppContext();
  context.putIfAbsent(ProcessManager, () => new ProcessManager());
  context.putIfAbsent(Logger, () => new BufferLogger());
  context.putIfAbsent(OperatingSystemUtils, () => new OperatingSystemUtils());
  await context.runInZone(method);
}

/// A testing utility class that encapsulates a recording.
class _Recording {
  final File file;
  final Archive _archive;

  _Recording(this.file, this._archive);

  static _Recording readFrom(Directory dir) {
    File file = new File(path.join(
        dir.path, RecordingProcessManager.kDefaultRecordTo));
    Archive archive = new ZipDecoder().decodeBytes(file.readAsBytesSync());
    return new _Recording(file, archive);
  }

  List<Map<String, dynamic>> get manifest {
    return JSON.decoder.convert(_getFileContent('MANIFEST.txt', UTF8));
  }

  dynamic stdoutForEntryAt(int index) =>
      _getStdioContent(manifest[index], 'stdout');

  dynamic stderrForEntryAt(int index) =>
      _getStdioContent(manifest[index], 'stderr');

  dynamic _getFileContent(String name, Encoding encoding) {
    List<int> bytes = _fileNamed(name).content;
    return encoding == null ? bytes : encoding.decode(bytes);
  }

  dynamic _getStdioContent(Map<String, dynamic> entry, String type) {
    String basename = entry['basename'];
    String encodingName = entry['${type}Encoding'];
    Encoding encoding;
    if (encodingName != null)
      encoding = encodingName == 'system'
          ? const SystemEncoding()
          : Encoding.getByName(encodingName);
    return _getFileContent('$basename.$type', encoding);
  }

  ArchiveFile _fileNamed(String name) => _archive.firstWhere(_hasName(name));

  Predicate<ArchiveFile> _hasName(String name) =>
      (ArchiveFile file) => file.name == name;
}
