// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';
import 'package:ui/src/engine.dart';

import '../common/test_initialization.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

Future<void> testMain() async {
  setUpImplicitView();

  group('$ClipboardMessageHandler', () {
    const String testText = 'test text';
    const JSONMethodCodec codec = JSONMethodCodec();

    late ClipboardMessageHandler clipboardMessageHandler;
    _MockClipboardStrategy mockClipboardStrategy = _MockClipboardStrategy();

    setUp(() {
      clipboardMessageHandler = ClipboardMessageHandler();
      mockClipboardStrategy = _MockClipboardStrategy();
      clipboardMessageHandler.clipboardStrategy = mockClipboardStrategy;
    });

    test('kTextPlainFormat is correct', () {
      expect(ClipboardMessageHandler.kTextPlainFormat, 'text/plain');
    });

    group('setDataMethodCall', () {
      test('completes successfully when no exception arises', () async {
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.setDataMethodCall(completer.complete, testText);

        final ByteData result = await completer.future;
        expect(codec.decodeEnvelope(result), isNull);
      });

      test('completes with error when clipboard is not available', () async {
        mockClipboardStrategy.onSetData = (String? text) async {
          throw StateError('Clipboard is not available in the context.');
        };
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.setDataMethodCall(completer.complete, testText);

        final ByteData result = await completer.future;
        expect(
          () => codec.decodeEnvelope(result),
          throwsA(
            isA<PlatformException>()
                .having((PlatformException e) => e.code, 'code', equals('copy_fail'))
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  equals('Clipboard is not available in the context.'),
                ),
          ),
        );
      });

      test('completes with error when exception arises', () async {
        mockClipboardStrategy.onSetData = (String? text) async {
          throw Exception('');
        };
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.setDataMethodCall(completer.complete, testText);

        final ByteData result = await completer.future;
        expect(
          () => codec.decodeEnvelope(result),
          throwsA(
            isA<PlatformException>()
                .having((PlatformException e) => e.code, 'code', equals('copy_fail'))
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  equals('Clipboard.setData failed.'),
                ),
          ),
        );
      });
    });

    group('getDataMethodCall', () {
      test('completes with null value when filter is not supported', () async {
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.getDataMethodCall(completer.complete, 'unknown/unknown');

        final ByteData result = await completer.future;
        expect(codec.decodeEnvelope(result), isNull);
      });

      test('completes without text when clipboard is empty', () async {
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.getDataMethodCall(
          completer.complete,
          ClipboardMessageHandler.kTextPlainFormat,
        );

        final ByteData result = await completer.future;
        final Map<String, Object?> data = codec.decodeEnvelope(result) as Map<String, Object?>;
        expect(data['text'], isEmpty);
      });

      test('completes with text when clipboard is not empty', () async {
        mockClipboardStrategy.onGetData = () async => testText;
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.getDataMethodCall(
          completer.complete,
          ClipboardMessageHandler.kTextPlainFormat,
        );

        final ByteData result = await completer.future;
        final Map<String, Object?> data = codec.decodeEnvelope(result) as Map<String, Object?>;
        expect(data['text'], testText);
      });

      test('completes with error when clipboard is not available', () async {
        mockClipboardStrategy.onGetData = () async {
          throw StateError('Clipboard is not available in the context.');
        };
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.getDataMethodCall(
          completer.complete,
          ClipboardMessageHandler.kTextPlainFormat,
        );

        final ByteData result = await completer.future;
        expect(
          () => codec.decodeEnvelope(result),
          throwsA(
            isA<PlatformException>()
                .having((PlatformException e) => e.code, 'code', equals('paste_fail'))
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  equals('Clipboard is not available in the context.'),
                ),
          ),
        );
      });

      test('completes with error when exception arises', () async {
        mockClipboardStrategy.onGetData = () async {
          throw Exception('');
        };
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.getDataMethodCall(
          completer.complete,
          ClipboardMessageHandler.kTextPlainFormat,
        );

        final ByteData result = await completer.future;
        expect(
          () => codec.decodeEnvelope(result),
          throwsA(
            isA<PlatformException>()
                .having((PlatformException e) => e.code, 'code', equals('paste_fail'))
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  equals('Clipboard.getData failed.'),
                ),
          ),
        );
      });
    });

    group('hasStringsMethodCall', () {
      test('completes with false value when clipboard is empty', () async {
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.hasStringsMethodCall(completer.complete);

        final ByteData result = await completer.future;
        final Map<String, Object?> data = codec.decodeEnvelope(result) as Map<String, Object?>;
        expect(data['value'], isFalse);
      });

      test('completes with true value when clipboard is not empty', () async {
        mockClipboardStrategy.onGetData = () async => testText;
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.hasStringsMethodCall(completer.complete);

        final ByteData result = await completer.future;
        final Map<String, Object?> data = codec.decodeEnvelope(result) as Map<String, Object?>;
        expect(data['value'], isTrue);
      });

      test('completes with error when clipboard is not available', () async {
        mockClipboardStrategy.onGetData = () async {
          throw StateError('Clipboard is not available in the context.');
        };
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.hasStringsMethodCall(completer.complete);

        final ByteData result = await completer.future;
        expect(
          () => codec.decodeEnvelope(result),
          throwsA(
            isA<PlatformException>()
                .having((PlatformException e) => e.code, 'code', equals('has_strings_fail'))
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  equals('Clipboard is not available in the context.'),
                ),
          ),
        );
      });

      test('completes with error when exception arises', () async {
        mockClipboardStrategy.onGetData = () async {
          throw Exception('');
        };
        final Completer<ByteData> completer = Completer<ByteData>();

        clipboardMessageHandler.hasStringsMethodCall(completer.complete);

        final ByteData result = await completer.future;
        expect(
          () => codec.decodeEnvelope(result),
          throwsA(
            isA<PlatformException>()
                .having((PlatformException e) => e.code, 'code', equals('has_strings_fail'))
                .having(
                  (PlatformException e) => e.message,
                  'message',
                  equals('Clipboard.hasStrings failed.'),
                ),
          ),
        );
      });
    });
  });
}

class _MockClipboardStrategy implements ClipboardStrategy {
  Future<void> Function(String?)? onSetData;

  Future<String> Function()? onGetData;

  @override
  Future<void> setData(String? text) async {
    if (onSetData == null) {
      return;
    }
    await onSetData!.call(text);
  }

  @override
  Future<String> getData() async {
    if (onGetData == null) {
      return '';
    }
    return onGetData!.call();
  }
}
