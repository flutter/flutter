// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:zircon/zircon.dart';

/// Helper method to turn a [String] into a [ByteData] containing the
/// text of the string encoded as UTF-8.
ByteData utf8Bytes(final String text) {
  return ByteData.view(Uint8List.fromList(utf8.encode(text)).buffer);
}

void main() {
  // NOTE: This only tests stream sockets.
  // We should add tests for datagram sockets.

  test('create socket', () {
    final HandlePairResult pair = System.socketCreate();
    expect(pair.status, equals(ZX.OK));
    expect(pair.first.isValid, isTrue);
    expect(pair.second.isValid, isTrue);
  });

  test('close socket', () {
    final HandlePairResult pair = System.socketCreate();
    expect(pair.first.close(), equals(0));
    expect(pair.first.isValid, isFalse);
    expect(pair.second.isValid, isTrue);
    final WriteResult firstResult =
        System.socketWrite(pair.first, ByteData(1), 0);
    expect(firstResult.status, equals(ZX.ERR_BAD_HANDLE));
    final WriteResult secondResult =
        System.socketWrite(pair.second, ByteData(1), 0);
    expect(secondResult.status, equals(ZX.ERR_PEER_CLOSED));
  });

  test('read write socket', () {
    final HandlePairResult pair = System.socketCreate();

    // When no data is available, ZX.ERR_SHOULD_WAIT is returned.
    expect(
        System.socketRead(pair.second, 1).status, equals(ZX.ERR_SHOULD_WAIT));

    final ByteData data = utf8Bytes('Hello, world');
    final WriteResult writeResult = System.socketWrite(pair.first, data, 0);
    expect(writeResult.status, equals(ZX.OK));

    final ReadResult readResult =
        System.socketRead(pair.second, data.lengthInBytes);
    expect(readResult.status, equals(ZX.OK));
    expect(readResult.numBytes, equals(data.lengthInBytes));
    expect(readResult.bytes.lengthInBytes, equals(data.lengthInBytes));
    expect(readResult.bytesAsUTF8String(), equals('Hello, world'));
  });

  test('partial read socket', () {
    final HandlePairResult pair = System.socketCreate();
    final ByteData data = utf8Bytes('Hello, world');
    final WriteResult writeResult = System.socketWrite(pair.first, data, 0);
    expect(writeResult.status, equals(ZX.OK));

    const int shortLength = 'Hello'.length;
    final ReadResult shortReadResult =
        System.socketRead(pair.second, shortLength);
    expect(shortReadResult.status, equals(ZX.OK));
    expect(shortReadResult.numBytes, equals(shortLength));
    expect(shortReadResult.bytes.lengthInBytes, equals(shortLength));
    expect(shortReadResult.bytesAsUTF8String(), equals('Hello'));

    final int longLength = data.lengthInBytes * 2;
    final ReadResult longReadResult =
        System.socketRead(pair.second, longLength);
    expect(longReadResult.status, equals(ZX.OK));
    expect(longReadResult.numBytes, equals(data.lengthInBytes - shortLength));
    expect(longReadResult.bytes.lengthInBytes, equals(longLength));
    expect(longReadResult.bytesAsUTF8String(), equals(', world'));
  });

  test('partial write socket', () {
    final HandlePairResult pair = System.socketCreate();
    final WriteResult writeResult1 =
        System.socketWrite(pair.first, utf8Bytes('Hello, '), 0);
    expect(writeResult1.status, equals(ZX.OK));
    final WriteResult writeResult2 =
        System.socketWrite(pair.first, utf8Bytes('world'), 0);
    expect(writeResult2.status, equals(ZX.OK));

    final ReadResult readResult = System.socketRead(pair.second, 100);
    expect(readResult.status, equals(ZX.OK));
    expect(readResult.numBytes, equals('Hello, world'.length));
    expect(readResult.bytes.lengthInBytes, equals(100));
    expect(readResult.bytesAsUTF8String(), equals('Hello, world'));
  });

  test('async wait socket read', () async {
    final HandlePairResult pair = System.socketCreate();
    final Completer<int> completer = Completer<int>();
    pair.first.asyncWait(ZX.SOCKET_READABLE, (int status, int pending) {
      completer.complete(status);
    });

    expect(completer.isCompleted, isFalse);

    System.socketWrite(pair.second, utf8Bytes('Hi'), 0);

    final int status = await completer.future;
    expect(status, equals(ZX.OK));
  });

  test('async wait socket closed', () async {
    final HandlePairResult pair = System.socketCreate();
    final Completer<int> completer = Completer<int>();
    pair.first.asyncWait(ZX.SOCKET_PEER_CLOSED, (int status, int pending) {
      completer.complete(status);
    });

    expect(completer.isCompleted, isFalse);

    pair.second.close();

    final int status = await completer.future;
    expect(status, equals(ZX.OK));
  });
}
