// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

/// The kinds of system cursors supported by Flutter.
///
/// Each value of [MouseCursorSystemShape] corresponds to a [MouseCursor] object
/// in [SystemMouseCursors].
///
/// Widgets that wants to use system cursors should use the objects defined in
/// [SystemMouseCursors] instead of using [MouseCursorSystemShape].
///
/// See also:
///
///  * [SystemMouseCursors], which contains usable [MouseCursor] objects that
///    correspond to values of this type.
///  * [MouseCursorPlatformDelegate], which uses this type to define how
///    system cursors are implemented on platforms.
enum MouseCursorSystemShape {
  /// The shape that corresponds to [SystemCursors.none].
  none,

  /// The shape that corresponds to [SystemCursors.basic].
  ///
  /// This shape must be implemented by all platforms.
  basic,

  /// The shape that corresponds to [SystemCursors.click].
  click,

  /// The shape that corresponds to [SystemCursors.text].
  text,

  /// The shape that corresponds to [SystemCursors.forbidden].
  forbidden,

  /// The shape that corresponds to [SystemCursors.grab].
  grab,

  /// The shape that corresponds to [SystemCursors.grabbing].
  grabbing,
}

/// Details for [MouseCursorPlatformDelegate.activateSystemCursor], such as the
/// target device and the system cursor shape.
@immutable
class MouseCursorPlatformActivateSystemCursorDetails {
  /// Create details for a [MouseCursorPlatformDelegate.activateSystemCursor]
  /// call.
  ///
  /// All parameters must not be null.
  const MouseCursorPlatformActivateSystemCursorDetails({
    @required this.device,
    @required this.systemShape,
  }) : assert(device != null), assert(systemShape != null);

  /// The pointer device that should change cursor.
  final int device;

  /// The kind of system cursor that should change to.
  final MouseCursorSystemShape systemShape;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != MouseCursorPlatformActivateSystemCursorDetails)
      return false;
    final MouseCursorPlatformActivateSystemCursorDetails typed = other;
    return typed.device == device && typed.systemShape == systemShape;
  }

  @override
  int get hashCode => hashValues(device, systemShape);

  @override
  String toString() {
    return '$runtimeType(device: $device, systemShape: $systemShape)';
  }
}

/// An interface for the operations that a [MouseCursor] can use to control the
/// platform.
///
/// This interface is implemented by each platform that supports mouse cursor.
///
/// See also:
///
///  * [MouseCursor], whose subclasses and methods use this class to perform
///    operations.
///  * [MouseCursorManager], which takes this class as a parameter.
abstract class MouseCursorPlatformDelegate {
  /// Create a [MouseCursorPlatformDelegate].
  const MouseCursorPlatformDelegate();

  /// Asks the platform to change the cursor of `device` to the system cursor
  /// specified by `systemShape`.
  ///
  /// It resolves to `true` if the operation is successful, `false` if the
  /// operation is unsupported by the platform, or rejects to error if the
  /// operation is implemented but an error occurs.
  Future<bool> activateSystemCursor(MouseCursorPlatformActivateSystemCursorDetails details);
}

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
