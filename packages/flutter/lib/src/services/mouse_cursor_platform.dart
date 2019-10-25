// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

import 'mouse_cursor_android.dart';
import 'mouse_cursor_glfw.dart';
import 'mouse_cursor_macos.dart';
import 'platform_channel.dart';

/// The implementation of [MouseCursorPlatformDelegate] on a platform that
/// does not support mouse cursor.
///
/// Every operation is a no-op and returns with a successful state.
class MouseCursorUnsupportedPlatformDelegate extends MouseCursorPlatformDelegate {
  /// Create a [MouseCursorUnsupportedPlatformDelegate].
  const MouseCursorUnsupportedPlatformDelegate();

  @override
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details) async {
    return true;
  }
}

/// The [MouseCursorManager] that implements the platform-specific code based on
/// the platform that this program is running on.
///
/// See also:
///
///  * [MouseTracker], which owns an instance of this class.
class StandardMouseCursorManager extends MouseCursorManager {
  /// Create a [MouseCursorManager] by providing the channel.
  ///
  /// The `mouseCursorChannel` is used to create platform delegates, and must
  /// not be null.
  StandardMouseCursorManager(
    MethodChannel mouseCursorChannel,
  ) : assert(mouseCursorChannel != null) {
    _platformDelegate = _createDelegate(mouseCursorChannel);
    assert(_platformDelegate != null);
  }

  @override
  MouseCursorPlatformDelegate get platformDelegate => _platformDelegate;
  MouseCursorPlatformDelegate _platformDelegate;

  MouseCursorPlatformDelegate _createDelegate(MethodChannel channel) {
    // Must check kIsWeb first; Platform.isXXX is unsupported on Web and will
    // throw errors.
    if (kIsWeb)
      return const MouseCursorUnsupportedPlatformDelegate();
    if (Platform.isLinux) {
      return MouseCursorGLFWDelegate(mouseCursorChannel: channel);
    } else if (Platform.isAndroid) {
      return MouseCursorAndroidDelegate(mouseCursorChannel: channel);
    } else if (Platform.isMacOS) {
      return MouseCursorMacOSDelegate(mouseCursorChannel: channel);
    } else {
      return const MouseCursorUnsupportedPlatformDelegate();
    }
  }
}
