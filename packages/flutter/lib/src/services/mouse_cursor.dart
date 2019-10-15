// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'mouse_cursors.dart';
import 'platform_channel.dart';

String _cursorToString(int cursor) {
  return '0x${cursor.toRadixString(16).padLeft(8, '0')}';
}

/// A delegate for communicating with the platform to perform operations related
/// to mouse cursor.
///
/// See also:
///
///  * [MouseCursorDefaultDelegate], which is the typical implementation that
///    communicates with the platform over a method channel.
abstract class MouseCursorDelegate {
  // This class is only used for implementation.
  MouseCursorDelegate._();

  /// Requests the platform to change the mouse cursor of certain device. The
  /// returning future resolves to a boolean that indicates whether the request
  /// is successful.
  ///
  /// It's caller's responsibility to avoid sending duplicate requests, since
  /// this class does not keep track of history requests.
  ///
  /// The `device` must be an existing device. The `cursor` must be a cursor
  /// that is allowed to be sent to the platform; for example, it must not be
  /// [MouseCursors.releaseControl].
  Future<bool> setCursor(int device, int cursor);
}

/// The default implementation of [MouseCursorDelegate], which communitates with
/// the platform over a [MethodChannel].
class MouseCursorDefaultDelegate implements MouseCursorDelegate {
  /// Create a [MouseCursorDefaultDelegate] by providing the channel.
  ///
  /// The `channel` must not be null.
  MouseCursorDefaultDelegate(this.channel) : assert(channel != null);

  /// The channel used to send messages. Typically [SystemChannels.mouseCursor].
  final MethodChannel channel;

  @override
  Future<bool> setCursor(int device, int cursor) async {
    assert(cursor != MouseCursors.releaseControl,
      'The specified value ${_cursorToString(cursor)} is a permitted value for mouse cursor.');
    return channel.invokeMethod<bool>('setCursor', <dynamic>[device, cursor]);
  }
}
