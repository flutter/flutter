// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:io';
import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

import 'mouse_cursor_android.dart';
import 'mouse_cursor_glfw.dart';
import 'mouse_cursor_macos.dart';
import 'platform_channel.dart';

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
/// A mouse cursor is a graphical image on the screen that echoes the movement
/// of a pointer device, such as a mouse or a stylus. A [MouseCursor] object
/// is a stateless definition of a kind of mouse cursor, such as an arrow,
/// a pointing hand, or an I-beam.
///
/// A [MouseCursor] object is used by being assigned to a region. The most
/// common way of doing so is [MouseRegion], which is wrapped and exposed by
/// many other widgets.
///
/// When a pointer enters a region that is assigned with a [MouseCursor], the
/// cursor's [MouseCursor.activate] is called.
///
/// See also:
///
///  * [MouseRegion], which is a common way of assigning a region with a
///    [MouseCursor].
///  * [MouseTracker], which determines the cursor that each device should show,
///    and dispatches the changing callbacks.
///  * [SystemMouseCursors], which provies many system cursors.
///  * [NoopMouseCursors], which is a special type of mouse cursor that does
///    nothing.
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
@immutable
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

// A mouse cursor based on resources provided by the platform.
//
// See also:
//
//  * [SystemMouseCursors], which lists all system mouse cursors.
@immutable
class _SystemMouseCursor extends MouseCursor {
  const _SystemMouseCursor(this.shape, this.description)
    : assert(shape != null), assert(description != null);

  final SystemMouseCursorShape shape;

  final String description;

  @override
  Future<bool> activate(MouseCursorActivateDetails details) {
    return details.platformDelegate.activateSystemCursor(
      MouseCursorPlatformActivateSystemCursorDetails(
        device: details.device,
        shape: shape,
      ),
    );
  }

  @override
  String describeCursor() {
    return description;
  }
}

// A [_SystemMouseCursor] that guarantees to be implemented.
@immutable
class _EnsuredImplementedSystemMouseCursor extends _SystemMouseCursor {
  const _EnsuredImplementedSystemMouseCursor(
    SystemMouseCursorShape shape,
    String description,
  ) : super(shape, description);

  @override
  Future<bool> activate(MouseCursorActivateDetails details) async {
    final bool implemented = await super.activate(details);
    assert(implemented);
    return implemented;
  }
}

/// A collection of system [MouseCursor]s.
///
/// System cursors are mouse cursors that are included in a platform, available
/// without external resources. [SystemMouseCursors] is a superset of the system
/// cursors of every platform that Flutter supports. A cursor that is
/// unimplemented by a platform will fallback to another cursor or the basic
/// cursor.
class SystemMouseCursors {
  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  static const MouseCursor releaseControl = NoopMouseCursor();

  /// Displays no cursor at the pointer.
  static const MouseCursor none = _SystemMouseCursor(SystemMouseCursorShape.none, 'none');

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  ///
  /// This cursor is the fallback of unimplemented cursors, and guarantees to
  /// be implemented by all platforms.
  static const MouseCursor basic = _EnsuredImplementedSystemMouseCursor(
    SystemMouseCursorShape.basic, 'basic');

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable. Typically the shape of a pointing hand.
  static const MouseCursor click = _SystemMouseCursor(SystemMouseCursorShape.click, 'click');

  /// A cursor that indicates a selectable text. Typically the shape of a
  /// capital I.
  static const MouseCursor text = _SystemMouseCursor(SystemMouseCursorShape.text, 'text');

  /// A cursor that indicates an unpermitted action. Typically the shape of a
  /// circle with a diagnal line.
  static const MouseCursor forbidden = _SystemMouseCursor(SystemMouseCursorShape.forbidden, 'forbidden');

  /// A cursor that indicates something that can be dragged. Typically the shape
  /// of an open hand.
  static const MouseCursor grab = _SystemMouseCursor(SystemMouseCursorShape.grab, 'grab');

  /// A cursor that indicates something that is being dragged. Typically the
  /// shape of a closed hand.
  static const MouseCursor grabbing = _SystemMouseCursor(SystemMouseCursorShape.grabbing, 'grabbing');
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

/// The base class of a manager that maintains states related to mouse cursor
/// and provides a simple interface to operate [MouseCursor]s.
///
/// Widgets should not use [MouseCursorManager] directly, instead they should
/// assign [MouseCursor]s to regions, and then [MouseTracker] will handle cursor
/// changes accordingly.
///
/// See also:
///
///  * [MouseCursor], which talks more about handling mouse cursors.
///  * [StandardMouseCursorManager], which implements the platform-specific
///    code based on the platform that this program is running on.
///  * [MouseTracker], which uses this class.
abstract class MouseCursorManager {
  /// The delegate of the platform that this manager operates.
  ///
  /// It is provided to [MouseCursor] to perform platform operations.
  MouseCursorPlatformDelegate get platformDelegate;

  /// Set the cursor of pointer `device` to `cursor`.
  ///
  /// This method handles states or fallbacks.
  ///
  /// This method resolves if the operation is successful, or throws errors if
  /// any occur.
  Future<void> setDeviceCursor(int device, MouseCursor cursor) async {
    final MouseCursorActivateDetails details = MouseCursorActivateDetails(
      device: device,
      platformDelegate: platformDelegate,
    );
    final bool implemented = await cursor.activate(details);
    if (!implemented) {
      final bool basicImplemented = await SystemMouseCursors.basic.activate(details);
      assert(basicImplemented);
    }
  }
}

/// The [MouseCursorManager] that implements the platform-specific code based on
/// the platform that this program is running on.
///
/// See also:
///
///  * [MouseTracker], which owns an instance of this class.
class StandardMouseCursorManager extends MouseCursorManager {
  /// Create a [MouseCursorManager] by providing the channel.
  ///
  /// The `mouseCursorChannel` is used to create platform delegates, and must
  /// not be null.
  StandardMouseCursorManager(
    MethodChannel mouseCursorChannel,
  ) : assert(mouseCursorChannel != null) {
    _platformDelegate = _createDelegate(mouseCursorChannel);
    assert(_platformDelegate != null);
  }

  @override
  MouseCursorPlatformDelegate get platformDelegate => _platformDelegate;
  MouseCursorPlatformDelegate _platformDelegate;

  MouseCursorPlatformDelegate _createDelegate(MethodChannel channel) {
    if (Platform.isLinux) {
      return MouseCursorGLFWDelegate(mouseCursorChannel: channel);
    } else if (Platform.isAndroid) {
      return MouseCursorAndroidDelegate(mouseCursorChannel: channel);
    } else if (Platform.isMacOS) {
      return MouseCursorMacOSDelegate(mouseCursorChannel: channel);
    } else {
      return const MouseCursorUnsupportedPlatformDelegate();
    }
  }
}
