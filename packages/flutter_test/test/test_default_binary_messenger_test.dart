// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class TestDelegate extends BinaryMessenger {
  @override
  Future<ByteData?>? send(String channel, ByteData? message) async {
    expect(channel, '');
    expect(message, isNull);
    throw 'Vic Fontaine';
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
    await future!.catchError((Object error) { });
    try {
      await TestDefaultBinaryMessenger(delegate).send('', null);
      expect(true, isFalse); // should not reach here
    } catch (error) {
      expect(error, 'Vic Fontaine');
    }
  });
}
