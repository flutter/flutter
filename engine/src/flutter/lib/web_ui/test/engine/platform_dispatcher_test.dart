// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/bootstrap/browser.dart';
import 'package:test/test.dart';

void main() {
  internalBootstrapBrowserTest(() => testMain);
}

void testMain() {
  group('PlatformDispatcher', () {
    test('responds to flutter/skia Skia.setResourceCacheMaxBytes', () async {
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData?> completer = Completer<ByteData?>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/skia',
        codec.encodeMethodCall(MethodCall(
          'Skia.setResourceCacheMaxBytes',
          512 * 1000 * 1000,
        )),
        completer.complete,
      );

      final ByteData? response = await completer.future;
      expect(response, isNotNull);
      expect(
        codec.decodeEnvelope(response!),
        [true],
      );
    });

    test('responds to flutter/platform HapticFeedback.vibrate', () async {
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData?> completer = Completer<ByteData?>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(MethodCall(
          'HapticFeedback.vibrate',
        )),
        completer.complete,
      );

      final ByteData? response = await completer.future;
      expect(response, isNotNull);
      expect(
        codec.decodeEnvelope(response!),
        true,
      );
    });

    test('responds correctly to flutter/platform Clipboard.getData failure',
        () async {
      // Patch browser so that clipboard api is not available.
      dynamic originalClipboard =
          js_util.getProperty(html.window.navigator, 'clipboard');
      js_util.setProperty(html.window.navigator, 'clipboard', null);
      const MethodCodec codec = JSONMethodCodec();
      final Completer<ByteData?> completer = Completer<ByteData?>();
      ui.PlatformDispatcher.instance.sendPlatformMessage(
        'flutter/platform',
        codec.encodeMethodCall(MethodCall(
          'Clipboard.getData',
        )),
        completer.complete,
      );
      final ByteData? response = await completer.future;
      if (response != null) {
        expect(
              () => codec.decodeEnvelope(response),
          throwsA(isA<PlatformException>()),
        );
      }
      js_util.setProperty(
          html.window.navigator, 'clipboard', originalClipboard);
    });
  });
}
