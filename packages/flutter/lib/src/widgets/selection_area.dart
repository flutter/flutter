import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'focus_manager.dart';
import 'framework.dart';
import 'gesture_detector.dart';

/// A widget that introduces an area that allows for arbitrary text selection.
class SelectionArea extends StatefulWidget {
  /// Create a new [SelectionArea] widget/
  const SelectionArea({
    required this.child,
    Key? key,
    this.enabled = true,
    required this.focusNode,
  }) : super(key: key);

  /// The child widget this selection area applies to.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// Whether this selection area enables text selection in descendant widgets.
  ///
  /// Defaults to `true`. If set to `false`, child text widgets cannot be selected
  /// unless they are an editable subtype, or if the subtree is wrapped in a separate
  /// selection area widget.
  final bool enabled;

  final FocusNode focusNode;

  @override
  State<SelectionArea> createState() => _SelectionAreaState();

  /// Look up the nearest [SelectionService] introduced via a [SelectionArea]
  /// widget.
  ///
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

  Offset? _start;
  Offset? _end;

  void _handleKeyEvent(RawKeyEvent event) {
    if (!widget.focusNode.hasFocus)
      return;
    if (event.data is! RawKeyDownEvent)
      return;
    final RawKeyDownEvent down = event.data as RawKeyDownEvent;
    if (down.isControlPressed) {
      if (down.isKeyPressed(LogicalKeyboardKey.keyC)) {
        _copy();
      }

      if (down.isKeyPressed(LogicalKeyboardKey.keyA)) {
        _selectAll();
      }
    }
  }

  @override
  void initState() {
    RawKeyboard.instance.addListener(_handleKeyEvent);
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
        () => TapGestureRecognizer(debugOwner: this),
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
    RawKeyboard.instance.removeListener(_handleKeyEvent);
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

  void _selectAll() {
    _cancelSelection();
    _startSelection(Offset.zero);
    _updateSelection(Offset.infinite);
  }

  Future<void> _copy() async {
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
    Clipboard.setData(ClipboardData.text(selections.join('\n')));
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: _gestureRecognizers,
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      child: widget.child,
    );
  }
}
