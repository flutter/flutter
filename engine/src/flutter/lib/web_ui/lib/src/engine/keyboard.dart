// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.6
part of engine;

/// After a keydown is received, this is the duration we wait for a repeat event
/// before we decide to synthesize a keyup event.
///
/// On Linux and Windows, the typical ranges for keyboard repeat delay go up to
/// 1000ms. On Mac, the range goes up to 2000ms.
const Duration _keydownCancelDuration = Duration(milliseconds: 1000);

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

  /// A mapping of [KeyboardEvent.code] to [Timer].
  ///
  /// The timer is for when to synthesize a keyup for the [KeyboardEvent.code]
  /// if no repeat events were received.
  final Map<String, Timer> _keydownTimers = <String, Timer>{};

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

    for (final String key in _keydownTimers.keys) {
      _keydownTimers[key].cancel();
    }
    _keydownTimers.clear();

    _keydownListener = null;
    _keyupListener = null;
    _instance = null;
  }

  static const JSONMessageCodec _messageCodec = JSONMessageCodec();

  /// Contains meta state from the latest event.
  ///
  /// Initializing with `0x0` which means no meta keys are pressed.
  int _lastMetaState = 0x0;

  void _handleHtmlEvent(html.KeyboardEvent event) {
    if (window._onPlatformMessage == null) {
      return;
    }

    if (_shouldPreventDefault(event)) {
      event.preventDefault();
    }

    final String timerKey = event.code;

    // Don't synthesize a keyup event for modifier keys because the browser always
    // sends a keyup event for those.
    if (!_isModifierKey(event)) {
      // When the user enters a browser/system shortcut (e.g. `cmd+alt+i`) the
      // browser doesn't send a keyup for it. This puts the framework in a
      // corrupt state because it thinks the key was never released.
      //
      // To avoid this, we rely on the fact that browsers send repeat events
      // while the key is held down by the user. If we don't receive a repeat
      // event within a specific duration ([_keydownCancelDuration]) we assume
      // the user has released the key and we synthesize a keyup event.
      _keydownTimers[timerKey]?.cancel();
      if (event.type == 'keydown') {
        _keydownTimers[timerKey] = Timer(_keydownCancelDuration, () {
          _keydownTimers.remove(timerKey);
          _synthesizeKeyup(event);
        });
      } else {
        _keydownTimers.remove(timerKey);
      }
    }

    _lastMetaState = _getMetaState(event);
    final Map<String, dynamic> eventData = <String, dynamic>{
      'type': event.type,
      'keymap': 'web',
      'code': event.code,
      'key': event.key,
      'metaState': _lastMetaState,
    };

    window.invokeOnPlatformMessage('flutter/keyevent',
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

  void _synthesizeKeyup(html.KeyboardEvent event) {
    final Map<String, dynamic> eventData = <String, dynamic>{
      'type': 'keyup',
      'keymap': 'web',
      'code': event.code,
      'key': event.key,
      'metaState': _lastMetaState,
    };

    window.invokeOnPlatformMessage('flutter/keyevent',
        _messageCodec.encodeMessage(eventData), _noopCallback);
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

/// Returns true if the [event] was caused by a modifier key.
///
/// Modifier keys are shift, alt, ctrl and meta/cmd/win. These are the keys used
/// to perform keyboard shortcuts (e.g. `cmd+c`, `cmd+l`).
bool _isModifierKey(html.KeyboardEvent event) {
  final String key = event.key;
  return key == 'Meta' || key == 'Shift' || key == 'Alt' || key == 'Control';
}

void _noopCallback(ByteData data) {}
