// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/test.dart';

void main() {
  group('Keyboard', () {
    test('initializes', () {
      expect(Keyboard.instance, isNull);
      Keyboard.initialize();
      expect(Keyboard.instance, isNotNull);
    });

    test('dispatches keyup to flutter/keyevent channel', () {
      String channelReceived;
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        channelReceived = channel;
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      html.window.dispatchEvent(html.KeyboardEvent('keyup'));

      expect(channelReceived, 'flutter/keyevent');
      expect(dataReceived['type'], 'keyup');
      expect(dataReceived['keymap'], 'android');

      // Unfortunately there's no way to fake `keyCode`.
      expect(dataReceived['keyCode'], 0);

      // Unfortunately there's no way to fake `key`.
      expect(dataReceived, isNot(contains('codePoint')));
    });

    test('dispatches keydown to flutter/keyevent channel', () {
      String channelReceived;
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        channelReceived = channel;
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      html.window.dispatchEvent(html.KeyboardEvent('keydown'));

      expect(channelReceived, 'flutter/keyevent');
      expect(dataReceived['type'], 'keydown');
      expect(dataReceived['keymap'], 'android');

      // Unfortunately there's no way to fake `keyCode`.
      expect(dataReceived['keyCode'], 0);

      // Unfortunately there's no way to fake `key`.
      expect(dataReceived, isNot(contains('codePoint')));
    });

    test('stops dispatching events after dispose', () {
      int count = 0;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        count += 1;
      };

      html.window.dispatchEvent(html.KeyboardEvent('keydown'));
      expect(count, 1);
      html.window.dispatchEvent(html.KeyboardEvent('keyup'));
      expect(count, 2);

      Keyboard.instance.dispose();
      expect(Keyboard.instance, isNull);

      // No more event dispatching.
      html.window.dispatchEvent(html.KeyboardEvent('keydown'));
      expect(count, 2);
      html.window.dispatchEvent(html.KeyboardEvent('keyup'));
      expect(count, 2);
    });
  });
}
