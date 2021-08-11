// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.


part of ui;

/// The type of a key event.
// Must match the KeyEventType enum in ui/window/key_data.h.
enum KeyEventType {
  /// The key is pressed.
  down,

  /// The key is released.
  up,

  /// The key is held, causing a repeated key input.
  repeat,
}

/// Information about a key event.
class KeyData {
  /// Creates an object that represents a key event.
  const KeyData({
    required this.timeStamp,
    required this.type,
    required this.physical,
    required this.logical,
    required this.character,
    required this.synthesized,
  });

  /// Time of event dispatch, relative to an arbitrary timeline.
  ///
  /// For [KeyEventType.synchronize] and [KeyEventType.cancel] events, the [timeStamp]
  /// might not be the actual time that the key press or release happens.
  final Duration timeStamp;

  /// The type of the event.
  final KeyEventType type;

  /// The key code for the physical key that has changed.
  final int physical;

  /// The key code for the logical key that has changed.
  final int logical;

  /// Character input from the event.
  ///
  /// Ignored for up events.
  final String? character;

  /// If [synthesized] is true, this event does not correspond to a native event.
  ///
  /// Although most of Flutter's keyboard events are transformed from native
  /// events, some events are not based on native events, and are synthesized
  /// only to conform Flutter's key event model (as documented in
  /// the `HardwareKeyboard` class in the framework).
  ///
  /// For example, some key downs or ups might be lost when the window loses
  /// focus. Some platforms provides ways to query whether a key is being held.
  /// If Flutter detects an inconsistency between the state Flutter records and
  /// the state returned by the system, Flutter will synthesize a corresponding
  /// event to synchronize the state without breaking the event model.
  ///
  /// As another example, macOS treats CapsLock in a special way by sending
  /// down and up events at the down of alterate presses to indicate the
  /// direction in which the lock is toggled instead of that the physical key is
  /// going. Flutter normalizes the behavior by converting a native down event
  /// into a down event followed immediately by a synthesized up event, and
  /// the native up event also into a down event followed immediately by a
  /// synthesized up event.
  ///
  /// Synthesized events do not have a trustworthy [timeStamp], and should not be
  /// processed as if the key actually went down or up at the time of the
  /// callback.
  ///
  /// [KeyRepeatEvent] is never synthesized.
  final bool synthesized;

  String _logicalToString() {
    final String result = '0x${logical.toRadixString(16)}';
    // Find the bits that are not included in `valueMask`, shifted to the right.
    // For example, if [logical] is 0x12abcdabcd, then the result is 0x12.
    //
    // This is mostly equivalent to a right shift, resolving the problem that
    // JavaScript only support 32-bit bitwise operations and needs to use
    // division instead.
    final int planeNum = (logical / 0x100000000).floor();
    final String planeDescription = (() {
      switch (planeNum) {
        case 0x000:
          return ' (Unicode)';
        case 0x001:
          return ' (Unprintable)';
        case 0x002:
          return ' (Flutter)';
        case 0x017:
          return ' (Web)';
      }
      return '';
    })();
    return '$result$planeDescription';
  }

  String? _escapeCharacter() {
    if (character == null) {
      return character ?? '<none>';
    }
    switch (character!) {
      case '\n':
        return r'"\n"';
      case '\t':
        return r'"\t"';
      case '\r':
        return r'"\r"';
      case '\b':
        return r'"\b"';
      case '\f':
        return r'"\f"';
      default:
        return '"$character"';
    }
  }

  String? _quotedCharCode() {
    if (character == null)
      return '';
    final Iterable<String> hexChars = character!.codeUnits
        .map((int code) => code.toRadixString(16).padLeft(2, '0'));
    return ' (0x${hexChars.join(' ')})';
  }

  @override
  String toString() => 'KeyData(type: ${_typeToString(type)}, physical: 0x${physical.toRadixString(16)}, '
    'logical: ${_logicalToString()}, character: ${_escapeCharacter()}${_quotedCharCode()}${synthesized ? ', synthesized' : ''})';

  /// Returns a complete textual description of the information in this object.
  String toStringFull() {
    return '$runtimeType('
            'type: ${_typeToString(type)}, '
            'timeStamp: $timeStamp, '
            'physical: 0x${physical.toRadixString(16)}, '
            'logical: 0x${logical.toRadixString(16)}, '
            'character: $character, '
            'synthesized: $synthesized'
           ')';
  }

  static String _typeToString(KeyEventType type) {
    switch (type) {
      case KeyEventType.up:
        return 'up';
      case KeyEventType.down:
        return 'down';
      case KeyEventType.repeat:
        return 'repeat';
    }
  }
}
