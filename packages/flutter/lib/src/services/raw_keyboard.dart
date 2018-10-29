// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Base class for platform specific key event data.
///
/// This base class exists to have a common type to use for each of the
/// target platform's key event data structures.
///
/// See also:
///
///  * [RawKeyEventDataAndroid], a specialization for Android.
///  * [RawKeyEventDataFuchsia], a specialization for Fuchsia.
///  * [RawKeyDownEvent] and [RawKeyUpEvent], the classes that hold the
///    reference to [RawKeyEventData] subclasses.
///  * [RawKeyboard], which uses these interfaces to expose key data.
@immutable
abstract class RawKeyEventData {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const RawKeyEventData();
}

/// Platform-specific key event data for Android.
///
/// This object contains information about key events obtained from Android's
/// `KeyEvent` interface.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataAndroid extends RawKeyEventData {
  /// Creates a key event data structure specific for Android.
  ///
  /// The [flags], [codePoint], [keyCode], [scanCode], and [metaState] arguments
  /// must not be null.
  const RawKeyEventDataAndroid({
    this.flags = 0,
    this.codePoint = 0,
    this.keyCode = 0,
    this.scanCode = 0,
    this.metaState = 0,
  }) : assert(flags != null),
       assert(codePoint != null),
       assert(keyCode != null),
       assert(scanCode != null),
       assert(metaState != null);

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

/// Platform-specific key event data for Fuchsia.
///
/// This object contains information about key events obtained from Fuchsia's
/// `KeyData` interface.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyEventDataFuchsia extends RawKeyEventData {
  /// Creates a key event data structure specific for Fuchsia.
  ///
  /// The [hidUsage], [codePoint], and [modifiers] arguments must not be null.
  const RawKeyEventDataFuchsia({
    this.hidUsage = 0,
    this.codePoint = 0,
    this.modifiers = 0,
  }) : assert(hidUsage != null),
       assert(codePoint != null),
       assert(modifiers != null);

  /// The USB HID usage.
  ///
  /// See <http://www.usb.org/developers/hidpage/Hut1_12v2.pdf>
  final int hidUsage;

  /// The Unicode code point represented by the key event, if any.
  ///
  /// If there is no Unicode code point, this value is zero.
  final int codePoint;

  /// The modifiers that we present when the key event occurred.
  ///
  /// See <https://fuchsia.googlesource.com/garnet/+/master/public/fidl/fuchsia.ui.input/input_event_constants.fidl>
  /// for the numerical values of the modifiers.
  final int modifiers;
}

/// Base class for raw key events.
///
/// Raw key events pass through as much information as possible from the
/// underlying platform's key events, which makes they provide a high level of
/// fidelity but a low level of portability.
///
/// See also:
///
///  * [RawKeyDownEvent], a specialization for events representing the user pressing a key.
///  * [RawKeyUpEvent], a specialization for events representing the user releasing a key.
///  * [RawKeyboard], which uses this interface to expose key data.
///  * [RawKeyboardListener], a widget that listens for raw key events.
@immutable
abstract class RawKeyEvent {
  /// Initializes fields for subclasses.
  const RawKeyEvent({
    @required this.data,
  });

  /// Creates a concrete [RawKeyEvent] class from a message in the form received
  /// on the [SystemChannels.keyEvent] channel.
  factory RawKeyEvent.fromMessage(Map<String, dynamic> message) {
    RawKeyEventData data;

    final String keymap = message['keymap'];
    switch (keymap) {
      case 'android':
        data = RawKeyEventDataAndroid(
          flags: message['flags'] ?? 0,
          codePoint: message['codePoint'] ?? 0,
          keyCode: message['keyCode'] ?? 0,
          scanCode: message['scanCode'] ?? 0,
          metaState: message['metaState'] ?? 0,
        );
        break;
      case 'fuchsia':
        data = RawKeyEventDataFuchsia(
          hidUsage: message['hidUsage'] ?? 0,
          codePoint: message['codePoint'] ?? 0,
          modifiers: message['modifiers'] ?? 0,
        );
        break;
      default:
        // We don't yet implement raw key events on iOS, but we don't hit this
        // exception because the engine never sends us these messages.
        throw FlutterError('Unknown keymap for key events: $keymap');
    }

    final String type = message['type'];
    switch (type) {
      case 'keydown':
        return RawKeyDownEvent(data: data);
      case 'keyup':
        return RawKeyUpEvent(data: data);
      default:
        throw FlutterError('Unknown key event type: $type');
    }
  }

  /// Platform-specific information about the key event.
  final RawKeyEventData data;
}

/// The user has pressed a key on the keyboard.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyDownEvent extends RawKeyEvent {
  /// Creates a key event that represents the user pressing a key.
  const RawKeyDownEvent({
    @required RawKeyEventData data,
  }) : super(data: data);
}

/// The user has released a key on the keyboard.
///
/// See also:
///
///  * [RawKeyboard], which uses this interface to expose key data.
class RawKeyUpEvent extends RawKeyEvent {
  /// Creates a key event that represents the user releasing a key.
  const RawKeyUpEvent({
    @required RawKeyEventData data,
  }) : super(data: data);
}

/// An interface for listening to raw key events.
///
/// Raw key events pass through as much information as possible from the
/// underlying platform's key events, which makes them provide a high level of
/// fidelity but a low level of portability.
///
/// A [RawKeyboard] is useful for listening to raw key events and hardware
/// buttons that are represented as keys. Typically used by games and other apps
/// that use keyboards for purposes other than text entry.
///
/// See also:
///
///  * [RawKeyDownEvent] and [RawKeyUpEvent], the classes used to describe
///    specific raw key events.
///  * [RawKeyboardListener], a widget that listens for raw key events.
///  * [SystemChannels.keyEvent], the low-level channel used for receiving
///    events from the system.
class RawKeyboard {
  RawKeyboard._() {
    SystemChannels.keyEvent.setMessageHandler(_handleKeyEvent);
  }

  /// The shared instance of [RawKeyboard].
  static final RawKeyboard instance = RawKeyboard._();

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
    final RawKeyEvent event = RawKeyEvent.fromMessage(message);
    if (event == null)
      return;
    for (ValueChanged<RawKeyEvent> listener in List<ValueChanged<RawKeyEvent>>.from(_listeners))
      if (_listeners.contains(listener))
        listener(event);
  }
}
