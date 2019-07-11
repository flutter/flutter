// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Provides keyboard bindings, such as the `flutter/keyevent` channel.
class Keyboard {
  /// Initializes the [Keyboard] singleton.
  ///
  /// Use the [instance] getter to get the singleton after calling this method.
  static void initialize() {
    _instance ??= Keyboard._();
  }

  /// The [Keyboard] singleton.
  static Keyboard get instance => _instance;
  static Keyboard _instance;

  html.EventListener _keydownListener;
  html.EventListener _keyupListener;

  Keyboard._() {
    _keydownListener = (html.Event event) {
      _handleHtmlEvent(event);
    };
    html.window.addEventListener('keydown', _keydownListener);

    _keyupListener = (html.Event event) {
      _handleHtmlEvent(event);
    };
    html.window.addEventListener('keyup', _keyupListener);
    registerHotRestartListener(() {
      dispose();
    });
  }

  /// Uninitializes the [Keyboard] singleton.
  ///
  /// After calling this method this object becomes unusable and [instance]
  /// becomes `null`. Call [initialize] again to initialize a new singleton.
  void dispose() {
    html.window.removeEventListener('keydown', _keydownListener);
    html.window.removeEventListener('keyup', _keyupListener);
    _keydownListener = null;
    _keyupListener = null;
    _instance = null;
  }

  static const JSONMessageCodec _messageCodec = JSONMessageCodec();

  void _handleHtmlEvent(html.KeyboardEvent event) {
    final Map<String, dynamic> eventData = <String, dynamic>{
      'type': event.type,
      // TODO(yjbanov): this emulates Android because that the only reasonable
      //                thing to map to right now (the other choice is fuchsia).
      //                However, eventually we need to have something that maps
      //                better to Web.
      'keymap': 'android',
      'keyCode': event.keyCode,
    };

    // TODO(yjbanov): The browser does not report `charCode` for 'keydown' and
    //                'keyup', only for 'keypress'. This restores the value
    //                from the 'key' field. However, we need to verify how
    //                many code units a single key can have. Right now it
    //                assumes exactly one unit (that's what Flutter framework
    //                expects). But we'll need a different strategy if other
    //                code unit counts are possible.
    if (event.key.codeUnits.length == 1) {
      eventData['codePoint'] = event.key.codeUnits.first;
    }

    ui.window.onPlatformMessage('flutter/keyevent',
        _messageCodec.encodeMessage(eventData), _noopCallback);
  }
}

void _noopCallback(ByteData data) {}
