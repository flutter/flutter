// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/foundation.dart';

import 'raw_keyboard_android.dart';
import 'raw_keyboard_fuschia.dart';
import 'system_channels.dart';

/// An enum describing the side of the keyboard that a key is on, to allow
/// discrimination between which key is pressed (e.g. the left or right SHIFT
/// key).
///
/// See also:
///
///  * [RawKeyEventData.isModifierPressed], which accepts this enum as an
///    argument.
enum KeyboardSide {
  /// Matches if either the left, right or both versions of the key are pressed.
  any,

  /// Matches the left version of the key.
  left,

  /// Matches the right version of the key.
  right,

  /// Matches the left and right version of the key pressed simultaneously.
  all,
}

/// An enum describing the type of modifier key that is being pressed.
///
/// See also:
///
///  * [RawKeyEventData.isModifierPressed], which accepts this enum as an
///    argument.
enum ModifierKey {
  /// The CTRL modifier key.
  ///
  /// Typically, there are two of these.
  controlModifier,

  /// The SHIFT modifier key.
  ///
  /// Typically, there are two of these.
  shiftModifier,

  /// The ALT modifier key.
  ///
  /// Typically, there are two of these.
  altModifier,

  /// The META modifier key.
  ///
  /// Typically, there are two of these. This is, for example, the Windows key
  /// on Windows (⊞), the Command (⌘) key on macOS and iOS, and the Search (🔍)
  /// key on Android.
  metaModifier,

  /// The CAPS LOCK modifier key.
  ///
  /// Typically, there is one of these. Only shown as "pressed" when the caps
  /// lock is on, so on a key up when the mode is turned on, on each key press
  /// when it's enabled, and on a key down when it is turned off.
  capsLockModifier,

  /// The NUM LOCK modifier key.
  ///
  /// Typically, there is one of these. Only shown as "pressed" when the num
  /// lock is on, so on a key up when the mode is turned on, on each key press
  /// when it's enabled, and on a key down when it is turned off.
  numLockModifier,

  /// The SCROLL LOCK modifier key.
  ///
  /// Typically, there is one of these.  Only shown as "pressed" when the scroll
  /// lock is on, so on a key up when the mode is turned on, on each key press
  /// when it's enabled, and on a key down when it is turned off.
  scrollLockModifier,

  /// The FUNCTION (Fn) modifier key.
  ///
  /// Typically, there is one of these.
  functionModifier,

  /// The SYMBOL modifier key.
  ///
  /// Typically, there is one of these.
  symbolModifier,
}

/// Base class for platform-specific key event data.
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
  /// Abstract const constructor.
  ///
  /// This constructor enables subclasses to provide const constructors so that
  /// they can be used in const expressions.
  const RawKeyEventData();

  /// Returns true if the given [ModifierKey] was pressed at the time of this
  /// event.
  ///
  /// If [side] is specified, then this restricts its check to the specified
  /// side of the keyboard. Defaults to checking for the key being down on
  /// either side of the keyboard. If there is only one instance of the key on
  /// the keyboard, then [side] is ignored.
  bool isModifierPressed(ModifierKey key, {KeyboardSide side = KeyboardSide.any});

  /// Returns a [KeyboardSide] enum value that describes which side or sides of
  /// the given keyboard modifier key were pressed at the time of this event.
  ///
  /// If the modifier key wasn't pressed at the time of this event, returns
  /// null. If the given key only appears in one place on the keyboard, returns
  /// [KeyboardSide.all] if pressed. Never returns [KeyboardSide.any], because
  /// that doesn't make sense in this context.
  KeyboardSide getModifierSide(ModifierKey key);

  /// Returns true if a CTRL modifier key was pressed at the time of this event,
  /// regardless of which side of the keyboard it is on.
  ///
  /// Use [isModifierPressed] if you need to know which control key was pressed.
  bool get isControlPressed => isModifierPressed(ModifierKey.controlModifier, side: KeyboardSide.any);

  /// Returns true if a SHIFT modifier key was pressed at the time of this
  /// event, regardless of which side of the keyboard it is on.
  ///
  /// Use [isModifierPressed] if you need to know which shift key was pressed.
  bool get isShiftPressed => isModifierPressed(ModifierKey.shiftModifier, side: KeyboardSide.any);

  /// Returns true if a ALT modifier key was pressed at the time of this event,
  /// regardless of which side of the keyboard it is on.
  ///
  /// Use [isModifierPressed] if you need to know which alt key was pressed.
  bool get isAltPressed => isModifierPressed(ModifierKey.altModifier, side: KeyboardSide.any);

  /// Returns true if a META modifier key was pressed at the time of this event,
  /// regardless of which side of the keyboard it is on.
  ///
  /// Use [isModifierPressed] if you need to know which meta key was pressed.
  bool get isMetaPressed => isModifierPressed(ModifierKey.metaModifier, side: KeyboardSide.any);

  /// Returns a map of modifier keys that were pressed at the time of this
  /// event, and the keyboard side or sides that the key was on.
  Map<ModifierKey, KeyboardSide> get modifiersPressed {
    final Map<ModifierKey, KeyboardSide> result = <ModifierKey, KeyboardSide>{};
    for (ModifierKey key in ModifierKey.values) {
      if (isModifierPressed(key)) {
        result[key] = getModifierSide(key);
      }
    }
    return result;
  }
}

/// Base class for raw key events.
///
/// Raw key events pass through as much information as possible from the
/// underlying platform's key events, which allows them to provide a high level
/// of fidelity but a low level of portability.
///
/// See also:
///
///  * [RawKeyDownEvent], a specialization for events representing the user
///    pressing a key.
///  * [RawKeyUpEvent], a specialization for events representing the user
///    releasing a key.
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
        // We don't yet implement raw key events on iOS or other platforms, but
        // we don't hit this exception because the engine never sends us these
        // messages.
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
    if (_listeners.isEmpty) {
      return;
    }
    final RawKeyEvent event = RawKeyEvent.fromMessage(message);
    if (event == null) {
      return;
    }
    for (ValueChanged<RawKeyEvent> listener in List<ValueChanged<RawKeyEvent>>.from(_listeners)) {
      if (_listeners.contains(listener)) {
        listener(event);
      }
    }
  }
}
