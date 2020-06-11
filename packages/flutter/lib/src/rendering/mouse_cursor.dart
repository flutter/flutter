// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'dart:async';
import 'dart:collection' show LinkedHashSet;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'mouse_tracking.dart';

/// A mixin for [BaseMouseTracker] that sets the mouse pointer's cursors
/// on device update.
///
/// See also:
///
///  * [MouseTracker], which uses this mixin.
mixin MouseTrackerCursorMixin on BaseMouseTracker {
  /// Returns the active mouse cursor of a device.
  ///
  /// The return value is the last [MouseCursor] activated onto this
  /// device, even if the activation failed.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  @visibleForTesting
  MouseCursor debugDeviceActiveCursor(int device) {
    MouseCursor result;
    assert(() {
      result = _lastSession[device]?.cursor;
      return true;
    }());
    return result;
  }

  @protected
  @override
  void handleDeviceUpdate(MouseTrackerUpdateDetails details) {
    super.handleDeviceUpdate(details);
    _handleDeviceUpdateMouseCursor(details);
  }

  final Map<int, MouseCursorSession> _lastSession = <int, MouseCursorSession>{};

  // Find the first non-deferred mouse cursor, which fallbacks to
  // [SystemMouseCursors.basic].
  //
  // The `annotations` is the current annotations that the device is hovering in
  // visual order from front the back.
  // The return value is never null.
  MouseCursor _findFirstCursor(LinkedHashSet<MouseTrackerAnnotation> annotations) {
    return _DeferringMouseCursor.firstNonDeferred(
      annotations.map((MouseTrackerAnnotation annotation) => annotation.cursor),
    ) ?? SystemMouseCursors.basic;
  }

  // Handles device update and changes mouse cursors.
  void _handleDeviceUpdateMouseCursor(MouseTrackerUpdateDetails details) {
    final int device = details.device;

    if (details.triggeringEvent is PointerRemovedEvent) {
      _lastSession.remove(device);
      return;
    }

    final MouseCursorSession lastSession = _lastSession[device];
    final MouseCursor nextCursor = _findFirstCursor(details.nextAnnotations);
    if (lastSession?.cursor == nextCursor)
      return;

    final MouseCursorSession nextSession = nextCursor.createSession(device);
    _lastSession[device] = nextSession;

    lastSession?.dispose();
    nextSession.activate();
  }
}

/// Manages the duration that a pointing device should display a specific mouse
/// cursor.
///
/// While [MouseCursor] classes describe the kind of cursors, [MouseCursorSession]
/// classes represents a continuous use of the cursor on a pointing device. The
/// [MouseCursorSession] classes can be stateful. For example, a cursor that
/// needs to load resources might want to set a temporary cursor first, then
/// switch to the correct cursor after the load is completed.
///
/// A [MouseCursorSession] has the following lifecycle:
///
///  * When a pointing device should start displaying a cursor, [MouseTracker]
///    creates a session by calling [MouseCursor.createSession] on the target
///    cursor, and stores it in a table associated with the device.
///  * [MouseTracker] then immediately calls the session's [activate], where the
///    session should fetch resources and make system calls.
///  * When the pointing device should start displaying a different cursor,
///    [MouseTracker] calls [dispose] on this session. After [dispose], this session
///    will no longer be used in the future.
abstract class MouseCursorSession {
  /// Create a session.
  ///
  /// All arguments must be non-null.
  MouseCursorSession(this.cursor, this.device)
    : assert(cursor != null),
      assert(device != null);

  /// The cursor that created this session.
  final MouseCursor cursor;

  /// The device ID of the pointing device.
  final int device;

  /// Override this method to do the work of changing the cursor of the device.
  ///
  /// Called right after this session is created.
  ///
  /// This method has full control over the cursor until the [dispose] call, and
  /// can make system calls to change the pointer cursor as many times as
  /// necessary (usually through [SystemChannels.mouseCursor]). It can also
  /// collect resources, and store the result in this object.
  @protected
  Future<void> activate();

  /// Called when device stops displaying the cursor.
  ///
  /// After this call, this session instance will no longer be used in the
  /// future.
  ///
  /// When implementing this method in subclasses, you should release resources
  /// and prevent [activate] from causing side effects after disposal.
  @protected
  void dispose();
}

/// An interface for mouse cursor definitions.
///
/// A mouse cursor is a graphical image on the screen that echoes the movement
/// of a pointing device, such as a mouse or a stylus. A [MouseCursor] object
/// defines a kind of mouse cursor, such as an arrow, a pointing hand, or an
/// I-beam.
///
/// During the painting phase, [MouseCursor] objects are assigned to regions on
/// the screen via annotations. Later during a device update (e.g. when a mouse
/// moves), [MouseTracker] finds the _active cursor_ of each mouse device, which
/// is the front-most region associated with the position of each mouse cursor,
/// or defaults to [SystemMouseCursors.basic] if no cursors are associated with
/// the position. [MouseTracker] changes the cursor of the pointer if the new
/// active cursor is different from the previous active cursor, whose effect is
/// defined by the session created by [createSession].
///
/// ## Cursor classes
///
/// A [SystemMouseCursor] is a cursor that is natively supported by the
/// platform that the program is running on. All supported system mouse cursors
/// are enumerated in [SystemMouseCursors].
///
/// ## Using cursors
///
/// A [MouseCursor] object is used by being assigned to a [MouseRegion] or
/// another widget that exposes the [MouseRegion] API, such as
/// [InkWell.mouseCursor].
///
/// {@tool snippet --template=stateless_widget_material}
/// This sample creates a rectangular region that is wrapped by a [MouseRegion]
/// with a system mouse cursor. The mouse pointer becomes an I-beam when
/// hovering over the region.
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
/// [MouseCursorSession] represents the duration when a pointing device displays
/// a cursor, and defines the states and behaviors of the cursor. Every mouse
/// cursor class usually has a corresponding [MouseCursorSession] class.
///
/// [MouseTrackerCursorMixin] is a mixin that adds the feature of changing
/// cursors to [BaseMouseTracker], which tracks the relationship between mouse
/// devices and annotations. [MouseTrackerCursorMixin] is usually used as a part
/// of [MouseTracker].
@immutable
abstract class MouseCursor with Diagnosticable {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const MouseCursor();

  /// Associate a pointing device to this cursor.
  ///
  /// A mouse cursor class usually has a corresponding [MouseCursorSession]
  /// class, and instantiates such class in this method.
  ///
  /// This method is called each time a pointing device starts displaying this
  /// cursor. A given cursor can be displayed by multiple devices at the same
  /// time, in which case this method will be called separately for each device.
  @protected
  @factory
  MouseCursorSession createSession(int device);

  /// A very short description of the mouse cursor.
  ///
  /// The [debugDescription] should be a few words that can describe this cursor
  /// to make debug information more readable. It is returned as the [toString]
  /// when the diagnostic level is at or above [DiagnosticLevel.info].
  ///
  /// The [debugDescription] must not be null or empty string.
  String get debugDescription;

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    final String debugDescription = this.debugDescription;
    if (minLevel.index >= DiagnosticLevel.info.index && debugDescription != null)
      return debugDescription;
    return super.toString(minLevel: minLevel);
  }

  /// A special class that indicates that the region with this cursor defers the
  /// choice of cursor to the next region behind it.
  ///
  /// When an event occurs, [MouseTracker] will update each pointer's cursor by
  /// finding the list of regions that contain the pointer's location, from front
  /// to back in hit-test order. The pointer's cursor will be the first cursor in
  /// the list that is not a [MouseCursor.defer].
  static const MouseCursor defer = _DeferringMouseCursor._();

  /// A special value that doesn't change cursor by itself, but make a region
  /// that blocks other regions behind it from changing the cursor.
  ///
  /// When a pointer enters a region with a cursor of [uncontrolled], the pointer
  /// retains its previous cursor and keeps so until it moves out of the region.
  /// Technically, this region absorb the mouse cursor hit test without changing
  /// the pointer's cursor.
  ///
  /// This is useful in a region that displays a platform view, which let the
  /// operating system handle pointer events and change cursors accordingly. To
  /// achieve this, the region's cursor must not be any Flutter cursor, since
  /// that might overwrite the system request upon pointer entering; the cursor
  /// must not be null either, since that allows the widgets behind the region to
  /// change cursors.
  static const MouseCursor uncontrolled = _NoopMouseCursor._();
}

class _DeferringMouseCursor extends MouseCursor {
  const _DeferringMouseCursor._();

  @override
  MouseCursorSession createSession(int device) {
    assert(false, '_DeferringMouseCursor can not create a session');
    throw UnimplementedError();
  }

  @override
  String get debugDescription => 'defer';

  /// Returns the first cursor that is not a [MouseCursor.defer].
  static MouseCursor firstNonDeferred(Iterable<MouseCursor> cursors) {
    for (final MouseCursor cursor in cursors) {
      assert(cursor != null);
      if (cursor != MouseCursor.defer)
        return cursor;
    }
    return null;
  }
}

class _NoopMouseCursorSession extends MouseCursorSession {
  _NoopMouseCursorSession(_NoopMouseCursor cursor, int device)
    : super(cursor, device);

  @override
  Future<void> activate() async { /* Nothing */ }

  @override
  void dispose() { /* Nothing */ }
}

/// A mouse cursor that doesn't change the cursor when activated.
///
/// Although setting a region's cursor to [NoopMouseCursor] doesn't change the
/// cursor, it blocks regions behind it from changing the cursor, in contrast to
/// setting the cursor to null. More information about the usage of this class
/// can be found at [MouseCursors.uncontrolled].
///
/// To use this class, use [MouseCursors.uncontrolled]. Directly
/// instantiating this class is not allowed.
class _NoopMouseCursor extends MouseCursor {
  // Application code shouldn't directly instantiate this class, since its only
  // instance is accessible at [SystemMouseCursors.releaseControl].
  const _NoopMouseCursor._();

  @override
  @protected
  _NoopMouseCursorSession createSession(int device) => _NoopMouseCursorSession(this, device);

  @override
  String get debugDescription => 'uncontrolled';
}

class _SystemMouseCursorSession extends MouseCursorSession {
  _SystemMouseCursorSession(SystemMouseCursor cursor, int device)
    : super(cursor, device);

  @override
  SystemMouseCursor get cursor => super.cursor as SystemMouseCursor;

  @override
  Future<void> activate() {
    return SystemChannels.mouseCursor.invokeMethod<void>(
      'activateSystemCursor',
      <String, dynamic>{
        'device': device,
        'kind': cursor.kind,
      },
    );
  }

  @override
  void dispose() { /* Nothing */ }
}

/// A mouse cursor that is natively supported on the platform that the
/// application is running on.
///
/// System cursors can be used without external resources, and their appearances
/// match the experience of native apps. Examples of system cursors are a
/// pointing arrow, a pointing hand, a double arrow for resizing, or a text
/// I-beam, etc.
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
class SystemMouseCursor extends MouseCursor {
  // Application code shouldn't directly instantiate system mouse cursors, since
  // the supported system cursors are enumerated in [SystemMouseCursors].
  const SystemMouseCursor._({
    @required this.kind,
  }) : assert(kind != null);

  /// A string that identifies the kind of the cursor.
  ///
  /// The interpretation of [kind] is platform-dependent.
  final String kind;

  @override
  String get debugDescription => '$runtimeType($kind)';

  @override
  @protected
  _SystemMouseCursorSession createSession(int device) => _SystemMouseCursorSession(this, device);

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != runtimeType)
      return false;
    return other is SystemMouseCursor
        && other.kind == kind;
  }

  @override
  int get hashCode => kind.hashCode;

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<String>('kind', kind, level: DiagnosticLevel.debug));
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

  /// Hide the cursor.
  ///
  /// Any cursor other than [none] or [uncontrolled] unhides the cursor.
  static const SystemMouseCursor none = SystemMouseCursor._(kind: 'none');

  /// The platform-dependent basic cursor.
  ///
  /// Typically the shape of an arrow.
  static const SystemMouseCursor basic = SystemMouseCursor._(kind: 'basic');

  /// A cursor that indicates a user interface element that is clickable, such as a hyperlink.
  ///
  /// Typically the shape of a pointing hand.
  static const SystemMouseCursor click = SystemMouseCursor._(kind: 'click');

  /// A cursor that indicates selectable text.
  ///
  /// Typically the shape of a capital I.
  static const SystemMouseCursor text = SystemMouseCursor._(kind: 'text');

  /// A cursor that indicates a forbidden action.
  ///
  /// Typically the shape of a circle with a diagonal line.
  static const SystemMouseCursor forbidden = SystemMouseCursor._(kind: 'forbidden');

  /// A cursor that indicates something that can be dragged.
  ///
  /// Typically the shape of an open hand.
  static const SystemMouseCursor grab = SystemMouseCursor._(kind: 'grab');

  /// A cursor that indicates something that is being dragged.
  ///
  /// Typically the shape of a closed hand.
  static const SystemMouseCursor grabbing = SystemMouseCursor._(kind: 'grabbing');
}
