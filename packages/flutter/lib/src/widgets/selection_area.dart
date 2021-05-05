import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import '../../widgets.dart';

class SelectionArea extends StatefulWidget {
  const SelectionArea({
    required this.child,
    Key? key,
    this.enabled = true,
  }) : super(key: key);

  final Widget child;

  /// Whether this selection area enables text selection in descendant widgets.
  ///
  /// Defaults to `true`. If set to `false`, child text widgets cannot be selected
  /// unless they are an editable subtype, or if the subtree is wrapped in a separate
  /// selection area widget.
  final bool enabled;

  @override
  _SelectionAreaState createState() => _SelectionAreaState();

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

  void _handleDragEnd(DragEndDetails details) {
  }

  void _handleDragCancel() {
    _cancelSelection();
  }

  void _handleTapDown(TapDownDetails details) {
    if (details.kind != PointerDeviceKind.mouse)
      return;
    _cancelSelection();
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

  void _onKeyEvent(RawKeyEvent event) {
    if (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyC)) {
      _onCopy();
      return;
    }
    if (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyA)) {
      _selectAll();
      return;
    }
  }

  Future<void> _onCopy() async {
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
  void initState() {
    super.initState();
    RawKeyboard.instance.addListener(_onKeyEvent);
    _gestureRecognizers[VerticalDragGestureRecognizer] = GestureRecognizerFactoryWithHandlers<VerticalDragGestureRecognizer>(
      () => VerticalDragGestureRecognizer(),
      (VerticalDragGestureRecognizer instance) {
        instance
          ..onDown = _handleDragDown
          ..onStart = _handleDragStart
          ..onUpdate = _handleDragUpdate
          ..onEnd = _handleDragEnd
          ..onCancel = _handleDragCancel
          ..dragStartBehavior = DragStartBehavior.down
          ..supportedDevices = <PointerDeviceKind>{PointerDeviceKind.mouse};
      },
    );
    _gestureRecognizers[TapGestureRecognizer] = GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
        () => TapGestureRecognizer(debugOwner: this),
        (TapGestureRecognizer instance) {
          instance
            .onTapDown = _handleTapDown;
        },
      );
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onKeyEvent);
    for (final Selectable selectable in _selectables) {
      selectable.clear();
    }
    _selectables.clear();
    super.dispose();
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
