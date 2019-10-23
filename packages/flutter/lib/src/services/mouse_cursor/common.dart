// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

/// The kinds of all system cursors supported by Flutter.
///
/// Each value of [SystemMouseCursorShape] corresponds to a [MouseCursor] object
/// in [SystemMouseCursors].
///
/// You should directly use the objects defined in [SystemMouseCursors]
/// when possible instead of using this value to redefine these cursors.
///
/// See also:
///
///  * [SystemMouseCursors], which contains usable [MouseCursor] objects that
///    correspond to values of this type.
///  * [MouseCursorPlatformDelegate], which uses this type to define how
///    system cursors are implemented on platforms.
enum SystemMouseCursorShape {
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

/// Details for [MouseCursor.activate], such as the target device and the
/// platform.
@immutable
class MouseCursorActivateDetails {
  /// Create details for a [MouseCursor.activate] call.
  ///
  /// All parameters must not be null.
  const MouseCursorActivateDetails({
    @required this.device,
    @required this.platformDelegate,
  }) : assert(device != null), assert(platformDelegate != null);

  /// The pointer device that should change cursor.
  final int device;

  /// The delegate of the platform that the program is currently running on,
  /// with which the cursor can perform operations related to mouse cursor.
  final MouseCursorPlatformDelegate platformDelegate;
}

/// An interface for mouse cursor definitions.
///
/// A [MouseCursor] object is a stateless definition of a kind of mouse cursor
/// to be used as a parameter of widgets.
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

  /// Change a pointer device to this cursor based on the information provided
  /// by `details`.
  ///
  /// The `details` contains the target device and the platform delegate. The
  /// cursor can control the platform using `delegate.platformDelegate`.
  ///
  /// This method resolves to `true` if the operation is successful, `false` if
  /// the operation is unsupported by the platform, or rejects to error if the
  /// operation is implemented but an error occurs.
  ///
  /// This method is called by [MouseTracker] when a mouse pointer enters a
  /// region that is assigned with this mouse cursor.
  Future<bool> activate(MouseCursorActivateDetails details);

  /// A platform-independent short description for this cursor.
  ///
  /// It is usually one or several readable words.
  String describeCursor();

  @override
  String toString() {
    return '$runtimeType(${describeCursor()})';
  }
}

/// A mouse cursor that does nothing when activated.
///
/// See also:
///
///  * [SystemMouseCursors.releaseControl], which is an object of this cursor.
class NoopMouseCursor extends MouseCursor {
  /// Create a [NoopMouseCursor].
  const NoopMouseCursor();

  /// Does nothing and immediately returns true.
  @override
  Future<bool> activate(MouseCursorActivateDetails details) async {
    return true;
  }

  @override
  String describeCursor() => 'noop';
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
    @required this.shape,
  }) : assert(device != null), assert(shape != null);

  /// The pointer device that should change cursor.
  final int device;

  /// The kind of system cursor that should change to.
  final SystemMouseCursorShape shape;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != MouseCursorPlatformActivateSystemCursorDetails)
      return false;
    final MouseCursorPlatformActivateSystemCursorDetails typed = other;
    return typed.device == device && typed.shape == shape;
  }

  @override
  int get hashCode => hashValues(device, shape);

  @override
  String toString() {
    return '$runtimeType(device: $device, shape: $shape)';
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
  /// specified by `shape`.
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
