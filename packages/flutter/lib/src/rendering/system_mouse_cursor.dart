// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

export 'package:flutter/services.dart' show MouseCursor;

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
/// Each cursor is noted with its corresponding native cursors on each platform:
///
///  * Android: API name in Java
///  * Web: CSS cursor
///  * Windows: Win32 API
///  * Linux: GDK, `gdk_cursor_new_from_name`
///  * macOS: API name in Objective C
///
/// If the platform that the application is running on is not listed for a cursor,
/// using this cursor falls back to [SystemMouseCursors.basic].
///
/// [SystemMouseCursors] enumerates the complete set of system cursors supported
/// by Flutter, which are hard-coded in the engine. Therefore, manually
/// instantiating this class is not supported.
class SystemMouseCursor extends MouseCursor {
  // Application code shouldn't directly instantiate system mouse cursors, since
  // the supported system cursors are enumerated in [SystemMouseCursors].
  const SystemMouseCursor._({
    required this.kind,
  }) : assert(kind != null);

  /// A string that identifies the kind of the cursor.
  ///
  /// The interpretation of [kind] is platform-dependent.
  final String kind;

  @override
  String get debugDescription => '${objectRuntimeType(this, 'SystemMouseCursor')}($kind)';

  @override
  @protected
  _SystemMouseCursorSession createSession(int device) => _SystemMouseCursorSession(this, device);

  @override
  bool operator ==(Object other) {
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
/// result, or fallback to the [basic] arrow. This mapping is defined by the
/// Flutter engine.
///
/// The cursors should be named based on the cursors' use cases instead of their
/// appearance, because different platforms might (although not commonly) use
/// different shapes for the same use case.
class SystemMouseCursors {
  // This class only contains static members, and should not be instantiated or
  // extended.
  factory SystemMouseCursors._() => throw Error();

  // The mapping in this class must be kept in sync with the following files in
  // the engine:
  //
  // * Android: shell/platform/android/io/flutter/plugin/mouse/MouseCursorPlugin.java
  // * Web: lib/web_ui/lib/src/engine/mouse_cursor.dart
  // * Windows: shell/platform/windows/win32_flutter_window.cc
  // * Linux: shell/platform/linux/fl_mouse_cursor_plugin.cc
  // * macOS: shell/platform/darwin/macos/framework/Source/FlutterMouseCursorPlugin.mm


  /// Hide the cursor.
  ///
  /// Any cursor other than [none] or [MouseCursor.uncontrolled] unhides the
  /// cursor.
  static const SystemMouseCursor none = SystemMouseCursor._(kind: 'none');


  // STATUS

  /// The platform-dependent basic cursor.
  ///
  /// Typically the shape of an arrow.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_DEFAULT, TYPE_ARROW
  ///  * Web: default
  ///  * Windows: IDC_ARROW
  ///  * Linux: default
  ///  * macOS: arrowCursor
  static const SystemMouseCursor basic = SystemMouseCursor._(kind: 'basic');

  /// A cursor that emphasizes an element being clickable, such as a hyperlink.
  ///
  /// Typically the shape of a pointing hand.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_HAND
  ///  * Web: pointer
  ///  * Windows: IDC_HAND
  ///  * Linux: pointer
  ///  * macOS: pointingHandCursor
  static const SystemMouseCursor click = SystemMouseCursor._(kind: 'click');

  /// A cursor indicating an operation that will not be carried out.
  ///
  /// Typically the shape of a circle with a diagonal line. May fall back to
  /// [noDrop].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_NO_DROP
  ///  * Web: not-allowed
  ///  * Windows: IDC_NO
  ///  * Linux: not-allowed
  ///  * macOS: operationNotAllowedCursor
  ///
  /// See also:
  ///
  ///  * [noDrop], which indicates somewhere that the current item may not be
  ///    dropped.
  static const SystemMouseCursor forbidden = SystemMouseCursor._(kind: 'forbidden');

  /// A cursor indicating the status that the program is busy and therefore
  /// can not be interacted with.
  ///
  /// Typically the shape of an hourglass or a watch.
  ///
  /// This cursor is not available as a system cursor on macOS. Although macOS
  /// displays a "spinning ball" cursor when busy, it's handled by the OS and not
  /// exposed for applications to choose.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_WAIT
  ///  * Windows: IDC_WAIT
  ///  * Web: wait
  ///  * Linux: wait
  ///
  /// See also:
  ///
  ///  * [progress], which is similar to [wait] but the program can still be
  ///    interacted with.
  static const SystemMouseCursor wait = SystemMouseCursor._(kind: 'wait');

  /// A cursor indicating the status that the program is busy but can still be
  /// interacted with.
  ///
  /// Typically the shape of an arrow with an hourglass or a watch at the corner.
  /// Does *not* fall back to [wait] if unavailable.
  ///
  /// Corresponds to:
  ///
  ///  * Web: progress
  ///  * Windows: IDC_APPSTARTING
  ///  * Linux: progress
  ///
  /// See also:
  ///
  ///  * [wait], which is similar to [progress] but the program can not be
  ///    interacted with.
  static const SystemMouseCursor progress = SystemMouseCursor._(kind: 'progress');

  /// A cursor indicating somewhere the user can trigger a context menu.
  ///
  /// Typically the shape of an arrow with a small menu at the corner.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_CONTEXT_MENU
  ///  * Web: context-menu
  ///  * Linux: context-menu
  ///  * macOS: contextualMenuCursor
  static const SystemMouseCursor contextMenu = SystemMouseCursor._(kind: 'contextMenu');

  /// A cursor indicating help information.
  ///
  /// Typically the shape of a question mark, or an arrow therewith.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_HELP
  ///  * Windows: IDC_HELP
  ///  * Web: help
  ///  * Linux: help
  static const SystemMouseCursor help = SystemMouseCursor._(kind: 'help');


  // SELECTION

  /// A cursor indicating selectable text.
  ///
  /// Typically the shape of a capital I.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TEXT
  ///  * Web: text
  ///  * Windows: IDC_IBEAM
  ///  * Linux: text
  ///  * macOS: IBeamCursor
  static const SystemMouseCursor text = SystemMouseCursor._(kind: 'text');

  /// A cursor indicating selectable vertical text.
  ///
  /// Typically the shape of a capital I rotated to be horizontal. May fall back
  /// to [text].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_VERTICAL_TEXT
  ///  * Web: vertical-text
  ///  * Linux: vertical-text
  ///  * macOS: IBeamCursorForVerticalLayout
  static const SystemMouseCursor verticalText = SystemMouseCursor._(kind: 'verticalText');

  /// A cursor indicating selectable table cells.
  ///
  /// Typically the shape of a hollow plus sign.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_CELL
  ///  * Web: cell
  ///  * Linux: cell
  static const SystemMouseCursor cell = SystemMouseCursor._(kind: 'cell');

  /// A cursor indicating precise selection, such as selecting a pixel in a
  /// bitmap.
  ///
  /// Typically the shape of a crosshair.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_CROSSHAIR
  ///  * Web: crosshair
  ///  * Windows: IDC_CROSS
  ///  * Linux: crosshair
  ///  * macOS: crosshairCursor
  static const SystemMouseCursor precise = SystemMouseCursor._(kind: 'precise');


  // DRAG-AND-DROP

  /// A cursor indicating moving something.
  ///
  /// Typically the shape of four-way arrow. May fall back to [allScroll].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_ALL_SCROLL
  ///  * Windows: IDC_SIZEALL
  ///  * Web: move
  ///  * Linux: move
  static const SystemMouseCursor move = SystemMouseCursor._(kind: 'move');

  /// A cursor indicating something that can be dragged.
  ///
  /// Typically the shape of an open hand.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_GRAB
  ///  * Web: grab
  ///  * Linux: grab
  ///  * macOS: openHandCursor
  static const SystemMouseCursor grab = SystemMouseCursor._(kind: 'grab');

  /// A cursor indicating something that is being dragged.
  ///
  /// Typically the shape of a closed hand.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_GRABBING
  ///  * Web: grabbing
  ///  * Linux: grabbing
  ///  * macOS: closedHandCursor
  static const SystemMouseCursor grabbing = SystemMouseCursor._(kind: 'grabbing');

  /// A cursor indicating somewhere that the current item may not be dropped.
  ///
  /// Typically the shape of a hand with a [forbidden] sign at the corner. May
  /// fall back to [forbidden].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_NO_DROP
  ///  * Web: no-drop
  ///  * Windows: IDC_NO
  ///  * Linux: no-drop
  ///  * macOS: operationNotAllowedCursor
  ///
  /// See also:
  ///
  ///  * [forbidden], which indicates an action that will not be carried out.
  static const SystemMouseCursor noDrop = SystemMouseCursor._(kind: 'noDrop');

  /// A cursor indicating that the current operation will create an alias of, or
  /// a shortcut of the item.
  ///
  /// Typically the shape of an arrow with a shortcut icon at the corner.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_ALIAS
  ///  * Web: alias
  ///  * Linux: alias
  ///  * macOS: dragLinkCursor
  static const SystemMouseCursor alias = SystemMouseCursor._(kind: 'alias');

  /// A cursor indicating that the current operation will copy the item.
  ///
  /// Typically the shape of an arrow with a boxed plus sign at the corner.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_COPY
  ///  * Web: copy
  ///  * Linux: copy
  ///  * macOS: dragCopyCursor
  static const SystemMouseCursor copy = SystemMouseCursor._(kind: 'copy');

  /// A cursor indicating that the current operation will result in the
  /// disappearance of the item.
  ///
  /// Typically the shape of an arrow with a cloud of smoke at the corner.
  ///
  /// Corresponds to:
  ///
  ///  * macOS: disappearingItemCursor
  static const SystemMouseCursor disappearing = SystemMouseCursor._(kind: 'disappearing');


  // RESIZING AND SCROLLING

  /// A cursor indicating scrolling in any direction.
  ///
  /// Typically the shape of a dot surrounded by 4 arrows.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_ALL_SCROLL
  ///  * Windows: IDC_SIZEALL
  ///  * Web: all-scroll
  ///  * Linux: all-scroll
  ///
  /// See also:
  ///
  ///  * [move], which indicates moving in any direction.
  static const SystemMouseCursor allScroll = SystemMouseCursor._(kind: 'allScroll');

  /// A cursor indicating resizing an object bidirectionally from its left or
  /// right edge.
  ///
  /// Typically the shape of a bidirectional arrow pointing left and right.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_HORIZONTAL_DOUBLE_ARROW
  ///  * Web: ew-resize
  ///  * Windows: IDC_SIZEWE
  ///  * Linux: ew-resize
  ///  * macOS: resizeLeftRightCursor
  static const SystemMouseCursor resizeLeftRight = SystemMouseCursor._(kind: 'resizeLeftRight');

  /// A cursor indicating resizing an object bidirectionally from its top or
  /// bottom edge.
  ///
  /// Typically the shape of a bidirectional arrow pointing up and down.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_VERTICAL_DOUBLE_ARROW
  ///  * Web: ns-resize
  ///  * Windows: IDC_SIZENS
  ///  * Linux: ns-resize
  ///  * macOS: resizeUpDownCursor
  static const SystemMouseCursor resizeUpDown = SystemMouseCursor._(kind: 'resizeUpDown');

  /// A cursor indicating resizing an object bidirectionally from its top left or
  /// bottom right corner.
  ///
  /// Typically the shape of a bidirectional arrow pointing upper left and lower right.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TOP_LEFT_DIAGONAL_DOUBLE_ARROW
  ///  * Web: nwse-resize
  ///  * Windows: IDC_SIZENWSE
  ///  * Linux: nwse-resize
  static const SystemMouseCursor resizeUpLeftDownRight = SystemMouseCursor._(kind: 'resizeUpLeftDownRight');

  /// A cursor indicating resizing an object bidirectionally from its top right or
  /// bottom left corner.
  ///
  /// Typically the shape of a bidirectional arrow pointing upper right and lower left.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TOP_RIGHT_DIAGONAL_DOUBLE_ARROW
  ///  * Windows: IDC_SIZENESW
  ///  * Web: nesw-resize
  ///  * Linux: nesw-resize
  static const SystemMouseCursor resizeUpRightDownLeft = SystemMouseCursor._(kind: 'resizeUpRightDownLeft');

  /// A cursor indicating resizing an object from its top edge.
  ///
  /// Typically the shape of an arrow pointing up. May fallback to [resizeUpDown].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_VERTICAL_DOUBLE_ARROW
  ///  * Web: n-resize
  ///  * Windows: IDC_SIZENS
  ///  * Linux: n-resize
  ///  * macOS: resizeUpCursor
  static const SystemMouseCursor resizeUp = SystemMouseCursor._(kind: 'resizeUp');

  /// A cursor indicating resizing an object from its bottom edge.
  ///
  /// Typically the shape of an arrow pointing down. May fallback to [resizeUpDown].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_VERTICAL_DOUBLE_ARROW
  ///  * Web: s-resize
  ///  * Windows: IDC_SIZENS
  ///  * Linux: s-resize
  ///  * macOS: resizeDownCursor
  static const SystemMouseCursor resizeDown = SystemMouseCursor._(kind: 'resizeDown');

  /// A cursor indicating resizing an object from its left edge.
  ///
  /// Typically the shape of an arrow pointing left. May fallback to [resizeLeftRight].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_HORIZONTAL_DOUBLE_ARROW
  ///  * Web: w-resize
  ///  * Windows: IDC_SIZEWE
  ///  * Linux: w-resize
  ///  * macOS: resizeLeftCursor
  static const SystemMouseCursor resizeLeft = SystemMouseCursor._(kind: 'resizeLeft');

  /// A cursor indicating resizing an object from its right edge.
  ///
  /// Typically the shape of an arrow pointing right. May fallback to [resizeLeftRight].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_HORIZONTAL_DOUBLE_ARROW
  ///  * Web: e-resize
  ///  * Windows: IDC_SIZEWE
  ///  * Linux: e-resize
  ///  * macOS: resizeRightCursor
  static const SystemMouseCursor resizeRight = SystemMouseCursor._(kind: 'resizeRight');

  /// A cursor indicating resizing an object from its top-left corner.
  ///
  /// Typically the shape of an arrow pointing upper left. May fallback to [resizeUpLeftDownRight].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TOP_LEFT_DIAGONAL_DOUBLE_ARROW
  ///  * Web: nw-resize
  ///  * Windows: IDC_SIZENWSE
  ///  * Linux: nw-resize
  static const SystemMouseCursor resizeUpLeft = SystemMouseCursor._(kind: 'resizeUpLeft');

  /// A cursor indicating resizing an object from its top-right corner.
  ///
  /// Typically the shape of an arrow pointing upper right. May fallback to [resizeUpRightDownLeft].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TOP_RIGHT_DIAGONAL_DOUBLE_ARROW
  ///  * Web: ne-resize
  ///  * Windows: IDC_SIZENESW
  ///  * Linux: ne-resize
  static const SystemMouseCursor resizeUpRight = SystemMouseCursor._(kind: 'resizeUpRight');

  /// A cursor indicating resizing an object from its bottom-left corner.
  ///
  /// Typically the shape of an arrow pointing lower left. May fallback to [resizeUpRightDownLeft].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TOP_RIGHT_DIAGONAL_DOUBLE_ARROW
  ///  * Web: sw-resize
  ///  * Windows: IDC_SIZENESW
  ///  * Linux: sw-resize
  static const SystemMouseCursor resizeDownLeft = SystemMouseCursor._(kind: 'resizeDownLeft');

  /// A cursor indicating resizing an object from its bottom-right corner.
  ///
  /// Typically the shape of an arrow pointing lower right. May fallback to [resizeUpLeftDownRight].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_TOP_LEFT_DIAGONAL_DOUBLE_ARROW
  ///  * Web: se-resize
  ///  * Windows: IDC_SIZENWSE
  ///  * Linux: se-resize
  static const SystemMouseCursor resizeDownRight = SystemMouseCursor._(kind: 'resizeDownRight');

  /// A cursor indicating resizing a column, or an item horizontally.
  ///
  /// Typically the shape of arrows pointing left and right with a vertical bar
  /// separating them. May fallback to [resizeLeftRight].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_HORIZONTAL_DOUBLE_ARROW
  ///  * Web: col-resize
  ///  * Windows: IDC_SIZEWE
  ///  * Linux: col-resize
  ///  * macOS: resizeLeftRightCursor
  static const SystemMouseCursor resizeColumn = SystemMouseCursor._(kind: 'resizeColumn');

  /// A cursor indicating resizing a row, or an item vertically.
  ///
  /// Typically the shape of arrows pointing up and down with a horizontal bar
  /// separating them. May fallback to [resizeUpDown].
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_VERTICAL_DOUBLE_ARROW
  ///  * Web: row-resize
  ///  * Windows: IDC_SIZENS
  ///  * Linux: row-resize
  ///  * macOS: resizeUpDownCursor
  static const SystemMouseCursor resizeRow = SystemMouseCursor._(kind: 'resizeRow');


  // OTHER OPERATIONS

  /// A cursor indicating zooming in.
  ///
  /// Typically a magnifying glass with a plus sign.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_ZOOM_IN
  ///  * Web: zoom-in
  ///  * Linux: zoom-in
  static const SystemMouseCursor zoomIn = SystemMouseCursor._(kind: 'zoomIn');

  /// A cursor indicating zooming out.
  ///
  /// Typically a magnifying glass with a minus sign.
  ///
  /// Corresponds to:
  ///
  ///  * Android: TYPE_ZOOM_OUT
  ///  * Web: zoom-out
  ///  * Linux: zoom-out
  static const SystemMouseCursor zoomOut = SystemMouseCursor._(kind: 'zoomOut');
}
