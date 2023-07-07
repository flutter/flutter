// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:math' as math show min;
import 'dart:typed_data';

import 'package:file/src/common.dart' as common;
import 'package:file/src/io.dart' as io;

import 'memory_file.dart';
import 'node.dart';
import 'utils.dart' as utils;

/// A [MemoryFileSystem]-backed implementation of [io.RandomAccessFile].
class MemoryRandomAccessFile implements io.RandomAccessFile {
  /// Constructs a [MemoryRandomAccessFile].
  ///
  /// This should be used only by [MemoryFile.open] or [MemoryFile.openSync].
  MemoryRandomAccessFile(this.path, this._node, this._mode) {
    switch (_mode) {
      case io.FileMode.read:
        break;
      case io.FileMode.write:
      case io.FileMode.writeOnly:
        truncateSync(0);
        break;
      case io.FileMode.append:
      case io.FileMode.writeOnlyAppend:
        _position = lengthSync();
        break;
      default:
        // [FileMode] provides no way of retrieving its value or name.
        throw UnimplementedError('Unsupported FileMode');
    }
  }

  @override
  final String path;

  final FileNode _node;
  final io.FileMode _mode;

  bool _isOpen = true;
  int _position = 0;

  /// Whether an asynchronous operation is pending.
  ///
  /// See [_asyncWrapper] for details.
  bool get _asyncOperationPending => __asyncOperationPending;

  set _asyncOperationPending(bool value) {
    assert(__asyncOperationPending != value);
    __asyncOperationPending = value;
  }

  bool __asyncOperationPending = false;

  /// Throws a [io.FileSystemException] if an operation is attempted on a file
  /// that is not open.
  void _checkOpen() {
    if (!_isOpen) {
      throw io.FileSystemException('File closed', path);
    }
  }

  /// Throws a [io.FileSystemException] if attempting to read from a file that
  /// has not been opened for reading.
  void _checkReadable(String operation) {
    switch (_mode) {
      case io.FileMode.read:
      case io.FileMode.write:
      case io.FileMode.append:
        return;
      case io.FileMode.writeOnly:
      case io.FileMode.writeOnlyAppend:
      default:
        throw io.FileSystemException(
            '$operation failed', path, common.badFileDescriptor(path).osError);
    }
  }

  /// Throws a [io.FileSystemException] if attempting to read from a file that
  /// has not been opened for writing.
  void _checkWritable(String operation) {
    if (utils.isWriteMode(_mode)) {
      return;
    }

    throw io.FileSystemException(
        '$operation failed', path, common.badFileDescriptor(path).osError);
  }

  /// Throws a [io.FileSystemException] if attempting to perform an operation
  /// while an asynchronous operation is already in progress.
  ///
  /// See [_asyncWrapper] for details.
  void _checkAsync() {
    if (_asyncOperationPending) {
      throw io.FileSystemException(
          'An async operation is currently pending', path);
    }
  }

  /// Wraps a synchronous function to make it appear asynchronous.
  ///
  /// [_asyncOperationPending], [_checkAsync], and [_asyncWrapper] are used to
  /// mimic [RandomAccessFile]'s enforcement that only one asynchronous
  /// operation is pending for a [RandomAccessFile] instance.  Since
  /// [MemoryFileSystem]-based classes are likely to be used in tests, fidelity
  /// is important to catch errors that might occur in production.
  ///
  /// [_asyncWrapper] does not call [f] directly since setting and unsetting
  /// [_asyncOperationPending] synchronously would not be meaningful.  We
  /// instead execute [f] through a [Future.delayed] callback to better simulate
  /// asynchrony.
  Future<R> _asyncWrapper<R>(R Function() f) async {
    _checkAsync();

    _asyncOperationPending = true;
    try {
      return await Future<R>.delayed(
        Duration.zero,
        () {
          // Temporarily reset [_asyncOpPending] in case [f]'s has its own
          // checks for pending asynchronous operations.
          _asyncOperationPending = false;
          try {
            return f();
          } finally {
            _asyncOperationPending = true;
          }
        },
      );
    } finally {
      _asyncOperationPending = false;
    }
  }

  @override
  Future<void> close() async => _asyncWrapper(closeSync);

  @override
  void closeSync() {
    _checkOpen();
    _isOpen = false;
  }

  @override
  Future<io.RandomAccessFile> flush() async {
    await _asyncWrapper(flushSync);
    return this;
  }

  @override
  void flushSync() {
    _checkOpen();
    _checkAsync();
  }

  @override
  Future<int> length() => _asyncWrapper(lengthSync);

  @override
  int lengthSync() {
    _checkOpen();
    _checkAsync();
    return _node.size;
  }

  @override
  Future<io.RandomAccessFile> lock([
    io.FileLock mode = io.FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async {
    await _asyncWrapper(() => lockSync(mode, start, end));
    return this;
  }

  @override
  void lockSync([
    io.FileLock mode = io.FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {
    _checkOpen();
    _checkAsync();
    // TODO(jamesderlin): Implement, https://github.com/google/file.dart/issues/140
    throw UnimplementedError('TODO');
  }

  @override
  Future<int> position() => _asyncWrapper(positionSync);

  @override
  int positionSync() {
    _checkOpen();
    _checkAsync();
    return _position;
  }

  @override
  Future<Uint8List> read(int bytes) => _asyncWrapper(() => readSync(bytes));

  @override
  Uint8List readSync(int bytes) {
    _checkOpen();
    _checkAsync();
    _checkReadable('read');
    // TODO(jamesderlin): Check for integer overflow.
    final int end = math.min(_position + bytes, lengthSync());
    final Uint8List copy = _node.content.sublist(_position, end);
    _position = end;
    return copy;
  }

  @override
  Future<int> readByte() => _asyncWrapper(readByteSync);

  @override
  int readByteSync() {
    _checkOpen();
    _checkAsync();
    _checkReadable('readByte');

    if (_position >= lengthSync()) {
      return -1;
    }
    return _node.content[_position++];
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) =>
      _asyncWrapper(() => readIntoSync(buffer, start, end));

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    _checkOpen();
    _checkAsync();
    _checkReadable('readInto');

    end = RangeError.checkValidRange(start, end, buffer.length);

    final int length = lengthSync();
    int i;
    for (i = start; i < end && _position < length; i += 1, _position += 1) {
      buffer[i] = _node.content[_position];
    }
    return i - start;
  }

  @override
  Future<io.RandomAccessFile> setPosition(int position) async {
    await _asyncWrapper(() => setPositionSync(position));
    return this;
  }

  @override
  void setPositionSync(int position) {
    _checkOpen();
    _checkAsync();

    if (position < 0) {
      throw io.FileSystemException(
          'setPosition failed', path, common.invalidArgument(path).osError);
    }

    // Empirical testing indicates that setting the position to be beyond the
    // end of the file is legal and will zero-fill upon the next write.
    _position = position;
  }

  @override
  Future<io.RandomAccessFile> truncate(int length) async {
    await _asyncWrapper(() => truncateSync(length));
    return this;
  }

  @override
  void truncateSync(int length) {
    _checkOpen();
    _checkAsync();

    if (length < 0 || !utils.isWriteMode(_mode)) {
      throw io.FileSystemException(
          'truncate failed', path, common.invalidArgument(path).osError);
    }

    final int oldLength = lengthSync();
    if (length < oldLength) {
      _node.truncate(length);

      // [_position] is intentionally left untouched to match the observed
      // behavior of [RandomAccessFile].
    } else if (length > oldLength) {
      _node.write(Uint8List(length - oldLength));
    }
    assert(lengthSync() == length);
  }

  @override
  Future<io.RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    await _asyncWrapper(() => unlockSync(start, end));
    return this;
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    _checkOpen();
    _checkAsync();
    // TODO(jamesderlin): Implement, https://github.com/google/file.dart/issues/140
    throw UnimplementedError('TODO');
  }

  @override
  Future<io.RandomAccessFile> writeByte(int value) async {
    await _asyncWrapper(() => writeByteSync(value));
    return this;
  }

  @override
  int writeByteSync(int value) {
    _checkOpen();
    _checkAsync();
    _checkWritable('writeByte');

    // [Uint8List] will truncate values to 8-bits automatically, so we don't
    // need to check [value].

    int length = lengthSync();
    if (_position >= length) {
      // If [_position] is out of bounds, [RandomAccessFile] zero-fills the
      // file.
      truncateSync(_position + 1);
      length = lengthSync();
    }
    assert(_position < length);
    _node.content[_position++] = value;

    // Despite what the documentation states, [RandomAccessFile.writeByteSync]
    // always seems to return 1, even if we had to extend the file for an out of
    // bounds write.  See https://github.com/dart-lang/sdk/issues/42298.
    return 1;
  }

  @override
  Future<io.RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    await _asyncWrapper(() => writeFromSync(buffer, start, end));
    return this;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    _checkOpen();
    _checkAsync();
    _checkWritable('writeFrom');

    end = RangeError.checkValidRange(start, end, buffer.length);

    final int writeByteCount = end - start;
    final int endPosition = _position + writeByteCount;

    if (endPosition > lengthSync()) {
      truncateSync(endPosition);
    }

    _node.content.setRange(_position, endPosition, buffer, start);
    _position = endPosition;
  }

  @override
  Future<io.RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) async {
    await _asyncWrapper(() => writeStringSync(string, encoding: encoding));
    return this;
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) {
    writeFromSync(encoding.encode(string));
  }
}
