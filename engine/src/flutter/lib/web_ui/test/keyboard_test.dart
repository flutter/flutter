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
    /// Used to save and restore [ui.window.onPlatformMessage] after each test.
    ui.PlatformMessageCallback savedCallback;

    setUp(() {
      savedCallback = ui.window.onPlatformMessage;
    });

    tearDown(() {
      ui.window.onPlatformMessage = savedCallback;
    });

    test('initializes and disposes', () {
      expect(Keyboard.instance, isNull);
      Keyboard.initialize();
      expect(Keyboard.instance, isA<Keyboard>());
      Keyboard.instance.dispose();
      expect(Keyboard.instance, isNull);
    });

    test('dispatches keyup to flutter/keyevent channel', () {
      Keyboard.initialize();

      String channelReceived;
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        channelReceived = channel;
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      html.KeyboardEvent event;

      event = dispatchKeyboardEvent('keyup', key: 'SomeKey', code: 'SomeCode');

      expect(event.defaultPrevented, isFalse);
      expect(channelReceived, 'flutter/keyevent');
      expect(dataReceived, <String, dynamic>{
        'type': 'keyup',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        'metaState': 0x0,
      });

      Keyboard.instance.dispose();
    });

    test('dispatches keydown to flutter/keyevent channel', () {
      Keyboard.initialize();

      String channelReceived;
      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        channelReceived = channel;
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      html.KeyboardEvent event;

      event =
          dispatchKeyboardEvent('keydown', key: 'SomeKey', code: 'SomeCode');

      expect(channelReceived, 'flutter/keyevent');
      expect(dataReceived, <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        'metaState': 0x0,
      });
      expect(event.defaultPrevented, isFalse);

      Keyboard.instance.dispose();
    });

    test('dispatches correct meta state', () {
      Keyboard.initialize();

      Map<String, dynamic> dataReceived;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        dataReceived = const JSONMessageCodec().decodeMessage(data);
      };

      html.KeyboardEvent event;

      event = dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        isControlPressed: true,
      );
      expect(event.defaultPrevented, isFalse);
      expect(dataReceived, <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        //          ctrl
        'metaState': 0x4,
      });

      event = dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        isShiftPressed: true,
        isAltPressed: true,
        isMetaPressed: true,
      );
      expect(event.defaultPrevented, isFalse);
      expect(dataReceived, <String, dynamic>{
        'type': 'keydown',
        'keymap': 'web',
        'code': 'SomeCode',
        'key': 'SomeKey',
        //          shift  alt   meta
        'metaState': 0x1 | 0x2 | 0x8,
      });

      Keyboard.instance.dispose();
    });

    test('dispatches repeat events', () {
      Keyboard.initialize();

      List<Map<String, dynamic>> messages = <Map<String, dynamic>>[];
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        messages.add(const JSONMessageCodec().decodeMessage(data));
      };

      html.KeyboardEvent event;

      event = dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        repeat: true,
      );
      expect(event.defaultPrevented, isFalse);

      event = dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        repeat: true,
      );
      expect(event.defaultPrevented, isFalse);

      event = dispatchKeyboardEvent(
        'keydown',
        key: 'SomeKey',
        code: 'SomeCode',
        repeat: true,
      );
      expect(event.defaultPrevented, isFalse);

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

      Keyboard.instance.dispose();
    });

    test('stops dispatching events after dispose', () {
      Keyboard.initialize();

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

    test('prevents default when "Tab" is pressed', () {
      Keyboard.initialize();

      int count = 0;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        count += 1;
      };

      final html.KeyboardEvent event = dispatchKeyboardEvent(
        'keydown',
        key: 'Tab',
        code: 'Tab',
      );

      expect(event.defaultPrevented, isTrue);
      expect(count, 1);

      Keyboard.instance.dispose();
    });

    test('ignores keyboard events triggered on text fields', () {
      Keyboard.initialize();

      int count = 0;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        count += 1;
      };

      useTextEditingElement((html.Element element) {
        final html.KeyboardEvent event = dispatchKeyboardEvent(
          'keydown',
          key: 'SomeKey',
          code: 'SomeCode',
          target: element,
        );

        expect(event.defaultPrevented, isFalse);
        expect(count, 0);
      });

      Keyboard.instance.dispose();
    });

    test('the "Tab" key should never be ignored', () {
      Keyboard.initialize();

      int count = 0;
      ui.window.onPlatformMessage = (String channel, ByteData data,
          ui.PlatformMessageResponseCallback callback) {
        count += 1;
      };

      useTextEditingElement((html.Element element) {
        final html.KeyboardEvent event = dispatchKeyboardEvent(
          'keydown',
          key: 'Tab',
          code: 'Tab',
          target: element,
        );

        expect(event.defaultPrevented, isTrue);
        expect(count, 1);
      });

      Keyboard.instance.dispose();
    });
  });
}

typedef ElementCallback = void Function(html.Element element);

void useTextEditingElement(ElementCallback callback) {
  final html.InputElement input = html.InputElement();
  input.classes.add(HybridTextEditing.textEditingClass);

  try {
    html.document.body.append(input);
    callback(input);
  } finally {
    input.remove();
  }
}

html.KeyboardEvent dispatchKeyboardEvent(
  String type, {
  html.EventTarget target,
  String key,
  String code,
  bool repeat = false,
  bool isShiftPressed = false,
  bool isAltPressed = false,
  bool isControlPressed = false,
  bool isMetaPressed = false,
}) {
  target ??= html.window;

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
      'bubbles': true,
      'cancelable': true,
    }
  ];
  final html.KeyboardEvent event =
      js_util.callConstructor(jsKeyboardEvent, js_util.jsify(eventArgs));
  target.dispatchEvent(event);

  return event;
}
