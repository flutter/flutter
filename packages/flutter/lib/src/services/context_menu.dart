// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'system_channels.dart';

// TODO(justinmc): Document, and explain that this controls the browser context menu, not Flutter's context menus.
class ContextMenu {
  ContextMenu._();

  /// Ensure that a [ContextMenu] instance has been set up so that the platform
  /// can handle messages on the scribble method channel.
  static void ensureInitialized() {
    _instance; // ignore: unnecessary_statements
  }

  static final ContextMenu _instance = ContextMenu._();

  final MethodChannel _channel = SystemChannels.contextMenu;

  static void disableContextMenu() {
    print('justin disable context menu');
    _instance._channel.invokeMethod<void>(
      'disableContextMenu',
    );
  }

  static void enableContextMenu() {
    print('justin enable context menu');
    _instance._channel.invokeMethod<void>(
      'enableContextMenu',
    );
  }
}
