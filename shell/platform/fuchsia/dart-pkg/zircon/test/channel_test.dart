// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:litetest/litetest.dart';

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

  test('[ffi] create channel', () {
    final ZDChannel? channel = ZDChannel.create();
    expect(channel, isNotNull);
    final ZDHandlePair pair = channel!.handlePair;
    expect(pair.left.isValid(), isTrue);
    expect(pair.right.isValid(), isTrue);
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

  test('[ffi] close channel', () {
    final ZDChannel? channel = ZDChannel.create();
    final ZDHandlePair pair = channel!.handlePair;
    expect(pair.left.close(), isTrue);
    expect(pair.left.isValid, isFalse);
    expect(pair.right.isValid, isTrue);
    expect(channel.writeLeft(ByteData(1), <ZDHandle>[]),
        equals(ZX.ERR_BAD_HANDLE));
    expect(channel.writeRight(ByteData(1), <ZDHandle>[]),
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

  group('etc functions', () {
    test('moved handle', () {
      final HandlePairResult pair = System.channelCreate();
      final ByteData data = utf8Bytes('');
      final HandlePairResult transferred = System.channelCreate();

      final HandleDisposition disposition = HandleDisposition(ZX.HANDLE_OP_MOVE,
          transferred.first, ZX.OBJ_TYPE_CHANNEL, ZX.RIGHTS_IO);
      final int status = System.channelWriteEtc(
          pair.first, data, <HandleDisposition>[disposition]);
      expect(status, equals(ZX.OK));
      expect(disposition.result, equals(ZX.OK));
      expect(transferred.first.isValid, isFalse);

      final ReadEtcResult readResult =
          System.channelQueryAndReadEtc(pair.second);
      expect(readResult.status, equals(ZX.OK));
      expect(readResult.numBytes, equals(0));
      expect(readResult.bytes.lengthInBytes, equals(0));
      expect(readResult.bytesAsUTF8String(), equals(''));
      expect(readResult.handleInfos.length, equals(1));
      final HandleInfo handleInfo = readResult.handleInfos[0];
      expect(handleInfo.handle.isValid, isTrue);
      expect(handleInfo.type, equals(ZX.OBJ_TYPE_CHANNEL));
      expect(handleInfo.rights, equals(ZX.RIGHTS_IO));
    });

    test('copied handle', () {
      final HandlePairResult pair = System.channelCreate();
      final ByteData data = utf8Bytes('');
      final HandleResult vmo = System.vmoCreate(0);

      final HandleDisposition disposition = HandleDisposition(
          ZX.HANDLE_OP_DUPLICATE,
          vmo.handle,
          ZX.OBJ_TYPE_VMO,
          ZX.RIGHT_SAME_RIGHTS);
      final int status = System.channelWriteEtc(
          pair.first, data, <HandleDisposition>[disposition]);
      expect(status, equals(ZX.OK));
      expect(disposition.result, equals(ZX.OK));
      expect(vmo.handle.isValid, isTrue);

      final ReadEtcResult readResult =
          System.channelQueryAndReadEtc(pair.second);
      expect(readResult.status, equals(ZX.OK));
      expect(readResult.numBytes, equals(0));
      expect(readResult.bytes.lengthInBytes, equals(0));
      expect(readResult.bytesAsUTF8String(), equals(''));
      expect(readResult.handleInfos.length, equals(1));
      final HandleInfo handleInfo = readResult.handleInfos[0];
      expect(handleInfo.handle.isValid, isTrue);
      expect(handleInfo.type, equals(ZX.OBJ_TYPE_VMO));
      expect(handleInfo.rights, equals(ZX.DEFAULT_VMO_RIGHTS));
    });

    test('closed handle should error', () {
      final HandlePairResult pair = System.channelCreate();
      final ByteData data = utf8Bytes('');
      final HandlePairResult closed = System.channelCreate();

      final HandleDisposition disposition = HandleDisposition(ZX.HANDLE_OP_MOVE,
          closed.first, ZX.OBJ_TYPE_CHANNEL, ZX.RIGHT_SAME_RIGHTS);
      closed.first.close();
      final int status = System.channelWriteEtc(
          pair.first, data, <HandleDisposition>[disposition]);
      expect(status, equals(ZX.ERR_BAD_HANDLE));
      expect(disposition.result, equals(ZX.ERR_BAD_HANDLE));
      expect(closed.first.isValid, isFalse);

      final ReadEtcResult readResult =
          System.channelQueryAndReadEtc(pair.second);
      expect(readResult.status, equals(ZX.ERR_SHOULD_WAIT));
    });

    test('multiple handles', () {
      final HandlePairResult pair = System.channelCreate();
      final ByteData data = utf8Bytes('');
      final HandlePairResult transferred = System.channelCreate();
      final HandleResult vmo = System.vmoCreate(0);

      final List<HandleDisposition> dispositions = [
        HandleDisposition(ZX.HANDLE_OP_MOVE, transferred.first,
            ZX.OBJ_TYPE_CHANNEL, ZX.RIGHTS_IO),
        HandleDisposition(ZX.HANDLE_OP_DUPLICATE, vmo.handle, ZX.OBJ_TYPE_VMO,
            ZX.RIGHT_SAME_RIGHTS)
      ];
      final int status = System.channelWriteEtc(pair.first, data, dispositions);
      expect(status, equals(ZX.OK));
      expect(dispositions[0].result, equals(ZX.OK));
      expect(dispositions[1].result, equals(ZX.OK));
      expect(transferred.first.isValid, isFalse);
      expect(vmo.handle.isValid, isTrue);

      final ReadEtcResult readResult =
          System.channelQueryAndReadEtc(pair.second);
      expect(readResult.status, equals(ZX.OK));
      expect(readResult.numBytes, equals(0));
      expect(readResult.bytes.lengthInBytes, equals(0));
      expect(readResult.bytesAsUTF8String(), equals(''));

      expect(readResult.handleInfos.length, equals(2));
      final HandleInfo handleInfo = readResult.handleInfos[0];
      expect(handleInfo.handle.isValid, isTrue);
      expect(handleInfo.type, equals(ZX.OBJ_TYPE_CHANNEL));
      expect(handleInfo.rights, equals(ZX.RIGHTS_IO));
      final HandleInfo vmoInfo = readResult.handleInfos[1];
      expect(vmoInfo.handle.isValid, isTrue);
      expect(vmoInfo.type, equals(ZX.OBJ_TYPE_VMO));
      expect(vmoInfo.rights, equals(ZX.DEFAULT_VMO_RIGHTS));
    });
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
