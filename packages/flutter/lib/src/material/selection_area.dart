// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'desktop_text_selection.dart';
import 'text_selection.dart';
import 'theme.dart';

const Set<PointerDeviceKind> _LongPressSelectionDevices = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

/// A widget that introduces an area for user selections.
///
/// Flutter widgets are not selectable by default. To enable selection for
/// a flutter application, consider wrapping a portion of widget subtree with
/// [SelectionArea]. The wrapped subtree can be selected by users using mice or
/// touch gestures, e.g. users can select widgets by holding the mouse
/// left-clicks and dragging across widgets, or they can use long press gestures
/// to select words on touch devices.
///
/// This widget creates a [SelectableRegion] with platform-adaptive selection
/// controls, and it also creates appropriate gesture recognizers for both mouse
/// users and touch screen users. This widget listens to user gestures and uses
/// [SelectableRegionState] APIs to update the selection.
///
/// {@tool dartpad}
/// This example shows how to make the entire app selectable.
///
/// ** See code in examples/api/lib/material/selection_area/selection_area.dart **
/// {@end-tool}
///
/// See also:
///  * [SelectableRegion], which provides an overview of the selection system.
class SelectionArea extends StatefulWidget {
  /// Creates a [SelectionArea].
  ///
  /// If [selectionControls] is null, a platform specific one is used.
  const SelectionArea({
    super.key,
    this.focusNode,
    this.selectionControls,
    required this.child,
  });

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The delegate to build the selection handles and toolbar.
  ///
  /// If it is null, the platform specific selection control is used.
  final TextSelectionControls? selectionControls;

  /// The child widget this selection area applies to.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  @override
  State<StatefulWidget> createState() => _SelectionAreaState();
}

class _SelectionAreaState extends State<SelectionArea> {
  final GlobalKey<SelectableRegionState> _selectableRegionKey = GlobalKey<SelectableRegionState>();
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};

  SelectableRegionState get _selectableRegion => _selectableRegionKey.currentState!;

  static final Map<ShortcutActivator, Intent> _appleShortcuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.keyC, meta: true): CopySelectionTextIntent.copy,
    const SingleActivator(LogicalKeyboardKey.keyA, meta: true): const SelectAllTextIntent(SelectionChangedCause.keyboard),
  };
  static final Map<ShortcutActivator, Intent> _commonShortCuts = <ShortcutActivator, Intent>{
    const SingleActivator(LogicalKeyboardKey.keyC, control: true): CopySelectionTextIntent.copy,
    const SingleActivator(LogicalKeyboardKey.keyA, control: true): const SelectAllTextIntent(SelectionChangedCause.keyboard),
  };

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    SelectAllTextIntent: _makeOverridable(_SelectAllAction(this)),
    CopySelectionTextIntent: _makeOverridable(_CopySelectionAction(this)),
  };

  Action<T> _makeOverridable<T extends Intent>(Action<T> defaultAction) {
    return Action<T>.overridable(context: context, defaultAction: defaultAction);
  }

  @override
  void initState() {
    super.initState();
    _initMouseGestureRecognizer();
    _initTouchGestureRecognizer();
    // Other gestures.
    _gestureRecognizers[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
      () => TapGestureRecognizer(debugOwner: this),
      (TapGestureRecognizer instance) {
        instance.onTap = _clearSelection;
        instance.onSecondaryTapDown = _handleRightClickDown;
      },
    );
  }

  void _initMouseGestureRecognizer() {
    _gestureRecognizers[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
          () => PanGestureRecognizer(debugOwner:this, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
          (PanGestureRecognizer instance) {
        instance
          ..onDown = _startNewMouseSelectionGesture
          ..onStart = _handleMouseDragStart
          ..onUpdate = _handleMouseDragUpdate
          ..onEnd = _handleMouseDragEnd
          ..onCancel = _clearSelection
          ..dragStartBehavior = DragStartBehavior.down;
      },
    );
  }

  void _initTouchGestureRecognizer() {
    _gestureRecognizers[LongPressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(debugOwner: this, supportedDevices: _LongPressSelectionDevices),
      (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _handleTouchLongPressStart
          ..onLongPressMoveUpdate = _handleTouchLongPressMoveUpdate
          ..onLongPressEnd = _handleTouchLongPressEnd
          ..onLongPressCancel = _clearSelection;
      },
    );
  }

  FocusNode get _effectiveFocusNode {
    if (widget.focusNode != null)
      return widget.focusNode!;
    _internalNode ??= FocusNode();
    return _internalNode!;
  }
  FocusNode? _internalNode;

  void _startNewMouseSelectionGesture(DragDownDetails details) {
    _effectiveFocusNode.requestFocus();
    _selectableRegion.hideToolbar();
    _clearSelection();
  }

  void _handleMouseDragStart(DragStartDetails details) {
    _selectableRegion.selectStartTo(offset: details.globalPosition);
  }

  void _handleMouseDragUpdate(DragUpdateDetails details) {
    _selectableRegion.selectEndTo(offset: details.globalPosition, continuous: true);
  }

  void _handleMouseDragEnd(DragEndDetails details) {
    _selectableRegion.finalizeSelection();

  }

  void _clearSelection() {
    // This can be called when disposing gesture detector in which case the
    // state may be null.
    _selectableRegionKey.currentState?.clearSelection();
  }

  void _handleTouchLongPressStart(LongPressStartDetails details) {
    _effectiveFocusNode.requestFocus();
    _selectableRegion.selectWordAt(offset: details.globalPosition);
    _selectableRegion.showToolbar();
    _selectableRegion.showHandles();
  }

  void _handleTouchLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _selectableRegion.selectEndTo(offset: details.globalPosition);
  }

  void _handleTouchLongPressEnd(LongPressEndDetails details) {
    _selectableRegion.finalizeSelection();
  }

  void _handleRightClickDown(TapDownDetails details) {
    _effectiveFocusNode.requestFocus();
    _selectableRegion.selectWordAt(offset: details.globalPosition);
    _selectableRegion.showHandles();
    _selectableRegion.showToolbar(location: details.globalPosition);
  }

  @override
  void dispose() {
    _internalNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    TextSelectionControls? controls = widget.selectionControls;
    late Map<ShortcutActivator, Intent> shortcuts;
    switch (Theme.of(context).platform) {
      case TargetPlatform.android:
        shortcuts = _commonShortCuts;
        controls ??= materialTextSelectionControls;
        break;
      case TargetPlatform.fuchsia:
        shortcuts = _commonShortCuts;
        controls ??= materialTextSelectionControls;
        break;
      case TargetPlatform.iOS:
        shortcuts = _appleShortcuts;
        controls ??= cupertinoTextSelectionControls;
        break;
      case TargetPlatform.linux:
        shortcuts = _commonShortCuts;
        controls ??= desktopTextSelectionControls;
        break;
      case TargetPlatform.windows:
        shortcuts = _commonShortCuts;
        controls ??= desktopTextSelectionControls;
        break;
      case TargetPlatform.macOS:
        shortcuts = _appleShortcuts;
        controls ??= cupertinoDesktopTextSelectionControls;
        break;
    }
    return RawGestureDetector(
        gestures: _gestureRecognizers,
        behavior: HitTestBehavior.translucent,
        excludeFromSemantics: true,
        child: Shortcuts(
          shortcuts: shortcuts,
          child: Actions(
            actions: _actions,
            child: SelectableRegion(
              key: _selectableRegionKey,
              focusNode: _effectiveFocusNode,
              selectionControls: controls,
              child: widget.child,
            )
          ),
        ),
    );
  }
}

class _SelectAllAction extends ContextAction<SelectAllTextIntent> {
  _SelectAllAction(this.state);

  final _SelectionAreaState state;

  @override
  void invoke(SelectAllTextIntent intent, [BuildContext? context]) {
    state._selectableRegion.selectAll(SelectionChangedCause.keyboard);
  }
}

class _CopySelectionAction extends ContextAction<CopySelectionTextIntent> {
  _CopySelectionAction(this.state);

  final _SelectionAreaState state;

  @override
  void invoke(CopySelectionTextIntent intent, [BuildContext? context]) {
    final SelectedContent? data = state._selectableRegion.getSelectedContent();
    if (data == null) {
      return;
    }
    Clipboard.setData(ClipboardData(text: data.plainText));
  }
}
