// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection' show LinkedHashSet;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

import 'mouse_tracking.dart';

class _MouseCursorState {
  MouseTrackerAnnotation currentAnnotation;
  VoidCallback onCursorChange;
}

class _FallbackAnnotation with Diagnosticable implements MouseTrackerAnnotation {
  const _FallbackAnnotation();

  @override
  PointerEnterEventListener get onEnter => null;
  @override
  PointerHoverEventListener get onHover => null;
  @override
  PointerExitEventListener get onExit => null;
  @override
  PreparedMouseCursor get cursor => SystemMouseCursors.basic;
  @override
  void addCursorListener(VoidCallback listener) { }
  @override
  void removeCursorListener(VoidCallback listener) { }
}

/// A mixin for [BaseMouseTracker] that sets the mouse pointer's cursors
/// on device update.
///
/// See also:
///
///  * [MouseTracker], which uses this mixin.
mixin MouseTrackerCursorMixin on BaseMouseTracker {
  /// Returns the active mouse cursor of a device.
  ///
  /// The return value is the last [PreparedMouseCursor] activated onto this
  /// device, even if the activation failed.
  ///
  /// Only valid when asserts are enabled. In release builds, always returns
  /// null.
  @visibleForTesting
  PreparedMouseCursor debugDeviceActiveCursor(int device) {
    PreparedMouseCursor result;
    assert(() {
      result = _mouseCursorStates[device]?.currentAnnotation?.cursor;
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

  final Map<int, _MouseCursorState> _mouseCursorStates = <int, _MouseCursorState>{};

  // Find the mouse cursor, which fallbacks to _fallbackAnnotation.
  // The `annotations` is the current annotations that the device is
  // hovering in visual order from front the back.
  // The return value is never null.
  MouseTrackerAnnotation _findCursorAnnotation(LinkedHashSet<MouseTrackerAnnotation> annotations) {
    MouseTrackerAnnotation result;
    for (final MouseTrackerAnnotation annotation in annotations) {
      if (annotation.cursor != null) {
        result = annotation;
        break;
      }
    }
    return result ?? const _FallbackAnnotation();
  }

  // Handles device update and changes mouse cursors.
  void _handleDeviceUpdateMouseCursor(MouseTrackerUpdateDetails details) {
    final int device = details.device;

    if (details.triggeringEvent is PointerRemovedEvent) {
      _mouseCursorStates.remove(device);
      return;
    }

    final bool hadState = _mouseCursorStates.containsKey(device);
    _mouseCursorStates.putIfAbsent(device, () {
      final _MouseCursorState state = _MouseCursorState();
      state.onCursorChange = () {
        assert(state.currentAnnotation?.cursor != null);
        state.currentAnnotation.cursor._activate(device);
      };
      return state;
    });

    final _MouseCursorState state = _mouseCursorStates[device];
    final MouseTrackerAnnotation lastAnnotation = state.currentAnnotation;
    assert(lastAnnotation != null || !hadState);
    final MouseTrackerAnnotation nextAnnotation = _findCursorAnnotation(details.nextAnnotations);
    if (lastAnnotation == nextAnnotation)
      return;

    lastAnnotation?.removeCursorListener(state.onCursorChange);
    state.currentAnnotation = nextAnnotation;
    nextAnnotation.addCursorListener(state.onCursorChange);

    final PreparedMouseCursor lastCursor = lastAnnotation?.cursor;
    final PreparedMouseCursor nextCursor = nextAnnotation.cursor;
    if (nextCursor != lastCursor) {
      state.onCursorChange();
    }
  }
}

/// Imperative methods that talk to the platform and controls mouse cursors.
///
/// This class is usually used by [PreparedMouseCursor], and should not be used
/// by widgets or render objects.
class MouseCursorController {
  // This class is not meant to be instatiated or extended; this constructor
  // prevents instantiation and extension.
  MouseCursorController._();

  static MethodChannel get _channel => SystemChannels.mouseCursor;

  /// Request the platform to change the cursor of `device` to the system mouse
  /// cursor specified by `shapeCode`.
  ///
  /// All arguments are required, and must not be null.
  ///
  /// The returned future completes after the request is completed by the
  /// platform. It completes with an error if any errors are thrown from the
  /// platform. If the `shapeCode` is invalid, it is equivalent to setting
  /// the cursor to [SystemMouseCursors.basic].
  ///
  /// See also:
  ///
  ///  * [SystemMouseCursor], which explains system mouse cursors and shapes,
  ///    and uses this method.
  static Future<void> activateSystemCursor({
    @required int device,
    @required int shapeCode,
  }) {
    assert(device != null);
    assert(shapeCode != null);
    return _channel.invokeMethod<void>(
      'activateSystemCursor',
      <String, dynamic>{
        'device': device,
        'shapeCode': shapeCode,
      },
    );
  }
}

/// An interface for mouse cursor definitions.
///
/// A mouse cursor is a graphical image on the screen that echoes the movement
/// of a pointing device, such as a mouse or a stylus. A [MouseCursor] object
/// defines a kind of mouse cursor, such as an arrow, a pointing hand, or an
/// I-beam.
///
/// A [MouseCursor] object may, but not necessarily, contain the full resources
/// to be consumed by the system. If it does, it is a subclass to
/// [PreparedMouseCursor], and can be directly used by render objects and 
/// annotations. Otherwise, it only contains a full specification and need to
/// be prepared (to collect resources) and converted to a [PreparedMouseCursor],
/// which is done by [MouseRegion] the first time a pointer hovers over.
///
/// During the painting phase, [MouseCursor] objects are assigned to regions on
/// the screen via annotaions. Later during a device update (e.g. when a mouse
/// moves), [MouseTracker] finds the _active cursor_ of each mouse device, which
/// is the front-most region associated with the position of each mouse cursor,
/// or defaults to [SystemMouseCursors.basic] if no cursors are associated with
/// the position. [MouseTracker] changes the cursor of the pointer if the new
/// active cursor is different from the previous active cursor, whose effect is
/// defined by [PreparedMouseCursor.performActivate].
///
/// ## Cursor classes
///
/// A [SystemMouseCursor] is a prepared cursor that is natively supported by the
/// platform that the program is running on. All supported system mouse cursors
/// are enumerated in [SystemMouseCursors].
///
/// A [NoopMouseCursor] ia a a prepared cursor that keeps the current cursor when
/// activated. It is useful in special cases such as a platform view where the
/// mouse cursor is managed by other means, and wishes to block widgets behind it
/// from overwriting the cursor changes. Its singleton instance is available at
/// [SystemMouseCursors.uncontrolled].
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
/// To assign mouse cursors to render objects or annoations, the cursor must 
/// have been prepared, i.e. it must be a subclass to [PreparedMouseCursor].
///
/// ## Related classes
///
/// [MouseCursorController] implements low-level imperative control by directly
/// talking to the platform. It can be called by [MouseCursor]s, but should not
/// be directly used by widgets or render objects.
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
/// Subclasses of [PreparedMouseCursor] should override [performActivate] and
/// define the effect of setting a pointer to this cursor, which usually invoves
/// calling the methods from [MouseCursorController].
///
/// [PreparedMouseCursor] can be assigned to more places than [MouseCursor].
/// Besides widgets, it can also be assigned to a [RenderObject], such as
/// [RenderMouseRegion], or be assigned to [MouseTrackerAnnotation] if you want
/// to directly handle annoations.
abstract class PreparedMouseCursor extends MouseCursor {
  /// Abstract const constructor. This constructor enables subclasses to provide
  /// const constructors so that they can be used in const expressions.
  const PreparedMouseCursor();

  Future<void> _activate(int device) {
    return performActivate(device);
  }

  /// Do the work of applying this cursor to a pointing device.
  ///
  /// Do not call this function directly: assign this cursor object to a region
  /// instead (as described in the documentation of [PreparedMouseCursor]). This
  /// function is called by [MouseTracker] during a device update where a pointer
  /// enters the region.
  ///
  /// In implementing this function, you should call methods of
  /// [MouseCursorController] to send requests to the platform.
  @protected
  Future<void> performActivate(int device);
}

/// A mouse cursor that doesn't change the cursor when activated.
///
/// Although setting a region's cursor to [NoopMouseCursor] doesn't change the
/// cursor, it blocks regions behind it from changing the cursor, in contrast to
/// setting the cursor to null. More information about the usage of this class
/// can be found at [SystemMouseCursors.uncontrolled].
///
/// To use this class, use [SystemMouseCursors.uncontrolled]. Directly
/// instantiating this class is not allowed.
class NoopMouseCursor extends PreparedMouseCursor {
  // Application code shouldn't directly instantiate this class, since its only
  // instance is accessible at [SystemMouseCursors.releaseControl].
  const NoopMouseCursor._();

  @override
  @protected
  Future<void> performActivate(int device) async {
  }

  @override
  String get debugDescription => '';
}

/// A mouse cursor that is standard on the platform that the application is
/// running on.
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
  @protected
  Future<void> performActivate(int device) async {
    MouseCursorController.activateSystemCursor(
      shapeCode: shapeCode,
      device: device,
    );
  }

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
  static const NoopMouseCursor uncontrolled = NoopMouseCursor._();

  // The `shapeCode` values are chosen as the first 6 bytes of the MD5 hash of the
  // cursor's name at the time of creation. The reason for the 6-byte limit
  // is because JavaScript only supports 54 bits of integer.
  //
  // The `shapeCode` values must be kept in sync with the engine implementations.

  /// Hide the cursor.
  ///
  /// Any cursor other than [none] or [uncontrolled] unhides the cursor.
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
