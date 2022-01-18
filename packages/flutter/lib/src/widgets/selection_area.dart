// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'basic.dart';
import 'focus_manager.dart';
import 'focus_scope.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'selection_container.dart';
import 'shortcuts.dart';
import 'text_selection.dart';

const Set<PointerDeviceKind> _LongPressSelectionDevices = <PointerDeviceKind>{
  PointerDeviceKind.touch,
  PointerDeviceKind.stylus,
  PointerDeviceKind.invertedStylus,
};

/// A widget that introduces an area for selection.
///
/// Flutter widgets are not selectable by default. To enable selection for
/// a flutter application, consider wrapping a portion of widget subtree with
/// [SelectionArea]. The wrapped subtree can be selected by users using mouse or
/// touch gesture, e.g. users can select widgets by holding the mouse left click
/// and dragging across widgets, or they can use long press gestures to select a
/// word in a touch devices.
///
/// ## An overview of the selection system.
///
/// Every [Selectable] under the [SelectionArea] can be selected through user
/// gestures. They formed a selection tree structure to handle these gestures.
///
/// The [SelectionArea] is a wrapper over [SelectionContainer], It creates
/// [GestureRecognizer]s and [Shortcuts] to listen user inputs and convert them
/// to corresponding [SelectionEvent]s. These events are then sent to the
/// [SelectionContainer] it creates.
///
/// A [SelectionContainer] is a single [Selectable] that handles
/// [SelectionEvent]s on behave of child [Selectable]s in the subtree. It
/// creates an abstract for the parent [SelectionContainer] as if the parent is
/// interacting with a single [Selectable].
///
/// The [SelectionContainer] created by [SelectionArea] is the root node of a
/// selection tree. Each non-leaf node in the tree is a [SelectionContainer],
/// and the leaf node is a leaf widget whose render object implements
/// [Selectable]. They are connected through [SelectionRegistrarScope]s created
/// by [SelectionContainer]s.
///
/// Both [SelectionContainer]s and the leaf [Selectable]s need to register
/// themselves to the [SelectionRegistrar] from the
/// [SelectionRegistrarScope.maybeOf] if they want to participate in the
/// selection.
///
/// An example selection tree will look like:

/// ```dart
/// MaterialApp(
///   home: SelectionArea(
///     // ...
///     child: Scaffold(
///       appBar: AppBar(title: Text('Flutter Code Sample')),
///       body: ListView(
///         children: <Widget>[
///           Text('Item 0', style: TextStyle(fontSize: 50.0)),
///           Text('Item 1', style: TextStyle(fontSize: 50.0)),
///         ],
///       ),
///     ),
///   ),
///);
/// ```
///
///               SelectionContainer
///                (SelectionArea)
///                  /         \
///                 /           \
///                /             \
///           Selectable          \
///      ("Flutter Code Sample")   \
///                                 \
///                          SelectionContainer
///                              (ListView)
///                              /       \
///                             /         \
///                            /           \
///                     Selectable        Selectable
///                     ("Item 0")         ("Item 1")
///
///
/// ## Making a widget selectable
///
/// Some leaf widgets, such as [Text], have all of the selection logic wired up
/// automatically and can be selected as long as they are under a
/// [SelectionArea].
///
/// To make a custom selectable leaf widget, its render object
/// needs to mix [Selectable] and implements the required APIs to handle
/// [SelectionEvent]s as well as painting appropriate selection highlights.
///
/// The render object also needs to register itself to a [SelectionRegistrar].
/// For the most cases, one can use [SelectionRegistrant] to auto-register
/// itself with the register returned from [SelectionRegistrarScope.maybeOf].
///
/// ## Complex layout
///
/// By default, the screen order is used as the selection order. If a group of
/// [Selectable]s needs to select differently, consider wrapping them with a
/// [SelectionContainer] to customize its selection behavior.
///
/// In the case where a group of widgets should be excluded from selection under
/// a [SelectionArea], consider wrapping that group of widgets using
/// [SelectionRegistrarScope.disabled].
///
/// To create a separate selection system from its parent selection area,
/// wrap part of the subtree with another [SelectionArea]. The selection of the
/// child selection area can not extend pass its subtree, and the selection of
/// the parent selection area can not extend inside the child selection area.
///
/// See also:
///  * [SelectionHandler]: which contains APIs to handle selection events from the
///    [SelectionArea].
///  * [Selectable]: which provides API to participate in the selection system.
///  * [SelectionRegistrar]: which [Selectable] needs to subscribe to receive
///    selection events.
///  * [SelectionContainer]: which collects selectable widgets in the subtree
///    and provides api to dispatch selection event to the collected widget.
///
class SelectionArea extends StatefulWidget {
  /// Create a new [SelectionArea] widget.
  ///
  /// The [selectionControls] is used for building selection handles and toolbar
  /// for mobile devices.
  const SelectionArea({
    super.key,
    this.focusNode,
    required this.selectionControls,
    required this.child,
  });

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// The child widget this selection area applies to.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The delegate to build the selection handles and toolbar for mobile
  /// devices.
  ///
  /// If it is null, the platform specific selection control is used.
  final TextSelectionControls selectionControls;

  @override
  State<StatefulWidget> createState() => _SelectionAreaState();
}

class _SelectionAreaState extends State<SelectionArea> with TextSelectionDelegate implements SelectionRegistrar {
  // Shortcuts for devices that use command keys, such as MacOS.
  static const Map<ShortcutActivator, Intent> _kCmdBasedShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyC, meta: true) : _CopyIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, meta: true) : _SelectAllIntent(),
  };

  // Shortcuts for devices that use control keys, such as Windows and Linux.
  static const Map<ShortcutActivator, Intent> _kCtrlBasedShortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.keyC, control: true) : _CopyIntent(),
    SingleActivator(LogicalKeyboardKey.keyA, control: true) : _SelectAllIntent(),
  };

  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    _CopyIntent: CallbackAction<_CopyIntent>(onInvoke: _copy),
    _SelectAllIntent: CallbackAction<_SelectAllIntent>(onInvoke: _selectAll),
  };

  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};
  SelectionOverlay? _selectionOverlay;
  final LayerLink _startHandleLayerLink = LayerLink();
  final LayerLink _endHandleLayerLink = LayerLink();
  final LayerLink _toolbarLayerLink = LayerLink();
  late _SelectionAreaContainerDelegate _selectionDelegate;
  FocusNode? _focusNode;
  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_focusNode ??= FocusNode());
  // there should only ever be one selectable, which is the SelectionContainer.
  Selectable? _selectable;

  @override
  void initState() {
    super.initState();
    _selectionDelegate = _SelectionAreaContainerDelegate();
    _initMouseGestureRecognizer();
    _initTouchGestureRecognizer();
  }

  // Mouse helper methods.

  void _initMouseGestureRecognizer() {
    _gestureRecognizers[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
      () => PanGestureRecognizer(debugOwner:this, supportedDevices: <PointerDeviceKind>{ PointerDeviceKind.mouse }),
      (PanGestureRecognizer instance) {
        instance
          ..onDown = _startNewMouseSelectionGesture
          ..onStart = _handleMouseDragStart
          ..onUpdate = _handleMouseDragUpdate
          ..onEnd = _stopSelectionEndEdgeUpdate
          ..onCancel = _cancelSelection
          ..dragStartBehavior = DragStartBehavior.down;
      },
    );
  }

  void _startNewMouseSelectionGesture([Object? object]) {
    _effectiveFocusNode.requestFocus();
    _cancelSelection();
  }

  void _handleMouseDragStart(DragStartDetails details) {
    _selectable?.dispatchSelectionEvent(SelectionStartEdgeUpdateEvent(globalPosition: details.globalPosition));
  }

  void _handleMouseDragUpdate(DragUpdateDetails details) {
    final Offset offset = details.globalPosition;
    if (_selectionEndPosition != offset) {
      _selectionEndPosition = offset;
      _triggerSelectionEndEdgeUpdate();
    }
  }

  // Touch helper methods.

  void _initTouchGestureRecognizer() {
    _gestureRecognizers[LongPressGestureRecognizer] = GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
          () => LongPressGestureRecognizer(debugOwner: this, supportedDevices: _LongPressSelectionDevices),
          (LongPressGestureRecognizer instance) {
        instance
          ..onLongPressStart = _handleTouchLongPressStart
          ..onLongPressMoveUpdate = _handleTouchLongPressMoveUpdate
          ..onLongPressEnd = _stopSelectionEndEdgeUpdate
          ..onLongPressCancel = _cancelSelection;
      },
    );
    _gestureRecognizers[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
          () => TapGestureRecognizer(debugOwner: this),
          (TapGestureRecognizer instance) {
        instance.onTap = _cancelSelection;
      },
    );
  }

  void _handleTouchLongPressStart(LongPressStartDetails details) {
    _startNewMouseSelectionGesture();
    _selectable?.dispatchSelectionEvent(SelectWordSelectionEvent(globalPosition: details.globalPosition));
  }

  void _handleTouchLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final Offset offset = details.globalPosition;
    if (_selectionEndPosition != offset) {
      _selectionEndPosition = offset;
      _triggerSelectionEndEdgeUpdate();
    }
  }

  void _updateSelectionStatus() {
    late TextSelection selection;
    final SelectionGeometry geometry = _selectionDelegate.value;
    switch(geometry.status) {
      case SelectionStatus.uncollapsed:
        selection = const TextSelection(baseOffset: 0, extentOffset: 1);
        break;
      case SelectionStatus.collapsed:
        selection = const TextSelection(baseOffset: 0, extentOffset: 1);
        break;
      case SelectionStatus.none:
        selection = const TextSelection.collapsed(offset: 1);
        break;
    }
    textEditingValue = TextEditingValue(text: '__', selection: selection);
    if (geometry.startSelectionPoint != null || geometry.endSelectionPoint != null) {
      _showSelectionOverlay();
    } else {
      _hideSelectionOverlay();
    }
  }

  // Selection update helper methods.

  Offset? _selectionEndPosition;
  bool get _userDraggingSelectionEnd => _selectionEndPosition != null;
  bool _scheduledSelectionEndEdgeUpdate = false;
  void _triggerSelectionEndEdgeUpdate() {
    // This method can be called when the drag is not in progress. This can
    // happen if the the child scrollable returns SelectionResult.pending, and
    // the selection area scheduled a selection update for the next frame, but
    // the drag is lifted before the scheduled selection update is run.
    if (_scheduledSelectionEndEdgeUpdate || !_userDraggingSelectionEnd)
      return;
    if (_selectable?.dispatchSelectionEvent(
        SelectionEndEdgeUpdateEvent(globalPosition: _selectionEndPosition!)) == SelectionResult.pending) {
      _scheduledSelectionEndEdgeUpdate = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (!_scheduledSelectionEndEdgeUpdate)
          return;
        _scheduledSelectionEndEdgeUpdate = false;
        _triggerSelectionEndEdgeUpdate();
      });
      return;
    }
  }

  void _stopSelectionEndEdgeUpdate([Object? object]) {
    _scheduledSelectionEndEdgeUpdate = false;
    _selectionEndPosition = null;
  }

  Offset? _selectionStartPosition;
  bool get _userDraggingSelectionStart => _selectionStartPosition != null;
  bool _scheduledSelectionStartEdgeUpdate = false;
  void _triggerSelectionStartEdgeUpdate() {
    // This method can be called when the drag is not in progress. This can
    // happen if the the child scrollable returns SelectionResult.pending, and
    // the selection area scheduled a selection update for the next frame, but
    // the drag is lifted before the scheduled selection update is run.
    if (_scheduledSelectionStartEdgeUpdate || !_userDraggingSelectionStart)
      return;
    if (_selectable?.dispatchSelectionEvent(
        SelectionStartEdgeUpdateEvent(globalPosition: _selectionStartPosition!)) == SelectionResult.pending) {
      _scheduledSelectionStartEdgeUpdate = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (!_scheduledSelectionStartEdgeUpdate)
          return;
        _scheduledSelectionStartEdgeUpdate = false;
        _triggerSelectionStartEdgeUpdate();
      });
      return;
    }
  }

  void _stopSelectionStartEdgeUpdate() {
    _scheduledSelectionStartEdgeUpdate = false;
    _selectionEndPosition = null;
  }

  void _cancelSelection() {
    _stopSelectionEndEdgeUpdate();
    _stopSelectionStartEdgeUpdate();
    _selectable?.dispatchSelectionEvent(const ClearSelectionEvent());
  }

  void _selectAll([Intent? intent]) {
    _cancelSelection();
    _selectable?.dispatchSelectionEvent(const SelectAllSelectionEvent());
  }

  Future<void> _copy([Intent? intent]) async {
    final SelectedContent? data = _selectable?.getSelectedContent();
    if (data == null) {
      return;
    }
    Clipboard.setData(ClipboardData(text: data.plainText));
  }

  // SelectionOverlay helper methods.

  late Offset _selectionStartHandleDragPosition;
  late Offset _selectionEndHandleDragPosition;

  void _handleSelectionStartHandleDragStart(DragStartDetails details) {
    assert(_selectionDelegate.value.startSelectionPoint != null);
    _selectionStartHandleDragPosition = _selectionDelegate.value.startSelectionPoint!.localPosition;
  }

  void _handleSelectionStartHandleDragUpdate(DragUpdateDetails details) {
    _selectionStartHandleDragPosition = _selectionStartHandleDragPosition + details.delta;
    // The value corresponds to the paint origin of the selection handle.
    // Offset it to the center of the line to make it feel more natural.
    _selectionStartPosition = _selectionStartHandleDragPosition - Offset(0, _selectionDelegate.value.startSelectionPoint!.lineHeight / 2);
    _triggerSelectionStartEdgeUpdate();
  }

  void _handleSelectionEndHandleDragStart(DragStartDetails details) {
    assert(_selectionDelegate.value.endSelectionPoint != null);
    _selectionEndHandleDragPosition = _selectionDelegate.value.endSelectionPoint!.localPosition;
  }

  void _handleSelectionEndHandleDragUpdate(DragUpdateDetails details) {
    _selectionEndHandleDragPosition = _selectionEndHandleDragPosition + details.delta;
    // The value corresponds to the paint origin of the selection handle.
    // Offset it to the center of the line to make it feel more natural.
    _selectionEndPosition = _selectionEndHandleDragPosition - Offset(0, _selectionDelegate.value.endSelectionPoint!.lineHeight / 2);
    _triggerSelectionEndEdgeUpdate();
  }

  void _showSelectionOverlay() {
    assert(_selectionDelegate.value.startSelectionPoint != null ||
           _selectionDelegate.value.endSelectionPoint != null);
    final SelectionPoint? start = _selectionDelegate.value.startSelectionPoint;
    final SelectionPoint? end = _selectionDelegate.value.endSelectionPoint;
    late List<TextSelectionPoint> points;
    final Offset startLocalPosition = start?.localPosition ?? end!.localPosition;
    final Offset endLocalPosition = end?.localPosition ?? start!.localPosition;
    if (startLocalPosition.dy > endLocalPosition.dy) {
      points = <TextSelectionPoint>[
        TextSelectionPoint(endLocalPosition, TextDirection.ltr),
        TextSelectionPoint(startLocalPosition, TextDirection.ltr),
      ];
    } else {
      points = <TextSelectionPoint>[
        TextSelectionPoint(startLocalPosition, TextDirection.ltr),
        TextSelectionPoint(endLocalPosition, TextDirection.ltr),
      ];
    }
    if (_selectionOverlay == null) {
      _selectionOverlay = SelectionOverlay(
        context: context,
        debugRequiredFor: widget,
        startHandleType: start?.handleType ?? TextSelectionHandleType.left,
        lineHeightAtStart: start?.lineHeight ?? end!.lineHeight,
        onStartHandleDragStart: _handleSelectionStartHandleDragStart,
        onStartHandleDragUpdate: _handleSelectionStartHandleDragUpdate,
        onStartHandleDragEnd: (DragEndDetails details) => _stopSelectionStartEdgeUpdate(),
        endHandleType: end?.handleType ?? TextSelectionHandleType.right,
        lineHeightAtEnd: end?.lineHeight ?? start!.lineHeight,
        onEndHandleDragStart: _handleSelectionEndHandleDragStart,
        onEndHandleDragUpdate: _handleSelectionEndHandleDragUpdate,
        onEndHandleDragEnd: (DragEndDetails details) => _stopSelectionEndEdgeUpdate(),
        selectionEndPoints: points,
        selectionControls: widget.selectionControls,
        selectionDelegate: this,
        clipboardStatus: null,
        startHandleLayerLink: _startHandleLayerLink,
        endHandleLayerLink: _endHandleLayerLink,
        toolbarLayerLink: _toolbarLayerLink,
      );
    } else {
      _selectionOverlay!
        ..startHandleType = start?.handleType ?? TextSelectionHandleType.left
        ..lineHeightAtStart = start?.lineHeight ?? end!.lineHeight
        ..endHandleType = end?.handleType ?? TextSelectionHandleType.right
        ..lineHeightAtEnd = end?.lineHeight ?? start!.lineHeight
        ..selectionEndPoints = points;
    }
    _selectionOverlay!..showToolbar()..showHandles();
  }

  void _hideSelectionOverlay() {
    if (_selectionOverlay == null)
      return;
    _selectionOverlay!..hide()..dispose();
    _selectionOverlay = null;
  }

  // [TextSelectionDelegate] overrides.

  @override
  bool get cutEnabled => false;

  @override
  bool get pasteEnabled => false;

  @override
  void hideToolbar([bool hideHandles = true]) {
    _selectionOverlay?.hideToolbar();
    if (hideHandles) {
      _selectionOverlay?.hideToolbar();
    }
  }

  @override
  void selectAll(SelectionChangedCause cause) {
    _selectAll();
  }

  @override
  void copySelection(SelectionChangedCause cause) {
    _copy();
    _cancelSelection();
  }

  // TODO(chunhtai): remove this workaround after decoupling text selection
  // from text editing in TextSelectionDelegate.
  @override
  TextEditingValue textEditingValue = const TextEditingValue(text: '_');

  @override
  void bringIntoView(TextPosition position) {}

  @override
  void cutSelection(SelectionChangedCause cause) {
    assert(false);
  }

  @override
  void userUpdateTextEditingValue(TextEditingValue value, SelectionChangedCause cause) {}

  @override
  Future<void> pasteText(SelectionChangedCause cause) async {
    assert(false);
  }

  // [SelectionRegistrar] override.

  @override
  void add(Selectable selectable) {
    assert(_selectable == null);
    _selectable = selectable;
    _selectable!.addListener(_updateSelectionStatus);
    selectable.pushHandleLayers(_startHandleLayerLink, _endHandleLayerLink);
  }

  @override
  void remove(Selectable selectable) {
    _selectable?.removeListener(_updateSelectionStatus);
    _selectable?.pushHandleLayers(null, null);
    _selectable = null;
  }

  @override
  void dispose() {
    _selectable?.removeListener(_updateSelectionStatus);
    _selectable?.pushHandleLayers(null, null);
    _selectionDelegate.dispose();
    _focusNode?.dispose();
    super.dispose();
  }

  Map<ShortcutActivator, Intent> _getPlatformShortcuts() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return _kCtrlBasedShortcuts;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return _kCmdBasedShortcuts;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _toolbarLayerLink,
      child: Shortcuts(
        debugLabel: 'Selection Area shortcuts',
        shortcuts: _getPlatformShortcuts(),
        child: Actions(
          actions: _actions,
          child: Focus(
            focusNode: _effectiveFocusNode,
            child: RawGestureDetector(
              gestures: _gestureRecognizers,
              behavior: HitTestBehavior.translucent,
              excludeFromSemantics: true,
              child: SelectionContainer(
                registrar: this,
                delegate: _selectionDelegate,
                child: widget.child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectAllIntent extends Intent {
  const _SelectAllIntent();
}

class _CopyIntent extends Intent {
  const _CopyIntent();
}

class _SelectionAreaContainerDelegate extends MultiSelectableSelectionContainerDelegate {
  final Set<Selectable> _hasReceivedStartEvent = <Selectable>{};
  final Set<Selectable> _hasReceivedEndEvent = <Selectable>{};

  SelectionStartEdgeUpdateEvent? _lastStartEdgeUpdateEvent;
  SelectionEndEdgeUpdateEvent? _lastEndEdgeUpdateEvent;

  @override
  void remove(Selectable selectable) {
    _hasReceivedStartEvent.remove(selectable);
    _hasReceivedEndEvent.remove(selectable);
    super.remove(selectable);
  }

  void _updateLastEdgeEventsFromGeometries() {
    if (currentSelectionStartIndex != -1) {
      final Selectable start = selectables[currentSelectionStartIndex];
      final Offset localStartEdge = start.value.startSelectionPoint!.localPosition +
          Offset(0, - start.value.startSelectionPoint!.lineHeight / 2);
      _lastStartEdgeUpdateEvent = SelectionStartEdgeUpdateEvent(
        globalPosition: MatrixUtils.transformPoint(start.getTransformTo(null), localStartEdge),
      );
    }
    if (currentSelectionEndIndex != -1) {
      final Selectable end = selectables[currentSelectionEndIndex];
      final Offset localEndEdge = end.value.endSelectionPoint!.localPosition +
          Offset(0, -end.value.endSelectionPoint!.lineHeight / 2);
      _lastEndEdgeUpdateEvent = SelectionEndEdgeUpdateEvent(
        globalPosition: MatrixUtils.transformPoint(end.getTransformTo(null), localEndEdge),
      );
    }
  }

  @override
  SelectionResult handleSelectAll(SelectAllSelectionEvent event) {
    final SelectionResult result = super.handleSelectAll(event);
    for (final Selectable selectable in selectables) {
      _hasReceivedStartEvent.add(selectable);
      _hasReceivedEndEvent.add(selectable);
    }
    // Synthesize last update event so the edge updates continue to work.
    _updateLastEdgeEventsFromGeometries();
    return result;
  }

  /// Selects a word in a selectable at the location
  /// [SelectWordSelectionEvent.globalPosition].
  @override
  SelectionResult handleSelectWord(SelectWordSelectionEvent event) {
    final SelectionResult result = super.handleSelectWord(event);
    assert(currentSelectionStartIndex == currentSelectionEndIndex);
    if (currentSelectionStartIndex != -1) {
      _hasReceivedStartEvent.add(selectables[currentSelectionStartIndex]);
      _hasReceivedEndEvent.add(selectables[currentSelectionStartIndex]);
      _updateLastEdgeEventsFromGeometries();
    }
    return result;
  }

  @override
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    final SelectionResult result = super.handleClearSelection(event);
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    _lastStartEdgeUpdateEvent = null;
    _lastEndEdgeUpdateEvent = null;
    return result;
  }

  @override
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    if (event is SelectionEndEdgeUpdateEvent) {
      _lastEndEdgeUpdateEvent = event;
    } else {
      _lastStartEdgeUpdateEvent = event as SelectionStartEdgeUpdateEvent;
    }
    return super.handleSelectionEdgeUpdate(event);
  }

  @override
  void dispose() {
    _hasReceivedStartEvent.clear();
    _hasReceivedEndEvent.clear();
    super.dispose();
  }

  @override
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event) {
    if (event is SelectionEdgeUpdateEvent) {
      if (event is SelectionEndEdgeUpdateEvent) {
        _hasReceivedEndEvent.add(selectable);
      }
      if (event is SelectionStartEdgeUpdateEvent) {
        _hasReceivedStartEvent.add(selectable);
      }
      ensureChildUpdated(selectable);
    } else if (event is ClearSelectionEvent) {
      _hasReceivedStartEvent.remove(selectable);
      _hasReceivedEndEvent.remove(selectable);
    }
    return selectable.dispatchSelectionEvent(event);
  }

  @override
  void ensureChildUpdated(Selectable selectable) {
    if (_lastEndEdgeUpdateEvent != null && _hasReceivedEndEvent.add(selectable)) {
      if (currentSelectionEndIndex == -1) {
        handleSelectionEdgeUpdate(_lastEndEdgeUpdateEvent!);
      }
      selectable.dispatchSelectionEvent(_lastEndEdgeUpdateEvent!);
    }
    if (_lastStartEdgeUpdateEvent != null && _hasReceivedStartEvent.add(selectable)) {
      if (currentSelectionStartIndex == -1) {
        handleSelectionEdgeUpdate(_lastStartEdgeUpdateEvent!);
      }
      selectable.dispatchSelectionEvent(_lastStartEdgeUpdateEvent!);
    }
  }

  @override
  void didChangeSelectables() {
    if (_lastEndEdgeUpdateEvent != null) {
      handleSelectionEdgeUpdate(_lastEndEdgeUpdateEvent!);
    }
    if (_lastStartEdgeUpdateEvent != null) {
      handleSelectionEdgeUpdate(_lastStartEdgeUpdateEvent!);
    }
    final Set<Selectable> selectableSet = selectables.toSet();
    _hasReceivedEndEvent.removeWhere((Selectable selectable) => !selectableSet.contains(selectable));
    _hasReceivedStartEvent.removeWhere((Selectable selectable) => !selectableSet.contains(selectable));
    super.didChangeSelectables();
  }
}

/// An abstract base class for updating multiple selectable children.
///
/// This class optimize the selection update by keeping track of the
/// [Selectable]s that currently contain the selection edges.
abstract class MultiSelectableSelectionContainerDelegate extends SelectionContainerDelegate with ChangeNotifier {
  /// Gets the list selectables this delegate is managing.
  List<Selectable> selectables = <Selectable>[];

  /// The current selectable that contains the selection end edge.
  @protected
  int currentSelectionEndIndex = -1;

  /// The current selectable that contains the selection start edge.
  @protected
  int currentSelectionStartIndex = -1;

  LayerLink? _startHandleLayer;
  Selectable? _startHandleLayerOwner;
  LayerLink? _endHandleLayer;
  Selectable? _endHandleLayerOwner;

  bool _isHandlingSelectionEvent = false;
  bool _scheduledSelectableUpdate = false;
  bool _selectionInProgress = false;
  Set<Selectable> _additions = <Selectable>{};

  RenderBox get _box => selectionContainerContext.findRenderObject()! as RenderBox;

  @override
  void add(Selectable selectable) {
    assert(!selectables.contains(selectable));
    _additions.add(selectable);
    _scheduleSelectableUpdate();
  }

  @override
  void remove(Selectable selectable) {
    if (_additions.remove(selectable)) {
      return;
    }
    _removeSelectable(selectable);
    _scheduleSelectableUpdate();
  }

  /// Notifies this delegate that layout of the container has changed.
  void layoutDidChange() {
    _updateSelectionGeometry();
  }

  void _scheduleSelectableUpdate() {
    if (!_scheduledSelectableUpdate) {
      _scheduledSelectableUpdate = true;
      SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
        if (!_scheduledSelectableUpdate)
          return;
        _scheduledSelectableUpdate = false;
        _updateSelectables();
      });
    }
  }

  void _updateSelectables() {
    // Remove offScreen selectable.
    if (_additions.isNotEmpty) {
      _flushAdditions();
    }
    didChangeSelectables();
  }

  void _flushAdditions() {
    final List<Selectable> mergingSelectables = _additions.toList()..sort(compareOrder);
    final List<Selectable> existingSelectables = selectables;
    selectables = <Selectable>[];
    int mergingIndex = 0;
    int existingIndex = 0;
    int selectionStartIndex = currentSelectionStartIndex;
    int selectionEndIndex = currentSelectionEndIndex;
    // Merge two sorted lists.
    while (mergingIndex < mergingSelectables.length || existingIndex < existingSelectables.length) {
      if (mergingIndex >= mergingSelectables.length ||
          (existingIndex < existingSelectables.length &&
              compareOrder(existingSelectables[existingIndex], mergingSelectables[mergingIndex]) < 0)) {
        if (existingIndex == currentSelectionStartIndex) {
          selectionStartIndex = selectables.length;
        }
        if (existingIndex == currentSelectionEndIndex) {
          selectionEndIndex = selectables.length;
        }
        selectables.add(existingSelectables[existingIndex]);
        existingIndex += 1;
        continue;
      }

      // If the merging selectable falls in the selection range, their selection
      // needs to be updated.
      final Selectable mergingSelectable = mergingSelectables[mergingIndex];
      if (existingIndex < max(currentSelectionStartIndex, currentSelectionEndIndex) &&
          existingIndex > min(currentSelectionStartIndex, currentSelectionEndIndex)) {
        ensureChildUpdated(mergingSelectable);
      }
      mergingSelectable.addListener(_handleSelectableGeometryChange);
      selectables.add(mergingSelectable);
      mergingIndex += 1;
    }
    assert(mergingIndex == mergingSelectables.length &&
        existingIndex == existingSelectables.length &&
        selectables.length == existingIndex + mergingIndex);
    assert(selectionStartIndex >= -1 || selectionStartIndex < selectables.length);
    assert(selectionEndIndex >= -1 || selectionEndIndex < selectables.length);
    // selection indices should not be set to -1 unless they originally were.
    assert((currentSelectionStartIndex == -1) == (selectionStartIndex == -1));
    assert((currentSelectionEndIndex == -1) == (selectionEndIndex == -1));
    currentSelectionEndIndex = selectionEndIndex;
    currentSelectionStartIndex = selectionStartIndex;
    _additions = <Selectable>{};
  }

  void _removeSelectable(Selectable selectable) {
    assert(selectables.contains(selectable), 'The selectable is not in this registrar.');
    final int index = selectables.indexOf(selectable);
    selectables.removeAt(index);
    if (index <= currentSelectionEndIndex) {
      currentSelectionEndIndex -= 1;
    }
    if (index <= currentSelectionStartIndex) {
      currentSelectionStartIndex -= 1;
    }
    selectable.removeListener(_handleSelectableGeometryChange);
  }

  /// Called when this delegate finishes updating the selectables.
  @protected
  @mustCallSuper
  void didChangeSelectables() {
    _updateSelectionGeometry();
  }

  @override
  SelectionGeometry get value => _selectionGeometry;
  SelectionGeometry _selectionGeometry = const SelectionGeometry(
    hasContent: false,
    status: SelectionStatus.none,
  );

  /// Updates the [value] in this class and notifies listeners if necessary.
  void _updateSelectionGeometry() {
    final SelectionGeometry newValue = getSelectionGeometry();
    if (_selectionGeometry != newValue) {
      _selectionGeometry = newValue;
      notifyListeners();
    }
    _updateHandleLayersAndOwners();
  }

  /// The compare function this delegate used for determining the selection
  /// order of the selectables.
  ///
  /// Defaults to screen order.
  @protected
  Comparator<Selectable> get compareOrder => _compareScreenOrder;

  int _compareScreenOrder(Selectable a, Selectable b) {
    final Rect rectA = MatrixUtils.transformRect(
      a.getTransformTo(null),
      Rect.fromLTWH(0, 0, a.size.width, a.size.height),
    );
    final Rect rectB = MatrixUtils.transformRect(
      b.getTransformTo(null),
      Rect.fromLTWH(0, 0, b.size.width, b.size.height),
    );
    final int result = _compareVertically(rectA, rectB);
    if (result != 0)
      return result;
    return _compareHorizontally(rectA, rectB);
  }

  /// Compares two rectangles in the screen order solely by their vertical
  /// position.
  ///
  /// Returns positive if a is lower, negative if a is higher, 0 if their
  /// order can't be determine solely by their vertical position.
  static int _compareVertically(Rect a, Rect b) {
    if ((a.top - b.top < precisionErrorTolerance && a.bottom - b.bottom > - precisionErrorTolerance) ||
        (b.top - a.top < precisionErrorTolerance && b.bottom - a.bottom > - precisionErrorTolerance)) {
      return 0;
    }
    if ((a.top - b.top).abs() > precisionErrorTolerance)
      return a.top > b.top ? 1 : -1;
    return a.bottom > b.bottom ? 1 : -1;
  }

  /// Compares two rectangles in the screen order by their horizontal position
  /// assuming one of the rectangles enclose the other rect in vertically.
  ///
  /// Returns positive if a is lower, negative if a is higher.
  static int _compareHorizontally(Rect a, Rect b) {
    if (a.left - b.left < precisionErrorTolerance && a.right - b.right > - precisionErrorTolerance) {
      // a encloses b.
      return -1;
    }
    if (b.left - a.left < precisionErrorTolerance && b.right - a.right > - precisionErrorTolerance) {
      // b encloses a.
      return 1;
    }
    if ((a.left - b.left).abs() > precisionErrorTolerance)
      return a.left > b.left ? 1 : -1;
    return a.right > b.right ? 1 : -1;
  }

  void _handleSelectableGeometryChange() {
    // Geometries of selectable children may change multiple times when handling
    // selection events. Ignore these updates since the selection geometry of
    // this delegate will be updated after handling the selection events.
    if (_isHandlingSelectionEvent)
      return;
    _updateSelectionGeometry();
  }

  /// Gets the combined selection geometry for child selectables.
  @protected
  SelectionGeometry getSelectionGeometry() {
    if (currentSelectionEndIndex == -1 ||
        currentSelectionStartIndex == -1 ||
        selectables.isEmpty) {
      // There is no valid selection.
      return SelectionGeometry(
        status: SelectionStatus.none,
        hasContent: selectables.isNotEmpty,
      );
    }

    currentSelectionStartIndex = _adjustSelectionIndexBasedOnSelectionGeometry(
      currentSelectionStartIndex,
      currentSelectionEndIndex,
    );
    currentSelectionEndIndex = _adjustSelectionIndexBasedOnSelectionGeometry(
      currentSelectionEndIndex,
      currentSelectionStartIndex,
    );

    // Need to find the non-null start selection point.
    SelectionGeometry startGeometry = selectables[currentSelectionStartIndex].value;
    final bool forwardSelection = currentSelectionEndIndex >= currentSelectionStartIndex;
    int startIndexWalker = currentSelectionStartIndex;
    while (startIndexWalker != currentSelectionEndIndex && startGeometry.startSelectionPoint == null) {
      startIndexWalker += forwardSelection ? 1 : -1;
      startGeometry = selectables[startIndexWalker].value;
    }

    SelectionPoint? startPoint;
    if (startGeometry.startSelectionPoint != null) {
      final Matrix4 startTransform =  selectables[startIndexWalker].getTransformTo(_box);
      final Offset start = MatrixUtils.transformPoint(startTransform, startGeometry.startSelectionPoint!.localPosition);
      // It can be NaN if it is detached or off screen.
      if (start.isFinite) {
        startPoint = SelectionPoint(
          localPosition: start,
          lineHeight: startGeometry.startSelectionPoint!.lineHeight,
          handleType: startGeometry.startSelectionPoint!.handleType,
        );
      }
    }

    // Need to find the non-null end selection point.
    SelectionGeometry endGeometry = selectables[currentSelectionEndIndex].value;
    int endIndexWalker = currentSelectionEndIndex;
    while (endIndexWalker != currentSelectionStartIndex && endGeometry.endSelectionPoint == null) {
      endIndexWalker += forwardSelection ? -1 : 1;
      endGeometry = selectables[endIndexWalker].value;
    }
    SelectionPoint? endPoint;
    if (endGeometry.endSelectionPoint != null) {
      final Matrix4 endTransform =  selectables[endIndexWalker].getTransformTo(_box);
      final Offset end = MatrixUtils.transformPoint(endTransform, endGeometry.endSelectionPoint!.localPosition);
      // It can be NaN if it is detached or off screen.
      if (end.isFinite) {
        endPoint = SelectionPoint(
          localPosition: end,
          lineHeight: endGeometry.endSelectionPoint!.lineHeight,
          handleType: endGeometry.endSelectionPoint!.handleType,
        );
      }
    }

    return SelectionGeometry(
      startSelectionPoint: startPoint,
      endSelectionPoint: endPoint,
      status: startGeometry != endGeometry
        ? SelectionStatus.uncollapsed
        : startGeometry.status,
      // Would have at least one selectable child.
      hasContent: true,
    );
  }

  // The currentSelectionStartIndex or currentSelectionEndIndex may not be
  // the current index that contains selection edges. This can happen if the
  // selection edge is in between two selectables. One of the selectable will
  // have its selection collapsed at the index 0 or contentLength depends on
  // whether the selection is reversed or not. The current selection index can
  // be point to either one.
  //
  // This method adjusts the index to point to selectable with valid selection.
  int _adjustSelectionIndexBasedOnSelectionGeometry(int currentIndex, int towardIndex) {
    final bool forward = towardIndex > currentIndex;
    while (currentIndex != towardIndex &&
           selectables[currentIndex].value.status != SelectionStatus.uncollapsed) {
      currentIndex += forward ? 1 : -1;
    }
    return currentIndex;
  }

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (_startHandleLayer == startHandle && _endHandleLayer == endHandle)
      return;
    _startHandleLayer = startHandle;
    _endHandleLayer = endHandle;
    _updateHandleLayersAndOwners();
  }

  /// Pushes both handle layers to the selectables that contain selection edges.
  ///
  /// This method needs to be called every time the selectables that contain the
  /// selection edges changes, i.e. [currentSelectionStartIndex] or
  /// [currentSelectionEndIndex] changes. Otherwise, the handle may be painted
  /// in the wrong place.
  void _updateHandleLayersAndOwners() {
    LayerLink? effectiveStartHandle = _startHandleLayer;
    LayerLink? effectiveEndHandle = _endHandleLayer;
    if (effectiveStartHandle != null || effectiveEndHandle != null) {
      final Rect boxRect = Rect.fromLTWH(0, 0, _box.size.width, _box.size.height);
      final bool hideStartHandle = value.startSelectionPoint == null || !boxRect.contains(value.startSelectionPoint!.localPosition);
      final bool hideEndHandle = value.endSelectionPoint == null || !boxRect.contains(value.endSelectionPoint!.localPosition);
      effectiveStartHandle = hideStartHandle ? null : _startHandleLayer;
      effectiveEndHandle = hideEndHandle ? null : _endHandleLayer;
    }
    if (currentSelectionStartIndex == -1 || currentSelectionEndIndex == -1) {
      // No valid selection.
      if (_startHandleLayerOwner != null) {
        _startHandleLayerOwner!.pushHandleLayers(null, null);
        _startHandleLayerOwner = null;
      }
      if (_endHandleLayerOwner != null) {
        _endHandleLayerOwner!.pushHandleLayers(null, null);
        _endHandleLayerOwner = null;
      }
      return;
    }

    if (selectables[currentSelectionStartIndex] != _startHandleLayerOwner) {
      _startHandleLayerOwner?.pushHandleLayers(null, null);
    }
    if (selectables[currentSelectionEndIndex] != _endHandleLayerOwner) {
      _endHandleLayerOwner?.pushHandleLayers(null, null);
    }

    _startHandleLayerOwner = selectables[currentSelectionStartIndex];

    if (currentSelectionStartIndex == currentSelectionEndIndex) {
      // Selection edges is on the same selectable.
      _endHandleLayerOwner = _startHandleLayerOwner;
      _startHandleLayerOwner!.pushHandleLayers(effectiveStartHandle, effectiveEndHandle);
      return;
    }

    _startHandleLayerOwner!.pushHandleLayers(effectiveStartHandle, null);
    _endHandleLayerOwner = selectables[currentSelectionEndIndex];
    _endHandleLayerOwner!.pushHandleLayers(null, effectiveEndHandle);
  }

  /// Copies the selected contents of all selectables.
  @override
  SelectedContent? getSelectedContent() {
    final List<SelectedContent> selections = <SelectedContent>[];
    for (final Selectable selectable in selectables) {
      final SelectedContent? data = selectable.getSelectedContent();
      if (data != null)
        selections.add(data);
    }
    if (selections.isEmpty)
      return null;
    final StringBuffer buffer = StringBuffer();
    for (final SelectedContent selection in selections) {
      buffer.write(selection.plainText);
    }
    return SelectedContent(
      plainText: buffer.toString(),
    );
  }

  /// Selects all contents of all selectables.
  @protected
  SelectionResult handleSelectAll(SelectAllSelectionEvent event) {
    for (final Selectable selectable in selectables) {
      dispatchSelectionEventToChild(selectable, event);
    }
    currentSelectionStartIndex = 0;
    currentSelectionEndIndex = selectables.length - 1;
    return SelectionResult.none;
  }

  /// Selects a word in a selectable at the location
  /// [SelectWordSelectionEvent.globalPosition].
  @protected
  SelectionResult handleSelectWord(SelectWordSelectionEvent event) {
    assert(currentSelectionStartIndex == -1 && currentSelectionEndIndex == -1);
    for (int index = 0; index < selectables.length; index += 1) {
      final Rect localRect = Rect.fromLTWH(0, 0, selectables[index].size.width, selectables[index].size.height);
      final Matrix4 transform = selectables[index].getTransformTo(null);
      final Rect globalRect = MatrixUtils.transformRect(transform, localRect);
      if (globalRect.contains(event.globalPosition)) {
        dispatchSelectionEventToChild(selectables[index], event);
        currentSelectionStartIndex = currentSelectionEndIndex = index;
        return SelectionResult.end;
      }
    }
    return SelectionResult.none;
  }

  /// Removes the selection of all selectables this delegate manages.
  @protected
  SelectionResult handleClearSelection(ClearSelectionEvent event) {
    for (final Selectable selectable in selectables) {
      dispatchSelectionEventToChild(selectable, event);
    }
    currentSelectionEndIndex = -1;
    currentSelectionStartIndex = -1;
    return SelectionResult.none;
  }

  /// Updates the selection edges.
  @protected
  SelectionResult handleSelectionEdgeUpdate(SelectionEdgeUpdateEvent event) {
    if (event is SelectionEndEdgeUpdateEvent) {
      return currentSelectionEndIndex == -1 ? _initSelection(event, isEnd: true) : _adjustSelection(event, isEnd: true);
    }
    return currentSelectionStartIndex == -1 ? _initSelection(event, isEnd: false) : _adjustSelection(event, isEnd: false);
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    assert(event is SelectionEdgeUpdateEvent ||
        event is SelectAllSelectionEvent ||
        event is ClearSelectionEvent ||
        event is SelectWordSelectionEvent);
    final bool selectionWillbeInProgress = event is! ClearSelectionEvent;
    if (!_selectionInProgress && selectionWillbeInProgress) {
      // Sort the selectable every time a selection start.
      selectables.sort(compareOrder);
    }
    _selectionInProgress = selectionWillbeInProgress;
    _isHandlingSelectionEvent = true;
    late SelectionResult result;
    if (event is SelectionEdgeUpdateEvent) {
      result = handleSelectionEdgeUpdate(event);
    } else if (event is SelectAllSelectionEvent){
      result = handleSelectAll(event);
    } else if (event is ClearSelectionEvent){
      result = handleClearSelection(event);
    } else if (event is SelectWordSelectionEvent) {
      result = handleSelectWord(event);
    } else {
      result = SelectionResult.none;
    }
    _isHandlingSelectionEvent = false;
    _updateSelectionGeometry();
    return result;
  }

  @override
  void dispose() {
    for (final Selectable selectable in selectables) {
      selectable.removeListener(_handleSelectableGeometryChange);
    }
    selectables = const <Selectable>[];
    _scheduledSelectableUpdate = false;
    super.dispose();
  }

  /// Ensures the selectable child has received up to date selection event.
  ///
  /// This method is called when a new [Selectable] is added to the delegate,
  /// and its screen location falls into the previous selection.
  ///
  /// Subclasses are responsible for updating the selection of this newly added
  /// [Selectable].
  @protected
  void ensureChildUpdated(Selectable selectable);

  /// Dispatches a selection event to a specific selectable.
  ///
  /// Override this method if subclasses need to generate additional events or
  /// treatments prior to sending the selection events.
  @protected
  SelectionResult dispatchSelectionEventToChild(Selectable selectable, SelectionEvent event);

  /// Initializes the selection of the selectable children.
  ///
  /// The goal is to find the selectable child that contains the selection edge.
  /// Returns [SelectionResult.end] if the selection edge ends on any of the
  /// children. Otherwise, it returns [SelectionResult.previous] if the selection
  /// does not reach any of its children. Returns [SelectionResult.next]
  /// if the selection reach the end of its children.
  ///
  /// Ideally, this method should only be called twice at the beginning of the
  /// drag selection, once for [SelectionEndEdgeUpdateEvent], once for
  /// [SelectionStartEdgeUpdateEvent].
  SelectionResult _initSelection(SelectionEdgeUpdateEvent event, {required bool isEnd}) {
    assert((isEnd && currentSelectionEndIndex == -1) || (!isEnd && currentSelectionStartIndex == -1));
    int newIndex = -1;
    bool hasFoundEdgeIndex = false;
    SelectionResult? result;
    for (int index = 0; index < selectables.length && !hasFoundEdgeIndex; index += 1) {
      final Selectable child =  selectables[index];
      final SelectionResult childResult = dispatchSelectionEventToChild(child, event);
      switch (childResult) {
        case SelectionResult.next:
        case SelectionResult.none:
          newIndex = index;
          break;
        case SelectionResult.end:
          newIndex = index;
          result = SelectionResult.end;
          hasFoundEdgeIndex = true;
          break;
        case SelectionResult.previous:
          hasFoundEdgeIndex = true;
          if (index == 0) {
            newIndex = 0;
            result = SelectionResult.previous;
          }
          result ??= SelectionResult.end;
          break;
        case SelectionResult.pending:
          newIndex = index;
          result = SelectionResult.pending;
          hasFoundEdgeIndex = true;
          break;
      }
    }

    if (newIndex == -1) {
      assert(selectables.isEmpty);
      return SelectionResult.none;
    }
    if (isEnd) {
      currentSelectionEndIndex = newIndex;
    } else {
      currentSelectionStartIndex = newIndex;
    }
    // The result can only be null if the loop went through the entire list
    // without any of the selection returned end or previous. In this case, the
    // caller of this method needs to find the next selectable in their list.
    return result ?? SelectionResult.next;
  }

  /// Adjusts the selection based on the drag selection update event if there
  /// is already a selectable child that contains the selection edge.
  ///
  /// This method starts by sending the selection event to the current
  /// selectable that contains the selection edge, and finds forward or backward
  /// if that selectable no longer contains the selection edge.
  SelectionResult _adjustSelection(SelectionEdgeUpdateEvent event, {required bool isEnd}) {
    assert(() {
      if (isEnd) {
        assert(
        currentSelectionEndIndex < selectables.length &&
            currentSelectionEndIndex >= 0,
        'currentSelectionEndIndex is $currentSelectionEndIndex, is outside of selectables length ${selectables.length}'
        );
        return true;
      }
      assert(
      currentSelectionStartIndex < selectables.length &&
          currentSelectionStartIndex >= 0,
      'currentSelectionStartIndex is $currentSelectionStartIndex, is outside of selectables length ${selectables.length}'
      );
      return true;
    }());
    SelectionResult? finalResult;
    int newIndex = isEnd ? currentSelectionEndIndex : currentSelectionStartIndex;
    bool? forward;
    late SelectionResult currentSelectableResult;
    // This loop looks forward if currentSelectionIndex returns next, or backward
    // if it returns forward. The terminate condition are:
    // 1. the selectable returns end, pending, none.
    // 2. the selectable returns previous when looking forward.
    // 2. the selectable returns next when looking backward.
    while (newIndex < selectables.length &&
        newIndex >= 0 && finalResult == null) {
      currentSelectableResult = dispatchSelectionEventToChild(selectables[newIndex], event);
      switch (currentSelectableResult) {
        case SelectionResult.end:
        case SelectionResult.pending:
        case SelectionResult.none:
          finalResult = currentSelectableResult;
          break;
        case SelectionResult.next:
          if (forward == false) {
            newIndex += 1;
            finalResult = SelectionResult.end;
          } else if (newIndex == selectables.length -1) {
            finalResult = currentSelectableResult;
          } else {
            forward = true;
            newIndex += 1;
          }
          break;
        case SelectionResult.previous:
          if (forward ?? false) {
            newIndex -= 1;
            finalResult = SelectionResult.end;
          } else if (newIndex == 0) {
            finalResult = currentSelectableResult;
          } else {
            forward = false;
            newIndex -= 1;
          }
          break;
      }
    }
    if (isEnd) {
      currentSelectionEndIndex = newIndex;
    } else {
      currentSelectionStartIndex = newIndex;
    }
    return finalResult!;
  }
}
