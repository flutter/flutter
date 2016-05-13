// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';

import 'basic.dart';
import 'editable.dart';
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

// Builds a copy/paste toolbar.
// TODO(mpcomplete): A single position is probably insufficient.
typedef Widget TextSelectionToolbarBuilder(BuildContext context, Point position, TextSelectionDelegate delegate);

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// An interface for manipulating the selection, to be used by the implementor
/// of the toolbar widget.
abstract class TextSelectionDelegate {
  /// Gets the current text input.
  InputValue get inputValue;

  /// Sets the current text input (replaces the whole line).
  set inputValue(InputValue value);

  /// Hides the text selection toolbar.
  void hideToolbar();
}

/// Manages a pair of text selection handles to be shown in an Overlay
/// containing the owning widget.
class TextSelectionOverlay implements TextSelectionDelegate {
  TextSelectionOverlay({
    InputValue input,
    this.context,
    this.debugRequiredFor,
    this.renderObject,
    this.onSelectionOverlayChanged,
    this.handleBuilder,
    this.toolbarBuilder
  }): _input = input;

  final BuildContext context;
  final Widget debugRequiredFor;
  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  final RenderEditableLine renderObject;
  final ValueChanged<InputValue> onSelectionOverlayChanged;
  final TextSelectionHandleBuilder handleBuilder;
  final TextSelectionToolbarBuilder toolbarBuilder;
  InputValue _input;

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry> _handles;

  /// A copy/paste toolbar.
  OverlayEntry _toolbar;

  TextSelection get _selection => _input.selection;

  /// Shows the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      new OverlayEntry(builder: (BuildContext c) => _buildOverlay(c, _TextSelectionHandlePosition.start)),
      new OverlayEntry(builder: (BuildContext c) => _buildOverlay(c, _TextSelectionHandlePosition.end)),
    ];
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insertAll(_handles);
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = new OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insert(_toolbar);
  }

  /// Updates the overlay after the [selection] has changed.
  void update(InputValue newInput) {
    if (_input == newInput)
      return;

    _input = newInput;
    if (_handles != null) {
      _handles[0].markNeedsBuild();
      _handles[1].markNeedsBuild();
    }
    _toolbar?.markNeedsBuild();
  }

  /// Hides the overlay.
  void hide() {
    if (_handles != null) {
      _handles[0].remove();
      _handles[1].remove();
      _handles = null;
    }
    _toolbar?.remove();
    _toolbar = null;
  }

  Widget _buildOverlay(BuildContext context, _TextSelectionHandlePosition position) {
    if ((_selection.isCollapsed && position == _TextSelectionHandlePosition.end) ||
        handleBuilder == null)
      return new Container();  // hide the second handle when collapsed
    return new _TextSelectionHandleOverlay(
      onSelectionHandleChanged: _handleSelectionHandleChanged,
      onSelectionHandleTapped: _handleSelectionHandleTapped,
      renderObject: renderObject,
      selection: _selection,
      builder: handleBuilder,
      position: position
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (toolbarBuilder == null)
      return new Container();

    // Find the horizontal midpoint, just above the selected text.
    List<TextSelectionPoint> endpoints = renderObject.getEndpointsForSelection(_selection);
    Point midpoint = new Point(
      (endpoints.length == 1) ?
        endpoints[0].point.x :
        (endpoints[0].point.x + endpoints[1].point.x) / 2.0,
      endpoints[0].point.y - renderObject.size.height
    );

    return toolbarBuilder(context, midpoint, this);
  }

  void _handleSelectionHandleChanged(TextSelection newSelection) {
    inputValue = _input.copyWith(selection: newSelection, composing: TextRange.empty);
  }

  void _handleSelectionHandleTapped() {
    if (inputValue.selection.isCollapsed) {
      if (_toolbar != null) {
        _toolbar?.remove();
        _toolbar = null;
      } else {
        showToolbar();
      }
    }
  }

  @override
  InputValue get inputValue => _input;

  @override
  set inputValue(InputValue value) {
    update(value);
    if (onSelectionOverlayChanged != null)
      onSelectionOverlayChanged(value);
  }

  @override
  void hideToolbar() {
    hide();
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
    this.onSelectionHandleTapped,
    this.builder
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final RenderEditableLine renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback onSelectionHandleTapped;
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

  void _handleTap() {
    config.onSelectionHandleTapped();
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
      onTap: _handleTap,
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
