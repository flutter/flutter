// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

/// @docImport 'package:flutter/widgets.dart';
library;

import 'dart:ui' show Offset, Rect;

import 'system_channels.dart';

/// The result of [SystemMagnifier.show].
enum SystemMagnifierShowResult {
  /// The system magnifier is shown.
  shown,

  /// The platform has a system magnifier, but could not show it this time.
  ///
  /// For example, on iOS this happens when the Flutter view is not loaded.
  /// A later call to [SystemMagnifier.show] may succeed.
  notShown,

  /// The platform has no system magnifier.
  ///
  /// For example, iOS versions before 17.0 have no system loupe. Later calls
  /// to [SystemMagnifier.show] give the same result.
  unsupported,
}

/// Shows and hides the text magnifier drawn by the platform.
///
/// Currently, only supported on iOS 17.0 and later, where this is the system
/// loupe. Only call these methods on iOS.
///
/// See also:
///
///  * [SystemTextMagnifier], which wraps this functionality in a widget.
abstract final class SystemMagnifier {
  /// Shows the system magnifier at `gesturePosition`, magnifying the caret
  /// at `caretRect`, or moves it there if it is already shown.
  ///
  /// Both are in the logical coordinates of the Flutter view.
  ///
  /// The returned [Future] completes with whether the magnifier is shown. If
  /// it completes with [SystemMagnifierShowResult.unsupported], there is no
  /// need to call this method again.
  ///
  /// See also:
  ///
  ///  * [hide], which hides the magnifier shown by this method.
  static Future<SystemMagnifierShowResult> show({
    required Offset gesturePosition,
    required Rect caretRect,
  }) async {
    final bool? shown = await SystemChannels.platform.invokeMethod<bool>(
      'Magnifier.showSystemMagnifier',
      <String, Object>{
        'position': <String, double>{'x': gesturePosition.dx, 'y': gesturePosition.dy},
        'caretRect': <String, double>{
          'x': caretRect.left,
          'y': caretRect.top,
          'width': caretRect.width,
          'height': caretRect.height,
        },
      },
    );
    return switch (shown) {
      true => SystemMagnifierShowResult.shown,
      false => SystemMagnifierShowResult.notShown,
      null => SystemMagnifierShowResult.unsupported,
    };
  }

  /// Hides the system magnifier shown by [show], if any.
  static Future<void> hide() {
    return SystemChannels.platform.invokeMethod<void>('Magnifier.hideSystemMagnifier');
  }
}
