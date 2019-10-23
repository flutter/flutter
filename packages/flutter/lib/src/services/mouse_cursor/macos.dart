// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import '../platform_channel.dart';
import 'common.dart';

// The channel interface with the platform.
//
// It is separated to a class for the conventience of reference by the shell
// implementation.
@immutable
class _MacOSPlatformActions {
  const _MacOSPlatformActions(this.mouseCursorChannel);

  final MethodChannel mouseCursorChannel;

  // Set cursor as a sytem cursor specified by `systemConstant`.
  Future<void> setAsSystemCursor({@required int systemConstant}) {
    assert(systemConstant != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setAsSystemCursor',
      <String, dynamic>{
        'systemConstant': systemConstant,
      },
    );
  }

  // Hide cursor, or unhide cursor.
  Future<void> setHidden({
    @required bool hidden,
  }) {
    assert(hidden != null);
    return mouseCursorChannel.invokeMethod<void>(
      'setHidden',
      <String, dynamic>{
        'hidden': hidden,
      },
    );
  }
}

/// The implementation of [MouseCursorPlatformDelegate] that controls
/// [macOS](https://developer.apple.com/documentation) over a method channel.
class MouseCursorMacOSDelegate extends MouseCursorPlatformDelegate {
  /// Create a [MouseCursorMacOSDelegate] by providing the method channel to use.
  ///
  /// The [mouseCursorChannel] must not be null, and is usually
  /// [SystemChannels.mouseCursor].
  MouseCursorMacOSDelegate({@required MethodChannel mouseCursorChannel})
    : assert(mouseCursorChannel != null),
      _platform = _MacOSPlatformActions(mouseCursorChannel);

  // System cursor constants are used to set system cursor on macOS.
  // The list should be kept in sync with
  // [NSCursor constants](https://developer.apple.com/documentation/appkit/nscursor#overview).
  // However, macOS doesn't define system constants for system cursors,
  // therefore the values should be kept in sync with Flutter's
  // `FlutterMouseCursorPlugin.mm`.

  /// The constant that represents macOS's `NSCursor.arrowCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantArrow = 0x0001;

  /// The constant that represents macOS's `NSCursor.iBeamCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantIBeam = 0x0002;

  /// The constant that represents macOS's `NSCursor.crosshairCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantCrosshair = 0x0003;

  /// The constant that represents macOS's `NSCursor.closedHandCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantClosedHand = 0x0004;

  /// The constant that represents macOS's `NSCursor.openHandCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantOpenHand = 0x0005;

  /// The constant that represents macOS's `NSCursor.pointingHandCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantPointingHand = 0x0006;

  /// The constant that represents macOS's `NSCursor.resizeLeftCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantResizeLeft = 0x0007;

  /// The constant that represents macOS's `NSCursor.resizeRightCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantResizeRight = 0x0008;

  /// The constant that represents macOS's `NSCursor.resizeLeftRightCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantResizeLeftRight = 0x0009;

  /// The constant that represents macOS's `NSCursor.resizeUpCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantResizeUp = 0x000a;

  /// The constant that represents macOS's `NSCursor.resizeDownCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantResizeDown = 0x000b;

  /// The constant that represents macOS's `NSCursor.resizeUpDownCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantResizeUpDown = 0x000c;

  /// The constant that represents macOS's `NSCursor.disappearingItemCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantDisappearingItem = 0x000d;

  /// The constant that represents macOS's `NSCursor.iBeamCursorForVerticalLayoutCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantIBeamCursorForVerticalLayout = 0x000e;

  /// The constant that represents macOS's `NSCursor.operationNotAllowed`,
  /// used internally to set system cursor.
  static const int kSystemConstantOperationNotAllowed = 0x000f;

  /// The constant that represents macOS's `NSCursor.dragLinkCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantDragLink = 0x0010;

  /// The constant that represents macOS's `NSCursor.dragCopyCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantDragCopy = 0x0011;

  /// The constant that represents macOS's `NSCursor.contextualMenuCursor`,
  /// used internally to set system cursor.
  static const int kSystemConstantContextualMenu = 0x0012;

  final _MacOSPlatformActions _platform;
  bool _isHidden = false;

  Future<bool> _activateSystemConstant(int systemConstant) async {
    if (_isHidden) {
      _isHidden = false;
      await _platform.setHidden(hidden: false);
    }
    await _platform.setAsSystemCursor(systemConstant: systemConstant);
    return true;
  }

  Future<bool> _hideCursor() async {
    if (!_isHidden) {
      _isHidden = true;
      await _platform.setHidden(hidden: true);
    }
    return true;
  }

  @override
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details) async {
    switch (details.shape) {
      case SystemMouseCursorShape.none:
        return _hideCursor();
      case SystemMouseCursorShape.basic:
        return _activateSystemConstant(MouseCursorMacOSDelegate.kSystemConstantArrow);
      case SystemMouseCursorShape.click:
        return _activateSystemConstant(MouseCursorMacOSDelegate.kSystemConstantPointingHand);
      case SystemMouseCursorShape.text:
        return _activateSystemConstant(MouseCursorMacOSDelegate.kSystemConstantIBeam);
      case SystemMouseCursorShape.forbidden:
        return _activateSystemConstant(MouseCursorMacOSDelegate.kSystemConstantDisappearingItem);
      case SystemMouseCursorShape.grab:
        return _activateSystemConstant(MouseCursorMacOSDelegate.kSystemConstantClosedHand);
      case SystemMouseCursorShape.grabbing:
        return _activateSystemConstant(MouseCursorMacOSDelegate.kSystemConstantOpenHand);
      default:
        break;
    }
    return false;
  }
}
