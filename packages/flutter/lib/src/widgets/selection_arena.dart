import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';

import '../../widgets.dart';

class SelectionArea extends StatefulWidget {
  const SelectionArea({required this.child, Key? key}) : super(key: key);

  final Widget child;

  @override
  _SelectionAreaState createState() => _SelectionAreaState();

  static SelectionRegistrant? of(BuildContext context) {
    return context.findAncestorStateOfType<_SelectionAreaState>();
  }
}

class _SelectionState {
  _SelectionState(this.start, this.end);

  final TextPosition start;
  final TextPosition end;
}

class _RegistrantData {
  _RegistrantData(this.paragraph);

  final RenderParagraph paragraph;
  Rect? bounds;
}

class _SelectionAreaState extends State<SelectionArea> with ChangeNotifier implements SelectionRegistrant {
  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = GlobalKey<RawGestureDetectorState>();
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};
  final Map<RenderParagraph, _RegistrantData> _selectionCandidates = <RenderParagraph, _RegistrantData>{};
  final Map<RenderParagraph, _SelectionState> _selectionStates = <RenderParagraph, _SelectionState>{};

  Offset? _selectionStart;
  Offset? _selectionEnd;

  @override
  void add(RenderParagraph renderBox) {
    _selectionCandidates[renderBox] = _RegistrantData(renderBox);
  }

  @override
  void remove(RenderParagraph renderBox) {
    _selectionCandidates.remove(renderBox);
  }

  @override
  void update(RenderParagraph renderBox, Rect rect) {
    var tl = renderBox.localToGlobal(rect.topLeft);
    var br = renderBox.localToGlobal(rect.bottomRight);
    _selectionCandidates[renderBox]?.bounds = Rect.fromPoints(tl, br);
  }

  void _handleDragDown(DragDownDetails details) {
    _selectionStart = null;
    _selectionEnd = null;
  }

  void _handleDragStart(DragStartDetails details) {
    _selectionStart = details.globalPosition;
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _selectionEnd = details.globalPosition;
    _maybeUpdateSelection();
  }

  void _handleDragEnd(DragEndDetails details) { }

  void _handleDragCancel() {
    _selectionStart = null;
    _selectionEnd = null;
    _maybeUpdateSelection();
  }

  // This logic needs to change based on text direction.
  void _maybeUpdateSelection() {
    Offset? selectionStartT = _selectionStart;
    Offset? selectionEndT = _selectionEnd;
    if (selectionEndT == null || selectionStartT == null) {
      if (_selectionStates.isNotEmpty) {
        _selectionStates.clear();
        notifyListeners();
      }
      return;
    }
    // First check if we've entirely passed any selected texts.
    //
    //  *
    //       HELLO THERE x
    //
    Offset selectionStart = selectionStartT;
    Offset selectionEnd = selectionEndT;
    bool didUpdate = false;
    for (var data in _selectionCandidates.values) {
      Rect? bounds = data.bounds;
      if (bounds == null) {
        continue;
      }
      var textSelectionStart = Offset(math.max(selectionStart.dx, bounds.topLeft.dx), math.max(selectionStart.dy, bounds.topLeft.dy));
      var textSelectionEnd = Offset(math.min(selectionEnd.dx, bounds.bottomRight.dx), math.max(selectionEnd.dy, bounds.bottom));

      // if (textSelectionStart.dy > bounds.bottom) {
      //   continue;
      // }
      TextPosition startTextPosition = data.paragraph.getPositionForOffset(data.paragraph.globalToLocal(selectionStart));
      TextPosition endTextPosition = data.paragraph.getPositionForOffset(data.paragraph.globalToLocal(selectionEnd));
      if (startTextPosition == endTextPosition) {
        continue;
      }
      didUpdate = true;
      _selectionStates[data.paragraph] = _SelectionState(startTextPosition, endTextPosition);
    }
    if (didUpdate) {
      notifyListeners();
    }
  }

  @override
  void initState() {
    super.initState();
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
  }

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      key: _gestureDetectorKey,
      gestures: _gestureRecognizers,
      behavior: HitTestBehavior.translucent,
      excludeFromSemantics: true,
      child: RenderHackyTextSelectionWidget(this, widget.child),
    );
  }
}

class RenderHackyTextSelectionWidget extends SingleChildRenderObjectWidget {
  RenderHackyTextSelectionWidget(this._state, Widget child) : super(child: child);

  final _SelectionAreaState _state;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return HackyTextSelectionPainter(_state);
  }

}

class HackyTextSelectionPainter extends RenderProxyBox {
  HackyTextSelectionPainter(this._state) {
    _state.addListener(markNeedsPaint);
  }


  _SelectionAreaState _state;

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    for (var entry in _state._selectionStates.entries) {
      var start = entry.value.start;
      var end = entry.value.end;
      var origin = globalToLocal(_state._selectionCandidates[entry.key]!.bounds!.topLeft);
      for (var box in entry.key.getBoxesForSelection(TextSelection(baseOffset: start.offset, extentOffset: end.offset, affinity: start.affinity))) {
        var tl = globalToLocal(entry.key.localToGlobal(Offset(box.left, box.top)));
        var br = globalToLocal(entry.key.localToGlobal(Offset(box.right, box.bottom)));
        context.canvas.drawRect(Rect.fromPoints(tl, br), Paint()..color = Color(0xAF6694e8) ..style = PaintingStyle.fill);
      }
    }
  }
}
