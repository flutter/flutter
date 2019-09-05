// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show Offset;

import 'package:flutter/foundation.dart';
import 'message_codecs.dart';
import 'platform_channel.dart';

// We ignore this warning because mouse cursor has a lot of enum-like constants,
// which is clearer when grouped in a class.
// ignore: avoid_classes_with_only_static_members
/// Integer constants which represent system mouse cursors from various
/// platforms.
///
/// This is a collection of all system mouse cursors supported by all platforms
/// that Flutter is interested in. The implementation to these cursors are left
/// to platforms, which means multiple constants might result in the same cursor,
/// and the same constant might look different across platforms.
///
/// The integer values of the constants are intentionally randomized (results
/// of hashing). When defining custom cursors, you are free to choose how
/// to pick values, as long as the result does not collide with existing
/// values and is consistent between platforms and the framework.
class MouseCursors {
  /// A special value to display no cursor at the pointer.
  static const int none = 0x334c4a4c;

  /// A special value to release the control of cursors.
  ///
  /// Setting a region with this value means that Flutter will not actively
  /// change the cursor when the pointer enters or is hovering this region.
  /// Typically used on a platform view or other regions that manages the cursor
  /// by itself.
  ///
  /// This constant is only used by [MouseCursorManager] and should not be sent
  /// to the platforms via the channel.
  static const int renounced = 0x795c0b0a;

  /// The platform-dependent basic cursor. Typically an arrow.
  static const int basic = 0xf17aaabc;

  /// A cursor that indicates a link or other clickable object that is not
  /// obvious enough otherwise. Typically the shape of a pointing hand.
  static const int click = 0xa8affc08;

  /// A cursor that indicates a selectable text. Typically the shape of an
  /// I-beam.
  static const int text = 0x1cb251ec;

  /// A cursor that indicates that the intended action is not permitted.
  /// Typically the shape of a circle with a diagnal line.
  static const int no = 0x7fa3b767;

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  static const int grab = 0x28b91f80;

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  static const int grabbing = 0x6631ce3e;
}

class _DeviceCursorState {
  _DeviceCursorState (
    this.device, {
    int cursor = MouseCursors.basic,
  }) : _cursor = cursor;

  final int device;
  int _cursor;

  bool changeCursor(int cursor) {
    if (cursor == MouseCursors.renounced)
      return false;
    if (cursor != _cursor) {
      _cursor = cursor;
      return true;
    }
    return false;
  }
}

/// TODOC
class MouseCursorManager {
  /// Create a [MouseCursorManager] by providing necessary information.
  ///
  /// The `channel` is the method channel that can talk to the platform.
  /// Typically [SystemChannels.mouseCursor].
  MouseCursorManager({
    MethodChannel channel,
  }) : _channel = channel;

  final MethodChannel _channel;
  // A map from devices to their cursor states.
  final Map<int, _DeviceCursorState> _deviceStates = <int, _DeviceCursorState>{};

  /// Called on an event that might cause pointers to change cursors.
  ///
  /// It resolves to true if all requests are successful, or false if any
  /// request fails.
  ///
  /// Calling this method with the same cursor configuration is cheap, because
  /// [MouseCursorManager] keeps track of the current cursor of each device.
  Future<void> onChangeCursor(Map<int, int> cursorForDevices) async {
    // Create a state if absent, then find the devices that need changing.
    final Iterable<MapEntry<int, int>> filteredEntries = cursorForDevices.entries.where(
      (MapEntry<int, int> entry) {
        final _DeviceCursorState state = _deviceStates.putIfAbsent(
          entry.key,
          () => _DeviceCursorState(entry.key, cursor: MouseCursors.basic),
        );
        return state.changeCursor(entry.value);
      }
    );
    if (filteredEntries.isEmpty) {
      return true;
    }
    return _requestSetIcons(Map<int, int>.fromEntries(filteredEntries));
  }

  /// Called when a device is disconnected.
  ///
  /// It only frees the memory of the internal record. Nothing needs to be sent
  /// to the platform, since the pointer should be gone.
  void onDeviceDisconnected(int device) {
    _deviceStates.remove(device);
  }

  Future<bool> _requestSetIcons(Map<int, int> cursorForDevices) {
    assert(cursorForDevices.isNotEmpty);
    return _channel.invokeMethod<bool>(
      'setIcons',
      <String, dynamic>{
        'cursorForDevices': cursorForDevices,
      },
    );
  }
}
