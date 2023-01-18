// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Controls the browser's context menu on the web platform.
///
/// The context menu is the menu that appears on right clicking or selecting
/// text, for example.
///
/// On web, by default, the browser's context menu is enabled by default, and
/// Flutter's context menus are hidden.
///
/// On all non-web platforms this does nothing.
class BrowserContextMenu {
  BrowserContextMenu._();

  /// Ensure that a [ContextMenu] instance has been set up so that the platform
  /// can handle messages on the scribble method channel.
  static void ensureInitialized() {
    _instance; // ignore: unnecessary_statements
  }

  static final BrowserContextMenu _instance = BrowserContextMenu._();

  final MethodChannel _channel = SystemChannels.contextMenu;

  /// Disable the browser's context menu.
  ///
  /// By default, when the app starts, the browser's context menu is already
  /// enabled.
  ///
  /// See also:
  ///  * [enableContextMenu], which performs the opposite operation.
  static Future<void> disableContextMenu() {
    assert(kIsWeb, 'This has no effect on platforms other than web.');
    return _instance._channel.invokeMethod<void>(
      'disableContextMenu',
    );
  }

  /// Enable the browser's context menu.
  ///
  /// By default, when the app starts, the browser's context menu is already
  /// enabled. Typically this method would be called after first calling
  /// [disableContextMenu].
  ///
  /// See also:
  ///  * [disableContextMenu], which performs the opposite operation.
  static Future<void> enableContextMenu() {
    assert(kIsWeb, 'This has no effect on platforms other than web.');
    return _instance._channel.invokeMethod<void>(
      'enableContextMenu',
    );
  }
}
