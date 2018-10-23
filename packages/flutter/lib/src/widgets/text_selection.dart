// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

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

export 'package:flutter/services.dart' show TextSelectionDelegate;

/// Which type of selection handle to be displayed.
///
/// With mixed-direction text, both handles may be the same type. Examples:
///
/// * LTR text: 'the &lt;quick brown&gt; fox':
///
///   The '&lt;' is drawn with the [left] type, the '&gt;' with the [right]
///
/// * RTL text: 'XOF &lt;NWORB KCIUQ&gt; EHT':
///
///   Same as above.
///
/// * mixed text: '&lt;the NWOR&lt;B KCIUQ fox'
///
///   Here 'the QUICK B' is selected, but 'QUICK BROWN' is RTL. Both are drawn
///   with the [left] type.
///
/// See also:
///
///  * [TextDirection], which discusses left-to-right and right-to-left text in
///    more detail.
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
typedef TextSelectionOverlayChanged = void Function(TextEditingValue value, Rect caretRect);

/// An interface for building the selection UI, to be provided by the
/// implementor of the toolbar widget.
///
/// Override text operations such as [handleCut] if needed.
abstract class TextSelectionControls {
  /// Builds a selection handle of the given type.
  ///
  /// The top left corner of this widget is positioned at the bottom of the
  /// selection position.
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight);

  /// Builds a toolbar near a text selection.
  ///
  /// Typically displays buttons for copying and pasting text.
  Widget buildToolbar(BuildContext context, Rect globalEditableRegion, Offset position, TextSelectionDelegate delegate);

  /// Returns the size of the selection handle.
  Size get handleSize;

  /// Whether the current selection of the text field managed by the given
  /// `delegate` can be removed from the text field and placed into the
  /// [Clipboard].
  ///
  /// By default, false is returned when nothing is selected in the text field.
  ///
  /// Subclasses can use this to decide if they should expose the cut
  /// functionality to the user.
  bool canCut(TextSelectionDelegate delegate) {
    return !delegate.textEditingValue.selection.isCollapsed;
  }

  /// Whether the current selection of the text field managed by the given
  /// `delegate` can be copied to the [Clipboard].
  ///
  /// By default, false is returned when nothing is selected in the text field.
  ///
  /// Subclasses can use this to decide if they should expose the copy
  /// functionality to the user.
  bool canCopy(TextSelectionDelegate delegate) {
    return !delegate.textEditingValue.selection.isCollapsed;
  }

  /// Whether the current [Clipboard] content can be pasted into the text field
  /// managed by the given `delegate`.
  ///
  /// Subclasses can use this to decide if they should expose the paste
  /// functionality to the user.
  bool canPaste(TextSelectionDelegate delegate) {
    // TODO(goderbauer): return false when clipboard is empty, https://github.com/flutter/flutter/issues/11254
    return true;
  }

  /// Whether the current selection of the text field managed by the given
  /// `delegate` can be extended to include the entire content of the text
  /// field.
  ///
  /// Subclasses can use this to decide if they should expose the select all
  /// functionality to the user.
  bool canSelectAll(TextSelectionDelegate delegate) {
    return delegate.textEditingValue.text.isNotEmpty && delegate.textEditingValue.selection.isCollapsed;
  }

  /// Copy the current selection of the text field managed by the given
  /// `delegate` to the [Clipboard]. Then, remove the selected text from the
  /// text field and hide the toolbar.
  ///
  /// This is called by subclasses when their cut affordance is activated by
  /// the user.
  void handleCut(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    Clipboard.setData(ClipboardData(
      text: value.selection.textInside(value.text),
    ));
    delegate.textEditingValue = TextEditingValue(
      text: value.selection.textBefore(value.text)
          + value.selection.textAfter(value.text),
      selection: TextSelection.collapsed(
        offset: value.selection.start
      ),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  /// Copy the current selection of the text field managed by the given
  /// `delegate` to the [Clipboard]. Then, move the cursor to the end of the
  /// text (collapsing the selection in the process), and hide the toolbar.
  ///
  /// This is called by subclasses when their copy affordance is activated by
  /// the user.
  void handleCopy(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    Clipboard.setData(ClipboardData(
      text: value.selection.textInside(value.text),
    ));
    delegate.textEditingValue = TextEditingValue(
      text: value.text,
      selection: TextSelection.collapsed(offset: value.selection.end),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  /// Paste the current clipboard selection (obtained from [Clipboard]) into
  /// the text field managed by the given `delegate`, replacing its current
  /// selection, if any. Then, hide the toolbar.
  ///
  /// This is called by subclasses when their paste affordance is activated by
  /// the user.
  ///
  /// This function is asynchronous since interacting with the clipboard is
  /// asynchronous. Race conditions may exist with this API as currently
  /// implemented.
  // TODO(ianh): https://github.com/flutter/flutter/issues/11427
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    final TextEditingValue value = delegate.textEditingValue; // Snapshot the input before using `await`.
    final ClipboardData data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data != null) {
      delegate.textEditingValue = TextEditingValue(
        text: value.selection.textBefore(value.text)
            + data.text
            + value.selection.textAfter(value.text),
        selection: TextSelection.collapsed(
          offset: value.selection.start + data.text.length
        ),
      );
    }
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
    delegate.hideToolbar();
  }

  /// Adjust the selection of the text field managed by the given `delegate` so
  /// that everything is selected.
  ///
  /// Does not hide the toolbar.
  ///
  /// This is called by subclasses when their select-all affordance is activated
  /// by the user.
  void handleSelectAll(TextSelectionDelegate delegate) {
    delegate.textEditingValue = TextEditingValue(
      text: delegate.textEditingValue.text,
      selection: TextSelection(
        baseOffset: 0,
        extentOffset: delegate.textEditingValue.text.length
      ),
    );
    delegate.bringIntoView(delegate.textEditingValue.selection.extent);
  }
}

/// An object that manages a pair of text selection handles.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class TextSelectionOverlay {
  /// Creates an object that manages overly entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  TextSelectionOverlay({
    @required TextEditingValue value,
    @required this.context,
    this.debugRequiredFor,
    @required this.layerLink,
    @required this.renderObject,
    this.selectionControls,
    this.selectionDelegate,
  }): assert(value != null),
      assert(context != null),
      _value = value {
    final OverlayState overlay = Overlay.of(context);
    assert(overlay != null);
    _handleController = AnimationController(duration: _fadeDuration, vsync: overlay);
    _toolbarController = AnimationController(duration: _fadeDuration, vsync: overlay);
  }

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget debugRequiredFor;

  /// The object supplied to the [CompositedTransformTarget] that wraps the text
  /// field.
  final LayerLink layerLink;

  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  /// The editable line in which the selected text is being displayed.
  final RenderEditable renderObject;

  /// Builds text selection handles and toolbar.
  final TextSelectionControls selectionControls;

  /// The delegate for manipulating the current selection in the owning
  /// text field.
  final TextSelectionDelegate selectionDelegate;

  /// Controls the fade-in animations.
  static const Duration _fadeDuration = Duration(milliseconds: 150);
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
      OverlayEntry(builder: (BuildContext context) => _buildHandle(context, _TextSelectionHandlePosition.start)),
      OverlayEntry(builder: (BuildContext context) => _buildHandle(context, _TextSelectionHandlePosition.end)),
    ];
    Overlay.of(context, debugRequiredFor: debugRequiredFor).insertAll(_handles);
    _handleController.forward(from: 0.0);
  }

  /// Shows the toolbar by inserting it into the [context]'s overlay.
  void showToolbar() {
    assert(_toolbar == null);
    _toolbar = OverlayEntry(builder: _buildToolbar);
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

  /// Causes the overlay to update its rendering.
  ///
  /// This is intended to be called when the [renderObject] may have changed its
  /// text metrics (e.g. because the text was scrolled).
  void updateForScroll() {
    _markNeedsBuild();
  }

  void _markNeedsBuild([Duration duration]) {
    if (_handles != null) {
      _handles[0].markNeedsBuild();
      _handles[1].markNeedsBuild();
    }
    _toolbar?.markNeedsBuild();
  }

  /// Whether the handles are currently visible.
  bool get handlesAreVisible => _handles != null;

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible => _toolbar != null;

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
      return Container(); // hide the second handle when collapsed

    return FadeTransition(
      opacity: _handleOpacity,
      child: _TextSelectionHandleOverlay(
        onSelectionHandleChanged: (TextSelection newSelection) { _handleSelectionHandleChanged(newSelection, position); },
        onSelectionHandleTapped: _handleSelectionHandleTapped,
        layerLink: layerLink,
        renderObject: renderObject,
        selection: _selection,
        selectionControls: selectionControls,
        position: position,
      )
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null)
      return Container();

    // Find the horizontal midpoint, just above the selected text.
    final List<TextSelectionPoint> endpoints = renderObject.getEndpointsForSelection(_selection);
    final Offset midpoint = Offset(
      (endpoints.length == 1) ?
        endpoints[0].point.dx :
        (endpoints[0].point.dx + endpoints[1].point.dx) / 2.0,
      endpoints[0].point.dy - renderObject.preferredLineHeight,
    );

    final Rect editingRegion = Rect.fromPoints(
      renderObject.localToGlobal(Offset.zero),
      renderObject.localToGlobal(renderObject.size.bottomRight(Offset.zero)),
    );

    return FadeTransition(
      opacity: _toolbarOpacity,
      child: CompositedTransformFollower(
        link: layerLink,
        showWhenUnlinked: false,
        offset: -editingRegion.topLeft,
        child: selectionControls.buildToolbar(context, editingRegion, midpoint, selectionDelegate),
      ),
    );
  }

  void _handleSelectionHandleChanged(TextSelection newSelection, _TextSelectionHandlePosition position) {
    TextPosition textPosition;
    switch (position) {
      case _TextSelectionHandlePosition.start:
        textPosition = newSelection.base;
        break;
      case _TextSelectionHandlePosition.end:
        textPosition =newSelection.extent;
        break;
    }
    selectionDelegate.textEditingValue = _value.copyWith(selection: newSelection, composing: TextRange.empty);
    selectionDelegate.bringIntoView(textPosition);
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
}

/// This widget represents a single draggable text selection handle.
class _TextSelectionHandleOverlay extends StatefulWidget {
  const _TextSelectionHandleOverlay({
    Key key,
    @required this.selection,
    @required this.position,
    @required this.layerLink,
    @required this.renderObject,
    @required this.onSelectionHandleChanged,
    @required this.onSelectionHandleTapped,
    @required this.selectionControls
  }) : super(key: key);

  final TextSelection selection;
  final _TextSelectionHandlePosition position;
  final LayerLink layerLink;
  final RenderEditable renderObject;
  final ValueChanged<TextSelection> onSelectionHandleChanged;
  final VoidCallback onSelectionHandleTapped;
  final TextSelectionControls selectionControls;

  @override
  _TextSelectionHandleOverlayState createState() => _TextSelectionHandleOverlayState();
}

class _TextSelectionHandleOverlayState extends State<_TextSelectionHandleOverlay> {
  Offset _dragPosition;

  void _handleDragStart(DragStartDetails details) {
    _dragPosition = details.globalPosition + Offset(0.0, -widget.selectionControls.handleSize.height);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _dragPosition += details.delta;
    final TextPosition position = widget.renderObject.getPositionForPoint(_dragPosition);

    if (widget.selection.isCollapsed) {
      widget.onSelectionHandleChanged(TextSelection.fromPosition(position));
      return;
    }

    TextSelection newSelection;
    switch (widget.position) {
      case _TextSelectionHandlePosition.start:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset
        );
        break;
      case _TextSelectionHandlePosition.end:
        newSelection = TextSelection(
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

    return CompositedTransformFollower(
      link: widget.layerLink,
      showWhenUnlinked: false,
      child: GestureDetector(
        onPanStart: _handleDragStart,
        onPanUpdate: _handleDragUpdate,
        onTap: _handleTap,
        child: Stack(
          // Always let the selection handles draw outside of the conceptual
          // box where (0,0) is the top left corner of the RenderEditable.
          overflow: Overflow.visible,
          children: <Widget>[
            Positioned(
              left: point.dx,
              top: point.dy,
              child: widget.selectionControls.buildHandle(
                context,
                type,
                widget.renderObject.preferredLineHeight,
              ),
            ),
          ],
        ),
      ),
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
