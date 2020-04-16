// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';

import 'mouse_tracking.dart';

/// An interface for mouse cursor definitions.
///
/// A mouse cursor is a graphical image on the screen that echoes the movement
/// of a pointing device, such as a mouse or a stylus. A [MouseCursor] object
/// defines a kind of mouse cursor, such as an arrow, a pointing hand, or an
/// I-beam.
///
/// Internally, when the mouse pointer moves, it finds the front-most region
/// associated with a mouse cursor. The cursor of the pointer changes if the
/// MouseRegion it is currently hovering over has a different mouse cursor
/// specified than the one that's currently active. If no cursors are associated
/// with a position, it defaults to [SystemMouseCursors.basic].
///
/// A [MouseCursor] object may contain the full resources, ready to be consumed
/// by the system (in which case it should subclass [PreparedMouseCursor]), or it
/// might contain a full specification and need to collect resources before being
/// converted to a [PreparedMouseCursor].
///
/// ## Cursor classes
///
/// A [SystemMouseCursor] is a prepared cursor that is natively supported by the
/// platform that the program is running on, and is the most common kind of
/// cursor. All supported system mouse cursors are enumerated in
/// [SystemMouseCursors].
///
/// A [NoopMouseCursor] ia a a prepared cursor that keeps the current cursor when
/// activated. It is useful in special cases such as a platform view where the
/// mouse cursor is managed by other means. Its singleton instance is available
/// at [SystemMouseCursors.uncontrolled].
///
/// ## Using cursors
///
/// A [MouseCursor] object is used by being assigned to a [MouseRegion]. Many
/// other widgets that use [MouseRegion] also expose its API, such as
/// [InkWell.mouseCursor].
///
/// {@tool snippet --template=stateless_widget_material}
/// This sample creates a rectangular region that is wrapped by a [MouseRegion]
/// with a system mouse cursor. The mouse pointer becomes an I-beam when
/// hovering over the region.
///
/// ```dart imports
/// import 'package:flutter/widgets.dart';
/// import 'package:flutter/gestures.dart';
/// ```
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Center(
///     child: MouseRegion(
///       cursor: SystemMouseCursors.text,
///       child: Container(
///         width: 200,
///         height: 100,
///         decoration: BoxDecoration(
///           color: Colors.blue,
///           border: Border.all(color: Colors.yellow),
///         ),
///       ),
///     ),
///   );
/// }
/// ```
/// {@end-tool}
///
/// Assigning regions with mouse cursors on platforms that do not support mouse
/// cursors, or when there are no mice connected, will have no effect.
///
/// ## Related classes
///
/// The following classes are designed to be created and used by the framework,
/// therefore should not be directly used by widgets.
///
/// [MouseTrackerCursorMixin] is a class that manages states, and dispatches
/// specific operations based on general mouse device updates.
///
/// [MouseCursorController] implements low-level imperative control by directly
/// talking to the platform.
///
/// See also:
///
///  * [MouseRegion], a widget used to associate a [MouseCursor] with a region.
///  * [MouseTracker], a class that determines the cursor that each device should
///    show, and dispatches the changing callbacks.
///  * [SystemMouseCursors], a class that enumerates supported system cursors.
@immutable
abstract class MouseCursor with Diagnosticable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MouseCursor();

  /// A very short description of the mouse cursor.
  ///
  /// The [debugDescription] shoule be a few words that can differentiate
  /// instances of a class to make debug information more readable. For example,
  /// a [SystemMouseCursor] class with description "drag" will be printed as
  /// "SystemMouseCursor(drag)".
  ///
  /// The [debugDescription] must not be null, but can be an empty string.
  String get debugDescription;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final String debugDescription = this.debugDescription;
    if (minLevel.index >= DiagnosticLevel.info.index && debugDescription != null)
      return '$runtimeType($debugDescription)';
    return super.toString(minLevel: minLevel);
  }
}

/// An interface for mouse cursors that have all resources prepared and ready to
/// be used by the operating system.
///
/// Although [PreparedMouseCursor] adds no changes on top of [MouseCursor], this
/// class is designed to prevent unprepared cursor types from accessing methods
/// that directly talk to the system.
abstract class PreparedMouseCursor extends MouseCursor {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PreparedMouseCursor();
}

/// A mouse cursor that does nothing when activated.
///
/// The singleton instance of this class is available at
/// [SystemMouseCursors.uncontrolled], which also introduces its usage.
/// Directly instantiating this class is not allowed.
class NoopMouseCursor extends PreparedMouseCursor {
  // Application code shouldn't directly instantiate this class, since its only
  // instance is accessible at [SystemMouseCursors.releaseControl].
  const NoopMouseCursor._();

  @override
  String get debugDescription => '';
}

/// A mouse cursor that is standard on the platform that the application is
/// running on.
///
/// System cursors are the most commonly used cursors, since they are available
/// without external resources and match the experience of native apps. Examples
/// of system cursors are a pointing arrow, a pointing hand, a double arrow for
/// resizing, or a text I-beam, etc.
/// 
/// An instance of [SystemMouseCursor] refers to one cursor from each platform
/// that represents the same concept, such as being text text, being clickable,
/// or being a forbidden operation. Since the set of system cursors supported by
/// each platform varies, multiple instances can correspond to the same system
/// cursor.
///
/// [SystemMouseCursors] enumerates the complete set of system cursors supported
/// by Flutter, which are hard-coded in the engine. Therefore, manually
/// instantiating this class is not supported.
class SystemMouseCursor extends PreparedMouseCursor {
  // Application code shouldn't directly instantiate system mouse cursors, since
  // the supported system cursors are enumerated in [SystemMouseCursors].
  const SystemMouseCursor._({
    @required this.shapeCode,
    @required this.debugDescription,
  }) : assert(shapeCode != null),
       assert(debugDescription != null);

  /// A globally unique number that identifies the shape of the cursor.
  ///
  /// A [shapeCode] is an opaque, platform-dependent value.
  ///
  /// See the documentation of [SystemMouseCursor] for introduction.
  final int shapeCode;

  @override
  final String debugDescription;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is SystemMouseCursor
        && other.shapeCode == shapeCode;
  }

  @override
  int get hashCode => shapeCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(IntProperty('shapeCode', shapeCode, level: DiagnosticLevel.debug));
  }
}

/// A collection of system [MouseCursor]s.
///
/// System cursors are standard mouse cursors that are provided by the current
/// platform. They don't require external resources.
///
/// [SystemMouseCursors] is a superset of the system cursors of every platform
/// that Flutter supports, therefore some of these objects might map to the same
/// result, or fallback to the basic arrow. This mapping is defined by the
/// Flutter engine.
/// 
/// The cursor names are chosen to reflect the cursors' use cases instead of
/// their shapes, because different platforms might (although not commonly) use
/// different shapes for the same use case.
class SystemMouseCursors {
  // This class only contains static members, and should not be instantiated or
  // extended.
  factory SystemMouseCursors._() => null;

  /// A special value that tells Flutter to release the control of cursors.
  ///
  /// A region with this value will absorb the mouse cursor hit test without
  /// changing the pointer's cursor when it enters or is hovering over this
  /// region.
  ///
  /// This value is typically used on a platform view, which detects pointer
  /// movement and changes cursors in a non-Flutter way.
  static const NoopMouseCursor uncontrolled = NoopMouseCursor._();

  // The `shapeCode` values are chosen as the first 6 bytes of the MD5 hash of the
  // cursor's name at the time of creation. The reason for the 6-byte limit
  // is because JavaScript only supports 54 bits of integer.
  //
  // The `shapeCode` values must be kept in sync with the engine implementations.

  /// Hide the cursor.
  static const SystemMouseCursor none = SystemMouseCursor._(shapeCode: 0x334c4a, debugDescription: 'none');

  /// The platform-dependent basic cursor.
  ///
  /// Typically the shape of an arrow.
  static const SystemMouseCursor basic = SystemMouseCursor._(shapeCode: 0xf17aaa, debugDescription: 'basic');

  /// A cursor that indicates a user interface element that is clickable, such as a hyperlink.
  ///
  /// Typically the shape of a pointing hand.
  static const SystemMouseCursor click = SystemMouseCursor._(shapeCode: 0xa8affc, debugDescription: 'click');

  /// A cursor that indicates selectable text.
  ///
  /// Typically the shape of a capital I.
  static const SystemMouseCursor text = SystemMouseCursor._(shapeCode: 0x1cb251, debugDescription: 'text');

  /// A cursor that indicates a forbidden action.
  ///
  /// Typically the shape of a circle with a diagnal line.
  static const SystemMouseCursor forbidden = SystemMouseCursor._(shapeCode: 0x350f9d, debugDescription: 'forbidden');

  /// A cursor that indicates something that can be dragged.
  ///
  /// Typically the shape of an open hand.
  static const SystemMouseCursor grab = SystemMouseCursor._(shapeCode: 0x28b91f, debugDescription: 'grab');

  /// A cursor that indicates something that is being dragged.
  ///
  /// Typically the shape of a closed hand.
  static const SystemMouseCursor grabbing = SystemMouseCursor._(shapeCode: 0x6631ce, debugDescription: 'grabbing');
}
