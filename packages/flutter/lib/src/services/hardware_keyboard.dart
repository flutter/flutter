// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedList, LinkedListEntry;

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'binding.dart';
import 'keyboard_key.dart';
import 'keyboard_keys.dart';


/// Represents a lock mode of a keyboard, such as [capsLock].
///
/// A lock mode locks part of a keyboard keys into a distinct mode of operation,
/// depending on the lock settings selected. The status of the mode is toggled
/// with each key down of its corresponding logical key. A [KeyboardLockMode]
/// object is used to query whether this mode is enabled on the keyboard.
///
/// Only a limited number of modes are supported, which are enumerated as static
/// members of this class. Manual constructing of this class is prohibited.
class KeyboardLockMode implements KeyboardStateCriterion {
  // KeyboardLockMode has a fixed pool of supported keys, enumerated as static
  // members of this class, therefore constructing is prohibited.
  KeyboardLockMode._(this.logical);

  /// The logical key that triggers this lock mode.
  final LogicalKeyboardKey logical;

  @override
  bool active(KeyboardState state) {
    return state.modeEnabled(this);
  }

  /// Represents the number lock mode on the keyboard.
  ///
  /// On supporting systems, enabling number lock mode usually allows key
  /// presses of the number pad to input numbers, instead of acting as up, down,
  /// left, right, page up, end, etc.
  static final KeyboardLockMode numLock = KeyboardLockMode._(LogicalKeyboardKey.numLock);

  /// Represents the scrolling lock mode on the keyboard.
  ///
  /// On supporting systems and applications (such as spreadsheet), enabling
  /// scrolling lock mode usually allows key presses of the cursor keys to
  /// scroll the document instead of the cursor.
  static final KeyboardLockMode scrollLock = KeyboardLockMode._(LogicalKeyboardKey.scrollLock);

  /// Represents the capital lock mode on the keyboard.
  ///
  /// On supporting systems, enabling capital lock mode usually allows key
  /// presses of the letter keys to input upper cases.
  static final KeyboardLockMode capsLock = KeyboardLockMode._(LogicalKeyboardKey.capsLock);

  /// Whether a logical key corresponds to a valid lock mode.
  static bool isLock(LogicalKeyboardKey logical) => _knownLockModes.containsKey(logical.keyId);

  static final Map<int, KeyboardLockMode> _knownLockModes = <int, KeyboardLockMode>{
    numLock.logical.keyId: numLock,
    scrollLock.logical.keyId: scrollLock,
    capsLock.logical.keyId: capsLock,
  };
}

/// A virtual keyboard key that represents any of several keys.
///
/// [UnionKeyboardKey] takes multiple keys, and when tested against a keyboard
/// state or a key event, it is satisfied if any of its keys are satisifed.
/// This is useful when the application does not distinguish certain sets of
/// keys, such as a pair of left and right modifiers.
class UnionKeyboardKey implements KeyboardStateCriterion, KeyboardEventCriterion {
  /// Construct a virtual keyboard key that represents any of the provided keys.
  const UnionKeyboardKey(this.keys);

  /// The list of keys that this virtual key represents.
  final List<KeyboardKey> keys;

  @override
  bool active(KeyboardState state) {
    return keys.any((KeyboardKey key) => key.active(state));
  }

  @override
  bool fulfilled(KeyEvent event) {
    return keys.any((KeyboardKey key) => key.fulfilled(event));
  }

  /// Represents either the left or the right logical shift key.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.shiftLeft], [LogicalKeyboardKey.shiftRight].
  static const UnionKeyboardKey shiftLogical = UnionKeyboardKey(<KeyboardKey>[
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  ]);

  /// Represents either the left or the right logical alt key.
  ///
  /// Does not include AltGr key.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.altLeft], [LogicalKeyboardKey.altRight].
  static const UnionKeyboardKey altLogical = UnionKeyboardKey(<KeyboardKey>[
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
  ]);

  /// Represents either the left or the right logical meta key.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.metaLeft], [LogicalKeyboardKey.metaRight].
  static const UnionKeyboardKey metaLogical = UnionKeyboardKey(<KeyboardKey>[
    LogicalKeyboardKey.metaLeft,
    LogicalKeyboardKey.metaRight,
  ]);

  /// Represents either the left or the right logical control key.
  ///
  /// See also:
  ///
  ///  * [LogicalKeyboardKey.controlLeft], [LogicalKeyboardKey.controlRight].
  static const UnionKeyboardKey controlLogical = UnionKeyboardKey(<KeyboardKey>[
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
  ]);
}

/// An event indicating that the user has pressed a key down on the keyboard.
///
/// See also:
///
///  * [HardwareKeyboard], which produces this event.
class KeyDownEvent extends KeyEvent {
  /// Creates a key event that represents the user pressing a key.
  const KeyDownEvent({
    required PhysicalKeyboardKey physical,
    required LogicalKeyboardKey logical,
    String? character,
    required Duration timeStamp,
    bool synthesized = false,
  }) : super(
         physical: physical,
         logical: logical,
         character: character,
         timeStamp: timeStamp,
         synthesized: synthesized,
       );
}

/// An event indicating that the user has released a key on the keyboard.
///
/// See also:
///
///  * [HardwareKeyboard], which produces this event.
class KeyUpEvent extends KeyEvent {
  /// Creates a key event that represents the user pressing a key.
  const KeyUpEvent({
    required PhysicalKeyboardKey physical,
    required LogicalKeyboardKey logical,
    required Duration timeStamp,
    bool synthesized = false,
  }) : super(
         physical: physical,
         logical: logical,
         timeStamp: timeStamp,
         synthesized: synthesized,
       );
}

/// An event indicating that the user has been holding a key on the keyboard
/// and causing repeated events.
///
/// See also:
///
///  * [HardwareKeyboard], which produces this event.
class KeyRepeatEvent extends KeyEvent {
  /// Creates a key event that represents the user pressing a key.
  const KeyRepeatEvent({
    required PhysicalKeyboardKey physical,
    required LogicalKeyboardKey logical,
    String? character,
    required Duration timeStamp,
  }) : super(
         physical: physical,
         logical: logical,
         character: character,
         timeStamp: timeStamp,
       );
}

///
typedef KeyEventCallback = bool Function(KeyEvent event);

class _ListenerEntry extends LinkedListEntry<_ListenerEntry> {
  _ListenerEntry(this.listener);
  final KeyEventCallback listener;
}

/// An interface to listen to hardware [KeyEvent]s and query key states.
///
/// [HardwareKeyboard] dispatches key events from hardware keyboards (in contrast
/// to on-screen keyboards) received from the native platform after
/// normalization. To stay notified whenever keys are pressed and released, add a
/// listener with [addListener]. Alternatively, you can listen to key events only
/// when specific part of the app is focused with [Focus.onKeyEvent].
///
/// [HardwareKeyboard] also offers basic state querying. Query whether a key is
/// being held, or a lock key is enabled, with [physicalKeyPressed],
/// [logicalKeyPressed], or [locked].
///
/// The singleton [HardwareKeyboard] instance is held by the [ServicesBinding] as
/// [ServicesBinding.hardwareKeyboard], and can be conveniently accessed using the
/// [HardwareKeyboard.instance] static accessor.
///
/// ## Event model
///
/// Flutter normalizes hardware key events from the native platform in terms of
/// event model and key options, while preserving platform-specific features as
/// much as possible.
///
/// [HardwareKeyboard] tries to dispatch events following the model as follows:
///
///  * At initialization, all keys are released.
///  * A key tap sequence always consists of one [KeyDownEvent], zero or more
///    [KeyRepeatEvent]s, and one [KeyUpEvent].
///  * All events in the same key tap sequence have the same physical key and
///    logical key.
///  * Only [KeyDownEvent]s and [KeyRepeatEvent]s may have `character`, which
///    might vary within the key tap sequence.
///  * Lock state always toggles at a respetive [KeyDownEvent].
///
/// However, this model might not be met on some platforms until the migration
/// period is over, since the [KeyEvent]s on these platforms are still one-to-one
/// mapped from [RawKeyEvent]s.
///
/// The resulting events might not map one-to-one to native key events. A
/// [KeyEvent] that does not correspond to a native event is marked as
/// `synthesized`.
///
/// ## Compared to [RawKeyboard]
///
/// [RawKeyboard] is the legacy API, will be deprecated and removed in the
/// future.
///
/// [RawKeyboard] dispatches events that contain raw key event data and computes
/// unified key information in the framework. [RawKeyboard] provides a less
/// unified, less regular event model than [HardwareKeyboard], and includes
/// unnecessary mapping data of other platforms in the app.
///
/// It is recommended to always use [HardwareKeyboard] and [KeyEvent] APIs to
/// handle key events.
///
/// See also:
///
///  * [KeyDownEvent] and [KeyUpEvent], the classes used to describe specific key
///    events.
///  * [RawKeyboard], the legacy API that dispatches key events containing raw
///    system data.
///  * [ServiceBinding.hardwareKeyboard], a typical global singleton of this class.
abstract class HardwareKeyboard extends KeyboardState {

  /// Provides convenient access to the current [HardwareKeyboard] singleton from
  /// the [ServicesBinding] instance.
  static HardwareKeyboard get instance => ServicesBinding.instance!.hardwareKeyboard;

  /// Whether [HardwareKeyboard] is using data from [ui.KeyData], or
  /// [RawKeyEvent] otherwise.
  ///
  /// While [HardwareKeyboard] is designed for the new API [ui.KeyData], it is
  /// compatible with the legacy API [RawKeyEvent] during the deprecation
  /// process. The flag [receivingKeyData] is recorded to disable events from
  /// [RawKeyEvent] on platforms where [ui.KeyData] is available, and to disable
  /// certain sanity assertions for the legacy API.
  @protected
  bool receivingKeyData = false;

  final Map<int, int> _physicalPressCount = <int, int>{};
  /// Returns true if the given [PhysicalKeyboardKey] is pressed.
  ///
  /// If used during a key event listener, the result will have taken the event
  /// into account.
  ///
  /// If multiple key down events with the same physical `usbHidUsage` have been
  /// observed, the result will turn false only with the same number of key up
  /// events.
  ///
  /// See also:
  ///
  ///  * [physicalKeyPressed], which tells if a physical key is being pressed.
  ///  * [locked], which tells if a logical lock key is enabled.
  @override
  @protected
  bool physicalPressed(PhysicalKeyboardKey physical) {
    final int? count = _physicalPressCount[physical.usbHidUsage];
    assert(count == null || count > 0);
    return count != null && count > 0;
  }

  final Map<int, int> _logicalPressCount = <int, int>{};
  /// Returns true if the given [LogicalKeyboardKey] is pressed.
  ///
  /// If used during a key event listener, the result will have taken the event
  /// into account.
  ///
  /// If multiple key down events with the same logical `keyId` have been
  /// observed, the result will turn false only with the same number of key up
  /// events.
  ///
  /// See also:
  ///
  ///  * [physicalKeyPressed], which tells if a physical key is being pressed.
  ///  * [locked], which tells if a logical lock key is enabled.
  @override
  @protected
  bool logicalPressed(LogicalKeyboardKey logical) {
    final int? count = _logicalPressCount[logical.keyId];
    assert(count == null || count > 0);
    return count != null && count > 0;
  }

  late final Map<int, bool> _locked = <int, bool>{};
  /// Returns true if the lock flag of the given [LogicalKeyboardKey] is enabled.
  ///
  /// Lock keys, such as CapsLock, are logical keys that toggle their
  /// respective boolean states on key down events. Such flags are usually used
  /// as modifier to other keys or events.
  ///
  /// If used during a key event listener, the result will have taken the event
  /// into account.
  @override
  @protected
  bool locked(LogicalKeyboardKey logical) {
    return _locked[logical.keyId] ?? false;
  }

  bool isPressed(KeyboardStateCriterion criterion) => criterion.active(this);

  /// Updates states with `event`, and sends the `event` to listeners.
  ///
  /// This method is called by subclasses, typically
  /// [ServiceBinding.hardwareKeyboard], which is responsible to accept raw data
  /// (such as [ui.KeyData]) and convert them to [KeyEvent].
  @protected
  bool dispatchKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      _physicalPressCount.update(event.physical.usbHidUsage,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
      _logicalPressCount.update(event.logical.keyId,
        (int count) => count + 1,
        ifAbsent: () => 1,
      );
      if (LockKeyboardKey.isLockKey(event.logical)) {
        _locked.update(event.logical.keyId,
          (bool value) => !value,
          ifAbsent: () => true,
        );
      }
    } else if (event is KeyUpEvent) {
      int Function() alertMissingKey(Object info) {
        return () {
          // Only throw assertion for KeyData. RawKeyEvent does not guarantee this.
          assert(!receivingKeyData,
              'KeyUpEvent refers to key ${info.toString()}, which has not been pressed.');
          return 0;
        };
      }
      final int physicalCount = _physicalPressCount.update(event.physical.usbHidUsage,
        (int count) => count - 1, ifAbsent: alertMissingKey(event.physical));
      if (physicalCount == 0) {
        _physicalPressCount.remove(event.physical.usbHidUsage);
      }
      final int logicalCount = _logicalPressCount.update(event.logical.keyId,
        (int count) => count - 1, ifAbsent: alertMissingKey(event.logical));
      if (logicalCount == 0) {
        _logicalPressCount.remove(event.logical.keyId);
      }
    } else if (event is KeyRepeatEvent) {
      assert(!receivingKeyData || _physicalPressCount.containsKey(event.physical.usbHidUsage));
      assert(!receivingKeyData || _logicalPressCount.containsKey(event.logical.keyId));
    }
    if (onEvent == null) {
      return false;
    } else {
      return onEvent!(event);
    }
  }

  KeyEventCallback? onEvent;
}
