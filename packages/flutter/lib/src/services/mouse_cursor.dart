// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'mouse_cursors.dart';
import 'platform_channel.dart';

String _cursorToString(int cursor) {
  return '0x${cursor.toRadixString(16).padLeft(8, '0')}';
}

/// TODOC
abstract class MouseCursorDelegate {
  // This class is only used for implementation.
  MouseCursorDelegate._();

  /// Handles when [MouseCursorDelegate] requests to set cursors of certain devices.
  /// The returning future resolves true if and only if the entire request is
  /// successful.
  ///
  /// The `deviceCursors` is a map from device ID to their targer cursors. An
  /// empty map is does nothing and returns true. It's caller's responsibility
  /// to avoid sending duplicate requests, since this class does not keep track
  /// of history requests.
  Future<bool> setCursors(Map<int, int> deviceCursors);
}

/// TODOC
class MouseCursorDefaultDelegate implements MouseCursorDelegate {
  /// TODOC
  MouseCursorDefaultDelegate(this.channel);

  /// TODOC
  final MethodChannel channel;

  @override
  Future<bool> setCursors(Map<int, int> deviceCursors) async {
    if (deviceCursors.isEmpty) {
      return true;
    }
    // Translate int keys into string keys
    final Map<String, int> translated = <String, int>{};
    deviceCursors.forEach((int device, int cursor) {
      assert(cursor != MouseCursors.releaseControl,
        'The specified value ${_cursorToString(cursor)} is a permitted value for mouse cursor.');
      translated[device.toString()] = cursor;
    });
    return channel.invokeMethod<bool>('setCursors', <dynamic>[translated]);
  }
}
