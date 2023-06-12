// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:math' as math show min;
import 'dart:typed_data';

import 'package:file/file.dart';
import 'package:file/src/backends/memory/operations.dart';
import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

import 'common.dart';
import 'memory_file_system_entity.dart';
import 'memory_random_access_file.dart';
import 'node.dart';
import 'utils.dart' as utils;

/// Internal implementation of [File].
class MemoryFile extends MemoryFileSystemEntity implements File {
  /// Instantiates a new [MemoryFile].
  const MemoryFile(NodeBasedFileSystem fileSystem, String path)
      : super(fileSystem, path);

  FileNode get _resolvedBackingOrCreate {
    Node? node = backingOrNull;
    if (node == null) {
      node = _doCreate();
    } else {
      node = utils.isLink(node)
          ? utils.resolveLinks(node as LinkNode, () => path)
          : node;
      utils.checkType(expectedType, node.type, () => path);
    }
    return node as FileNode;
  }

  @override
  io.FileSystemEntityType get expectedType => io.FileSystemEntityType.file;

  @override
  bool existsSync() {
    fileSystem.opHandle.call(path, FileSystemOp.exists);
    return backingOrNull?.stat.type == expectedType;
  }

  @override
  Future<File> create({bool recursive = false, bool exclusive = false}) async {
    createSync(recursive: recursive, exclusive: exclusive);
    return this;
  }

  // TODO(dartbug.com/49647): Pass `exclusive` through after it lands.
  @override
  void createSync({bool recursive = false, bool exclusive = false}) {
    fileSystem.opHandle(path, FileSystemOp.create);
    _doCreate(recursive: recursive /*, exclusive: exclusive*/);
  }

  Node? _doCreate({bool recursive = false}) {
    Node? node = internalCreateSync(
      followTailLink: true,
      createChild: (DirectoryNode parent, bool isFinalSegment) {
        if (isFinalSegment) {
          return FileNode(parent);
        } else if (recursive) {
          return DirectoryNode(parent);
        }
        return null;
      },
    );
    if (node?.type != expectedType) {
      // There was an existing non-file entity at this object's path
      assert(node?.type == FileSystemEntityType.directory);
      throw common.isADirectory(path);
    }
    return node;
  }

  @override
  Future<File> rename(String newPath) async => renameSync(newPath);

  @override
  File renameSync(String newPath) => internalRenameSync(
        newPath,
        followTailLink: true,
        checkType: (Node node) {
          FileSystemEntityType actualType = node.stat.type;
          if (actualType != expectedType) {
            throw actualType == FileSystemEntityType.notFound
                ? common.noSuchFileOrDirectory(path)
                : common.isADirectory(path);
          }
        },
      ) as File;

  @override
  Future<File> copy(String newPath) async => copySync(newPath);

  @override
  File copySync(String newPath) {
    fileSystem.opHandle(path, FileSystemOp.copy);
    FileNode sourceNode = resolvedBacking as FileNode;
    fileSystem.findNode(
      newPath,
      segmentVisitor: (
        DirectoryNode parent,
        String childName,
        Node? child,
        int currentSegment,
        int finalSegment,
      ) {
        if (currentSegment == finalSegment) {
          if (child != null) {
            if (utils.isLink(child)) {
              List<String> ledger = <String>[];
              child = utils.resolveLinks(child as LinkNode, () => newPath,
                  ledger: ledger);
              checkExists(child, () => newPath);
              parent = child.parent;
              childName = ledger.last;
              assert(parent.children.containsKey(childName));
            }
            utils.checkType(expectedType, child.type, () => newPath);
            parent.children.remove(childName);
          }
          FileNode newNode = FileNode(parent);
          newNode.copyFrom(sourceNode);
          parent.children[childName] = newNode;
        }
        return child;
      },
    );
    return clone(newPath);
  }

  @override
  Future<int> length() async => lengthSync();

  @override
  int lengthSync() => (resolvedBacking as FileNode).size;

  @override
  File get absolute => super.absolute as File;

  @override
  Future<DateTime> lastAccessed() async => lastAccessedSync();

  @override
  DateTime lastAccessedSync() => (resolvedBacking as FileNode).stat.accessed;

  @override
  Future<dynamic> setLastAccessed(DateTime time) async =>
      setLastAccessedSync(time);

  @override
  void setLastAccessedSync(DateTime time) {
    FileNode node = resolvedBacking as FileNode;
    node.accessed = time.millisecondsSinceEpoch;
  }

  @override
  Future<DateTime> lastModified() async => lastModifiedSync();

  @override
  DateTime lastModifiedSync() => (resolvedBacking as FileNode).stat.modified;

  @override
  Future<dynamic> setLastModified(DateTime time) async =>
      setLastModifiedSync(time);

  @override
  void setLastModifiedSync(DateTime time) {
    FileNode node = resolvedBacking as FileNode;
    node.modified = time.millisecondsSinceEpoch;
  }

  @override
  Future<io.RandomAccessFile> open(
          {io.FileMode mode = io.FileMode.read}) async =>
      openSync(mode: mode);

  @override
  io.RandomAccessFile openSync({io.FileMode mode = io.FileMode.read}) {
    fileSystem.opHandle(path, FileSystemOp.open);
    if (utils.isWriteMode(mode) && !existsSync()) {
      // [resolvedBacking] requires that the file already exists, so we must
      // create it here first.
      createSync();
    }

    return MemoryRandomAccessFile(path, resolvedBacking as FileNode, mode);
  }

  @override
  Stream<Uint8List> openRead([int? start, int? end]) {
    fileSystem.opHandle(path, FileSystemOp.open);
    try {
      FileNode node = resolvedBacking as FileNode;
      Uint8List content = node.content;
      if (start != null) {
        content = end == null
            ? content.sublist(start)
            : content.sublist(start, math.min(end, content.length));
      }
      return Stream<Uint8List>.fromIterable(<Uint8List>[content]);
    } catch (e) {
      return Stream<Uint8List>.fromFuture(Future<Uint8List>.error(e));
    }
  }

  @override
  io.IOSink openWrite({
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
  }) {
    fileSystem.opHandle(path, FileSystemOp.open);
    if (!utils.isWriteMode(mode)) {
      throw ArgumentError.value(mode, 'mode',
          'Must be either WRITE, APPEND, WRITE_ONLY, or WRITE_ONLY_APPEND');
    }
    return _FileSink.fromFile(this, mode, encoding);
  }

  @override
  Future<Uint8List> readAsBytes() async => readAsBytesSync();

  @override
  Uint8List readAsBytesSync() {
    fileSystem.opHandle(path, FileSystemOp.read);
    return Uint8List.fromList((resolvedBacking as FileNode).content);
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) async =>
      readAsStringSync(encoding: encoding);

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    try {
      return encoding.decode(readAsBytesSync());
    } on FormatException catch (err) {
      throw FileSystemException(err.message, path);
    }
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) async =>
      readAsLinesSync(encoding: encoding);

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    String str = readAsStringSync(encoding: encoding);

    if (str.isEmpty) {
      return <String>[];
    }

    final List<String> lines = str.split('\n');
    if (str.endsWith('\n')) {
      // A final newline should not create an additional line.
      lines.removeLast();
    }

    return lines;
  }

  @override
  Future<File> writeAsBytes(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) async {
    writeAsBytesSync(bytes, mode: mode, flush: flush);
    return this;
  }

  @override
  void writeAsBytesSync(
    List<int> bytes, {
    io.FileMode mode = io.FileMode.write,
    bool flush = false,
  }) {
    if (!utils.isWriteMode(mode)) {
      throw common.badFileDescriptor(path);
    }
    FileNode node = _resolvedBackingOrCreate;
    _truncateIfNecessary(node, mode);
    fileSystem.opHandle(path, FileSystemOp.write);
    node.write(bytes);
    node.touch();
  }

  @override
  Future<File> writeAsString(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) async {
    writeAsStringSync(contents, mode: mode, encoding: encoding, flush: flush);
    return this;
  }

  @override
  void writeAsStringSync(
    String contents, {
    io.FileMode mode = io.FileMode.write,
    Encoding encoding = utf8,
    bool flush = false,
  }) =>
      writeAsBytesSync(encoding.encode(contents), mode: mode, flush: flush);

  @override
  @protected
  File clone(String path) => MemoryFile(fileSystem, path);

  void _truncateIfNecessary(FileNode node, io.FileMode mode) {
    if (mode == io.FileMode.write || mode == io.FileMode.writeOnly) {
      node.clear();
    }
  }

  @override
  String toString() => "MemoryFile: '$path'";
}

/// Implementation of an [io.IOSink] that's backed by a [FileNode].
class _FileSink implements io.IOSink {
  factory _FileSink.fromFile(
    MemoryFile file,
    io.FileMode mode,
    Encoding encoding,
  ) {
    late FileNode node;
    Exception? deferredException;

    // Resolve the backing immediately to ensure that the [FileNode] we write
    // to is the same as when [openWrite] was called.  This can matter if the
    // file is moved or removed while open.
    try {
      node = file._resolvedBackingOrCreate;
    } on Exception catch (e) {
      // For behavioral consistency with [LocalFile], do not report failures
      // immediately.
      deferredException = e;
    }

    Future<FileNode> future = Future<FileNode>.microtask(() {
      if (deferredException != null) {
        throw deferredException;
      }
      file._truncateIfNecessary(node, mode);
      return node;
    });
    return _FileSink._(future, encoding);
  }

  _FileSink._(Future<FileNode> _node, this.encoding) : _pendingWrites = _node;

  final Completer<void> _completer = Completer<void>();

  Future<FileNode> _pendingWrites;
  Completer<void>? _streamCompleter;
  bool _isClosed = false;

  @override
  Encoding encoding;

  bool get isStreaming => !(_streamCompleter?.isCompleted ?? true);

  @override
  void add(List<int> data) {
    _checkNotStreaming();
    if (_isClosed) {
      throw StateError('StreamSink is closed');
    }

    _addData(data);
  }

  @override
  void write(Object? obj) => add(encoding.encode(obj?.toString() ?? 'null'));

  @override
  void writeAll(Iterable<dynamic> objects, [String separator = '']) {
    bool firstIter = true;
    for (dynamic obj in objects) {
      if (!firstIter) {
        write(separator);
      }
      firstIter = false;
      write(obj);
    }
  }

  @override
  void writeln([Object? obj = '']) {
    write(obj);
    write('\n');
  }

  @override
  void writeCharCode(int charCode) => write(String.fromCharCode(charCode));

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _checkNotStreaming();
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    _checkNotStreaming();
    _streamCompleter = Completer<void>();
    void finish() {
      _streamCompleter!.complete();
      _streamCompleter = null;
    }

    stream.listen(
      (List<int> data) => _addData(data),
      cancelOnError: true,
      onError: (Object error, StackTrace stackTrace) {
        _completer.completeError(error, stackTrace);
        finish();
      },
      onDone: finish,
    );
    return _streamCompleter!.future;
  }

  @override
  Future<void> flush() {
    _checkNotStreaming();
    return _pendingWrites;
  }

  @override
  Future<void> close() {
    _checkNotStreaming();
    if (!_isClosed) {
      _isClosed = true;
      _pendingWrites.then(
        (_) => _completer.complete(),
        onError: (Object error, StackTrace stackTrace) =>
            _completer.completeError(error, stackTrace),
      );
    }
    return _completer.future;
  }

  @override
  Future<void> get done => _completer.future;

  void _addData(List<int> data) {
    _pendingWrites = _pendingWrites.then((FileNode node) {
      node.write(data);
      return node;
    });
  }

  void _checkNotStreaming() {
    if (isStreaming) {
      throw StateError('StreamSink is bound to a stream');
    }
  }
}
