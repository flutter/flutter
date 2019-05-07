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
  test('create channel', () {
    final HandlePairResult pair = System.channelCreate();
    expect(pair.status, equals(ZX.OK));
    expect(pair.first.isValid, isTrue);
    expect(pair.second.isValid, isTrue);
  });

  test('close channel', () {
    final HandlePairResult pair = System.channelCreate();
    expect(pair.first.close(), equals(0));
    expect(pair.first.isValid, isFalse);
    expect(pair.second.isValid, isTrue);
    expect(System.channelWrite(pair.first, ByteData(1), <Handle>[]),
        equals(ZX.ERR_BAD_HANDLE));
    expect(System.channelWrite(pair.second, ByteData(1), <Handle>[]),
        equals(ZX.ERR_PEER_CLOSED));
  });

  test('channel bytes', () {
    final HandlePairResult pair = System.channelCreate();

    // When no data is available, ZX.ERR_SHOULD_WAIT is returned.
    expect(System.channelQueryAndRead(pair.second).status,
        equals(ZX.ERR_SHOULD_WAIT));

    // Write bytes.
    final ByteData data = utf8Bytes('Hello, world');
    final int status = System.channelWrite(pair.first, data, <Handle>[]);
    expect(status, equals(ZX.OK));

    // Read bytes.
    final ReadResult readResult = System.channelQueryAndRead(pair.second);
    expect(readResult.status, equals(ZX.OK));
    expect(readResult.numBytes, equals(data.lengthInBytes));
    expect(readResult.bytes.lengthInBytes, equals(data.lengthInBytes));
    expect(readResult.bytesAsUTF8String(), equals('Hello, world'));
    expect(readResult.handles.length, equals(0));
  });

  test('channel handles', () {
    final HandlePairResult pair = System.channelCreate();
    final ByteData data = utf8Bytes('');
    final HandlePairResult eventPair = System.eventpairCreate();
    final int status =
        System.channelWrite(pair.first, data, <Handle>[eventPair.first]);
    expect(status, equals(ZX.OK));
    expect(eventPair.first.isValid, isFalse);

    final ReadResult readResult = System.channelQueryAndRead(pair.second);
    expect(readResult.status, equals(ZX.OK));
    expect(readResult.numBytes, equals(0));
    expect(readResult.bytes.lengthInBytes, equals(0));
    expect(readResult.bytesAsUTF8String(), equals(''));
    expect(readResult.handles.length, equals(1));
    expect(readResult.handles[0].isValid, isTrue);
  });

  test('async wait channel read', () async {
    final HandlePairResult pair = System.channelCreate();
    final Completer<List<int>> completer = Completer<List<int>>();
    pair.first.asyncWait(ZX.CHANNEL_READABLE, (int status, int pending) {
      completer.complete(<int>[status, pending]);
    });

    expect(completer.isCompleted, isFalse);

    System.channelWrite(pair.second, utf8Bytes('Hi'), <Handle>[]);

    final List<int> result = await completer.future;
    expect(result[0], equals(ZX.OK)); // status
    expect(result[1] & ZX.CHANNEL_READABLE,
        equals(ZX.CHANNEL_READABLE)); // pending
  });

  test('async wait channel closed', () async {
    final HandlePairResult pair = System.channelCreate();
    final Completer<int> completer = Completer<int>();
    pair.first.asyncWait(ZX.CHANNEL_PEER_CLOSED, (int status, int pending) {
      completer.complete(status);
    });

    expect(completer.isCompleted, isFalse);

    pair.second.close();

    final int status = await completer.future;
    expect(status, equals(ZX.OK));
  });
}
