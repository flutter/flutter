// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';
import 'dart:typed_data';

import 'package:file/src/io.dart' as io;
import 'package:meta/meta.dart';

/// A [RandomAccessFile] implementation that forwards all methods and properties
/// to a delegate.
abstract class ForwardingRandomAccessFile implements io.RandomAccessFile {
  /// The entity to which this entity will forward all methods and properties.
  @protected
  io.RandomAccessFile get delegate;

  @override
  String get path => delegate.path;

  @override
  Future<void> close() => delegate.close();

  @override
  void closeSync() => delegate.closeSync();

  @override
  Future<io.RandomAccessFile> flush() async {
    await delegate.flush();
    return this;
  }

  @override
  void flushSync() => delegate.flushSync();

  @override
  Future<int> length() => delegate.length();

  @override
  int lengthSync() => delegate.lengthSync();

  @override
  Future<io.RandomAccessFile> lock([
    io.FileLock mode = io.FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async {
    await delegate.lock(mode, start, end);
    return this;
  }

  @override
  void lockSync([
    io.FileLock mode = io.FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) =>
      delegate.lockSync(mode, start, end);

  @override
  Future<int> position() => delegate.position();

  @override
  int positionSync() => delegate.positionSync();

  @override
  Future<Uint8List> read(int bytes) => delegate.read(bytes);

  @override
  Uint8List readSync(int bytes) => delegate.readSync(bytes);

  @override
  Future<int> readByte() => delegate.readByte();

  @override
  int readByteSync() => delegate.readByteSync();

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) =>
      delegate.readInto(buffer, start, end);

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) =>
      delegate.readIntoSync(buffer, start, end);

  @override
  Future<io.RandomAccessFile> setPosition(int position) async {
    await delegate.setPosition(position);
    return this;
  }

  @override
  void setPositionSync(int position) => delegate.setPositionSync(position);

  @override
  Future<io.RandomAccessFile> truncate(int length) async {
    await delegate.truncate(length);
    return this;
  }

  @override
  void truncateSync(int length) => delegate.truncateSync(length);

  @override
  Future<io.RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    await delegate.unlock(start, end);
    return this;
  }

  @override
  void unlockSync([int start = 0, int end = -1]) =>
      delegate.unlockSync(start, end);

  @override
  Future<io.RandomAccessFile> writeByte(int value) async {
    await delegate.writeByte(value);
    return this;
  }

  @override
  int writeByteSync(int value) => delegate.writeByteSync(value);

  @override
  Future<io.RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    await delegate.writeFrom(buffer, start, end);
    return this;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) =>
      delegate.writeFromSync(buffer, start, end);

  @override
  Future<io.RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) async {
    await delegate.writeString(string, encoding: encoding);
    return this;
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) =>
      delegate.writeStringSync(string, encoding: encoding);
}
