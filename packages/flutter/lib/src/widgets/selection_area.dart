// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'actions.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'shortcuts.dart';

/// A widget that introduces an area that allows for arbitrary text selection.
///
/// This widget is introduced automatically in all routes when targeting the web.
class SelectionArea extends StatefulWidget {
  /// Create a new [SelectionArea] widget.
  ///
  /// To disable text selection for a part of the widget hiearchy, wrap them
  /// in a selection area widget with [enabled] set to `false`.
  const SelectionArea({
    required this.child,
    Key? key,
    this.enabled = true,
  }) : super(key: key);

  /// The child widget this selection area applies to.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;


  /// Whether this selection area enables text selection in descendant widgets.
  ///
  /// Defaults to `true`. If set to `false`, child text widgets cannot be selected
  /// unless the subtree is wrapped in a separate selection area widget that
  /// takes focus.
  final bool enabled;

  @override
  State<SelectionArea> createState() => _SelectionAreaState();

  /// Look up the nearest [SelectionService] introduced via a [SelectionArea]
  /// widget.
  ///s
  /// Returns `null` if there is no selection service or if selection was not
  /// enabled on a [SelectionArea].
  static SelectionService? of(BuildContext context) {
    final _SelectionAreaState? state = context.findRootAncestorStateOfType<_SelectionAreaState>();
    if (state == null || !state.widget.enabled)
      return null;
    return state;
  }
}

class _SelectionAreaState extends State<SelectionArea> implements SelectionService {
  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = GlobalKey<RawGestureDetectorState>();
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};
  final Set<Selectable> _selectables = <Selectable>{};
  late final Map<Type, Action<Intent>> _actions = <Type, Action<Intent>>{
    _CopyIntent: CallbackAction<_CopyIntent>(onInvoke: _copy),
    _SelectAllIntent: CallbackAction<_SelectAllIntent>(onInvoke: _selectAll),
  };

  Offset? _start;
  Offset? _end;

  @override
  void initState() {
    super.initState();
    _gestureRecognizers[PanGestureRecognizer] = GestureRecognizerFactoryWithHandlers<PanGestureRecognizer>(
      () => PanGestureRecognizer(supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
      (PanGestureRecognizer instance) {
        instance
          ..onDown = _handleDragDown
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onCancel = _cancelSelection
          ..dragStartBehavior = DragStartBehavior.down;
      },
    );
    _gestureRecognizers[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this, supportedDevices: <PointerDeviceKind>{PointerDeviceKind.mouse}),
        (TapGestureRecognizer instance) {
          instance.onTap = _cancelSelection;
        },
      );
  }

  @override
  void dispose() {
    for (final Selectable selectable in _selectables) {
      selectable.clear();
    }
    _selectables.clear();
    super.dispose();
  }

  @override
  void add(Selectable selectable) {
    _selectables.add(selectable);
  }

  @override
  void remove(Selectable selectable) {
    _selectables.remove(selectable);
    selectable.clear();
  }


  void _handleDragDown(DragDownDetails details) {
    _cancelSelection();
  }

  void _handleDragStart(DragStartDetails details) {
    final Offset offset = (context.findRenderObject() as RenderBox?)!.localToGlobal(details.localPosition);
    _startSelection(offset);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final Offset offset = (context.findRenderObject() as RenderBox?)!.localToGlobal(details.localPosition);
    _updateSelection(offset);
  }

  void _startSelection(Offset offset) {
    _start = offset;
  }

  void _updateSelection(Offset offset) {
    _end = offset;
    final Rect globalSelectionRect = Rect.fromPoints(_start!, _end!);
    for (final Selectable selectable in _selectables) {
      selectable.update(globalSelectionRect);
    }
  }

  void _cancelSelection() {
    _start = null;
    _end = null;
    for (final Selectable selectable in _selectables)
      selectable.clear();
  }

  void _selectAll(Intent intent) {
    _cancelSelection();
    _startSelection(Offset.zero);
    _updateSelection(Offset.infinite);
  }

  Future<void> _copy(Intent intent) async {
    final List<Object> selections = <Object>[];
    for (final Selectable selectable in _selectables) {
      final Object? data = selectable.copy();
      if (data != null)
        selections.add(data);
    }
    if (selections.isEmpty)
      return;
    // The order in which these should be concatenated is ???. For now this
    // sorts by the order in which the selectables were added.
    final String data = selections.join('\n');
    Clipboard.setData(ClipboardData(text: data));
  }

  @override
  Widget build(BuildContext context) {
    return Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.keyC, control: true) : _CopyIntent(),
        SingleActivator(LogicalKeyboardKey.keyA, control: true) : _SelectAllIntent(),
      },
      child: Actions(
        actions: _actions,
        child: RawGestureDetector(
          key: _gestureDetectorKey,
          gestures: _gestureRecognizers,
          behavior: HitTestBehavior.translucent,
          excludeFromSemantics: true,
          child: widget.child,
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
