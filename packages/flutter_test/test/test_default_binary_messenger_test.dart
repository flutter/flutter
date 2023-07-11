// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class RecognizableTestException implements Exception {
  const RecognizableTestException();
}

class TestDelegate extends BinaryMessenger {
  @override
  Future<ByteData?>? send(String channel, ByteData? message) async {
    expect(channel, '');
    expect(message, isNull);
    throw const RecognizableTestException();
  }

  // Rest of the API isn't needed for this test.
  @override
  Future<void> handlePlatformMessage(String channel, ByteData? data, ui.PlatformMessageResponseCallback? callback) => throw UnimplementedError();
  @override
  void setMessageHandler(String channel, MessageHandler? handler) => throw UnimplementedError();
}

class WorkingTestDelegate extends BinaryMessenger {
  @override
  Future<ByteData?>? send(String channel, ByteData? message) async {
    return ByteData.sublistView(Uint8List.fromList(<int>[1, 2, 3]));
  }

  // Rest of the API isn't needed for this test.
  @override
  Future<void> handlePlatformMessage(String channel, ByteData? data, ui.PlatformMessageResponseCallback? callback) => throw UnimplementedError();
  @override
  void setMessageHandler(String channel, MessageHandler? handler) => throw UnimplementedError();
}

void main() {
  testWidgets('Caught exceptions are caught by the test framework', (WidgetTester tester) async {
    final BinaryMessenger delegate = TestDelegate();
    final Future<ByteData?>? future = delegate.send('', null);
    expect(future, isNotNull);
    // TODO(srawlins): Fix this static issue,
    // https://github.com/flutter/flutter/issues/105750.
    // ignore: body_might_complete_normally_catch_error
    await future!.catchError((Object error) { });
    try {
      await TestDefaultBinaryMessenger(delegate).send('', null);
      expect(true, isFalse); // should not reach here
    } catch (error) {
      expect(error, const RecognizableTestException());
    }
  });

  testWidgets('Mock MessageHandler is set correctly',
      (WidgetTester tester) async {
    final TestDefaultBinaryMessenger binaryMessenger =
        TestDefaultBinaryMessenger(WorkingTestDelegate());
    binaryMessenger.setMockMessageHandler(
        '',
        (ByteData? message) async =>
            ByteData.sublistView(Uint8List.fromList(<int>[2, 3, 4])));

    final ByteData? result = await binaryMessenger.send('', null);
    expect(result?.buffer.asUint8List(), Uint8List.fromList(<int>[2, 3, 4]));
  });

  testWidgets('Mock AllMessagesHandler is set correctly',
      (WidgetTester tester) async {
    final TestDefaultBinaryMessenger binaryMessenger =
        TestDefaultBinaryMessenger(WorkingTestDelegate());
    binaryMessenger.allMessagesHandler =
        (String channel, MessageHandler? handler, ByteData? message) async =>
            ByteData.sublistView(Uint8List.fromList(<int>[2, 3, 4]));

    final ByteData? result = await binaryMessenger.send('', null);
    expect(result?.buffer.asUint8List(), Uint8List.fromList(<int>[2, 3, 4]));
  });
}
