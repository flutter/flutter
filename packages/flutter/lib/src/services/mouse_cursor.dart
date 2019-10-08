// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'mouse_cursors.dart';
import 'platform_channel.dart';

String _cursorToString(int cursor) {
  return '0x${cursor.toRadixString(16).padLeft(8, '0')}';
}

class _DeviceCursorState {
  _DeviceCursorState (
    this.device, {
    int cursor = MouseCursors.basic,
  }) : _cursor = cursor;

  final int device;
  int _cursor;

  bool changeCursor(int cursor) {
    if (cursor == MouseCursors.releaseControl)
      return false;
    if (cursor != _cursor) {
      _cursor = cursor;
      return true;
    }
    return false;
  }
}

/// TODOC
abstract class MouseCursorManagerDelegate {
  // This class is only used for implementation.
  MouseCursorManagerDelegate._();

  /// Handles when [MouseCursorManager] requests to set cursors of certain devices.
  /// The returning future resolves true if and only if the entire request is
  /// successful.
  ///
  /// The `cursorForDevices` is a map from device ID to their targer cursors.
  Future<bool> setCursors(Map<int, int> cursorForDevices);
}

/// TODOC
class MouseCursorManagerDefaultDelegate implements MouseCursorManagerDelegate {
  /// TODOC
  MouseCursorManagerDefaultDelegate(this.channel);

  /// TODOC
  final MethodChannel channel;

  @override
  Future<bool> setCursors(Map<int, int> cursorForDevices) {
    assert(cursorForDevices.isNotEmpty);
    assert(() {
      cursorForDevices.forEach((int device, int cursor) {
        assert(cursor != MouseCursors.releaseControl &&
               cursor != MouseCursors.fallThrough,
          'Mouse cursor ${_cursorToString(cursor)} is not an actual value to be set.');
      });
      return true;
    }());
    return channel.invokeMethod<bool>('setCursors', cursorForDevices);
  }
}

/// TODOC
class MouseCursorManager {
  /// Create a [MouseCursorManager] by providing necessary information.
  ///
  /// The `channel` is the method channel that can talk to the platform.
  /// Typically [SystemChannels.mouseCursor].
  MouseCursorManager({
    @required MouseCursorManagerDelegate delegate,
  }) : assert(delegate != null),
       _delegate = delegate;

  final MouseCursorManagerDelegate _delegate;

  // A map from devices to their cursor states.
  final Map<int, _DeviceCursorState> _deviceStates = <int, _DeviceCursorState>{};

  /// Called on an event that might cause pointers to change cursors.
  ///
  /// It resolves to true if all requests are successful, or false if any
  /// request fails.
  ///
  /// Calling this method with the same cursor configuration is cheap, because
  /// [MouseCursorManager] keeps track of the current cursor of each device.
  Future<void> setCursors(Map<int, int> cursorForDevices) async {
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
    return _delegate.setCursors(Map<int, int>.fromEntries(filteredEntries));
  }

  /// Called when a device is disconnected.
  ///
  /// It only frees the memory of the internal record. Nothing needs to be sent
  /// to the platform, since the pointer should be gone.
  void clearDeviceRecord(int device) {
    _deviceStates.remove(device);
  }
}
