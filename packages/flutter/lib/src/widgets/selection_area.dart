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
}

class _SelectionAreaState extends State<SelectionArea> {
  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = GlobalKey<RawGestureDetectorState>();
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};

  BoxHitTestResult Function(Offset)? _hitTest;
  _SelectionRegion? _region;

  void _handleDragDown(DragDownDetails details) {
    _cancelSelection();
  }

  void _handleDragStart(DragStartDetails details) {
    _startSelection(details.localPosition);
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _updateSelection(details.localPosition);
  }

  void _handleDragEnd(DragEndDetails details) {}

  void _handleDragCancel() {
    _cancelSelection();
  }

  void _handleTapDown(TapDownDetails details) {
    if (details.kind != PointerDeviceKind.mouse)
      return;
    _cancelSelection();
  }

  void _startSelection(Offset offset) {
    if (_hitTest == null)
      return;
    final BoxHitTestResult result = _hitTest!(offset);
    _region = _SelectionRegion(offset)..add(result);
  }

  void _updateSelection(Offset offset) {
    if (_hitTest == null)
      return;
    final BoxHitTestResult result = _hitTest!(offset);
    _region!.add(result);
    _region!.updateSelections(offset);
  }

  void _cancelSelection() {
    final _SelectionRegion? region = _region;
    if (region == null)
      return;
    for (final Selectable<Object> selectable in region.selectables)
      selectable.clear();
    _region = null;
  }

  void _onKeyEvent(RawKeyEvent event) {
    if (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyC)) {
      _onCopy();
    }
  }

  void _onCopy() {
    final _SelectionRegion? region = _region;
    if (region == null || region.selectables.isEmpty)
      return;
    // The order in which these should be concatenated is ???. For now this
    // sorts by the order in which the selectables were added.
    final StringBuffer buffer = StringBuffer();
    for (final Selectable<Object> selectable in region.selectables) {
      final Object? data = selectable.copy();
      if (data == null) {
        continue;
      }
      // TODO: support more types than strings
      buffer.writeln(data); // Not sure what separator to use.
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
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
    final _SelectionRegion? region = _region;
    if (region != null) {
      for (final Selectable<Object> selectable in region.selectables) {
        selectable.clear();
      }
    }
    _region = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: _gestureRecognizers,
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      child: _SelectionArea(this, widget.child),
    );
  }
}


class _SelectionRegion {
  _SelectionRegion(this.start) : end = start;

  Offset start;
  Offset end;

  final Set<Selectable<Object>> selectables = <Selectable<Object>>{};
  final Map<Selectable<Object>, HitTestEntry> entries = <Selectable<Object>, HitTestEntry>{};

  void add(BoxHitTestResult result) {
    for (final HitTestEntry entry in result.path) {
      final HitTestTarget target = entry.target;
      if (target is Selectable<Object>) {
        final Selectable<Object> selectable = target as Selectable<Object>;
        if (!selectables.contains(selectable)) {
          selectables.add(selectable);
        }
        entries[selectable] = entry;
      }
    }
  }

  void updateSelections(Offset updatedEnd) {
    end = updatedEnd;
    for (final MapEntry<Selectable<Object>, HitTestEntry> entry in entries.entries) {
      final Offset startOffset = MatrixUtils.transformPoint(entry.value.transform!, start);
      final Offset endOffset = MatrixUtils.transformPoint(entry.value.transform!, end);
      entry.key.update(startOffset, endOffset);
    }
  }
}

class _SelectionArea extends SingleChildRenderObjectWidget {
  _SelectionArea(this._state, Widget child) : super(child: child);

  final _SelectionAreaState _state;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return _RenderSelectionArea(_state);
  }

}

class _RenderSelectionArea extends RenderProxyBox {
  _RenderSelectionArea(this._state) {
    _state._hitTest = performSelectionTest;
  }

  _SelectionAreaState _state;

  BoxHitTestResult performSelectionTest(Offset offset) {
    final BoxHitTestResult result = BoxHitTestResult();
    hitTestChildren(result, position: offset);
    return result;
  }
}
