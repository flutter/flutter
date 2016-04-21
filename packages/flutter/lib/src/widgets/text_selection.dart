// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'overlay.dart';

// TODO(mpcomplete): Need one for [collapsed].
/// Which type of selection handle to be displayed. With mixed-direction text,
/// both handles may be the same type. Examples:
/// LTR text: 'the <quick brown> fox'
///   The '<' is drawn with the [left] type, the '>' with the [right]
/// RTL text: 'xof <nworb kciuq> eht'
///   Same as above.
/// mixed text: '<the nwor<b quick fox'
///   Here 'the b' is selected, but 'brown' is RTL. Both are drawn with the
///   [left] type.
enum TextSelectionHandleType { left, right, collapsed }

/// Builds a handle of the given type.
typedef Widget TextSelectionHandleBuilder(BuildContext context, TextSelectionHandleType type);

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// Manages a pair of text selection handles to be shown in an Overlay
/// containing the owning widget.
class TextSelectionHandles {
  TextSelectionHandles({
    TextSelection selection,
    this.renderObject,
    this.onSelectionHandleChanged,
    this.builder
  }): _selection = selection;

  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  final RenderEditableLine renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final TextSelectionHandleBuilder builder;
  TextSelection _selection;

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry> _handles;

  /// Shows the handles by inserting them into the [context]'s overlay.
  void show(BuildContext context, { Widget debugRequiredFor }) {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      new OverlayEntry(builder: (BuildContext c) => _buildOverlay(c, _TextSelectionHandlePosition.start)),
      new OverlayEntry(builder: (BuildContext c) => _buildOverlay(c, _TextSelectionHandlePosition.end)),
    ];
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insertAll(_handles);
  }

  /// Updates the handles after the [selection] has changed.
  void update(TextSelection newSelection) {
    _selection = newSelection;
    _handles[0].markNeedsBuild();
    _handles[1].markNeedsBuild();
  }

  /// Hides the handles.
  void hide() {
    _handles[0].remove();
    _handles[1].remove();
    _handles = null;
  }

  Widget _buildOverlay(BuildContext context, _TextSelectionHandlePosition position) {
    if (_selection.isCollapsed && position == _TextSelectionHandlePosition.end)
      return new Container();  // hide the second handle when collapsed
    return new _TextSelectionHandleOverlay(
      onSelectionHandleChanged: _handleSelectionHandleChanged,
      renderObject: renderObject,
      selection: _selection,
      builder: builder,
      position: position
    );
  }

  void _handleSelectionHandleChanged(TextSelection newSelection) {
    if (onSelectionHandleChanged != null)
      onSelectionHandleChanged(newSelection);
    update(newSelection);
  }
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  _TextSelectionHandleOverlay({
    Key key,
    this.selection,
    this.position,
    this.renderObject,
    this.onSelectionHandleChanged,
    this.builder
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final RenderEditableLine renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final TextSelectionHandleBuilder builder;

  @override
  _TextSelectionHandleOverlayState createState() => new _TextSelectionHandleOverlayState();
}

class _TextSelectionHandleOverlayState extends State<_TextSelectionHandleOverlay> {
  Point _dragPosition;
  void _handleDragStart(Point position) {
    _dragPosition = position;
  }

  void _handleDragUpdate(double delta) {
    _dragPosition += new Offset(delta, 0.0);
    TextPosition position = config.renderObject.getPositionForPoint(_dragPosition);

    if (config.selection.isCollapsed) {
      config.onSelectionHandleChanged(new TextSelection.fromPosition(position));
      return;
    }

    TextSelection newSelection;
    switch (config.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = new TextSelection(
          baseOffset: position.offset,
          extentOffset: config.selection.extentOffset
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = new TextSelection(
          baseOffset: config.selection.baseOffset,
          extentOffset: position.offset
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset)
      return; // don't allow order swapping.

    config.onSelectionHandleChanged(newSelection);
  }

  @override
  Widget build(BuildContext context) {
    List<TextSelectionPoint> endpoints = config.renderObject.getEndpointsForSelection(config.selection);
    Point point;
    TextSelectionHandleType type;

    switch (config.position) {
      case _TextSelectionHandlePosition.start:
        point = endpoints[0].point;
        type = _chooseType(endpoints[0], TextSelectionHandleType.left, TextSelectionHandleType.right);
        break;
      case _TextSelectionHandlePosition.end:
        // [endpoints] will only contain 1 point for collapsed selections, in
        // which case we shouldn't be building the [end] handle.
        assert(endpoints.length == 2);
        point = endpoints[1].point;
        type = _chooseType(endpoints[1], TextSelectionHandleType.right, TextSelectionHandleType.left);
        break;
    }

    return new GestureDetector(
      onHorizontalDragStart: _handleDragStart,
      onHorizontalDragUpdate: _handleDragUpdate,
      child: new Stack(
        children: <Widget>[
          new Positioned(
            left: point.x,
            top: point.y,
            child: config.builder(context, type)
          )
        ]
      )
    );
  }

  TextSelectionHandleType _chooseType(
    TextSelectionPoint endpoint,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType
  ) {
    if (config.selection.isCollapsed)
      return TextSelectionHandleType.collapsed;

    switch (endpoint.direction) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
  }
}
