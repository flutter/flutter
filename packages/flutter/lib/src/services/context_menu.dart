// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'system_channels.dart';

/// Allows access to the system context menu.
///
/// The context menu is the menu that appears for example when doing text
/// selection. Flutter typically draws this menu itself, but this class deals
/// with the platform-rendered context menu.
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
  ///  * [hideSystemContextMenu], which hides the menu shown by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    this method is supported on the current platform.
  static Future<void> showSystemContextMenu(Rect rect) {
    return _channel.invokeMethod<void>(
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

  /// Hides the system context menu shown by [showSystemContextMenu].
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [showSystemContextMenu], which shows he menu hidden by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    the system context menu is supported on the current platform.
  static Future<void> hideSystemContextMenu() {
    return _channel.invokeMethod<void>(
      'ContextMenu.hideSystemContextMenu',
    );
  }
}
