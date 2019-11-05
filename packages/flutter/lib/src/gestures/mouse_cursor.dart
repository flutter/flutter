// Copyright 2019 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show hashValues;

import 'package:flutter/foundation.dart';

/// Details for [MouseCursorPlatform.activateShape], such as the target device
/// and the cursor shape.
@immutable
class MouseCursorActivateShapeDetails {
  /// Create details for a [MouseCursorPlatform.activateShape] call.
  ///
  /// All parameters must not be null.
  const MouseCursorActivateShapeDetails({
    @required this.device,
    @required this.shape,
  }) : assert(device != null), assert(shape != null);

  /// The pointer device that should change cursor.
  final int device;

  /// The kind of cursor shape that the device should change to.
  final int shape;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    final MouseCursorActivateShapeDetails typed = other;
    return typed.device == device && typed.shape == shape;
  }

  @override
  int get hashCode => hashValues(device, shape);

  @override
  String toString() {
    return '$runtimeType(device: $device, shape: $shape)';
  }
}

/// An interface consists of actions that can be called to manipulate mouse
/// cursor on the current platform.
///
/// See also:
///
///  * [MouseCursor], whose subclasses and methods use this class to perform
///    operations.
///  * [StandardMouseCursorPlatform], which is the standard implementation used
///    by the framework, and uses a method channel to talk to the platform.
///  * [MouseCursorManager], which takes this class as a parameter.
abstract class MouseCursorPlatform {
  /// Create a [MouseCursorPlatform].
  const MouseCursorPlatform();

  /// Request the platform to change the cursor of `details.device` to the shape
  /// specified by `details.shape`.
  ///
  /// {@template flutter.mouseCursor.shape}
  /// A mouse cursor shape is a platform-independent integer, used as a unique
  /// identifier for a kind of mouse cursor, such as "open hand" or "waiting
  /// hourglass". Its value does not have any meaning, often a result of some
  /// kind of hashing, and is used by [MouseCursorPlatform] by passing it to the
  /// platform as-is.
  /// {@endtemplate}
  ///
  /// The method resolves to true if the operation is successful, false if the
  /// operation is unsupported by the platform, or rejects to an error if the
  /// operation is implemented but an error occurs.
  Future<bool> activateShape(MouseCursorActivateShapeDetails details);
}

/// Details to activate a mouse cursor in [MouseCursor.activate], such as the
/// target device and the platform.
@immutable
class MouseCursorActivateDetails {
  /// Create details for a [MouseCursor.activate] call.
  ///
  /// All parameters must not be null.
  const MouseCursorActivateDetails({
    @required this.device,
    @required this.platform,
  }) : assert(device != null), assert(platform != null);

  /// The pointer device that should change cursor.
  final int device;

  /// A set of actions that can be called to manipulate mouse cursor on the
  /// current platform.
  final MouseCursorPlatform platform;
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

/// A mouse cursor whose [MouseCursor.activate] method does nothing and returns
/// true.
///
/// See also:
///
///  * [SystemMouseCursors.releaseControl], which is an object of this cursor.
@immutable
class NoopMouseCursor extends MouseCursor {
  /// Create a [NoopMouseCursor].
  const NoopMouseCursor();

  @override
  Future<bool> activate(MouseCursorActivateDetails details) async {
    return true;
  }

  @override
  String describeCursor() => 'noop';
}

/// A mouse cursor specified with a constant shape.
///
/// {@macro flutter.mouseCursor.shape}
///
/// See also:
///
///  * [SystemMouseCursors], which lists all system mouse cursors.
@immutable
class ConstantMouseCursor extends MouseCursor {
  /// Create a [ConstantMouseCursor] by providing the shape and a short
  /// description of the cursor.
  ///
  /// All arguments must not be null.
  const ConstantMouseCursor(this.shape, this.description)
    : assert(shape != null), assert(description != null);

  /// The cursor shape that this cursor will change a device into.
  final int shape;

  /// A short description of this cursor. Usually one or several words.
  ///
  /// The [describeCursor] method returns this value as a result.
  final String description;

  @override
  Future<bool> activate(MouseCursorActivateDetails details) {
    return details.platform.activateShape(
      MouseCursorActivateShapeDetails(
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

/// A manager that maintains states related to mouse cursor and provides a
/// simple interface to operate [MouseCursor]s.
///
/// This class is used by [MouseTracker], and should not be called directly by
/// widgets. Widgets that want to programmatically set cursors should assign
/// [MouseCursor]s to regions using [MouseRegion] or related tools.
///
/// See also:
///
///  * [MouseCursor], which talks more about handling mouse cursors.
///  * [MouseRegion], which is the idiomatic way of assigning mouse cursors
///    to regions.
///  * [MouseTracker], which uses this class.
class MouseCursorManager {
  /// Create a MouseCursorManager by providing the platform delegate.
  ///
  /// The `platform` defines how operations will be handled, is later passed to
  /// [MouseCursor], and must not be null. It is usually an instance of
  /// [StandardMouseCursorPlatform].
  MouseCursorManager({@required this.platform}) : assert(platform != null);

  /// The delegate of the platform that this manager operates.
  ///
  /// It is provided to [MouseCursor] to perform platform operations.
  final MouseCursorPlatform platform;

  /// Set the cursor of pointer `device` to `cursor`.
  ///
  /// This method handles states or fallbacks.
  ///
  /// This method resolves if the operation is successful, or throws errors if
  /// any occur.
  Future<void> setDeviceCursor(int device, MouseCursor cursor) async {
    final MouseCursorActivateDetails details = MouseCursorActivateDetails(
      device: device,
      platform: platform,
    );
    final bool implemented = await cursor.activate(details);
    if (!implemented) {
      final bool basicImplemented = await SystemMouseCursors.basic.activate(details);
      assert(basicImplemented);
    }
  }
}

/// A collection of system [MouseCursor]s.
///
/// System cursors are mouse cursors that are included in a platform, available
/// without external resources. [SystemMouseCursors] is a superset of the system
/// cursors of every platform that Flutter supports. A cursor that is not
/// implemented on a platform will fallback to some other cursor or the basic
/// cursor depending on the implementation of the Flutter engine on the platform.
class SystemMouseCursors {
  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A layer with this value will absorb the search for mouse cursor
  /// configuration, but the pointer's cursor will not be changed when it enters
  /// or is hovering this layer. This value is typically used on a platform view
  /// or other layers that manages the cursor by itself.
  static const MouseCursor releaseControl = NoopMouseCursor();

  // The shape of Flutter's system cursors are chosen as the first 8 bytes of
  // the MD5 hash of the cursor's name at the time it is created.

  /// Displays no cursor at the pointer.
  static const MouseCursor none = ConstantMouseCursor(0x334c4a4c, 'none');

  /// The platform-dependent basic cursor. Typically the shape of an arrow.
  ///
  /// This cursor is the fallback of unimplemented cursors, and guarantees to
  /// be implemented by all platforms.
  static const MouseCursor basic = ConstantMouseCursor(0xf17aaabc, 'basic');

  /// A cursor that indicates links or something that needs to be emphasized
  /// to be clickable.
  ///
  /// Typically the shape of a pointing hand.
  static const MouseCursor click = ConstantMouseCursor(0xa8affc08, 'click');

  /// A cursor that indicates a selectable text.
  ///
  /// Typically the shape of a capital I.
  static const MouseCursor text = ConstantMouseCursor(0x1cb251ec, 'text');

  /// A cursor that indicates an unpermitted action.
  ///
  /// Typically the shape of a circle with a diagnal line.
  static const MouseCursor forbidden = ConstantMouseCursor(0x350f9d68, 'forbidden');

  /// A cursor that indicates something that can be dragged.
  ///
  /// Typically the shape of an open hand.
  static const MouseCursor grab = ConstantMouseCursor(0x28b91f80, 'grab');

  /// A cursor that indicates something that is being dragged.
  ///
  /// Typically the shape of a closed hand.
  static const MouseCursor grabbing = ConstantMouseCursor(0x6631ce3e, 'grabbing');
}
