// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'system_channels.dart';

/// Allows access to the system context menu.
abstract final class ContextMenu {
  static const MethodChannel _channel = SystemChannels.platform;

  /// Shows the system context menu anchored on the given [Rect].
  ///
  /// The [Rect] represents what the context menu is pointing to. For example,
  /// for some text selection, this would be the selection [Rect].
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///     this method is supported on the current platform.
  static void showSystemContextMenu(Rect rect) {
    _channel.invokeMethod<void>(
      'ContextMenu.showSystemContextMenu',
      <String, dynamic>{
        'targetRect': <String, double>{
          'x': rect.left,
          'y': rect.top,
          'width': rect.width,
          'height': rect.height,
        },
      },
    );
  }
}
