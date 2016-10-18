// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:meta/meta.dart';

import 'platform_messages.dart';

/// Base class for platform specific key event data.
///
/// This base class exists to have a common type to use for each of the
/// target platform's key event data structures.
///
/// See also:
///
///  * [RawKeyEventDataAndroid]
///  * [RawKeyEvent]
///  * [RawKeyDownEvent]
///  * [RawKeyUpEvent]
abstract class RawKeyEventData {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RawKeyEventData();
}

/// Platform-specific key event data for Android.
///
/// This object contains information about key events obtained from Android's
/// KeyEvent interface.
class RawKeyEventDataAndroid extends RawKeyEventData {
  /// Creates a key event data structure specific for Android.
  ///
  /// The [flags], [codePoint], [keyCode], [scanCode], and [metaState] arguments
  /// must not be null.
  const RawKeyEventDataAndroid({
    this.flags: 0,
    this.codePoint: 0,
    this.keyCode: 0,
    this.scanCode: 0,
    this.metaState: 0,
  });

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getFlags()>
  final int flags;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getUnicodeChar()>
  final int codePoint;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getKeyCode()>
  final int keyCode;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getScanCode()>
  final int scanCode;

  /// See <https://developer.android.com/reference/android/view/KeyEvent.html#getMetaState()>
  final int metaState;
}

/// Base class for raw key events.
///
/// Raw key events pass through as much information as possible from the
/// underlying platform's key events, which makes they provide a high level of
/// fidelity but a low level of portability.
///
/// See also:
///
///  * [RawKeyDownEvent]
///  * [RawKeyUpEvent]
///  * [RawKeyboardListener], a widget that listens for raw key events.
abstract class RawKeyEvent {
  /// Initializes fields for subclasses.
  const RawKeyEvent({
    @required this.data,
  });

  /// Platform-specific information about the key event.
  final RawKeyEventData data;
}

/// The user has pressed a key on the keyboard.
class RawKeyDownEvent extends RawKeyEvent {
  /// Creates a key event that represents the user pressing a key.
  const RawKeyDownEvent({
    @required RawKeyEventData data,
  }) : super(data: data);
}

/// The user has released a key on the keyboard.
class RawKeyUpEvent extends RawKeyEvent {
  /// Creates a key event that represents the user releasing a key.
  const RawKeyUpEvent({
    @required RawKeyEventData data,
  }) : super(data: data);
}

RawKeyEvent _toRawKeyEvent(dynamic message) {
  RawKeyEventData data;

  String keymap = message['keymap'];
  switch (keymap) {
    case 'android':
      data = new RawKeyEventDataAndroid(
        flags: message['flags'] ?? 0,
        codePoint: message['codePoint'] ?? 0,
        keyCode: message['keyCode'] ?? 0,
        scanCode: message['scanCode'] ?? 0,
        metaState: message['metaState'] ?? 0,
      );
      break;
    default:
      throw new FlutterError('Unknown keymap for key events: $keymap');
  }

  String type = message['type'];
  switch (type) {
    case 'keydown':
      return new RawKeyDownEvent(data: data);
    case 'keyup':
      return new RawKeyUpEvent(data: data);
  }
  throw new FlutterError('Unknown key event type: $type');
}

/// An interface for listening to raw key events.
///
/// Raw key events pass through as much information as possible from the
/// underlying platform's key events, which makes they provide a high level of
/// fidelity but a low level of portability.
///
/// A [RawKeyboard] is useful for listening to raw key events and hardware
/// buttons that are represented as keys. Typically used by games and other apps
/// that use keyboards for purposes other than text entry.
///
/// See also:
///
///  * [RawKeyEvent]
///  * [RawKeyDownEvent]
///  * [RawKeyUpEvent]
class RawKeyboard {
  RawKeyboard._() {
    PlatformMessages.setJSONMessageHandler('flutter/keyevent', _handleKeyEvent);
  }

  /// The shared instance of [RawKeyboard].
  static final RawKeyboard instance = new RawKeyboard._();

  final List<ValueChanged<RawKeyEvent>> _listeners = <ValueChanged<RawKeyEvent>>[];

  /// Calls the listener every time the user presses or releases a key.
  ///
  /// Listeners can be removed with [removeListener].
  void addListener(ValueChanged<RawKeyEvent> listener) {
    _listeners.add(listener);
  }

  /// Stop calling the listener every time the user presses or releases a key.
  ///
  /// Listeners can be added with [addListener].
  void removeListener(ValueChanged<RawKeyEvent> listener) {
    _listeners.remove(listener);
  }

  Future<dynamic> _handleKeyEvent(dynamic message) async {
    if (_listeners.isEmpty)
      return;
    RawKeyEvent event = _toRawKeyEvent(message);
    if (event == null)
      return;
    for (ValueChanged<RawKeyEvent> listener in new List<ValueChanged<RawKeyEvent>>.from(_listeners))
      if (_listeners.contains(listener))
        listener(event);
  }
}
