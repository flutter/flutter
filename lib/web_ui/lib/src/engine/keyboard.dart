// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

part of engine;

/// Contains a whitelist of keys that must be sent to Flutter under all
/// circumstances.
///
/// When keys are pressed in a text field, we generally don't want to send them
/// to Flutter. This list of keys is the exception to that rule. Keys in this
/// list will be sent to Flutter even if pressed in a text field.
///
/// A good example is the "Tab" and "Shift" keys which are used by the framework
/// to move focus between text fields.
const List<String> _alwaysSentKeys = <String>[
  'Alt',
  'Control',
  'Meta',
  'Shift',
  'Tab',
];

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
    if (_shouldIgnoreEvent(event)) {
      return;
    }

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

  /// Whether the [Keyboard] class should ignore the given [html.KeyboardEvent].
  ///
  /// When this method returns true, it prevents the keyboard event from being
  /// sent to Flutter.
  bool _shouldIgnoreEvent(html.KeyboardEvent event) {
    // Keys in the [_alwaysSentKeys] list should never be ignored.
    if (_alwaysSentKeys.contains(event.key)) {
      return false;
    }
    // Other keys should be ignored if triggered on a text field.
    return event.target is html.Element &&
        HybridTextEditing.isEditingElement(event.target);
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
  // TODO: Re-enable lock key modifiers once there is support on Flutter
  // Framework. https://github.com/flutter/flutter/issues/46718
  return metaState;
}

void _noopCallback(ByteData data) {}
