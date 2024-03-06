// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/foundation.dart';

import 'system_channels.dart';

/// Allows access to the system context menu.
///
/// The context menu is the menu that appears, for example, when doing text
/// selection. Flutter typically draws this menu itself, but this class deals
/// with the platform-rendered context menu.
///
/// Only one instance can be visible at a time. Calling [show] while the system
/// context menu is already visible will hide it and show it again at the new
/// [Rect]. An instance that is hidden is informed via [onSystemHide].
///
/// Call [dispose] when no longer needed.
///
/// See also:
///
///  * [ContextMenuController], which controls Flutter-drawn context menus.
///  * [SystemContextMenu], which wraps this functionality in a widget.
class SystemContextMenuController {
  /// Creates an instance of [SystemContextMenuController].
  ///
  /// Not shown until [show] is called.
  SystemContextMenuController({
    this.onSystemHide,
  }) {
    _instances.add(this);
  }

  /// Called when the system has hidden the context menu.
  ///
  /// For example, tapping outside of the context menu typically causes the
  /// system to hide it directly. Flutter is made aware that the context menu is
  /// no longer visible through this callback.
  final VoidCallback? onSystemHide;

  static final Set<SystemContextMenuController> _instances = <SystemContextMenuController>{};

  static const MethodChannel _channel = SystemChannels.platform;

  static SystemContextMenuController? _lastShown;

  // TODO(justinmc): Name.
  /// Handles the engine informing Flutter that the system has hidden the
  /// context menu.
  static void handleSystemHide() {
    for (final SystemContextMenuController instance in _instances) {
      instance._handleSystemHide();
    }
  }

  /// True when the instance most recently [show]n has been hidden by the
  /// system.
  bool _hiddenBySystem = false;

  bool get _isVisible => this == _lastShown && !_hiddenBySystem;

  bool get _isDisposed => !_instances.contains(this);

  /// Handles the system hiding a context menu.
  ///
  /// This is called for all instances of [SystemContextMenuController], so it's
  /// not guaranteed that this instance was the one that was hidden.
  void _handleSystemHide() {
    assert(!_isDisposed);
    // If this instance wasn't being shown, then it wasn't the instance that was
    // hidden.
    if (!_isVisible) {
      return;
    }
    _hiddenBySystem = true;
    onSystemHide?.call();
  }

  /// Shows the system context menu anchored on the given [Rect].
  ///
  /// The [Rect] represents what the context menu is pointing to. For example,
  /// for some text selection, this would be the selection [Rect].
  ///
  /// There can only be one system context menu visible at a time. Calling this
  /// while another system context menu is already visible will remove the old
  /// menu before showing the new menu.
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [hideSystemContextMenu], which hides the menu shown by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    this method is supported on the current platform.
  Future<void> show(Rect rect) {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    assert(!_isDisposed);
    _lastShown = this;
    _hiddenBySystem = false;
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

  /// Hides this system context menu.
  ///
  /// If this hasn't been shown, or if another instance has hidden this menu,
  /// does nothing.
  ///
  /// Currently this is only supported on iOS 16.0 and later.
  ///
  /// See also:
  ///
  ///  * [showSystemContextMenu], which shows he menu hidden by this method.
  ///  * [MediaQuery.supportsShowingSystemContextMenu], which indicates whether
  ///    the system context menu is supported on the current platform.
  Future<void> hide() async {
    assert(defaultTargetPlatform == TargetPlatform.iOS);
    assert(!_isDisposed);
    // This check prevents a given instance from accidentally hiding some other
    // instance, since only one can be visible at a time.
    if (this != _lastShown) {
      return;
    }
    _lastShown = null;
    // This may be called unnecessarily in the case where the user has already
    // hidden the menu (for example by tapping the screen).
    return _channel.invokeMethod<void>(
      'ContextMenu.hideSystemContextMenu',
    );
  }

  /// Used to release resources when this instance will never be used again.
  void dispose() {
    assert(!_isDisposed);
    hide();
    _instances.remove(this);
  }
}
