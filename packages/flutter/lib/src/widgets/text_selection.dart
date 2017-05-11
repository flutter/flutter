// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'container.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'overlay.dart';
import 'transitions.dart';

/// Which type of selection handle to be displayed.
///
/// With mixed-direction text, both handles may be the same type. Examples:
///
/// * LTR text: 'the <quick brown> fox':
///   The '<' is drawn with the [left] type, the '>' with the [right]
///
/// * RTL text: 'xof <nworb kciuq> eht':
///   Same as above.
///
/// * mixed text: '<the nwor<b quick fox'
///   Here 'the b' is selected, but 'brown' is RTL. Both are drawn with the
///   [left] type.
enum TextSelectionHandleType {
  /// The selection handle is to the left of the selection end point.
  left,

  /// The selection handle is to the right of the selection end point.
  right,

  /// The start and end of the selection are co-incident at this point.
  collapsed,
}

/// The text position that a give selection handle manipulates. Dragging the
/// [start] handle always moves the [start]/[baseOffset] of the selection.
enum _TextSelectionHandlePosition { start, end }

/// Signature for reporting changes to the selection component of a
/// [TextEditingValue] for the purposes of a [TextSelectionOverlay]. The
/// [caretRect] argument gives the location of the caret in the coordinate space
/// of the [RenderBox] given by the [TextSelectionOverlay.renderObject].
///
/// Used by [TextSelectionOverlay.onSelectionOverlayChanged].
typedef void TextSelectionOverlayChanged(TextEditingValue value, Rect caretRect);

/// An interface for manipulating the selection, to be used by the implementor
/// of the toolbar widget.
abstract class TextSelectionDelegate {
  /// Gets the current text input.
  TextEditingValue get textEditingValue;

  /// Sets the current text input (replaces the whole line).
  set textEditingValue(TextEditingValue value);

  /// Hides the text selection toolbar.
  void hideToolbar();
}

/// An interface for building the selection UI, to be provided by the
/// implementor of the toolbar widget.
abstract class TextSelectionControls {
  /// Builds a selection handle of the given type.
  Widget buildHandle(BuildContext context, TextSelectionHandleType type);

  /// Builds a toolbar near a text selection.
  ///
  /// Typically displays buttons for copying and pasting text.
  // TODO(mpcomplete): A single position is probably insufficient.
  Widget buildToolbar(BuildContext context, Offset position, TextSelectionDelegate delegate);

  /// Returns the size of the selection handle.
  Size get handleSize;
}

/// An object that manages a pair of text selection handles.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class TextSelectionOverlay implements TextSelectionDelegate {
  /// Creates an object that manages overly entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  TextSelectionOverlay({
    @required TextEditingValue value,
    @required this.context,
    this.debugRequiredFor,
    this.renderObject,
    this.onSelectionOverlayChanged,
    this.selectionControls,
  }): _value  = value {
    assert(value != null);
    assert(context != null);
    final OverlayState overlay = Overlay.of(context);
    assert(overlay != null);
    _handleController = new AnimationController(duration: _kFadeDuration, vsync: overlay);
    _toolbarController = new AnimationController(duration: _kFadeDuration, vsync: overlay);
  }

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget debugRequiredFor;

  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  /// The editable line in which the selected text is being displayed.
  final RenderEditable renderObject;

  /// Called when the the selection changes.
  ///
  /// For example, if the use drags one of the selection handles, this function
  /// will be called with a new input value with an updated selection.
  final TextSelectionOverlayChanged onSelectionOverlayChanged;

  /// Builds text selection handles and toolbar.
  final TextSelectionControls selectionControls;

  /// Controls the fade-in animations.
  static const Duration _kFadeDuration = const Duration(milliseconds: 150);
  AnimationController _handleController;
  AnimationController _toolbarController;
  Animation<double> get _handleOpacity => _handleController.view;
  Animation<double> get _toolbarOpacity => _toolbarController.view;

  TextEditingValue _value;

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry> _handles;

  /// A copy/paste toolbar.
  OverlayEntry _toolbar;

  TextSelection get _selection => _value.selection;

  /// Shows the handles by inserting them into the [context]'s overlay.
  void showHandles() {
    assert(_handles == null);
    _handles = <OverlayEntry>[
      new OverlayEntry(builder: (BuildContext c) => _buildHandle(c, _TextSelectionHandlePosition.start)),
      new OverlayEntry(builder: (BuildContext c) => _buildHandle(c, _TextSelectionHandlePosition.end)),
    ];
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insertAll(_handles);
    _handleController.forward(from: 0.0);
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = new OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insert(_toolbar);
    _toolbarController.forward(from: 0.0);
  }

  /// Updates the overlay after the selection has changed.
  ///
  /// If this method is called while the [SchedulerBinding.schedulerPhase] is
  /// [SchedulerPhase.persistentCallbacks], i.e. during the build, layout, or
  /// paint phases (see [WidgetsBinding.drawFrame]), then the update is delayed
  /// until the post-frame callbacks phase. Otherwise the update is done
  /// synchronously. This means that it is safe to call during builds, but also
  /// that if you do call this during a build, the UI will not update until the
  /// next frame (i.e. many milliseconds later).
  void update(TextEditingValue newValue) {
    if (_value == newValue)
      return;
    _value = newValue;
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback(_markNeedsBuild);
    } else {
      _markNeedsBuild();
    }
  }

  void _markNeedsBuild([Duration duration]) {
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

    _handleController.stop();
    _toolbarController.stop();
  }

  /// Final cleanup.
  void dispose() {
    hide();
    _handleController.dispose();
    _toolbarController.dispose();
  }

  Widget _buildHandle(BuildContext context, _TextSelectionHandlePosition position) {
    if ((_selection.isCollapsed && position == _TextSelectionHandlePosition.end) ||
        selectionControls == null)
      return new Container();  // hide the second handle when collapsed

    return new FadeTransition(
      opacity: _handleOpacity,
      child: new _TextSelectionHandleOverlay(
        onSelectionHandleChanged: (TextSelection newSelection) { _handleSelectionHandleChanged(newSelection, position); },
        onSelectionHandleTapped: _handleSelectionHandleTapped,
        renderObject: renderObject,
        selection: _selection,
        selectionControls: selectionControls,
        position: position
      )
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null)
      return new Container();

    // Find the horizontal midpoint, just above the selected text.
    final List<TextSelectionPoint> endpoints = renderObject.getEndpointsForSelection(_selection);
    final Offset midpoint = new Offset(
      (endpoints.length == 1) ?
        endpoints[0].point.dx :
        (endpoints[0].point.dx + endpoints[1].point.dx) / 2.0,
      endpoints[0].point.dy - renderObject.size.height
    );

    return new FadeTransition(
      opacity: _toolbarOpacity,
      child: selectionControls.buildToolbar(context, midpoint, this)
    );
  }

  void _handleSelectionHandleChanged(TextSelection newSelection, _TextSelectionHandlePosition position) {
    Rect caretRect;
    switch (position) {
      case _TextSelectionHandlePosition.start:
        caretRect = renderObject.getLocalRectForCaret(newSelection.base);
        break;
      case _TextSelectionHandlePosition.end:
        caretRect = renderObject.getLocalRectForCaret(newSelection.extent);
        break;
    }
    update(_value.copyWith(selection: newSelection, composing: TextRange.empty));
    if (onSelectionOverlayChanged != null)
      onSelectionOverlayChanged(_value, caretRect);
  }

  void _handleSelectionHandleTapped() {
    if (_value.selection.isCollapsed) {
      if (_toolbar != null) {
        _toolbar?.remove();
        _toolbar = null;
      } else {
        showToolbar();
      }
    }
  }

  @override
  TextEditingValue get textEditingValue => _value;

  @override
  set textEditingValue(TextEditingValue newValue) {
    update(newValue);
    if (onSelectionOverlayChanged != null) {
      final Rect caretRect = renderObject.getLocalRectForCaret(newValue.selection.extent);
      onSelectionOverlayChanged(newValue, caretRect);
    }
  }

  @override
  void hideToolbar() {
    hide();
  }
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    Key key,
    this.selection,
    this.position,
    this.renderObject,
    this.onSelectionHandleChanged,
    this.onSelectionHandleTapped,
    this.selectionControls
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final RenderEditable renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback onSelectionHandleTapped;
  final TextSelectionControls selectionControls;

  @override
  _TextSelectionHandleOverlayState createState() => new _TextSelectionHandleOverlayState();
}

class _TextSelectionHandleOverlayState extends State<_TextSelectionHandleOverlay> {
  Offset _dragPosition;

  void _handleDragStart(DragStartDetails details) {
    _dragPosition = details.globalPosition + new Offset(0.0, -widget.selectionControls.handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final TextPosition position = widget.renderObject.getPositionForPoint(_dragPosition);

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(new TextSelection.fromPosition(position));
      return;
    }

    TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = new TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = new TextSelection(
          baseOffset: widget.selection.baseOffset,
          extentOffset: position.offset
        );
        break;
    }

    if (newSelection.baseOffset >= newSelection.extentOffset)
      return; // don't allow order swapping.

    widget.onSelectionHandleChanged(newSelection);
  }

  void _handleTap() {
    widget.onSelectionHandleTapped();
  }

  @override
  Widget build(BuildContext context) {
    final List<TextSelectionPoint> endpoints = widget.renderObject.getEndpointsForSelection(widget.selection);
    Offset point;
    TextSelectionHandleType type;

    switch (widget.position) {
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
      onPanStart: _handleDragStart,
      onPanUpdate: _handleDragUpdate,
      onTap: _handleTap,
      child: new Stack(
        children: <Widget>[
          new Positioned(
            left: point.dx,
            top: point.dy,
            child: widget.selectionControls.buildHandle(context, type)
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
    if (widget.selection.isCollapsed)
      return TextSelectionHandleType.collapsed;

    assert(endpoint.direction != null);
    switch (endpoint.direction) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
    return null;
  }
}
