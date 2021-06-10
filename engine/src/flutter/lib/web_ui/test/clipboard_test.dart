// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/ui.dart' as ui;
import 'package:ui/src/engine.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() async {
  await ui.webOnlyInitializeTestDomRenderer();
  group('message handler', () {
    const String testText = 'test text';

    late ClipboardMessageHandler clipboardMessageHandler;
    MockClipboardAPICopyStrategy clipboardAPICopyStrategy =
        MockClipboardAPICopyStrategy();
    MockClipboardAPIPasteStrategy clipboardAPIPasteStrategy =
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
      clipboardAPICopyStrategy.testResult = true;
      const MethodCodec codec = JSONMethodCodec();
      final Completer<bool> completer = Completer<bool>();
      ui.PlatformMessageResponseCallback callback = (ByteData? data) {
        completer.complete(codec.decodeEnvelope(data!));
      };

      clipboardMessageHandler.setDataMethodCall(
          const MethodCall('Clipboard.setData', <String, dynamic>{
            'text': testText,
          }),
          callback);

      expect(await completer.future, isTrue);
    });

    test('set data error', () async {
      clipboardAPICopyStrategy.testResult = false;
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData> completer = Completer<ByteData>();
      ui.PlatformMessageResponseCallback callback = (ByteData? data) {
        completer.complete(data!);
      };

      clipboardMessageHandler.setDataMethodCall(
          const MethodCall('Clipboard.setData', <String, dynamic>{
            'text': testText,
          }),
          callback);

      final ByteData result = await completer.future;
      expect(
        () =>codec.decodeEnvelope(result),
        throwsA(TypeMatcher<PlatformException>()
          .having((e) => e.code, 'code', equals('copy_fail'))));
    });

    test('get data successful', () async {
      clipboardAPIPasteStrategy.testResult = testText;
      const MethodCodec codec = JSONMethodCodec();
      final Completer<Map<String, dynamic>> completer = Completer<Map<String, dynamic>>();
      ui.PlatformMessageResponseCallback callback = (ByteData? data) {
        completer.complete(codec.decodeEnvelope(data!));
      };

      clipboardMessageHandler.getDataMethodCall(callback);

      final Map<String, dynamic> result = await completer.future;
      expect(result['text'], testText);
    });
  });
}

class MockClipboardAPICopyStrategy implements ClipboardAPICopyStrategy {
  bool testResult = true;

  @override
  Future<bool> setData(String? text) {
    return Future<bool>.value(testResult);
  }
}

class MockClipboardAPIPasteStrategy implements ClipboardAPIPasteStrategy {
  String testResult = '';

  @override
  Future<String> getData() {
    return Future<String>.value(testResult);
  }
}
