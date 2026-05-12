// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:characters/characters.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/widgets/ticker_provider.dart' show SingleTickerProviderStateMixin;

import 'basic.dart';
import 'constants.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'magnifier.dart';
import 'overlay.dart';
import 'selectable_region.dart';
import 'tap_region.dart';
import 'text_selection.dart'; // For TextSelectionControls
import 'transitions.dart';

/// A widget that manages text selection overlays.
class SelectionOverlayWidget extends StatefulWidget {
  /// Creates a [SelectionOverlayWidget].
  const SelectionOverlayWidget({
    super.key,
    required this.child,
    required this.controller,
    required this.editableKey,
    required this.selection,
    required this.selectionDelegate,
    this.onSelectionChanged,
    this.contextMenuBuilder,
    required this.selectionControls,
    required this.clipboardStatus,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.toolbarLayerLink,
    this.dragStartBehavior = DragStartBehavior.start,
    this.onSelectionHandleTapped,
    required this.isHandleShowing,
    this.showSelectionHandles = false,
    this.toolbarVisible = false,
    this.spellCheckToolbarVisible = false,
    this.spellCheckToolbarBuilder,
    this.onMagnifierShow,
    this.onMagnifierUpdate,
    this.onMagnifierHide,
    this.onDragEnd,
  });

  final Widget child;
  final OverlayPortalController controller;
  final GlobalKey editableKey;
  final TextSelection selection;
  final void Function({required TextSelection selection, required SelectionChangedCause? cause})?
  onSelectionChanged;
  final WidgetBuilder? contextMenuBuilder;
  final TextSelectionDelegate selectionDelegate;
  final TextSelectionControls? selectionControls;
  final ClipboardStatusNotifier? clipboardStatus;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final LayerLink toolbarLayerLink;
  final DragStartBehavior dragStartBehavior;
  final VoidCallback? onSelectionHandleTapped;
  final bool isHandleShowing;
  final bool showSelectionHandles;
  final bool toolbarVisible;
  final bool spellCheckToolbarVisible;
  final WidgetBuilder? spellCheckToolbarBuilder;
  final ValueChanged<MagnifierInfo>? onMagnifierShow;
  final ValueChanged<MagnifierInfo>? onMagnifierUpdate;
  final VoidCallback? onMagnifierHide;
  final VoidCallback? onDragEnd;

  @override
  State<SelectionOverlayWidget> createState() => _SelectionOverlayWidgetState();
}

class _SelectionOverlayWidgetState extends State<SelectionOverlayWidget> {
  RenderEditable? get _renderEditable =>
      widget.editableKey.currentContext?.findRenderObject() as RenderEditable?;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(SelectionOverlayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    super.dispose();
  }

  MagnifierInfo _buildMagnifier({
    required RenderEditable renderEditable,
    required Offset globalGesturePosition,
    required TextPosition currentTextPosition,
  }) {
    final TextSelection lineAtOffset = renderEditable.getLineAtOffset(currentTextPosition);
    final positionAtEndOfLine = TextPosition(
      offset: lineAtOffset.extentOffset,
      affinity: TextAffinity.upstream,
    );
    final positionAtBeginningOfLine = TextPosition(offset: lineAtOffset.baseOffset);

    final localLineBoundaries = Rect.fromPoints(
      renderEditable.getLocalRectForCaret(positionAtBeginningOfLine).topCenter,
      renderEditable.getLocalRectForCaret(positionAtEndOfLine).bottomCenter,
    );
    final overlay = Overlay.of(context, rootOverlay: true).context.findRenderObject() as RenderBox?;
    final Matrix4 transformToOverlay = renderEditable.getTransformTo(overlay);
    final Rect overlayLineBoundaries = MatrixUtils.transformRect(
      transformToOverlay,
      localLineBoundaries,
    );

    final Rect localCaretRect = renderEditable.getLocalRectForCaret(currentTextPosition);
    final Rect overlayCaretRect = MatrixUtils.transformRect(transformToOverlay, localCaretRect);

    final Offset overlayGesturePosition =
        overlay?.globalToLocal(globalGesturePosition) ?? globalGesturePosition;

    return MagnifierInfo(
      fieldBounds: MatrixUtils.transformRect(transformToOverlay, renderEditable.paintBounds),
      globalGesturePosition: overlayGesturePosition,
      caretRect: overlayCaretRect,
      currentLineBoundaries: overlayLineBoundaries,
    );
  }

  Widget _buildToolbarWidget({
    required BuildContext context,
    required OverlayChildLayoutInfo layoutInfo,
    required RenderEditable renderEditable,
    required bool isVisible,
  }) {
    if (widget.selectionControls == null && widget.contextMenuBuilder == null) {
      return const SizedBox.shrink();
    }

    final Rect editingRegion = MatrixUtils.transformRect(
      layoutInfo.childPaintTransform,
      Offset.zero & layoutInfo.childSize,
    );

    final List<TextSelectionPoint> endpoints = renderEditable.getEndpointsForSelection(
      widget.selection,
    );
    final double lineHeight = renderEditable.preferredLineHeight;

    final double midX;
    if (widget.selection.isCollapsed) {
      midX = endpoints.first.point.dx;
    } else {
      final bool isMultiline = endpoints.last.point.dy - endpoints.first.point.dy > lineHeight / 2;
      midX = isMultiline
          ? layoutInfo.childSize.width / 2
          : (endpoints.first.point.dx + endpoints.last.point.dx) / 2;
    }

    final midpoint = Offset(midX, endpoints.first.point.dy - lineHeight);

    Widget toolbarContent;
    if (widget.spellCheckToolbarVisible && widget.spellCheckToolbarBuilder != null) {
      toolbarContent = widget.spellCheckToolbarBuilder!(context);
    } else {
      final TextSelectionControls? controls = widget.selectionControls;

      if (controls != null && controls is! TextSelectionHandleControls) {
        toolbarContent = controls.buildToolbar(
          context,
          editingRegion,
          lineHeight,
          midpoint,
          endpoints,
          widget.selectionDelegate,
          widget.clipboardStatus,
          renderEditable.lastSecondaryTapDownPosition,
        );
      } else {
        toolbarContent =
            widget.contextMenuBuilder?.call(context) ??
            controls?.buildToolbar(
              context,
              editingRegion,
              lineHeight,
              midpoint,
              endpoints,
              widget.selectionDelegate,
              widget.clipboardStatus,
              renderEditable.lastSecondaryTapDownPosition,
            ) ??
            const SizedBox.shrink();
      }
    }

    return _SelectionToolbarWrapper(isVisible: isVisible, child: toolbarContent);
  }

  Widget _buildOverlayChild(BuildContext context, OverlayChildLayoutInfo layoutInfo) {
    // This layout builder phase is user-confirmed as the absolute safest location to interact
    // with live Render Tree geometry.
    final RenderEditable? renderEditable = _renderEditable;
    final bool hasVisibleElement =
        widget.isHandleShowing || widget.toolbarVisible || widget.spellCheckToolbarVisible;

    if (renderEditable == null || !hasVisibleElement) {
      return const SizedBox.shrink();
    }

    final bool startInViewport = renderEditable.selectionStartInViewport.value;
    final bool endInViewport = renderEditable.selectionEndInViewport.value;

    final Widget handlesLayer = widget.selection.isCollapsed
        ? _CollapsedSelectionOverlay(
            editableKey: widget.editableKey,
            selection: widget.selection,
            selectionDelegate: widget.selectionDelegate,
            isVisibleInViewport: startInViewport,
            selectionControls: widget.selectionControls,
            startHandleLayerLink: widget.startHandleLayerLink,
            dragStartBehavior: widget.dragStartBehavior,
            onSelectionHandleTapped: widget.onSelectionHandleTapped,
            handlesVisible: widget.isHandleShowing && widget.showSelectionHandles,
            onSelectionChanged: widget.onSelectionChanged,
            onMagnifierShow: widget.onMagnifierShow,
            onMagnifierUpdate: widget.onMagnifierUpdate,
            onMagnifierHide: widget.onMagnifierHide,
            buildMagnifier: _buildMagnifier,
            onDragEnd: widget.onDragEnd,
          )
        : _RangeSelectionOverlay(
            editableKey: widget.editableKey,
            selection: widget.selection,
            selectionDelegate: widget.selectionDelegate,
            startVisibleInViewport: startInViewport,
            endVisibleInViewport: endInViewport,
            selectionControls: widget.selectionControls,
            startHandleLayerLink: widget.startHandleLayerLink,
            endHandleLayerLink: widget.endHandleLayerLink,
            dragStartBehavior: widget.dragStartBehavior,
            onSelectionHandleTapped: widget.onSelectionHandleTapped,
            handlesVisible: widget.isHandleShowing && widget.showSelectionHandles,
            onSelectionChanged: widget.onSelectionChanged,
            onMagnifierShow: widget.onMagnifierShow,
            onMagnifierUpdate: widget.onMagnifierUpdate,
            onMagnifierHide: widget.onMagnifierHide,
            buildMagnifier: _buildMagnifier,
            onDragEnd: widget.onDragEnd,
          );

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        handlesLayer,
        if (widget.toolbarVisible || widget.spellCheckToolbarVisible)
          _buildToolbarWidget(
            context: context,
            layoutInfo: layoutInfo,
            renderEditable: renderEditable,
            isVisible: true,
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal.overlayChildLayoutBuilder(
      controller: widget.controller,
      overlayChildBuilder: _buildOverlayChild,
      child: widget.child,
    );
  }
}

typedef _MagnifierBuilderCallback =
    MagnifierInfo Function({
      required RenderEditable renderEditable,
      required Offset globalGesturePosition,
      required TextPosition currentTextPosition,
    });

/// Mathematical physics helper to snap cursor between line geometries.
double _getHandleDy(double dragDy, double handleDy, double preferredLineHeight) {
  final double distanceDragged = dragDy - handleDy;
  final dragDirection = distanceDragged < 0.0 ? -1 : 1;
  final int linesDragged = dragDirection * (distanceDragged.abs() / preferredLineHeight).floor();
  return handleDy + linesDragged * preferredLineHeight;
}

class _CollapsedSelectionOverlay extends StatefulWidget {
  const _CollapsedSelectionOverlay({
    required this.editableKey,
    required this.selection,
    required this.selectionDelegate,
    this.isVisibleInViewport = true,
    required this.selectionControls,
    required this.startHandleLayerLink,
    required this.dragStartBehavior,
    this.onSelectionHandleTapped,
    required this.handlesVisible,
    this.onSelectionChanged,
    this.onMagnifierShow,
    this.onMagnifierUpdate,
    this.onMagnifierHide,
    required this.buildMagnifier,
    this.onDragEnd,
  });

  final GlobalKey editableKey;
  final TextSelection selection;
  final TextSelectionDelegate selectionDelegate;
  final bool isVisibleInViewport;
  final TextSelectionControls? selectionControls;
  final LayerLink startHandleLayerLink;
  final DragStartBehavior dragStartBehavior;
  final VoidCallback? onSelectionHandleTapped;
  final bool handlesVisible;
  final void Function({required TextSelection selection, required SelectionChangedCause? cause})?
  onSelectionChanged;
  final ValueChanged<MagnifierInfo>? onMagnifierShow;
  final ValueChanged<MagnifierInfo>? onMagnifierUpdate;
  final VoidCallback? onMagnifierHide;
  final _MagnifierBuilderCallback buildMagnifier;
  final VoidCallback? onDragEnd;

  @override
  State<_CollapsedSelectionOverlay> createState() => _CollapsedSelectionOverlayState();
}

class _CollapsedSelectionOverlayState extends State<_CollapsedSelectionOverlay> {
  RenderEditable get _renderEditable =>
      widget.editableKey.currentContext!.findRenderObject()! as RenderEditable;

  late double _startHandleDragPosition;
  late double _startHandleDragTarget;
  bool _isDragging = false;

  double get _lineHeight => _renderEditable.preferredLineHeight;

  List<TextSelectionPoint> get _endpoints =>
      _renderEditable.getEndpointsForSelection(widget.selection);

  void _handleDragStart(DragStartDetails details) {
    _isDragging = details.kind == PointerDeviceKind.touch;
    _startHandleDragPosition = details.globalPosition.dy;

    final double centerOfLineLocal = _endpoints.first.point.dy - _lineHeight / 2;
    final double centerOfLineGlobal = _renderEditable
        .localToGlobal(Offset(0.0, centerOfLineLocal))
        .dy;
    _startHandleDragTarget = centerOfLineGlobal - details.globalPosition.dy;

    final TextPosition position = _renderEditable.getPositionForPoint(
      Offset(details.globalPosition.dx, centerOfLineGlobal),
    );

    widget.onMagnifierShow?.call(
      widget.buildMagnifier(
        renderEditable: _renderEditable,
        globalGesturePosition: details.globalPosition,
        currentTextPosition: position,
      ),
    );
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (!_isDragging) {
      _handleDragStart(
        DragStartDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          sourceTimeStamp: details.sourceTimeStamp,
          kind: details.kind,
        ),
      );
    }

    final Offset localPosition = _renderEditable.globalToLocal(details.globalPosition);
    final double startHandleDragLocalY = _renderEditable.globalToLocal(Offset(0.0, _startHandleDragPosition)).dy;
    final double nextPositionLocal = _getHandleDy(
      localPosition.dy,
      startHandleDragLocalY,
      _lineHeight,
    );

    _startHandleDragPosition = _renderEditable.localToGlobal(Offset(0.0, nextPositionLocal)).dy;

    final handleTargetGlobal = Offset(
      details.globalPosition.dx,
      _startHandleDragPosition + _startHandleDragTarget,
    );
    final TextPosition position = _renderEditable.getPositionForPoint(handleTargetGlobal);

    widget.onMagnifierUpdate?.call(
      widget.buildMagnifier(
        renderEditable: _renderEditable,
        globalGesturePosition: details.globalPosition,
        currentTextPosition: position,
      ),
    );

    final nextSelection = TextSelection.fromPosition(position);
    if (nextSelection != widget.selection) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          HapticFeedback.selectionClick();
        case TargetPlatform.fuchsia:
        case TargetPlatform.iOS:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    }
    widget.onSelectionChanged?.call(selection: nextSelection, cause: SelectionChangedCause.drag);
  }

  void _handleDragEnd(DragEndDetails details) {
    _isDragging = false;
    widget.onMagnifierHide?.call();
    widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectionControls == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: TapRegion(
            groupId: SelectableRegion,
            child: TextFieldTapRegion(
              child: ExcludeSemantics(
                child: _SelectionHandleOverlay(
                  type: TextSelectionHandleType.collapsed,
                  handleLayerLink: widget.startHandleLayerLink,
                  onSelectionHandleTapped: widget.onSelectionHandleTapped,
                  onSelectionHandleDragStart: _handleDragStart,
                  onSelectionHandleDragUpdate: _handleDragUpdate,
                  onSelectionHandleDragEnd: _handleDragEnd,
                  selectionControls: widget.selectionControls!,
                  handlesVisible: widget.handlesVisible,
                  inViewport: _renderEditable.selectionStartInViewport,
                  preferredLineHeight: _lineHeight,
                  dragStartBehavior: widget.dragStartBehavior,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RangeSelectionOverlay extends StatefulWidget {
  const _RangeSelectionOverlay({
    required this.editableKey,
    required this.selection,
    required this.selectionDelegate,
    this.startVisibleInViewport = true,
    this.endVisibleInViewport = true,
    required this.selectionControls,
    required this.startHandleLayerLink,
    required this.endHandleLayerLink,
    required this.dragStartBehavior,
    this.onSelectionHandleTapped,
    required this.handlesVisible,
    this.onSelectionChanged,
    this.onMagnifierShow,
    this.onMagnifierUpdate,
    this.onMagnifierHide,
    required this.buildMagnifier,
    this.onDragEnd,
  });

  final GlobalKey editableKey;
  final TextSelection selection;
  final TextSelectionDelegate selectionDelegate;
  final bool startVisibleInViewport;
  final bool endVisibleInViewport;
  final TextSelectionControls? selectionControls;
  final LayerLink startHandleLayerLink;
  final LayerLink endHandleLayerLink;
  final DragStartBehavior dragStartBehavior;
  final VoidCallback? onSelectionHandleTapped;
  final bool handlesVisible;
  final void Function({required TextSelection selection, required SelectionChangedCause? cause})?
  onSelectionChanged;
  final ValueChanged<MagnifierInfo>? onMagnifierShow;
  final ValueChanged<MagnifierInfo>? onMagnifierUpdate;
  final VoidCallback? onMagnifierHide;
  final _MagnifierBuilderCallback buildMagnifier;
  final VoidCallback? onDragEnd;

  @override
  State<_RangeSelectionOverlay> createState() => _RangeSelectionOverlayState();
}

class _RangeSelectionOverlayState extends State<_RangeSelectionOverlay> {
  RenderEditable get _renderEditable =>
      widget.editableKey.currentContext!.findRenderObject()! as RenderEditable;

  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  late double _startHandleDragPosition;
  late double _startHandleDragTarget;
  late double _endHandleDragPosition;
  late double _endHandleDragTarget;
  TextSelection? _dragStartSelection;

  List<TextSelectionPoint> get _endpoints =>
      _renderEditable.getEndpointsForSelection(widget.selection);

  TextSelectionHandleType _chooseType(
    TextDirection textDirection,
    TextSelectionHandleType ltrType,
    TextSelectionHandleType rtlType,
  ) {
    return switch (textDirection) {
      TextDirection.ltr => ltrType,
      TextDirection.rtl => rtlType,
    };
  }

  TextSelectionHandleType get _startHandleType => _chooseType(
    _renderEditable.textDirection,
    TextSelectionHandleType.left,
    TextSelectionHandleType.right,
  );

  TextSelectionHandleType get _endHandleType => _chooseType(
    _renderEditable.textDirection,
    TextSelectionHandleType.right,
    TextSelectionHandleType.left,
  );

  double get _lineHeightAtStart {
    final String currText = widget.selectionDelegate.textEditingValue.text;
    Rect? startHandleRect;
    if (_renderEditable.plainText == currText && widget.selection.isValid) {
      final String selectedGraphemes = widget.selection.textInside(currText);
      final int firstSelectedGraphemeExtent = selectedGraphemes.characters.first.length;
      startHandleRect = _renderEditable.getRectForComposingRange(
        TextRange(
          start: widget.selection.start,
          end: widget.selection.start + firstSelectedGraphemeExtent,
        ),
      );
    }
    return startHandleRect?.height ?? _renderEditable.preferredLineHeight;
  }

  double get _lineHeightAtEnd {
    final String currText = widget.selectionDelegate.textEditingValue.text;
    Rect? endHandleRect;
    if (_renderEditable.plainText == currText && widget.selection.isValid) {
      final String selectedGraphemes = widget.selection.textInside(currText);
      final int lastSelectedGraphemeExtent = selectedGraphemes.characters.last.length;
      endHandleRect = _renderEditable.getRectForComposingRange(
        TextRange(
          start: widget.selection.end - lastSelectedGraphemeExtent,
          end: widget.selection.end,
        ),
      );
    }
    return endHandleRect?.height ?? _renderEditable.preferredLineHeight;
  }

  bool get _canDragStart =>
      !_isDraggingEnd ||
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => false,
        TargetPlatform.android ||
        TargetPlatform.fuchsia ||
        TargetPlatform.linux ||
        TargetPlatform.windows => !kIsWeb,
      };

  bool get _canDragEnd =>
      !_isDraggingStart ||
      switch (defaultTargetPlatform) {
        TargetPlatform.iOS || TargetPlatform.macOS => false,
        TargetPlatform.android ||
        TargetPlatform.fuchsia ||
        TargetPlatform.linux ||
        TargetPlatform.windows => !kIsWeb,
      };

  void _handleStartDragStart(DragStartDetails details) {
    assert(!_isDraggingStart);
    if (!_canDragStart) {
      return;
    }
    _isDraggingStart = details.kind == PointerDeviceKind.touch;

    _startHandleDragPosition = details.globalPosition.dy;
    final double centerOfLineLocal =
        _endpoints.first.point.dy - _renderEditable.preferredLineHeight / 2;
    final double centerOfLineGlobal = _renderEditable
        .localToGlobal(Offset(0.0, centerOfLineLocal))
        .dy;
    _startHandleDragTarget = centerOfLineGlobal - details.globalPosition.dy;

    final TextPosition position = _renderEditable.getPositionForPoint(
      Offset(details.globalPosition.dx, centerOfLineGlobal),
    );

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _dragStartSelection ??= widget.selection;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }

    widget.onMagnifierShow?.call(
      widget.buildMagnifier(
        renderEditable: _renderEditable,
        globalGesturePosition: details.globalPosition,
        currentTextPosition: position,
      ),
    );
  }

  void _handleStartDragUpdate(DragUpdateDetails details) {
    if (!_canDragStart) {
      return;
    }
    if (!_isDraggingStart) {
      _handleStartDragStart(
        DragStartDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          sourceTimeStamp: details.sourceTimeStamp,
          kind: details.kind,
        ),
      );
    }

    final Offset localPosition = _renderEditable.globalToLocal(details.globalPosition);
    final double nextPositionLocal = _getHandleDy(
      localPosition.dy,
      _renderEditable.globalToLocal(Offset(0.0, _startHandleDragPosition)).dy,
      _renderEditable.preferredLineHeight,
    );
    _startHandleDragPosition = _renderEditable.localToGlobal(Offset(0.0, nextPositionLocal)).dy;

    final handleTargetGlobal = Offset(
      details.globalPosition.dx,
      _startHandleDragPosition + _startHandleDragTarget,
    );
    final TextPosition position = _renderEditable.getPositionForPoint(handleTargetGlobal);

    TextSelection? nextSelection;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        assert(_dragStartSelection != null);
        final bool dragStartSelectionNormalized =
            _dragStartSelection!.extentOffset >= _dragStartSelection!.baseOffset;
        nextSelection = TextSelection(
          baseOffset: dragStartSelectionNormalized
              ? _dragStartSelection!.extentOffset
              : _dragStartSelection!.baseOffset,
          extentOffset: position.offset,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        nextSelection = TextSelection(
          baseOffset: position.offset,
          extentOffset: widget.selection.extentOffset,
        );
        if (nextSelection.baseOffset >= nextSelection.extentOffset) {
          return;
        }
    }

    widget.onMagnifierUpdate?.call(
      widget.buildMagnifier(
        renderEditable: _renderEditable,
        globalGesturePosition: details.globalPosition,
        currentTextPosition: nextSelection.extent.offset < nextSelection.base.offset
            ? nextSelection.extent
            : nextSelection.base,
      ),
    );
    if (nextSelection != widget.selection) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          HapticFeedback.selectionClick();
        case TargetPlatform.fuchsia:
        case TargetPlatform.iOS:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    }
    widget.onSelectionChanged?.call(selection: nextSelection, cause: SelectionChangedCause.drag);
  }

  void _handleEndDragStart(DragStartDetails details) {
    assert(!_isDraggingEnd);
    if (!_canDragEnd) {
      return;
    }
    _isDraggingEnd = details.kind == PointerDeviceKind.touch;

    _endHandleDragPosition = details.globalPosition.dy;
    final double centerOfLineLocal =
        _endpoints.last.point.dy - _renderEditable.preferredLineHeight / 2;
    final double centerOfLineGlobal = _renderEditable
        .localToGlobal(Offset(0.0, centerOfLineLocal))
        .dy;
    _endHandleDragTarget = centerOfLineGlobal - details.globalPosition.dy;

    final TextPosition position = _renderEditable.getPositionForPoint(
      Offset(details.globalPosition.dx, centerOfLineGlobal),
    );

    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        _dragStartSelection ??= widget.selection;
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        break;
    }

    widget.onMagnifierShow?.call(
      widget.buildMagnifier(
        renderEditable: _renderEditable,
        globalGesturePosition: details.globalPosition,
        currentTextPosition: position,
      ),
    );
  }

  void _handleEndDragUpdate(DragUpdateDetails details) {
    if (!_canDragEnd) {
      return;
    }
    if (!_isDraggingEnd) {
      _handleEndDragStart(
        DragStartDetails(
          globalPosition: details.globalPosition,
          localPosition: details.localPosition,
          sourceTimeStamp: details.sourceTimeStamp,
          kind: details.kind,
        ),
      );
    }

    final Offset localPosition = _renderEditable.globalToLocal(details.globalPosition);
    final double nextPositionLocal = _getHandleDy(
      localPosition.dy,
      _renderEditable.globalToLocal(Offset(0.0, _endHandleDragPosition)).dy,
      _renderEditable.preferredLineHeight,
    );
    _endHandleDragPosition = _renderEditable.localToGlobal(Offset(0.0, nextPositionLocal)).dy;

    final handleTargetGlobal = Offset(
      details.globalPosition.dx,
      _endHandleDragPosition + _endHandleDragTarget,
    );
    final TextPosition position = _renderEditable.getPositionForPoint(handleTargetGlobal);

    TextSelection? nextSelection;
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        assert(_dragStartSelection != null);
        final bool dragStartSelectionNormalized =
            _dragStartSelection!.extentOffset >= _dragStartSelection!.baseOffset;
        nextSelection = TextSelection(
          baseOffset: dragStartSelectionNormalized
              ? _dragStartSelection!.baseOffset
              : _dragStartSelection!.extentOffset,
          extentOffset: position.offset,
        );
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        nextSelection = TextSelection(
          baseOffset: widget.selection.baseOffset,
          extentOffset: position.offset,
        );
        if (nextSelection.baseOffset >= nextSelection.extentOffset) {
          return;
        }
    }

    widget.onMagnifierUpdate?.call(
      widget.buildMagnifier(
        renderEditable: _renderEditable,
        globalGesturePosition: details.globalPosition,
        currentTextPosition: nextSelection.extent,
      ),
    );
    if (nextSelection != widget.selection) {
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          HapticFeedback.selectionClick();
        case TargetPlatform.fuchsia:
        case TargetPlatform.iOS:
        case TargetPlatform.linux:
        case TargetPlatform.macOS:
        case TargetPlatform.windows:
          break;
      }
    }
    widget.onSelectionChanged?.call(selection: nextSelection, cause: SelectionChangedCause.drag);
  }

  void _handleAnyDragEnd(DragEndDetails details) {
    _isDraggingStart = false;
    _isDraggingEnd = false;
    _dragStartSelection = null;
    widget.onMagnifierHide?.call();
    widget.onDragEnd?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectionControls == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        TapRegion(
          groupId: SelectableRegion,
          child: TextFieldTapRegion(
            child: ExcludeSemantics(
              child: _SelectionHandleOverlay(
                type: _startHandleType,
                handleLayerLink: widget.startHandleLayerLink,
                onSelectionHandleTapped: widget.onSelectionHandleTapped,
                onSelectionHandleDragStart: _handleStartDragStart,
                onSelectionHandleDragUpdate: _handleStartDragUpdate,
                onSelectionHandleDragEnd: _handleAnyDragEnd,
                selectionControls: widget.selectionControls!,
                handlesVisible: widget.handlesVisible,
                inViewport: _renderEditable.selectionStartInViewport,
                preferredLineHeight: _lineHeightAtStart,
                dragStartBehavior: widget.dragStartBehavior,
              ),
            ),
          ),
        ),
        TapRegion(
          groupId: SelectableRegion,
          child: TextFieldTapRegion(
            child: ExcludeSemantics(
              child: _SelectionHandleOverlay(
                type: _endHandleType,
                handleLayerLink: widget.endHandleLayerLink,
                onSelectionHandleTapped: widget.onSelectionHandleTapped,
                onSelectionHandleDragStart: _handleEndDragStart,
                onSelectionHandleDragUpdate: _handleEndDragUpdate,
                onSelectionHandleDragEnd: _handleAnyDragEnd,
                selectionControls: widget.selectionControls!,
                handlesVisible: widget.handlesVisible,
                inViewport: _renderEditable.selectionEndInViewport,
                preferredLineHeight: _lineHeightAtEnd,
                dragStartBehavior: widget.dragStartBehavior,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SelectionToolbarWrapper extends StatefulWidget {
  const _SelectionToolbarWrapper({this.isVisible = true, required this.child});

  final Widget child;
  final bool isVisible;

  @override
  State<_SelectionToolbarWrapper> createState() => _SelectionToolbarWrapperState();
}

class _SelectionToolbarWrapperState extends State<_SelectionToolbarWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: SelectionOverlay.fadeDuration,
    vsync: this,
    value: 0.0,
  );
  Animation<double> get _opacity => _controller.view;

  @override
  void initState() {
    super.initState();
    _toolbarVisibilityChanged();
  }

  @override
  void didUpdateWidget(_SelectionToolbarWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isVisible != widget.isVisible) {
      _toolbarVisibilityChanged();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toolbarVisibilityChanged() {
    if (widget.isVisible) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return TapRegion(
      groupId: SelectableRegion,
      child: TextFieldTapRegion(
        child: FadeTransition(opacity: _opacity, child: widget.child),
      ),
    );
  }
}

class _SelectionHandleOverlay extends StatefulWidget {
  const _SelectionHandleOverlay({
    required this.type,
    required this.handleLayerLink,
    this.onSelectionHandleTapped,
    this.onSelectionHandleDragStart,
    this.onSelectionHandleDragUpdate,
    this.onSelectionHandleDragEnd,
    required this.selectionControls,
    required this.handlesVisible,
    required this.inViewport,
    required this.preferredLineHeight,
    this.dragStartBehavior = DragStartBehavior.start,
  });

  final LayerLink handleLayerLink;
  final VoidCallback? onSelectionHandleTapped;
  final ValueChanged<DragStartDetails>? onSelectionHandleDragStart;
  final ValueChanged<DragUpdateDetails>? onSelectionHandleDragUpdate;
  final ValueChanged<DragEndDetails>? onSelectionHandleDragEnd;
  final TextSelectionControls selectionControls;
  final bool handlesVisible;
  final ValueListenable<bool> inViewport;
  final double preferredLineHeight;
  final TextSelectionHandleType type;
  final DragStartBehavior dragStartBehavior;

  @override
  State<_SelectionHandleOverlay> createState() => _SelectionHandleOverlayState();
}

class _SelectionHandleOverlayState extends State<_SelectionHandleOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    duration: SelectionOverlay.fadeDuration,
    vsync: this,
    //value: (widget.handlesVisible && widget.inViewport.value) ? 1.0 : 0.0,
  );

  @override
  void initState() {
    super.initState();
    widget.inViewport.addListener(_handleVisibilityChanged);
    _handleVisibilityChanged();
  }

  void _handleVisibilityChanged() {
    if (widget.handlesVisible && widget.inViewport.value) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  Rect _getHandleRect(TextSelectionHandleType type, double preferredLineHeight) {
    final Size handleSize = widget.selectionControls.getHandleSize(preferredLineHeight);
    return Rect.fromLTWH(0.0, 0.0, handleSize.width, handleSize.height);
  }

  @override
  void didUpdateWidget(_SelectionHandleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inViewport != widget.inViewport) {
      oldWidget.inViewport.removeListener(_handleVisibilityChanged);
      widget.inViewport.addListener(_handleVisibilityChanged);
      _handleVisibilityChanged();
    } else if (oldWidget.handlesVisible != widget.handlesVisible) {
      _handleVisibilityChanged();
    }
  }

  @override
  void dispose() {
    widget.inViewport.removeListener(_handleVisibilityChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Rect handleRect = _getHandleRect(widget.type, widget.preferredLineHeight);
    final Rect interactiveRect = handleRect.isEmpty
        ? handleRect
        : handleRect.expandToInclude(
            Rect.fromCircle(center: handleRect.center, radius: kMinInteractiveDimension / 2),
          );
    final RelativeRect padding = interactiveRect.isEmpty
        ? RelativeRect.fill
        : RelativeRect.fromLTRB(
            math.max((interactiveRect.width - handleRect.width) / 2, 0),
            math.max((interactiveRect.height - handleRect.height) / 2, 0),
            math.max((interactiveRect.width - handleRect.width) / 2, 0),
            math.max((interactiveRect.height - handleRect.height) / 2, 0),
          );
    final Offset handleAnchor = widget.selectionControls.getHandleAnchor(
      widget.type,
      widget.preferredLineHeight,
    );
    final bool eagerlyAcceptDragWhenCollapsed =
        widget.type == TextSelectionHandleType.collapsed &&
        switch (defaultTargetPlatform) {
          TargetPlatform.iOS => true,
          TargetPlatform.android ||
          TargetPlatform.fuchsia ||
          TargetPlatform.linux ||
          TargetPlatform.macOS ||
          TargetPlatform.windows => false,
        };

    return CompositedTransformFollower(
      link: widget.handleLayerLink,
      // Put the handle's anchor point on the leader's anchor point.
      offset: -handleAnchor - Offset(padding.left, padding.top),
      showWhenUnlinked: false,
      child: FadeTransition(
        opacity: _controller,
        child: SizedBox(
          width: interactiveRect.width,
          height: interactiveRect.height,
          child: Align(
            alignment: Alignment.topLeft,
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
                      ..gestureSettings = eagerlyAcceptDragWhenCollapsed
                          ? const DeviceGestureSettings(touchSlop: 1.0)
                          : null
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
      ),
    );
  }
}
