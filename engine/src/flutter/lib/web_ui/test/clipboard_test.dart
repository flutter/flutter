// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
import 'dart:async';
import 'dart:typed_data';

import 'package:mockito/mockito.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

Future<void> main() async {
  await ui.webOnlyInitializeTestDomRenderer();
  group('message handler', () {
    const String testText = 'test text';

    final Future<bool> success = Future.value(true);
    final Future<bool> failure = Future.value(false);
    final Future<String> pasteTest = Future.value(testText);

    ClipboardMessageHandler clipboardMessageHandler;
    ClipboardAPICopyStrategy clipboardAPICopyStrategy =
        MockClipboardAPICopyStrategy();
    ClipboardAPIPasteStrategy clipboardAPIPasteStrategy =
        MockClipboardAPIPasteStrategy();

    setUp(() {
      clipboardMessageHandler = new ClipboardMessageHandler();
      clipboardAPICopyStrategy = MockClipboardAPICopyStrategy();
      clipboardAPIPasteStrategy = MockClipboardAPIPasteStrategy();
      clipboardMessageHandler.copyToClipboardStrategy =
          clipboardAPICopyStrategy;
      clipboardMessageHandler.pasteFromClipboardStrategy =
          clipboardAPIPasteStrategy;
    });

    test('set data successful', () async {
      when(clipboardAPICopyStrategy.setData(testText))
          .thenAnswer((_) => success);
      const MethodCodec codec = JSONMethodCodec();
      bool result = false;
      ui.PlatformMessageResponseCallback callback = (ByteData data) {
        result = codec.decodeEnvelope(data);
      };

      await clipboardMessageHandler.setDataMethodCall(
          const MethodCall('Clipboard.setData', <String, dynamic>{
            'text': testText,
          }),
          callback);

      await expectLater(result, true);
    });

    test('set data error', () async {
      when(clipboardAPICopyStrategy.setData(testText))
          .thenAnswer((_) => failure);
      const MethodCodec codec = JSONMethodCodec();
      ByteData result;
      ui.PlatformMessageResponseCallback callback = (ByteData data) {
        result = data;
      };

      await clipboardMessageHandler.setDataMethodCall(
          const MethodCall('Clipboard.setData', <String, dynamic>{
            'text': testText,
          }),
          callback);

      expect(() async {
        codec.decodeEnvelope(result);
      }, throwsA(TypeMatcher<PlatformException>()
          .having((e) => e.code, 'code', equals('copy_fail'))));
    });

    test('get data successful', () async {
      when(clipboardAPIPasteStrategy.getData())
          .thenAnswer((_) => pasteTest);
      const MethodCodec codec = JSONMethodCodec();
      Map<String, dynamic> result;
      ui.PlatformMessageResponseCallback callback = (ByteData data) {
        result = codec.decodeEnvelope(data);
      };

      await clipboardMessageHandler.getDataMethodCall(callback);

      await expectLater(result['text'], testText);
    });
  });
}

class MockClipboardAPICopyStrategy extends Mock
    implements ClipboardAPICopyStrategy {}

class MockClipboardAPIPasteStrategy extends Mock
    implements ClipboardAPIPasteStrategy {}
