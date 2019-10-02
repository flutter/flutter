// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:typed_data';

import 'package:ui/src/engine.dart';
import 'package:ui/ui.dart' as ui;

import 'package:test/test.dart';

void main() {
  group('Keyboard', () {
    test('initializes', () {
      expect(Keyboard.instance, isNull);
      Keyboard.initialize();
      expect(Keyboard.instance, isA<Keyboard>());
    });

    test('dispatches keyup to flutter/keyevent channel', () {
      String channelReceived;
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        channelReceived = channel;
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      dispatchKeyboardEvent('keyup', key: 'SomeKey', code: 'SomeCode');

      expect(channelReceived, 'flutter/keyevent');
      expect(dataReceived, <String, dynamic>{
        'type': 'keyup',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        'metaState': 0x0,
      });
    });

    test('dispatches keydown to flutter/keyevent channel', () {
      String channelReceived;
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        channelReceived = channel;
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      dispatchKeyboardEvent('keydown', key: 'SomeKey', code: 'SomeCode');

      expect(channelReceived, 'flutter/keyevent');
      expect(dataReceived, <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        'metaState': 0x0,
      });
    });

    test('dispatches correct meta state', () {
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        isControlPressed: true,
      );
      expect(dataReceived, <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        //          ctrl
        'metaState': 0x4,
      });

      dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        isShiftPressed: true,
        isAltPressed: true,
        isMetaPressed: true,
      );
      expect(dataReceived, <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        //          shift  alt   meta
        'metaState': 0x1 | 0x2 | 0x8,
      });
    });

    test('dispatches repeat events', () {
      List<Map<String, dynamic>> messages = <Map<String, dynamic>>[];
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        messages.add(const JSONMessageCodec().decodeMessage(data));
      };

      dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        repeat: true,
      );
      dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        repeat: true,
      );
      dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        repeat: true,
      );

      final Map<String, dynamic> expectedMessage = <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        'metaState': 0,
      };
      expect(messages, <Map<String, dynamic>>[
        expectedMessage,
        expectedMessage,
        expectedMessage,
      ]);
    });

    test('stops dispatching events after dispose', () {
      int count = 0;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        count += 1;
      };

      dispatchKeyboardEvent('keydown');
      expect(count, 1);
      dispatchKeyboardEvent('keyup');
      expect(count, 2);

      Keyboard.instance.dispose();
      expect(Keyboard.instance, isNull);

      // No more event dispatching.
      dispatchKeyboardEvent('keydown');
      expect(count, 2);
      dispatchKeyboardEvent('keyup');
      expect(count, 2);
    });
  });
}

void dispatchKeyboardEvent(
  String type, {
  String key,
  String code,
  bool repeat = false,
  bool isShiftPressed = false,
  bool isAltPressed = false,
  bool isControlPressed = false,
  bool isMetaPressed = false,
}) {
  final Function jsKeyboardEvent =
      js_util.getProperty(html.window, 'KeyboardEvent');
  final List<dynamic> eventArgs = <dynamic>[
    type,
    <String, dynamic>{
      'key': key,
      'code': code,
      'repeat': repeat,
      'shiftKey': isShiftPressed,
      'altKey': isAltPressed,
      'ctrlKey': isControlPressed,
      'metaKey': isMetaPressed,
    }
  ];
  final event =
      js_util.callConstructor(jsKeyboardEvent, js_util.jsify(eventArgs));
  html.window.dispatchEvent(event);
}
