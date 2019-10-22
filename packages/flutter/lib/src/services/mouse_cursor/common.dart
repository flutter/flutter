// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

/// The kinds of all system cursors supported by Flutter.
///
/// Each value of [SystemCursorShape] corresponds to a [MouseCursor] object in
/// [SystemMouseCursors].
///
/// You should directly use the objects defined in [SystemMouseCursors]
/// when possible instead of redefining them on your own.
///
/// See also:
///
///  * [SystemMouseCursors], which contains usable [MouseCursor] objects that
///    correspond to values of [SystemCursorShape].
///  * [SystemMouseCursor], which uses this type.
enum SystemCursorShape {
  /// The shape that corresponds to [SystemCursors.none].
  none,

  /// The shape that corresponds to [SystemCursors.basic].
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

/// Details for [MouseCursor.activate], such as the target device and the
/// platform.
@immutable
class ActivateMouseCursorDetails {
  /// Create details for a [MouseCursor.activate] call.
  ///
  /// All parameters must not be null.
  const ActivateMouseCursorDetails({
    @required this.device,
    @required this.delegate,
  }) : assert(device != null), assert(delegate != null);

  /// The pointer device that should change cursor.
  final int device;

  /// TODOC
  final MouseCursorPlatformDelegate delegate;
}

/// A base class for mouse cursors.
///
/// When a mouse pointer enters a region that is assigned with a mouse cursor,
/// the cursor's [MouseCursor.activate] is called.
///
/// See also:
///
///  * [MouseRegion], which is a common way of assigning a region with a mouse
///    cursor.
///  * [MouseTracker], which determines the cursor that each device should show,
///    and dispatches the changing callbacks.
@immutable
abstract class MouseCursor {
  /// Create a mouse cursor.
  ///
  /// The base constructor does nothing.
  const MouseCursor();

  /// Perform necessary preparations and platform calls that change a device to
  /// this cursor.
  ///
  /// It is called by [MouseTracker] when a mouse pointer enters a region that
  /// is assigned with this mouse cursor.
  Future<void> activate(ActivateMouseCursorDetails details);

  /// A platform-independent short description for this cursor.
  ///
  /// It is usually one or several readable words.
  String describeCursor();

  @override
  String toString() {
    return '$runtimeType(${describeCursor()})';
  }
}

/// A special mouse cursor that does nothing.
class NoopMouseCursor extends MouseCursor {
  /// Create a [NoopMouseCursor].
  const NoopMouseCursor();

  /// This method does nothing and immediately returns.
  @override
  Future<void> activate(ActivateMouseCursorDetails details) async {
    return;
  }

  @override
  String describeCursor() => 'noop';
}

/// TODOC
abstract class MouseCursorPlatformDelegate {
  /// TODOC
  const MouseCursorPlatformDelegate();

  /// TODOC
  /// Returns whether the cursor was successfully set.
  Future<bool> activateSystemCursor(
    ActivateMouseCursorDetails details,
    SystemCursorShape shape,
  );
}

/// TODOC
class MouseCursorUnsupportedDelegate extends MouseCursorPlatformDelegate {
  /// TODOC
  const MouseCursorUnsupportedDelegate();

  @override
  Future<bool> activateSystemCursor(ActivateMouseCursorDetails details, SystemCursorShape shape) async {
    return true;
  }
}
