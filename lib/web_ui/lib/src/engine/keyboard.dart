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
    if (_shouldPreventDefault(event)) {
      event.preventDefault();
    }

    final Map<String, dynamic> eventData = <String, dynamic>{
      'type': event.type,
      'keymap': 'web',
      'code': event.code,
      'key': event.key,
      'metaState': _getMetaState(event),
    };

    ui.window.onPlatformMessage('flutter/keyevent',
        _messageCodec.encodeMessage(eventData), _noopCallback);
  }

  bool _shouldPreventDefault(html.KeyboardEvent event) {
    switch (event.key) {
      case 'Tab':
        return true;

      default:
        return false;
    }
  }
}

const int _modifierNone = 0x00;
const int _modifierShift = 0x01;
const int _modifierAlt = 0x02;
const int _modifierControl = 0x04;
const int _modifierMeta = 0x08;
const int _modifierNumLock = 0x10;
const int _modifierCapsLock = 0x20;
const int _modifierScrollLock = 0x40;

/// Creates a bitmask representing the meta state of the [event].
int _getMetaState(html.KeyboardEvent event) {
  int metaState = _modifierNone;
  if (event.getModifierState('Shift')) {
    metaState |= _modifierShift;
  }
  if (event.getModifierState('Alt')) {
    metaState |= _modifierAlt;
  }
  if (event.getModifierState('Control')) {
    metaState |= _modifierControl;
  }
  if (event.getModifierState('Meta')) {
    metaState |= _modifierMeta;
  }
  if (event.getModifierState('NumLock')) {
    metaState |= _modifierNumLock;
  }
  if (event.getModifierState('CapsLock')) {
    metaState |= _modifierCapsLock;
  }
  if (event.getModifierState('ScrollLock')) {
    metaState |= _modifierScrollLock;
  }
  return metaState;
}

void _noopCallback(ByteData data) {}
