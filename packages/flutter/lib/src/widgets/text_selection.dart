// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;

import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'binding.dart';
import 'constants.dart';
import 'container.dart';
import 'debug.dart';
import 'editable_text.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'magnifier.dart';
import 'overlay.dart';
import 'tap_region.dart';
import 'ticker_provider.dart';
import 'transitions.dart';

export 'package:flutter/rendering.dart' show TextSelectionPoint;
export 'package:flutter/services.dart' show TextSelectionDelegate;

/// A duration that controls how often the drag selection update callback is
/// called.
const Duration _kDragSelectionUpdateThrottle = Duration(milliseconds: 50);

/// Signature for when a pointer that's dragging to select text has moved again.
///
/// The first argument [startDetails] contains the details of the event that
/// initiated the dragging.
///
/// The second argument [updateDetails] contains the details of the current
/// pointer movement. It's the same as the one passed to [DragGestureRecognizer.onUpdate].
///
/// This signature is different from [GestureDragUpdateCallback] to make it
/// easier for various text fields to use [TextSelectionGestureDetector] without
/// having to store the start position.
typedef DragSelectionUpdateCallback = void Function(DragStartDetails startDetails, DragUpdateDetails updateDetails);

/// The type for a Function that builds a toolbar's container with the given
/// child.
///
/// See also:
///
///   * [TextSelectionToolbar.toolbarBuilder], which is of this type.
///     type.
///   * [CupertinoTextSelectionToolbar.toolbarBuilder], which is similar, but
///     for a Cupertino-style toolbar.
typedef ToolbarBuilder = Widget Function(BuildContext context, Widget child);

/// ParentData that determines whether or not to paint the corresponding child.
///
/// Used in the layout of the Cupertino and Material text selection menus, which
/// decide whether or not to paint their buttons after laying them out and
/// determining where they overflow.
class ToolbarItemsParentData extends ContainerBoxParentData<RenderBox> {
  /// Whether or not this child is painted.
  ///
  /// Children in the selection toolbar may be laid out for measurement purposes
  /// but not painted. This allows these children to be identified.
  bool shouldPaint = false;

  @override
  String toString() => '${super.toString()}; shouldPaint=$shouldPaint';
}

/// An interface for building the selection UI, to be provided by the
/// implementer of the toolbar widget.
///
/// Override text operations such as [handleCut] if needed.
///
/// See also:
///
///  * [SelectionArea], which selects appropriate text selection controls
///    based on the current platform.
abstract class TextSelectionControls {
  /// Builds a selection handle of the given `type`.
  ///
  /// The top left corner of this widget is positioned at the bottom of the
  /// selection position.
  ///
  /// The supplied [onTap] should be invoked when the handle is tapped, if such
  /// interaction is allowed. As a counterexample, the default selection handle
  /// on iOS [cupertinoTextSelectionControls] does not call [onTap] at all,
  /// since its handles are not meant to be tapped.
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]);

  /// Get the anchor point of the handle relative to itself. The anchor point is
  /// the point that is aligned with a specific point in the text. A handle
  /// often visually "points to" that location.
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight);

  /// Builds a toolbar near a text selection.
  ///
  /// Typically displays buttons for copying and pasting text.
  ///
  /// The [globalEditableRegion] parameter is the TextField size of the global
  /// coordinate system in logical pixels.
  ///
  /// The [textLineHeight] parameter is the [RenderEditable.preferredLineHeight]
  /// of the [RenderEditable] we are building a toolbar for.
  ///
  /// The [selectionMidpoint] parameter is a general calculation midpoint
  /// parameter of the toolbar. More detailed position information
  /// is computable from the [endpoints] parameter.
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    // TODO(chunhtai): Change to ValueListenable<ClipboardStatus>? once
    // migration is done. https://github.com/flutter/flutter/issues/99360
    ClipboardStatusNotifier? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  );

  /// Returns the size of the selection handle.
  Size getHandleSize(double textLineHeight);

  /// Whether the current selection of the text field managed by the given
  /// `delegate` can be removed from the text field and placed into the
  /// [Clipboard].
  ///
  /// By default, false is returned when nothing is selected in the text field.
  ///
  /// Subclasses can use this to decide if they should expose the cut
  /// functionality to the user.
  bool canCut(TextSelectionDelegate delegate) {
    return delegate.cutEnabled && !delegate.textEditingValue.selection.isCollapsed;
  }

  /// Whether the current selection of the text field managed by the given
  /// `delegate` can be copied to the [Clipboard].
  ///
  /// By default, false is returned when nothing is selected in the text field.
  ///
  /// Subclasses can use this to decide if they should expose the copy
  /// functionality to the user.
  bool canCopy(TextSelectionDelegate delegate) {
    return delegate.copyEnabled && !delegate.textEditingValue.selection.isCollapsed;
  }

  /// Whether the text field managed by the given `delegate` supports pasting
  /// from the clipboard.
  ///
  /// Subclasses can use this to decide if they should expose the paste
  /// functionality to the user.
  ///
  /// This does not consider the contents of the clipboard. Subclasses may want
  /// to, for example, disallow pasting when the clipboard contains an empty
  /// string.
  bool canPaste(TextSelectionDelegate delegate) {
    return delegate.pasteEnabled;
  }

  /// Whether the current selection of the text field managed by the given
  /// `delegate` can be extended to include the entire content of the text
  /// field.
  ///
  /// Subclasses can use this to decide if they should expose the select all
  /// functionality to the user.
  bool canSelectAll(TextSelectionDelegate delegate) {
    return delegate.selectAllEnabled && delegate.textEditingValue.text.isNotEmpty && delegate.textEditingValue.selection.isCollapsed;
  }

  /// Call [TextSelectionDelegate.cutSelection] to cut current selection.
  ///
  /// This is called by subclasses when their cut affordance is activated by
  /// the user.
  // TODO(chunhtai): remove optional parameter once migration is done.
  // https://github.com/flutter/flutter/issues/99360
  void handleCut(TextSelectionDelegate delegate, [ClipboardStatusNotifier? clipboardStatus]) {
    delegate.cutSelection(SelectionChangedCause.toolbar);
  }

  /// Call [TextSelectionDelegate.copySelection] to copy current selection.
  ///
  /// This is called by subclasses when their copy affordance is activated by
  /// the user.
  // TODO(chunhtai): remove optional parameter once migration is done.
  // https://github.com/flutter/flutter/issues/99360
  void handleCopy(TextSelectionDelegate delegate, [ClipboardStatusNotifier? clipboardStatus]) {
    delegate.copySelection(SelectionChangedCause.toolbar);
  }

  /// Call [TextSelectionDelegate.pasteText] to paste text.
  ///
  /// This is called by subclasses when their paste affordance is activated by
  /// the user.
  ///
  /// This function is asynchronous since interacting with the clipboard is
  /// asynchronous. Race conditions may exist with this API as currently
  /// implemented.
  // TODO(ianh): https://github.com/flutter/flutter/issues/11427
  Future<void> handlePaste(TextSelectionDelegate delegate) async {
    delegate.pasteText(SelectionChangedCause.toolbar);
  }

  /// Call [TextSelectionDelegate.selectAll] to set the current selection to
  /// contain the entire text value.
  ///
  /// Does not hide the toolbar.
  ///
  /// This is called by subclasses when their select-all affordance is activated
  /// by the user.
  void handleSelectAll(TextSelectionDelegate delegate) {
    delegate.selectAll(SelectionChangedCause.toolbar);
  }
}

/// Text selection controls that do not show any toolbars or handles.
///
/// This is a placeholder, suitable for temporary use during development, but
/// not practical for production. For example, it provides no way for the user
/// to interact with selections: no context menus on desktop, no toolbars or
/// drag handles on mobile, etc. For production, consider using
/// [MaterialTextSelectionControls] or creating a custom subclass of
/// [TextSelectionControls].
///
/// The [emptyTextSelectionControls] global variable has a
/// suitable instance of this class.
class EmptyTextSelectionControls extends TextSelectionControls {
  @override
  Size getHandleSize(double textLineHeight) => Size.zero;

  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) => const SizedBox.shrink();

  @override
  Widget buildHandle(BuildContext context, TextSelectionHandleType type, double textLineHeight, [VoidCallback? onTap]) {
    return const SizedBox.shrink();
  }

  @override
  Offset getHandleAnchor(TextSelectionHandleType type, double textLineHeight) {
    return Offset.zero;
  }
}

/// Text selection controls that do not show any toolbars or handles.
///
/// This is a placeholder, suitable for temporary use during development, but
/// not practical for production. For example, it provides no way for the user
/// to interact with selections: no context menus on desktop, no toolbars or
/// drag handles on mobile, etc. For production, consider using
/// [materialTextSelectionControls] or creating a custom subclass of
/// [TextSelectionControls].
final TextSelectionControls emptyTextSelectionControls = EmptyTextSelectionControls();


/// An object that manages a pair of text selection handles for a
/// [RenderEditable].
///
/// This class is a wrapper of [SelectionOverlay] to provide APIs specific for
/// [RenderEditable]s. To manage selection handles for custom widgets, use
/// [SelectionOverlay] instead.
class TextSelectionOverlay {
  /// Creates an object that manages overlay entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  TextSelectionOverlay({
    required TextEditingValue value,
    required this.context,
    Widget? debugRequiredFor,
    required LayerLink toolbarLayerLink,
    required LayerLink startHandleLayerLink,
    required LayerLink endHandleLayerLink,
    required this.renderObject,
    this.selectionControls,
    bool handlesVisible = false,
    required this.selectionDelegate,
    DragStartBehavior dragStartBehavior = DragStartBehavior.start,
    VoidCallback? onSelectionHandleTapped,
    ClipboardStatusNotifier? clipboardStatus,
    required TextMagnifierConfiguration magnifierConfiguration,
  }) : assert(value != null),
       assert(context != null),
       assert(handlesVisible != null),
       _handlesVisible = handlesVisible,
       _value = value {
    renderObject.selectionStartInViewport.addListener(_updateTextSelectionOverlayVisibilities);
    renderObject.selectionEndInViewport.addListener(_updateTextSelectionOverlayVisibilities);
    _updateTextSelectionOverlayVisibilities();
    _selectionOverlay = SelectionOverlay(
      magnifierConfiguration: magnifierConfiguration,
      context: context,
      debugRequiredFor: debugRequiredFor,
      // The metrics will be set when show handles.
      startHandleType: TextSelectionHandleType.collapsed,
      startHandlesVisible: _effectiveStartHandleVisibility,
      lineHeightAtStart: 0.0,
      onStartHandleDragStart: _handleSelectionStartHandleDragStart,
      onStartHandleDragUpdate: _handleSelectionStartHandleDragUpdate,
      onEndHandleDragEnd: _handleAnyDragEnd,
      endHandleType: TextSelectionHandleType.collapsed,
      endHandlesVisible: _effectiveEndHandleVisibility,
      lineHeightAtEnd: 0.0,
      onEndHandleDragStart: _handleSelectionEndHandleDragStart,
      onEndHandleDragUpdate: _handleSelectionEndHandleDragUpdate,
      onStartHandleDragEnd: _handleAnyDragEnd,
      toolbarVisible: _effectiveToolbarVisibility,
      selectionEndpoints: const <TextSelectionPoint>[],
      selectionControls: selectionControls,
      selectionDelegate: selectionDelegate,
      clipboardStatus: clipboardStatus,
      startHandleLayerLink: startHandleLayerLink,
      endHandleLayerLink: endHandleLayerLink,
      toolbarLayerLink: toolbarLayerLink,
      onSelectionHandleTapped: onSelectionHandleTapped,
      dragStartBehavior: dragStartBehavior,
      toolbarLocation: renderObject.lastSecondaryTapDownPosition,
    );
  }

  /// Controls the fade-in and fade-out animations for the toolbar and handles.
  @Deprecated(
    'Use `SelectionOverlay.fadeDuration` instead. '
    'This feature was deprecated after v2.12.0-4.1.pre.'
  )
  static const Duration fadeDuration = SelectionOverlay.fadeDuration;

  // TODO(mpcomplete): what if the renderObject is removed or replaced, or
  // moves? Not sure what cases I need to handle, or how to handle them.
  /// The editable line in which the selected text is being displayed.
  final RenderEditable renderObject;

  /// {@macro flutter.widgets.SelectionOverlay.selectionControls}
  final TextSelectionControls? selectionControls;

  /// {@macro flutter.widgets.SelectionOverlay.selectionDelegate}
  final TextSelectionDelegate selectionDelegate;

  late final SelectionOverlay _selectionOverlay;

  /// Retrieve current value.
  @visibleForTesting
  TextEditingValue get value => _value;

  TextEditingValue _value;

  TextSelection get _selection => _value.selection;

  final ValueNotifier<bool> _effectiveStartHandleVisibility = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _effectiveEndHandleVisibility = ValueNotifier<bool>(false);
  final ValueNotifier<bool> _effectiveToolbarVisibility = ValueNotifier<bool>(false);

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;

  void _updateTextSelectionOverlayVisibilities() {
    _effectiveStartHandleVisibility.value = _handlesVisible && renderObject.selectionStartInViewport.value;
    _effectiveEndHandleVisibility.value = _handlesVisible && renderObject.selectionEndInViewport.value;
    _effectiveToolbarVisibility.value = renderObject.selectionStartInViewport.value || renderObject.selectionEndInViewport.value;
  }

  /// Whether selection handles are visible.
  ///
  /// Set to false if you want to hide the handles. Use this property to show or
  /// hide the handle without rebuilding them.
  ///
  /// Defaults to false.
  bool get handlesVisible => _handlesVisible;
  bool _handlesVisible = false;
  set handlesVisible(bool visible) {
    assert(visible != null);
    if (_handlesVisible == visible) {
      return;
    }
    _handlesVisible = visible;
    _updateTextSelectionOverlayVisibilities();
  }

  /// {@macro flutter.widgets.SelectionOverlay.showHandles}
  void showHandles() {
    _updateSelectionOverlay();
    _selectionOverlay.showHandles();
  }

  /// {@macro flutter.widgets.SelectionOverlay.hideHandles}
  void hideHandles() => _selectionOverlay.hideHandles();

  /// {@macro flutter.widgets.SelectionOverlay.showToolbar}
  void showToolbar() {
    _updateSelectionOverlay();
    _selectionOverlay.showToolbar();
  }

  /// {@macro flutter.widgets.SelectionOverlay.showMagnifier}
  void showMagnifier(Offset positionToShow) {
    final TextPosition position = renderObject.getPositionForPoint(positionToShow);
    _updateSelectionOverlay();
    _selectionOverlay.showMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: positionToShow,
        renderEditable: renderObject,
      ),
    );
  }

  /// {@macro flutter.widgets.SelectionOverlay.updateMagnifier}
  void updateMagnifier(Offset positionToShow) {
    final TextPosition position = renderObject.getPositionForPoint(positionToShow);
    _updateSelectionOverlay();
    _selectionOverlay.updateMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: positionToShow,
        renderEditable: renderObject,
      ),
    );
  }

  /// {@macro flutter.widgets.SelectionOverlay.hideMagnifier}
  void hideMagnifier({required bool shouldShowToolbar}) {
    _selectionOverlay.hideMagnifier(shouldShowToolbar: shouldShowToolbar);
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
    if (_value == newValue) {
      return;
    }
    _value = newValue;
    _updateSelectionOverlay();
  }

  void _updateSelectionOverlay() {
    _selectionOverlay
      // Update selection handle metrics.
      ..startHandleType = _chooseType(
        renderObject.textDirection,
        TextSelectionHandleType.left,
        TextSelectionHandleType.right,
      )
      ..lineHeightAtStart = _getStartGlyphHeight()
      ..endHandleType = _chooseType(
        renderObject.textDirection,
        TextSelectionHandleType.right,
        TextSelectionHandleType.left,
      )
      ..lineHeightAtEnd = _getEndGlyphHeight()
      // Update selection toolbar metrics.
      ..selectionEndpoints = renderObject.getEndpointsForSelection(_selection)
      ..toolbarLocation = renderObject.lastSecondaryTapDownPosition;
  }

  /// Causes the overlay to update its rendering.
  ///
  /// This is intended to be called when the [renderObject] may have changed its
  /// text metrics (e.g. because the text was scrolled).
  void updateForScroll() => _updateSelectionOverlay();

  /// Whether the handles are currently visible.
  bool get handlesAreVisible => _selectionOverlay._handles != null && handlesVisible;

  /// Whether the toolbar is currently visible.
  bool get toolbarIsVisible => _selectionOverlay._toolbar != null;

  /// Whether the magnifier is currently visible.
  bool get magnifierIsVisible => _selectionOverlay._magnifierController.shown;

  /// {@macro flutter.widgets.SelectionOverlay.hide}
  void hide() => _selectionOverlay.hide();

  /// {@macro flutter.widgets.SelectionOverlay.hideToolbar}
  void hideToolbar() => _selectionOverlay.hideToolbar();

  /// {@macro flutter.widgets.SelectionOverlay.dispose}
  void dispose() {
    _selectionOverlay.dispose();
    renderObject.selectionStartInViewport.removeListener(_updateTextSelectionOverlayVisibilities);
    renderObject.selectionEndInViewport.removeListener(_updateTextSelectionOverlayVisibilities);
    _effectiveToolbarVisibility.dispose();
    _effectiveStartHandleVisibility.dispose();
    _effectiveEndHandleVisibility.dispose();
  }

  double _getStartGlyphHeight() {
    final InlineSpan span = renderObject.text!;
    final String prevText = span.toPlainText();
    final String currText = selectionDelegate.textEditingValue.text;
    final int firstSelectedGraphemeExtent;
    Rect? startHandleRect;
    // Only calculate handle rects if the text in the previous frame
    // is the same as the text in the current frame. This is done because
    // widget.renderObject contains the renderEditable from the previous frame.
    // If the text changed between the current and previous frames then
    // widget.renderObject.getRectForComposingRange might fail. In cases where
    // the current frame is different from the previous we fall back to
    // renderObject.preferredLineHeight.
    if (prevText == currText && _selection != null && _selection.isValid && !_selection.isCollapsed) {
      final String selectedGraphemes = _selection.textInside(currText);
      firstSelectedGraphemeExtent = selectedGraphemes.characters.first.length;
      startHandleRect = renderObject.getRectForComposingRange(TextRange(start: _selection.start, end: _selection.start + firstSelectedGraphemeExtent));
    }
    return startHandleRect?.height ?? renderObject.preferredLineHeight;
  }

  double _getEndGlyphHeight() {
    final InlineSpan span = renderObject.text!;
    final String prevText = span.toPlainText();
    final String currText = selectionDelegate.textEditingValue.text;
    final int lastSelectedGraphemeExtent;
    Rect? endHandleRect;
    // See the explanation in _getStartGlyphHeight.
    if (prevText == currText && _selection != null && _selection.isValid && !_selection.isCollapsed) {
      final String selectedGraphemes = _selection.textInside(currText);
      lastSelectedGraphemeExtent = selectedGraphemes.characters.last.length;
      endHandleRect = renderObject.getRectForComposingRange(TextRange(start: _selection.end - lastSelectedGraphemeExtent, end: _selection.end));
    }
    return endHandleRect?.height ?? renderObject.preferredLineHeight;
  }

  MagnifierOverlayInfoBearer _buildMagnifier({
    required RenderEditable renderEditable,
    required Offset globalGesturePosition,
    required TextPosition currentTextPosition,
  }) {
    final Offset globalRenderEditableTopLeft = renderEditable.localToGlobal(Offset.zero);
    final Rect localCaretRect = renderEditable.getLocalRectForCaret(currentTextPosition);

    final TextSelection lineAtOffset = renderEditable.getLineAtOffset(currentTextPosition);
    final TextPosition positionAtEndOfLine = TextPosition(
        offset: lineAtOffset.extentOffset,
        affinity: TextAffinity.upstream,
    );

    // Default affinity is downstream.
    final TextPosition positionAtBeginningOfLine = TextPosition(
      offset: lineAtOffset.baseOffset,
    );

    final Rect lineBoundaries = Rect.fromPoints(
      renderEditable.getLocalRectForCaret(positionAtBeginningOfLine).topCenter,
      renderEditable.getLocalRectForCaret(positionAtEndOfLine).bottomCenter,
    );

    return MagnifierOverlayInfoBearer(
      fieldBounds: globalRenderEditableTopLeft & renderEditable.size,
      globalGesturePosition: globalGesturePosition,
      caretRect: localCaretRect.shift(globalRenderEditableTopLeft),
      currentLineBoundaries: lineBoundaries.shift(globalRenderEditableTopLeft),
    );
  }

  late Offset _dragEndPosition;

  void _handleSelectionEndHandleDragStart(DragStartDetails details) {
    if (!renderObject.attached) {
      return;
    }
    final Size handleSize = selectionControls!.getHandleSize(
      renderObject.preferredLineHeight,
    );

    _dragEndPosition = details.globalPosition + Offset(0.0, -handleSize.height);
    final TextPosition position = renderObject.getPositionForPoint(_dragEndPosition);

    _selectionOverlay.showMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ),
    );
  }

  void _handleSelectionEndHandleDragUpdate(DragUpdateDetails details) {
    if (!renderObject.attached) {
      return;
    }
    _dragEndPosition += details.delta;

    final TextPosition position = renderObject.getPositionForPoint(_dragEndPosition);
    final TextSelection currentSelection = TextSelection.fromPosition(position);

    if (_selection.isCollapsed) {
      _selectionOverlay.updateMagnifier(_buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ));

      _handleSelectionHandleChanged(currentSelection, isEnd: true);
      return;
    }

    final TextSelection newSelection;
    switch (defaultTargetPlatform) {
      // On Apple platforms, dragging the base handle makes it the extent.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        newSelection = TextSelection(
          extentOffset: position.offset,
          baseOffset: _selection.start,
        );
        if (position.offset <= _selection.start) {
          return; // Don't allow order swapping.
        }
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        newSelection = TextSelection(
          baseOffset: _selection.baseOffset,
          extentOffset: position.offset,
        );
        if (newSelection.baseOffset >= newSelection.extentOffset) {
          return; // Don't allow order swapping.
        }
        break;
    }

    _handleSelectionHandleChanged(newSelection, isEnd: true);

     _selectionOverlay.updateMagnifier(_buildMagnifier(
      currentTextPosition: newSelection.extent,
      globalGesturePosition: details.globalPosition,
      renderEditable: renderObject,
    ));
  }

  late Offset _dragStartPosition;

  void _handleSelectionStartHandleDragStart(DragStartDetails details) {
    if (!renderObject.attached) {
      return;
    }
    final Size handleSize = selectionControls!.getHandleSize(
      renderObject.preferredLineHeight,
    );
    _dragStartPosition = details.globalPosition + Offset(0.0, -handleSize.height);
    final TextPosition position = renderObject.getPositionForPoint(_dragStartPosition);

    _selectionOverlay.showMagnifier(
      _buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ),
    );
  }

  void _handleSelectionStartHandleDragUpdate(DragUpdateDetails details) {
    if (!renderObject.attached) {
      return;
    }
    _dragStartPosition += details.delta;
    final TextPosition position = renderObject.getPositionForPoint(_dragStartPosition);

    if (_selection.isCollapsed) {
      _selectionOverlay.updateMagnifier(_buildMagnifier(
        currentTextPosition: position,
        globalGesturePosition: details.globalPosition,
        renderEditable: renderObject,
      ));

      _handleSelectionHandleChanged(TextSelection.fromPosition(position), isEnd: false);
      return;
    }

    final TextSelection newSelection;
    switch (defaultTargetPlatform) {
      // On Apple platforms, dragging the base handle makes it the extent.
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        newSelection = TextSelection(
          extentOffset: position.offset,
          baseOffset: _selection.end,
        );
        if (newSelection.extentOffset >= _selection.end) {
          return; // Don't allow order swapping.
        }
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        newSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: _selection.extentOffset,
        );
        if (newSelection.baseOffset >= newSelection.extentOffset) {
          return; // Don't allow order swapping.
        }
        break;
    }

    _selectionOverlay.updateMagnifier(_buildMagnifier(
      currentTextPosition: newSelection.extent.offset < newSelection.base.offset ? newSelection.extent : newSelection.base,
      globalGesturePosition: details.globalPosition,
      renderEditable: renderObject,
    ));

    _handleSelectionHandleChanged(newSelection, isEnd: false);
  }

  void _handleAnyDragEnd(DragEndDetails details) => _selectionOverlay.hideMagnifier(shouldShowToolbar: !_selection.isCollapsed);

  void _handleSelectionHandleChanged(TextSelection newSelection, {required bool isEnd}) {
    final TextPosition textPosition = isEnd ? newSelection.extent : newSelection.base;
    selectionDelegate.userUpdateTextEditingValue(
      _value.copyWith(selection: newSelection),
      SelectionChangedCause.drag,
    );
    selectionDelegate.bringIntoView(textPosition);
  }

  TextSelectionHandleType _chooseType(
      TextDirection textDirection,
      TextSelectionHandleType ltrType,
      TextSelectionHandleType rtlType,
      ) {
    if (_selection.isCollapsed) {
      return TextSelectionHandleType.collapsed;
    }

    assert(textDirection != null);
    switch (textDirection) {
      case TextDirection.ltr:
        return ltrType;
      case TextDirection.rtl:
        return rtlType;
    }
  }
}

/// An object that manages a pair of selection handles and a toolbar.
///
/// The selection handles are displayed in the [Overlay] that most closely
/// encloses the given [BuildContext].
class SelectionOverlay {
  /// Creates an object that manages overlay entries for selection handles.
  ///
  /// The [context] must not be null and must have an [Overlay] as an ancestor.
  SelectionOverlay({
    required this.context,
    this.debugRequiredFor,
    required TextSelectionHandleType startHandleType,
    required double lineHeightAtStart,
    this.startHandlesVisible,
    this.onStartHandleDragStart,
    this.onStartHandleDragUpdate,
    this.onStartHandleDragEnd,
    required TextSelectionHandleType endHandleType,
    required double lineHeightAtEnd,
    this.endHandlesVisible,
    this.onEndHandleDragStart,
    this.onEndHandleDragUpdate,
    this.onEndHandleDragEnd,
    this.toolbarVisible,
    required List<TextSelectionPoint> selectionEndpoints,
    required this.selectionControls,
    required this.selectionDelegate,
    required this.clipboardStatus,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.toolbarLayerLink,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onSelectionHandleTapped,
    Offset? toolbarLocation,
    this.magnifierConfiguration = TextMagnifierConfiguration.disabled,
  }) : _startHandleType = startHandleType,
       _lineHeightAtStart = lineHeightAtStart,
       _endHandleType = endHandleType,
       _lineHeightAtEnd = lineHeightAtEnd,
       _selectionEndpoints = selectionEndpoints,
       _toolbarLocation = toolbarLocation,
       assert(debugCheckHasOverlay(context));

  /// The context in which the selection handles should appear.
  ///
  /// This context must have an [Overlay] as an ancestor because this object
  /// will display the text selection handles in that [Overlay].
  final BuildContext context;


  final ValueNotifier<MagnifierOverlayInfoBearer> _magnifierOverlayInfoBearer =
      ValueNotifier<MagnifierOverlayInfoBearer>(MagnifierOverlayInfoBearer.empty);

  /// [MagnifierController.show] and [MagnifierController.hide] should not be called directly, except
  /// from inside [showMagnifier] and [hideMagnifier]. If it is desired to show or hide the magnifier,
  /// call [showMagnifier] or [hideMagnifier]. This is because the magnifier needs to orchestrate
  /// with other properties in [SelectionOverlay].
  final MagnifierController _magnifierController = MagnifierController();

  /// {@macro flutter.widgets.magnifier.TextMagnifierConfiguration.intro}
  ///
  /// {@macro flutter.widgets.magnifier.intro}
  ///
  /// By default, [SelectionOverlay]'s [TextMagnifierConfiguration] is disabled.
  ///
  /// {@macro flutter.widgets.magnifier.TextMagnifierConfiguration.details}
  final TextMagnifierConfiguration magnifierConfiguration;

  /// {@template flutter.widgets.SelectionOverlay.showMagnifier}
  /// Shows the magnifier, and hides the toolbar if it was showing when [showMagnifier]
  /// was called. This is safe to call on platforms not mobile, since
  /// a magnifierBuilder will not be provided, or the magnifierBuilder will return null
  /// on platforms not mobile.
  ///
  /// This is NOT the source of truth for if the magnifier is up or not,
  /// since magnifiers may hide themselves. If this info is needed, check
  /// [MagnifierController.shown].
  /// {@endtemplate}
  void showMagnifier(MagnifierOverlayInfoBearer initialInfoBearer) {
    if (_toolbar != null) {
      hideToolbar();
    }

    // Start from empty, so we don't utilize any remnant values.
    _magnifierOverlayInfoBearer.value = initialInfoBearer;

    // Pre-build the magnifiers so we can tell if we've built something
    // or not. If we don't build a magnifiers, then we should not
    // insert anything in the overlay.
    final Widget? builtMagnifier = magnifierConfiguration.magnifierBuilder(
      context,
      _magnifierController,
      _magnifierOverlayInfoBearer,
    );

    if (builtMagnifier == null) {
      return;
    }

    _magnifierController.show(
        context: context,
        below: magnifierConfiguration.shouldDisplayHandlesInMagnifier
            ? null
            : _handles?.first,
        builder: (_) => builtMagnifier);
  }

  /// {@template flutter.widgets.SelectionOverlay.hideMagnifier}
  /// Hide the current magnifier, optionally immediately showing
  /// the toolbar.
  ///
  /// This does nothing if there is no magnifier.
  /// {@endtemplate}
  void hideMagnifier({required bool shouldShowToolbar}) {
    // This cannot be a check on `MagnifierController.shown`, since
    // it's possible that the magnifier is still in the overlay, but
    // not shown in cases where the magnifier hides itself.
    if (_magnifierController.overlayEntry == null) {
      return;
    }

    _magnifierController.hide();

    if (shouldShowToolbar) {
      showToolbar();
    }
  }

  /// The type of start selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  TextSelectionHandleType get startHandleType => _startHandleType;
  TextSelectionHandleType _startHandleType;
  set startHandleType(TextSelectionHandleType value) {
    if (_startHandleType == value) {
      return;
    }
    _startHandleType = value;
    _markNeedsBuild();
  }

  /// The line height at the selection start.
  ///
  /// This value is used for calculating the size of the start selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  double get lineHeightAtStart => _lineHeightAtStart;
  double _lineHeightAtStart;
  set lineHeightAtStart(double value) {
    if (_lineHeightAtStart == value) {
      return;
    }
    _lineHeightAtStart = value;
    _markNeedsBuild();
  }

  /// Whether the start handle is visible.
  ///
  /// If the value changes, the start handle uses [FadeTransition] to transition
  /// itself on and off the screen.
  ///
  /// If this is null, the start selection handle will always be visible.
  final ValueListenable<bool>? startHandlesVisible;

  /// Called when the users start dragging the start selection handles.
  final ValueChanged<DragStartDetails>? onStartHandleDragStart;

  /// Called when the users drag the start selection handles to new locations.
  final ValueChanged<DragUpdateDetails>? onStartHandleDragUpdate;

  /// Called when the users lift their fingers after dragging the start selection
  /// handles.
  final ValueChanged<DragEndDetails>? onStartHandleDragEnd;

  /// The type of end selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  TextSelectionHandleType get endHandleType => _endHandleType;
  TextSelectionHandleType _endHandleType;
  set endHandleType(TextSelectionHandleType value) {
    if (_endHandleType == value) {
      return;
    }
    _endHandleType = value;
    _markNeedsBuild();
  }

  /// The line height at the selection end.
  ///
  /// This value is used for calculating the size of the end selection handle.
  ///
  /// Changing the value while the handles are visible causes them to rebuild.
  double get lineHeightAtEnd => _lineHeightAtEnd;
  double _lineHeightAtEnd;
  set lineHeightAtEnd(double value) {
    if (_lineHeightAtEnd == value) {
      return;
    }
    _lineHeightAtEnd = value;
    _markNeedsBuild();
  }

  /// Whether the end handle is visible.
  ///
  /// If the value changes, the end handle uses [FadeTransition] to transition
  /// itself on and off the screen.
  ///
  /// If this is null, the end selection handle will always be visible.
  final ValueListenable<bool>? endHandlesVisible;

  /// Called when the users start dragging the end selection handles.
  final ValueChanged<DragStartDetails>? onEndHandleDragStart;

  /// Called when the users drag the end selection handles to new locations.
  final ValueChanged<DragUpdateDetails>? onEndHandleDragUpdate;

  /// Called when the users lift their fingers after dragging the end selection
  /// handles.
  final ValueChanged<DragEndDetails>? onEndHandleDragEnd;

  /// Whether the toolbar is visible.
  ///
  /// If the value changes, the toolbar uses [FadeTransition] to transition
  /// itself on and off the screen.
  ///
  /// If this is null the toolbar will always be visible.
  final ValueListenable<bool>? toolbarVisible;

  /// The text selection positions of selection start and end.
  List<TextSelectionPoint> get selectionEndpoints => _selectionEndpoints;
  List<TextSelectionPoint> _selectionEndpoints;
  set selectionEndpoints(List<TextSelectionPoint> value) {
    if (!listEquals(_selectionEndpoints, value)) {
      _markNeedsBuild();
    }
    _selectionEndpoints = value;
  }

  /// Debugging information for explaining why the [Overlay] is required.
  final Widget? debugRequiredFor;

  /// The object supplied to the [CompositedTransformTarget] that wraps the text
  /// field.
  final LayerLink toolbarLayerLink;

  /// The objects supplied to the [CompositedTransformTarget] that wraps the
  /// location of start selection handle.
  final LayerLink startHandleLayerLink;

  /// The objects supplied to the [CompositedTransformTarget] that wraps the
  /// location of end selection handle.
  final LayerLink endHandleLayerLink;

  /// {@template flutter.widgets.SelectionOverlay.selectionControls}
  /// Builds text selection handles and toolbar.
  /// {@endtemplate}
  final TextSelectionControls? selectionControls;

  /// {@template flutter.widgets.SelectionOverlay.selectionDelegate}
  /// The delegate for manipulating the current selection in the owning
  /// text field.
  /// {@endtemplate}
  final TextSelectionDelegate selectionDelegate;

  /// Determines the way that drag start behavior is handled.
  ///
  /// If set to [DragStartBehavior.start], handle drag behavior will
  /// begin at the position where the drag gesture won the arena. If set to
  /// [DragStartBehavior.down] it will begin at the position where a down
  /// event is first detected.
  ///
  /// In general, setting this to [DragStartBehavior.start] will make drag
  /// animation smoother and setting it to [DragStartBehavior.down] will make
  /// drag behavior feel slightly more reactive.
  ///
  /// By default, the drag start behavior is [DragStartBehavior.start].
  ///
  /// See also:
  ///
  ///  * [DragGestureRecognizer.dragStartBehavior], which gives an example for the different behaviors.
  final DragStartBehavior dragStartBehavior;

  /// {@template flutter.widgets.SelectionOverlay.onSelectionHandleTapped}
  /// A callback that's optionally invoked when a selection handle is tapped.
  ///
  /// The [TextSelectionControls.buildHandle] implementation the text field
  /// uses decides where the handle's tap "hotspot" is, or whether the
  /// selection handle supports tap gestures at all. For instance,
  /// [MaterialTextSelectionControls] calls [onSelectionHandleTapped] when the
  /// selection handle's "knob" is tapped, while
  /// [CupertinoTextSelectionControls] builds a handle that's not sufficiently
  /// large for tapping (as it's not meant to be tapped) so it does not call
  /// [onSelectionHandleTapped] even when tapped.
  /// {@endtemplate}
  // See https://github.com/flutter/flutter/issues/39376#issuecomment-848406415
  // for provenance.
  final VoidCallback? onSelectionHandleTapped;

  /// Maintains the status of the clipboard for determining if its contents can
  /// be pasted or not.
  ///
  /// Useful because the actual value of the clipboard can only be checked
  /// asynchronously (see [Clipboard.getData]).
  final ClipboardStatusNotifier? clipboardStatus;

  /// The location of where the toolbar should be drawn in relative to the
  /// location of [toolbarLayerLink].
  ///
  /// If this is null, the toolbar is drawn based on [selectionEndpoints] and
  /// the rect of render object of [context].
  ///
  /// This is useful for displaying toolbars at the mouse right-click locations
  /// in desktop devices.
  Offset? get toolbarLocation => _toolbarLocation;
  Offset? _toolbarLocation;
  set toolbarLocation(Offset? value) {
    if (_toolbarLocation == value) {
      return;
    }
    _toolbarLocation = value;
    _markNeedsBuild();
  }

  /// Controls the fade-in and fade-out animations for the toolbar and handles.
  static const Duration fadeDuration = Duration(milliseconds: 150);

  /// A pair of handles. If this is non-null, there are always 2, though the
  /// second is hidden when the selection is collapsed.
  List<OverlayEntry>? _handles;

  /// A copy/paste toolbar.
  OverlayEntry? _toolbar;

  /// {@template flutter.widgets.SelectionOverlay.showHandles}
  /// Builds the handles by inserting them into the [context]'s overlay.
  /// {@endtemplate}
  void showHandles() {
    if (_handles != null) {
      return;
    }

    _handles = <OverlayEntry>[
      OverlayEntry(builder: _buildStartHandle),
      OverlayEntry(builder: _buildEndHandle),
    ];

    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor).insertAll(_handles!);
  }

  /// {@template flutter.widgets.SelectionOverlay.hideHandles}
  /// Destroys the handles by removing them from overlay.
  /// {@endtemplate}
  void hideHandles() {
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
  }

  /// {@template flutter.widgets.SelectionOverlay.showToolbar}
  /// Shows the toolbar by inserting it into the [context]'s overlay.
  /// {@endtemplate}
  void showToolbar() {
    if (_toolbar != null) {
      return;
    }
    _toolbar = OverlayEntry(builder: _buildToolbar);
    Overlay.of(context, rootOverlay: true, debugRequiredFor: debugRequiredFor).insert(_toolbar!);
  }

  bool _buildScheduled = false;
  void _markNeedsBuild() {
    if (_handles == null && _toolbar == null) {
      return;
    }
    // If we are in build state, it will be too late to update visibility.
    // We will need to schedule the build in next frame.
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      if (_buildScheduled) {
        return;
      }
      _buildScheduled = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration duration) {
        _buildScheduled = false;
        if (_handles != null) {
          _handles![0].markNeedsBuild();
          _handles![1].markNeedsBuild();
        }
        _toolbar?.markNeedsBuild();
      });
    } else {
      if (_handles != null) {
        _handles![0].markNeedsBuild();
        _handles![1].markNeedsBuild();
      }
      _toolbar?.markNeedsBuild();
    }
  }

  /// {@template flutter.widgets.SelectionOverlay.hide}
  /// Hides the entire overlay including the toolbar and the handles.
  /// {@endtemplate}
  void hide() {
    _magnifierController.hide();
    if (_handles != null) {
      _handles![0].remove();
      _handles![1].remove();
      _handles = null;
    }
    if (_toolbar != null) {
      hideToolbar();
    }
  }

  /// {@template flutter.widgets.SelectionOverlay.hideToolbar}
  /// Hides the toolbar part of the overlay.
  ///
  /// To hide the whole overlay, see [hide].
  /// {@endtemplate}
  void hideToolbar() {
    if (_toolbar == null) {
      return;
    }
    _toolbar?.remove();
    _toolbar = null;
  }

  /// {@template flutter.widgets.SelectionOverlay.dispose}
  /// Disposes this object and release resources.
  /// {@endtemplate}
  void dispose() {
    hide();
  }

  Widget _buildStartHandle(BuildContext context) {
    final Widget handle;
    final TextSelectionControls? selectionControls = this.selectionControls;
    if (selectionControls == null) {
      handle = const SizedBox.shrink();
    } else {
      handle = _SelectionHandleOverlay(
        type: _startHandleType,
        handleLayerLink: startHandleLayerLink,
        onSelectionHandleTapped: onSelectionHandleTapped,
        onSelectionHandleDragStart: onStartHandleDragStart,
        onSelectionHandleDragUpdate: onStartHandleDragUpdate,
        onSelectionHandleDragEnd: onStartHandleDragEnd,
        selectionControls: selectionControls,
        visibility: startHandlesVisible,
        preferredLineHeight: _lineHeightAtStart,
        dragStartBehavior: dragStartBehavior,
      );
    }
    return TextFieldTapRegion(
      child: ExcludeSemantics(
        child: handle,
      ),
    );
  }

  Widget _buildEndHandle(BuildContext context) {
    final Widget handle;
    final TextSelectionControls? selectionControls = this.selectionControls;
    if (selectionControls == null || _startHandleType == TextSelectionHandleType.collapsed) {
      // Hide the second handle when collapsed.
      handle = const SizedBox.shrink();
    } else {
      handle = _SelectionHandleOverlay(
        type: _endHandleType,
        handleLayerLink: endHandleLayerLink,
        onSelectionHandleTapped: onSelectionHandleTapped,
        onSelectionHandleDragStart: onEndHandleDragStart,
        onSelectionHandleDragUpdate: onEndHandleDragUpdate,
        onSelectionHandleDragEnd: onEndHandleDragEnd,
        selectionControls: selectionControls,
        visibility: endHandlesVisible,
        preferredLineHeight: _lineHeightAtEnd,
        dragStartBehavior: dragStartBehavior,
      );
    }
    return TextFieldTapRegion(
      child: ExcludeSemantics(
        child: handle,
      ),
    );
  }

  Widget _buildToolbar(BuildContext context) {
    if (selectionControls == null) {
      return const SizedBox.shrink();
    }

    final RenderBox renderBox = this.context.findRenderObject()! as RenderBox;

    final Rect editingRegion = Rect.fromPoints(
      renderBox.localToGlobal(Offset.zero),
      renderBox.localToGlobal(renderBox.size.bottomRight(Offset.zero)),
    );

    final bool isMultiline = selectionEndpoints.last.point.dy - selectionEndpoints.first.point.dy >
        lineHeightAtEnd / 2;

    // If the selected text spans more than 1 line, horizontally center the toolbar.
    // Derived from both iOS and Android.
    final double midX = isMultiline
      ? editingRegion.width / 2
      : (selectionEndpoints.first.point.dx + selectionEndpoints.last.point.dx) / 2;

    final Offset midpoint = Offset(
      midX,
      // The y-coordinate won't be made use of most likely.
      selectionEndpoints.first.point.dy - lineHeightAtStart,
    );

    return TextFieldTapRegion(
      child: Directionality(
        textDirection: Directionality.of(this.context),
        child: _SelectionToolbarOverlay(
          preferredLineHeight: lineHeightAtStart,
          toolbarLocation: toolbarLocation,
          layerLink: toolbarLayerLink,
          editingRegion: editingRegion,
          selectionControls: selectionControls,
          midpoint: midpoint,
          selectionEndpoints: selectionEndpoints,
          visibility: toolbarVisible,
          selectionDelegate: selectionDelegate,
          clipboardStatus: clipboardStatus,
        ),
      ),
    );
  }

  /// {@template flutter.widgets.SelectionOverlay.updateMagnifier}
  /// Update the current magnifier with new selection data, so the magnifier
  /// can respond accordingly.
  ///
  /// If the magnifier is not shown, this still updates the magnifier position
  /// because the magnifier may have hidden itself and is looking for a cue to reshow
  /// itself.
  ///
  /// If there is no magnifier in the overlay, this does nothing,
  /// {@endtemplate}
  void updateMagnifier(MagnifierOverlayInfoBearer magnifierOverlayInfoBearer) {
    if (_magnifierController.overlayEntry == null) {
      return;
    }

    _magnifierOverlayInfoBearer.value = magnifierOverlayInfoBearer;
  }
}

/// This widget represents a selection toolbar.
class _SelectionToolbarOverlay extends StatefulWidget {
  /// Creates a toolbar overlay.
  const _SelectionToolbarOverlay({
    required this.preferredLineHeight,
    required this.toolbarLocation,
    required this.layerLink,
    required this.editingRegion,
    required this.selectionControls,
    this.visibility,
    required this.midpoint,
    required this.selectionEndpoints,
    required this.selectionDelegate,
    required this.clipboardStatus,
  });

  final double preferredLineHeight;
  final Offset? toolbarLocation;
  final LayerLink layerLink;
  final Rect editingRegion;
  final TextSelectionControls? selectionControls;
  final ValueListenable<bool>? visibility;
  final Offset midpoint;
  final List<TextSelectionPoint> selectionEndpoints;
  final TextSelectionDelegate? selectionDelegate;
  final ClipboardStatusNotifier? clipboardStatus;

  @override
  _SelectionToolbarOverlayState createState() => _SelectionToolbarOverlayState();
}

class _SelectionToolbarOverlayState extends State<_SelectionToolbarOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: SelectionOverlay.fadeDuration, vsync: this);

    _toolbarVisibilityChanged();
    widget.visibility?.addListener(_toolbarVisibilityChanged);
  }

  @override
  void didUpdateWidget(_SelectionToolbarOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.visibility == widget.visibility) {
      return;
    }
    oldWidget.visibility?.removeListener(_toolbarVisibilityChanged);
    _toolbarVisibilityChanged();
    widget.visibility?.addListener(_toolbarVisibilityChanged);
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_toolbarVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  void _toolbarVisibilityChanged() {
    if (widget.visibility?.value ?? true) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: CompositedTransformFollower(
        link: widget.layerLink,
        showWhenUnlinked: false,
        offset: -widget.editingRegion.topLeft,
        child: Builder(
          builder: (BuildContext context) {
            return widget.selectionControls!.buildToolbar(
              context,
              widget.editingRegion,
              widget.preferredLineHeight,
              widget.midpoint,
              widget.selectionEndpoints,
              widget.selectionDelegate!,
              widget.clipboardStatus,
              widget.toolbarLocation,
            );
          },
        ),
      ),
    );
  }
}

/// This widget represents a single draggable selection handle.
class _SelectionHandleOverlay extends StatefulWidget {
  /// Create selection overlay.
  const _SelectionHandleOverlay({
    required this.type,
    required this.handleLayerLink,
    this.onSelectionHandleTapped,
    this.onSelectionHandleDragStart,
    this.onSelectionHandleDragUpdate,
    this.onSelectionHandleDragEnd,
    required this.selectionControls,
    this.visibility,
    required this.preferredLineHeight,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  final LayerLink handleLayerLink;
  final VoidCallback? onSelectionHandleTapped;
  final ValueChanged<DragStartDetails>? onSelectionHandleDragStart;
  final ValueChanged<DragUpdateDetails>? onSelectionHandleDragUpdate;
  final ValueChanged<DragEndDetails>? onSelectionHandleDragEnd;
  final TextSelectionControls selectionControls;
  final ValueListenable<bool>? visibility;
  final double preferredLineHeight;
  final TextSelectionHandleType type;
  final DragStartBehavior dragStartBehavior;

  @override
  State<_SelectionHandleOverlay> createState() => _SelectionHandleOverlayState();

}

class _SelectionHandleOverlayState extends State<_SelectionHandleOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: SelectionOverlay.fadeDuration, vsync: this);

    _handleVisibilityChanged();
    widget.visibility?.addListener(_handleVisibilityChanged);
  }

  void _handleVisibilityChanged() {
    if (widget.visibility?.value ?? true) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void didUpdateWidget(_SelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    oldWidget.visibility?.removeListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
    widget.visibility?.addListener(_handleVisibilityChanged);
  }

  @override
  void dispose() {
    widget.visibility?.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Offset handleAnchor = widget.selectionControls.getHandleAnchor(
      widget.type,
      widget.preferredLineHeight,
    );
    final Size handleSize = widget.selectionControls.getHandleSize(
      widget.preferredLineHeight,
    );

    final Rect handleRect = Rect.fromLTWH(
      -handleAnchor.dx,
      -handleAnchor.dy,
      handleSize.width,
      handleSize.height,
    );

    // Make sure the GestureDetector is big enough to be easily interactive.
    final Rect interactiveRect = handleRect.expandToInclude(
      Rect.fromCircle(center: handleRect.center, radius: kMinInteractiveDimension/ 2),
    );
    final RelativeRect padding = RelativeRect.fromLTRB(
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
      math.max((interactiveRect.width - handleRect.width) / 2, 0),
      math.max((interactiveRect.height - handleRect.height) / 2, 0),
    );

    return CompositedTransformFollower(
      link: widget.handleLayerLink,
      offset: interactiveRect.topLeft,
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _opacity,
        child: Container(
          alignment: Alignment.topLeft,
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              PanGestureRecognizer: GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
                () => PanGestureRecognizer(
                  debugOwner: this,
                  // Mouse events select the text and do not drag the cursor.
                  supportedDevices: <PointerDeviceKind>{
                    PointerDeviceKind.touch,
                    PointerDeviceKind.stylus,
                    PointerDeviceKind.unknown,
                  },
                ),
                (PanGestureRecognizer instance) {
                  instance
                    ..dragStartBehavior = widget.dragStartBehavior
                    ..onStart = widget.onSelectionHandleDragStart
                    ..onUpdate = widget.onSelectionHandleDragUpdate
                    ..onEnd = widget.onSelectionHandleDragEnd;
                },
              ),
            },
            child: Padding(
              padding: EdgeInsets.only(
                left: padding.left,
                top: padding.top,
                right: padding.right,
                bottom: padding.bottom,
              ),
              child: widget.selectionControls.buildHandle(
                context,
                widget.type,
                widget.preferredLineHeight,
                widget.onSelectionHandleTapped,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Delegate interface for the [TextSelectionGestureDetectorBuilder].
///
/// The interface is usually implemented by text field implementations wrapping
/// [EditableText], that use a [TextSelectionGestureDetectorBuilder] to build a
/// [TextSelectionGestureDetector] for their [EditableText]. The delegate provides
/// the builder with information about the current state of the text field.
/// Based on these information, the builder adds the correct gesture handlers
/// to the gesture detector.
///
/// See also:
///
///  * [TextField], which implements this delegate for the Material text field.
///  * [CupertinoTextField], which implements this delegate for the Cupertino
///    text field.
abstract class TextSelectionGestureDetectorBuilderDelegate {
  /// [GlobalKey] to the [EditableText] for which the
  /// [TextSelectionGestureDetectorBuilder] will build a [TextSelectionGestureDetector].
  GlobalKey<EditableTextState> get editableTextKey;

  /// Whether the text field should respond to force presses.
  bool get forcePressEnabled;

  /// Whether the user may select text in the text field.
  bool get selectionEnabled;
}

/// Builds a [TextSelectionGestureDetector] to wrap an [EditableText].
///
/// The class implements sensible defaults for many user interactions
/// with an [EditableText] (see the documentation of the various gesture handler
/// methods, e.g. [onTapDown], [onForcePressStart], etc.). Subclasses of
/// [TextSelectionGestureDetectorBuilder] can change the behavior performed in
/// responds to these gesture events by overriding the corresponding handler
/// methods of this class.
///
/// The resulting [TextSelectionGestureDetector] to wrap an [EditableText] is
/// obtained by calling [buildGestureDetector].
///
/// See also:
///
///  * [TextField], which uses a subclass to implement the Material-specific
///    gesture logic of an [EditableText].
///  * [CupertinoTextField], which uses a subclass to implement the
///    Cupertino-specific gesture logic of an [EditableText].
class TextSelectionGestureDetectorBuilder {
  /// Creates a [TextSelectionGestureDetectorBuilder].
  ///
  /// The [delegate] must not be null.
  TextSelectionGestureDetectorBuilder({
    required this.delegate,
  }) : assert(delegate != null);

  /// The delegate for this [TextSelectionGestureDetectorBuilder].
  ///
  /// The delegate provides the builder with information about what actions can
  /// currently be performed on the text field. Based on this, the builder adds
  /// the correct gesture handlers to the gesture detector.
  @protected
  final TextSelectionGestureDetectorBuilderDelegate delegate;

  /// Returns true if lastSecondaryTapDownPosition was on selection.
  bool get _lastSecondaryTapWasOnSelection {
    assert(renderEditable.lastSecondaryTapDownPosition != null);
    if (renderEditable.selection == null) {
      return false;
    }

    final TextPosition textPosition = renderEditable.getPositionForPoint(
      renderEditable.lastSecondaryTapDownPosition!,
    );

    return renderEditable.selection!.start <= textPosition.offset
        && renderEditable.selection!.end >= textPosition.offset;
  }

  bool _tapWasOnSelection(Offset position) {
    if (renderEditable.selection == null) {
      return false;
    }

    final TextPosition textPosition = renderEditable.getPositionForPoint(
      position,
    );

    return renderEditable.selection!.start < textPosition.offset
        && renderEditable.selection!.end > textPosition.offset;
  }

  // Expand the selection to the given global position.
  //
  // Either base or extent will be moved to the last tapped position, whichever
  // is closest. The selection will never shrink or pivot, only grow.
  //
  // If fromSelection is given, will expand from that selection instead of the
  // current selection in renderEditable.
  //
  // See also:
  //
  //   * [_extendSelection], which is similar but pivots the selection around
  //     the base.
  void _expandSelection(Offset offset, SelectionChangedCause cause, [TextSelection? fromSelection]) {
    assert(cause != null);
    assert(offset != null);
    assert(renderEditable.selection?.baseOffset != null);

    final TextPosition tappedPosition = renderEditable.getPositionForPoint(offset);
    final TextSelection selection = fromSelection ?? renderEditable.selection!;
    final bool baseIsCloser =
        (tappedPosition.offset - selection.baseOffset).abs()
        < (tappedPosition.offset - selection.extentOffset).abs();
    final TextSelection nextSelection = selection.copyWith(
      baseOffset: baseIsCloser ? selection.extentOffset : selection.baseOffset,
      extentOffset: tappedPosition.offset,
    );

    editableText.userUpdateTextEditingValue(
      editableText.textEditingValue.copyWith(
        selection: nextSelection,
      ),
      cause,
    );
  }

  // Extend the selection to the given global position.
  //
  // Holds the base in place and moves the extent.
  //
  // See also:
  //
  //   * [_expandSelection], which is similar but always increases the size of
  //     the selection.
  void _extendSelection(Offset offset, SelectionChangedCause cause) {
    assert(cause != null);
    assert(offset != null);
    assert(renderEditable.selection?.baseOffset != null);

    final TextPosition tappedPosition = renderEditable.getPositionForPoint(offset);
    final TextSelection selection = renderEditable.selection!;
    final TextSelection nextSelection = selection.copyWith(
      extentOffset: tappedPosition.offset,
    );

    editableText.userUpdateTextEditingValue(
      editableText.textEditingValue.copyWith(
        selection: nextSelection,
      ),
      cause,
    );
  }

  /// Whether to show the selection toolbar.
  ///
  /// It is based on the signal source when a [onTapDown] is called. This getter
  /// will return true if current [onTapDown] event is triggered by a touch or
  /// a stylus.
  bool get shouldShowSelectionToolbar => _shouldShowSelectionToolbar;
  bool _shouldShowSelectionToolbar = true;

  /// The [State] of the [EditableText] for which the builder will provide a
  /// [TextSelectionGestureDetector].
  @protected
  EditableTextState get editableText => delegate.editableTextKey.currentState!;

  /// The [RenderObject] of the [EditableText] for which the builder will
  /// provide a [TextSelectionGestureDetector].
  @protected
  RenderEditable get renderEditable => editableText.renderEditable;

  // The viewport offset pixels of the [RenderEditable] at the last drag start.
  double _dragStartViewportOffset = 0.0;

  // Returns true iff either shift key is currently down.
  bool get _isShiftPressed {
    return HardwareKeyboard.instance.logicalKeysPressed
      .any(<LogicalKeyboardKey>{
        LogicalKeyboardKey.shiftLeft,
        LogicalKeyboardKey.shiftRight,
      }.contains);
  }

  // True iff a tap + shift has been detected but the tap has not yet come up.
  bool _isShiftTapping = false;

  // For a shift + tap + drag gesture, the TextSelection at the point of the
  // tap. Mac uses this value to reset to the original selection when an
  // inversion of the base and offset happens.
  TextSelection? _shiftTapDragSelection;

  /// Handler for [TextSelectionGestureDetector.onTapDown].
  ///
  /// By default, it forwards the tap to [RenderEditable.handleTapDown] and sets
  /// [shouldShowSelectionToolbar] to true if the tap was initiated by a finger or stylus.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onTapDown], which triggers this callback.
  @protected
  void onTapDown(TapDownDetails details) {
    if (!delegate.selectionEnabled) {
      return;
    }
    renderEditable.handleTapDown(details);
    // The selection overlay should only be shown when the user is interacting
    // through a touch screen (via either a finger or a stylus). A mouse shouldn't
    // trigger the selection overlay.
    // For backwards-compatibility, we treat a null kind the same as touch.
    final PointerDeviceKind? kind = details.kind;
    _shouldShowSelectionToolbar = kind == null
      || kind == PointerDeviceKind.touch
      || kind == PointerDeviceKind.stylus;

    // Handle shift + click selection if needed.
    final bool isShiftPressedValid = _isShiftPressed && renderEditable.selection?.baseOffset != null;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.iOS:
        // On mobile platforms the selection is set on tap up.
        if (_isShiftTapping) {
          _isShiftTapping = false;
        }
        break;
      case TargetPlatform.macOS:
        // On macOS, a shift-tapped unfocused field expands from 0, not from the
        // previous selection.
        if (isShiftPressedValid) {
          _isShiftTapping = true;
          final TextSelection? fromSelection = renderEditable.hasFocus
              ? null
              : const TextSelection.collapsed(offset: 0);
          _expandSelection(
            details.globalPosition,
            SelectionChangedCause.tap,
            fromSelection,
          );
          return;
        }
        // On macOS, a tap/click places the selection in a precise position.
        // This differs from iOS/iPadOS, where if the gesture is done by a touch
        // then the selection moves to the closest word edge, instead of a
        // precise position.
        renderEditable.selectPosition(cause: SelectionChangedCause.tap);
        break;
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (isShiftPressedValid) {
          _isShiftTapping = true;
          _extendSelection(details.globalPosition, SelectionChangedCause.tap);
          return;
        }
        renderEditable.selectPosition(cause: SelectionChangedCause.tap);
        break;
    }
  }

  /// Handler for [TextSelectionGestureDetector.onForcePressStart].
  ///
  /// By default, it selects the word at the position of the force press,
  /// if selection is enabled.
  ///
  /// This callback is only applicable when force press is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onForcePressStart], which triggers this
  ///    callback.
  @protected
  void onForcePressStart(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    _shouldShowSelectionToolbar = true;
    if (delegate.selectionEnabled) {
      renderEditable.selectWordsInRange(
        from: details.globalPosition,
        cause: SelectionChangedCause.forcePress,
      );
    }
  }

  /// Handler for [TextSelectionGestureDetector.onForcePressEnd].
  ///
  /// By default, it selects words in the range specified in [details] and shows
  /// toolbar if it is necessary.
  ///
  /// This callback is only applicable when force press is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onForcePressEnd], which triggers this
  ///    callback.
  @protected
  void onForcePressEnd(ForcePressDetails details) {
    assert(delegate.forcePressEnabled);
    renderEditable.selectWordsInRange(
      from: details.globalPosition,
      cause: SelectionChangedCause.forcePress,
    );
    if (shouldShowSelectionToolbar) {
      editableText.showToolbar();
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleTapUp].
  ///
  /// By default, it selects word edge if selection is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleTapUp], which triggers
  ///    this callback.
  @protected
  void onSingleTapUp(TapUpDetails details) {
    if (delegate.selectionEnabled) {
      // Handle shift + click selection if needed.
      final bool isShiftPressedValid = _isShiftPressed && renderEditable.selection?.baseOffset != null;
      switch (defaultTargetPlatform) {
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          editableText.hideToolbar();
          // On desktop platforms the selection is set on tap down.
          if (_isShiftTapping) {
            _isShiftTapping = false;
          }
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
          editableText.hideToolbar();
          if (isShiftPressedValid) {
            _isShiftTapping = true;
            _extendSelection(details.globalPosition, SelectionChangedCause.tap);
            return;
          }
          renderEditable.selectPosition(cause: SelectionChangedCause.tap);
          break;
        case TargetPlatform.iOS:
          if (isShiftPressedValid) {
            // On iOS, a shift-tapped unfocused field expands from 0, not from
            // the previous selection.
            _isShiftTapping = true;
            final TextSelection? fromSelection = renderEditable.hasFocus
                ? null
                : const TextSelection.collapsed(offset: 0);
            _expandSelection(
              details.globalPosition,
              SelectionChangedCause.tap,
              fromSelection,
            );
            return;
          }
          switch (details.kind) {
            case PointerDeviceKind.mouse:
            case PointerDeviceKind.trackpad:
            case PointerDeviceKind.stylus:
            case PointerDeviceKind.invertedStylus:
              // Precise devices should place the cursor at a precise position.
              renderEditable.selectPosition(cause: SelectionChangedCause.tap);
              break;
            case PointerDeviceKind.touch:
            case PointerDeviceKind.unknown:
              // On iOS/iPadOS a touch tap places the cursor at the edge of the word.
              final TextSelection previousSelection = editableText.textEditingValue.selection;
              // If the tap was within the previous selection, then the selection should stay the same.
              if (!_tapWasOnSelection(details.globalPosition)) {
                renderEditable.selectWordEdge(cause: SelectionChangedCause.tap);
              }
              if (previousSelection == editableText.textEditingValue.selection && renderEditable.hasFocus) {
                editableText.toggleToolbar(false);
              } else {
                editableText.hideToolbar(false);
              }
              break;
          }
          break;
      }
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleTapCancel].
  ///
  /// By default, it services as place holder to enable subclass override.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleTapCancel], which triggers
  ///    this callback.
  @protected
  void onSingleTapCancel() {/* Subclass should override this method if needed. */}

  /// Handler for [TextSelectionGestureDetector.onSingleLongTapStart].
  ///
  /// By default, it selects text position specified in [details] if selection
  /// is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleLongTapStart], which triggers
  ///    this callback.
  @protected
  void onSingleLongTapStart(LongPressStartDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          editableText.showMagnifier(details.globalPosition);
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleLongTapMoveUpdate].
  ///
  /// By default, it updates the selection location specified in [details] if
  /// selection is enabled.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleLongTapMoveUpdate], which
  ///    triggers this callback.
  @protected
  void onSingleLongTapMoveUpdate(LongPressMoveUpdateDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.longPress,
      );

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.iOS:
          editableText.showMagnifier(details.globalPosition);
          break;
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSingleLongTapEnd].
  ///
  /// By default, it shows toolbar if necessary.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSingleLongTapEnd], which triggers this
  ///    callback.
  @protected
  void onSingleLongTapEnd(LongPressEndDetails details) {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
        editableText.hideMagnifier(shouldShowToolbar: false);
        break;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        break;
    }
    if (shouldShowSelectionToolbar) {
      editableText.showToolbar();
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSecondaryTap].
  ///
  /// By default, selects the word if possible and shows the toolbar.
  @protected
  void onSecondaryTap() {
    if (!delegate.selectionEnabled) {
      return;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (!_lastSecondaryTapWasOnSelection || !renderEditable.hasFocus) {
          renderEditable.selectWord(cause: SelectionChangedCause.tap);
        }
        if (shouldShowSelectionToolbar) {
          editableText.hideToolbar();
          editableText.showToolbar();
        }
        break;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        if (!renderEditable.hasFocus) {
          renderEditable.selectPosition(cause: SelectionChangedCause.tap);
        }
        editableText.toggleToolbar();
        break;
    }
  }

  /// Handler for [TextSelectionGestureDetector.onSecondaryTapDown].
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onSecondaryTapDown], which triggers this
  ///    callback.
  ///  * [onSecondaryTap], which is typically called after this.
  @protected
  void onSecondaryTapDown(TapDownDetails details) {
    renderEditable.handleSecondaryTapDown(details);
    _shouldShowSelectionToolbar = true;
  }

  /// Handler for [TextSelectionGestureDetector.onDoubleTapDown].
  ///
  /// By default, it selects a word through [RenderEditable.selectWord] if
  /// selectionEnabled and shows toolbar if necessary.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDoubleTapDown], which triggers this
  ///    callback.
  @protected
  void onDoubleTapDown(TapDownDetails details) {
    if (delegate.selectionEnabled) {
      renderEditable.selectWord(cause: SelectionChangedCause.tap);
      if (shouldShowSelectionToolbar) {
        editableText.showToolbar();
      }
    }
  }

  /// Handler for [TextSelectionGestureDetector.onDragSelectionStart].
  ///
  /// By default, it selects a text position specified in [details].
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDragSelectionStart], which triggers
  ///    this callback.
  @protected
  void onDragSelectionStart(DragStartDetails details) {
    if (!delegate.selectionEnabled) {
      return;
    }
    final PointerDeviceKind? kind = details.kind;
    _shouldShowSelectionToolbar = kind == null
      || kind == PointerDeviceKind.touch
      || kind == PointerDeviceKind.stylus;

    if (_isShiftPressed && renderEditable.selection != null && renderEditable.selection!.isValid) {
      _isShiftTapping = true;
      switch (defaultTargetPlatform) {
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          _expandSelection(details.globalPosition, SelectionChangedCause.drag);
          break;
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
        case TargetPlatform.windows:
          _extendSelection(details.globalPosition, SelectionChangedCause.drag);
          break;
      }
      _shiftTapDragSelection = renderEditable.selection;
    } else {
      renderEditable.selectPositionAt(
        from: details.globalPosition,
        cause: SelectionChangedCause.drag,
      );
    }

    _dragStartViewportOffset = renderEditable.offset.pixels;
  }

  /// Handler for [TextSelectionGestureDetector.onDragSelectionUpdate].
  ///
  /// By default, it updates the selection location specified in the provided
  /// details objects.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDragSelectionUpdate], which triggers
  ///    this callback./lib/src/material/text_field.dart
  @protected
  void onDragSelectionUpdate(DragStartDetails startDetails, DragUpdateDetails updateDetails) {
    if (!delegate.selectionEnabled) {
      return;
    }

    if (!_isShiftTapping) {
      // Adjust the drag start offset for possible viewport offset changes.
      final Offset startOffset = renderEditable.maxLines == 1
          ? Offset(renderEditable.offset.pixels - _dragStartViewportOffset, 0.0)
          : Offset(0.0, renderEditable.offset.pixels - _dragStartViewportOffset);

      return renderEditable.selectPositionAt(
        from: startDetails.globalPosition - startOffset,
        to: updateDetails.globalPosition,
        cause: SelectionChangedCause.drag,
      );
    }

    if (_shiftTapDragSelection!.isCollapsed
        || (defaultTargetPlatform != TargetPlatform.iOS
            && defaultTargetPlatform != TargetPlatform.macOS)) {
      return _extendSelection(updateDetails.globalPosition, SelectionChangedCause.drag);
    }

    // If the drag inverts the selection, Mac and iOS revert to the initial
    // selection.
    final TextSelection selection = editableText.textEditingValue.selection;
    final TextPosition nextExtent = renderEditable.getPositionForPoint(updateDetails.globalPosition);
    final bool isShiftTapDragSelectionForward =
        _shiftTapDragSelection!.baseOffset < _shiftTapDragSelection!.extentOffset;
    final bool isInverted = isShiftTapDragSelectionForward
        ? nextExtent.offset < _shiftTapDragSelection!.baseOffset
        : nextExtent.offset > _shiftTapDragSelection!.baseOffset;
    if (isInverted && selection.baseOffset == _shiftTapDragSelection!.baseOffset) {
      editableText.userUpdateTextEditingValue(
        editableText.textEditingValue.copyWith(
          selection: TextSelection(
            baseOffset: _shiftTapDragSelection!.extentOffset,
            extentOffset: nextExtent.offset,
          ),
        ),
        SelectionChangedCause.drag,
      );
    } else if (!isInverted
        && nextExtent.offset != _shiftTapDragSelection!.baseOffset
        && selection.baseOffset != _shiftTapDragSelection!.baseOffset) {
      editableText.userUpdateTextEditingValue(
        editableText.textEditingValue.copyWith(
          selection: TextSelection(
            baseOffset: _shiftTapDragSelection!.baseOffset,
            extentOffset: nextExtent.offset,
          ),
        ),
        SelectionChangedCause.drag,
      );
    } else {
      _extendSelection(updateDetails.globalPosition, SelectionChangedCause.drag);
    }
  }

  /// Handler for [TextSelectionGestureDetector.onDragSelectionEnd].
  ///
  /// By default, it simply cleans up the state used for handling certain
  /// built-in behaviors.
  ///
  /// See also:
  ///
  ///  * [TextSelectionGestureDetector.onDragSelectionEnd], which triggers this
  ///    callback.
  @protected
  void onDragSelectionEnd(DragEndDetails details) {
    if (_isShiftTapping) {
      _isShiftTapping = false;
      _shiftTapDragSelection = null;
    }
  }

  /// Returns a [TextSelectionGestureDetector] configured with the handlers
  /// provided by this builder.
  ///
  /// The [child] or its subtree should contain [EditableText].
  Widget buildGestureDetector({
    Key? key,
    HitTestBehavior? behavior,
    required Widget child,
  }) {
    return TextSelectionGestureDetector(
      key: key,
      onTapDown: onTapDown,
      onForcePressStart: delegate.forcePressEnabled ? onForcePressStart : null,
      onForcePressEnd: delegate.forcePressEnabled ? onForcePressEnd : null,
      onSecondaryTap: onSecondaryTap,
      onSecondaryTapDown: onSecondaryTapDown,
      onSingleTapUp: onSingleTapUp,
      onSingleTapCancel: onSingleTapCancel,
      onSingleLongTapStart: onSingleLongTapStart,
      onSingleLongTapMoveUpdate: onSingleLongTapMoveUpdate,
      onSingleLongTapEnd: onSingleLongTapEnd,
      onDoubleTapDown: onDoubleTapDown,
      onDragSelectionStart: onDragSelectionStart,
      onDragSelectionUpdate: onDragSelectionUpdate,
      onDragSelectionEnd: onDragSelectionEnd,
      behavior: behavior,
      child: child,
    );
  }
}

/// A gesture detector to respond to non-exclusive event chains for a text field.
///
/// An ordinary [GestureDetector] configured to handle events like tap and
/// double tap will only recognize one or the other. This widget detects both:
/// first the tap and then, if another tap down occurs within a time limit, the
/// double tap.
///
/// See also:
///
///  * [TextField], a Material text field which uses this gesture detector.
///  * [CupertinoTextField], a Cupertino text field which uses this gesture
///    detector.
class TextSelectionGestureDetector extends StatefulWidget {
  /// Create a [TextSelectionGestureDetector].
  ///
  /// Multiple callbacks can be called for one sequence of input gesture.
  /// The [child] parameter must not be null.
  const TextSelectionGestureDetector({
    super.key,
    this.onTapDown,
    this.onForcePressStart,
    this.onForcePressEnd,
    this.onSecondaryTap,
    this.onSecondaryTapDown,
    this.onSingleTapUp,
    this.onSingleTapCancel,
    this.onSingleLongTapStart,
    this.onSingleLongTapMoveUpdate,
    this.onSingleLongTapEnd,
    this.onDoubleTapDown,
    this.onDragSelectionStart,
    this.onDragSelectionUpdate,
    this.onDragSelectionEnd,
    this.behavior,
    required this.child,
  }) : assert(child != null);

  /// Called for every tap down including every tap down that's part of a
  /// double click or a long press, except touches that include enough movement
  /// to not qualify as taps (e.g. pans and flings).
  final GestureTapDownCallback? onTapDown;

  /// Called when a pointer has tapped down and the force of the pointer has
  /// just become greater than [ForcePressGestureRecognizer.startPressure].
  final GestureForcePressStartCallback? onForcePressStart;

  /// Called when a pointer that had previously triggered [onForcePressStart] is
  /// lifted off the screen.
  final GestureForcePressEndCallback? onForcePressEnd;

  /// Called for a tap event with the secondary mouse button.
  final GestureTapCallback? onSecondaryTap;

  /// Called for a tap down event with the secondary mouse button.
  final GestureTapDownCallback? onSecondaryTapDown;

  /// Called for each distinct tap except for every second tap of a double tap.
  /// For example, if the detector was configured with [onTapDown] and
  /// [onDoubleTapDown], three quick taps would be recognized as a single tap
  /// down, followed by a double tap down, followed by a single tap down.
  final GestureTapUpCallback? onSingleTapUp;

  /// Called for each touch that becomes recognized as a gesture that is not a
  /// short tap, such as a long tap or drag. It is called at the moment when
  /// another gesture from the touch is recognized.
  final GestureTapCancelCallback? onSingleTapCancel;

  /// Called for a single long tap that's sustained for longer than
  /// [kLongPressTimeout] but not necessarily lifted. Not called for a
  /// double-tap-hold, which calls [onDoubleTapDown] instead.
  final GestureLongPressStartCallback? onSingleLongTapStart;

  /// Called after [onSingleLongTapStart] when the pointer is dragged.
  final GestureLongPressMoveUpdateCallback? onSingleLongTapMoveUpdate;

  /// Called after [onSingleLongTapStart] when the pointer is lifted.
  final GestureLongPressEndCallback? onSingleLongTapEnd;

  /// Called after a momentary hold or a short tap that is close in space and
  /// time (within [kDoubleTapTimeout]) to a previous short tap.
  final GestureTapDownCallback? onDoubleTapDown;

  /// Called when a mouse starts dragging to select text.
  final GestureDragStartCallback? onDragSelectionStart;

  /// Called repeatedly as a mouse moves while dragging.
  ///
  /// The frequency of calls is throttled to avoid excessive text layout
  /// operations in text fields. The throttling is controlled by the constant
  /// [_kDragSelectionUpdateThrottle].
  final DragSelectionUpdateCallback? onDragSelectionUpdate;

  /// Called when a mouse that was previously dragging is released.
  final GestureDragEndCallback? onDragSelectionEnd;

  /// How this gesture detector should behave during hit testing.
  ///
  /// This defaults to [HitTestBehavior.deferToChild].
  final HitTestBehavior? behavior;

  /// Child below this widget.
  final Widget child;

  @override
  State<StatefulWidget> createState() => _TextSelectionGestureDetectorState();
}

class _TextSelectionGestureDetectorState extends State<TextSelectionGestureDetector> {
  // Counts down for a short duration after a previous tap. Null otherwise.
  Timer? _doubleTapTimer;
  Offset? _lastTapOffset;
  // True if a second tap down of a double tap is detected. Used to discard
  // subsequent tap up / tap hold of the same tap.
  bool _isDoubleTap = false;

  @override
  void dispose() {
    _doubleTapTimer?.cancel();
    _dragUpdateThrottleTimer?.cancel();
    super.dispose();
  }

  // The down handler is force-run on success of a single tap and optimistically
  // run before a long press success.
  void _handleTapDown(TapDownDetails details) {
    widget.onTapDown?.call(details);
    // This isn't detected as a double tap gesture in the gesture recognizer
    // because it's 2 single taps, each of which may do different things depending
    // on whether it's a single tap, the first tap of a double tap, the second
    // tap held down, a clean double tap etc.
    if (_doubleTapTimer != null && _isWithinDoubleTapTolerance(details.globalPosition)) {
      // If there was already a previous tap, the second down hold/tap is a
      // double tap down.
      widget.onDoubleTapDown?.call(details);

      _doubleTapTimer!.cancel();
      _doubleTapTimeout();
      _isDoubleTap = true;
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!_isDoubleTap) {
      widget.onSingleTapUp?.call(details);
      _lastTapOffset = details.globalPosition;
      _doubleTapTimer = Timer(kDoubleTapTimeout, _doubleTapTimeout);
    }
    _isDoubleTap = false;
  }

  void _handleTapCancel() {
    widget.onSingleTapCancel?.call();
  }

  DragStartDetails? _lastDragStartDetails;
  DragUpdateDetails? _lastDragUpdateDetails;
  Timer? _dragUpdateThrottleTimer;

  void _handleDragStart(DragStartDetails details) {
    assert(_lastDragStartDetails == null);
    _lastDragStartDetails = details;
    widget.onDragSelectionStart?.call(details);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _lastDragUpdateDetails = details;
    // Only schedule a new timer if there's no one pending.
    _dragUpdateThrottleTimer ??= Timer(_kDragSelectionUpdateThrottle, _handleDragUpdateThrottled);
  }

  /// Drag updates are being throttled to avoid excessive text layouts in text
  /// fields. The frequency of invocations is controlled by the constant
  /// [_kDragSelectionUpdateThrottle].
  ///
  /// Once the drag gesture ends, any pending drag update will be fired
  /// immediately. See [_handleDragEnd].
  void _handleDragUpdateThrottled() {
    assert(_lastDragStartDetails != null);
    assert(_lastDragUpdateDetails != null);
    widget.onDragSelectionUpdate?.call(_lastDragStartDetails!, _lastDragUpdateDetails!);
    _dragUpdateThrottleTimer = null;
    _lastDragUpdateDetails = null;
  }

  void _handleDragEnd(DragEndDetails details) {
    assert(_lastDragStartDetails != null);
    if (_dragUpdateThrottleTimer != null) {
      // If there's already an update scheduled, trigger it immediately and
      // cancel the timer.
      _dragUpdateThrottleTimer!.cancel();
      _handleDragUpdateThrottled();
    }
    widget.onDragSelectionEnd?.call(details);
    _dragUpdateThrottleTimer = null;
    _lastDragStartDetails = null;
    _lastDragUpdateDetails = null;
  }

  void _forcePressStarted(ForcePressDetails details) {
    _doubleTapTimer?.cancel();
    _doubleTapTimer = null;
    widget.onForcePressStart?.call(details);
  }

  void _forcePressEnded(ForcePressDetails details) {
    widget.onForcePressEnd?.call(details);
  }

  void _handleLongPressStart(LongPressStartDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapStart != null) {
      widget.onSingleLongTapStart!(details);
    }
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapMoveUpdate != null) {
      widget.onSingleLongTapMoveUpdate!(details);
    }
  }

  void _handleLongPressEnd(LongPressEndDetails details) {
    if (!_isDoubleTap && widget.onSingleLongTapEnd != null) {
      widget.onSingleLongTapEnd!(details);
    }
    _isDoubleTap = false;
  }

  void _doubleTapTimeout() {
    _doubleTapTimer = null;
    _lastTapOffset = null;
  }

  bool _isWithinDoubleTapTolerance(Offset secondTapOffset) {
    assert(secondTapOffset != null);
    if (_lastTapOffset == null) {
      return false;
    }

    final Offset difference = secondTapOffset - _lastTapOffset!;
    return difference.distance <= kDoubleTapSlop;
  }

  @override
  Widget build(BuildContext context) {
    final Map<Type, GestureRecognizerFactory> gestures = <Type, GestureRecognizerFactory>{};

    gestures[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance
          ..onSecondaryTap = widget.onSecondaryTap
          ..onSecondaryTapDown = widget.onSecondaryTapDown
          ..onTapDown = _handleTapDown
          ..onTapUp = _handleTapUp
          ..onTapCancel = _handleTapCancel;
      },
    );

    if (widget.onSingleLongTapStart != null ||
        widget.onSingleLongTapMoveUpdate != null ||
        widget.onSingleLongTapEnd != null) {
      gestures[LongPressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
        () => LongPressGestureRecognizer(debugOwner: this, kind: PointerDeviceKind.touch),
        (LongPressGestureRecognizer instance) {
          instance
            ..onLongPressStart = _handleLongPressStart
            ..onLongPressMoveUpdate = _handleLongPressMoveUpdate
            ..onLongPressEnd = _handleLongPressEnd;
        },
      );
    }

    if (widget.onDragSelectionStart != null ||
        widget.onDragSelectionUpdate != null ||
        widget.onDragSelectionEnd != null) {
      gestures[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
        () => PanGestureRecognizer(debugOwner: this, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
        (PanGestureRecognizer instance) {
          instance
            // Text selection should start from the position of the first pointer
            // down event.
            ..dragStartBehavior = DragStartBehavior.down
            ..onStart = _handleDragStart
            ..onUpdate = _handleDragUpdate
            ..onEnd = _handleDragEnd;
        },
      );
    }

    if (widget.onForcePressStart != null || widget.onForcePressEnd != null) {
      gestures[ForcePressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<ForcePressGestureRecognizer>(
        () => ForcePressGestureRecognizer(debugOwner: this),
        (ForcePressGestureRecognizer instance) {
          instance
            ..onStart = widget.onForcePressStart != null ? _forcePressStarted : null
            ..onEnd = widget.onForcePressEnd != null ? _forcePressEnded : null;
        },
      );
    }

    return RawGestureDetector(
      gestures: gestures,
      excludeFromSemantics: true,
      behavior: widget.behavior,
      child: widget.child,
    );
  }
}

/// A [ValueNotifier] whose [value] indicates whether the current contents of
/// the clipboard can be pasted.
///
/// The contents of the clipboard can only be read asynchronously, via
/// [Clipboard.getData], so this maintains a value that can be used
/// synchronously. Call [update] to asynchronously update value if needed.
class ClipboardStatusNotifier extends ValueNotifier<ClipboardStatus> with WidgetsBindingObserver {
  /// Create a new ClipboardStatusNotifier.
  ClipboardStatusNotifier({
    ClipboardStatus value = ClipboardStatus.unknown,
  }) : super(value);

  bool _disposed = false;
  // TODO(chunhtai): remove this getter once migration is done.
  // https://github.com/flutter/flutter/issues/99360
  /// True if this instance has been disposed.
  bool get disposed => _disposed;

  /// Check the [Clipboard] and update [value] if needed.
  Future<void> update() async {
    if (_disposed) {
      return;
    }

    final bool hasStrings;
    try {
      hasStrings = await Clipboard.hasStrings();
    } catch (exception, stack) {
      FlutterError.reportError(FlutterErrorDetails(
        exception: exception,
        stack: stack,
        library: 'widget library',
        context: ErrorDescription('while checking if the clipboard has strings'),
      ));
      // In the case of an error from the Clipboard API, set the value to
      // unknown so that it will try to update again later.
      if (_disposed || value == ClipboardStatus.unknown) {
        return;
      }
      value = ClipboardStatus.unknown;
      return;
    }

    final ClipboardStatus nextStatus = hasStrings
        ? ClipboardStatus.pasteable
        : ClipboardStatus.notPasteable;

    if (_disposed || nextStatus == value) {
      return;
    }
    value = nextStatus;
  }

  @override
  void addListener(VoidCallback listener) {
    if (!hasListeners) {
      WidgetsBinding.instance.addObserver(this);
    }
    if (value == ClipboardStatus.unknown) {
      update();
    }
    super.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!_disposed && !hasListeners) {
      WidgetsBinding.instance.removeObserver(this);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        update();
        break;
      case AppLifecycleState.detached:
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
        // Nothing to do.
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposed = true;
    super.dispose();
  }
}

/// An enumeration of the status of the content on the user's clipboard.
enum ClipboardStatus {
  /// The clipboard content can be pasted, such as a String of nonzero length.
  pasteable,

  /// The status of the clipboard is unknown. Since getting clipboard data is
  /// asynchronous (see [Clipboard.getData]), this status often exists while
  /// waiting to receive the clipboard contents for the first time.
  unknown,

  /// The content on the clipboard is not pastable, such as when it is empty.
  notPasteable,
}
