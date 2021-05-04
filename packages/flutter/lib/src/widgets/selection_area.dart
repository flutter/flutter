import 'dart:collection';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

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

class _Selection {
  _Selection(this.start, this.end);

  final TextPosition start;
  final TextPosition end;
}

class _RegistrantData {
  _RegistrantData(this.paragraph);

  final RenderParagraph paragraph;
  Rect? bounds;
}

class _SelectionAreaState extends State<SelectionArea> implements SelectionRegistrant {
  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = GlobalKey<RawGestureDetectorState>();
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};
  final Map<RenderParagraph, _RegistrantData> _selectionCandidates = <RenderParagraph, _RegistrantData>{};
  final Set<RenderParagraph> _selectionStates = <RenderParagraph>{};

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
    final Offset topLeft = renderBox.localToGlobal(rect.topLeft);
    final Offset bottomRight = renderBox.localToGlobal(rect.bottomRight);
    _selectionCandidates[renderBox]?.bounds = Rect.fromPoints(topLeft, bottomRight);
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
    final Offset? selectionStartT = _selectionStart;
    final Offset? selectionEndT = _selectionEnd;
    if (selectionEndT == null || selectionStartT == null) {
      if (_selectionStates.isNotEmpty) {
        for (final RenderParagraph paragraph in _selectionStates) {
          paragraph.textSelection = null;
        }
        _selectionStates.clear();
      }
      return;
    }
    // We should just ask each paragraph for a text selection, then it could account for
    // directionality.
    final Offset selectionStart = selectionStartT;
    final Offset selectionEnd = selectionEndT;
    for (final _RegistrantData data in _selectionCandidates.values) {
      final Rect? bounds = data.bounds;
      if (bounds == null) {
        continue;
      }
      if (selectionStart.dy > bounds.bottom || selectionEnd.dy < bounds.top) {
        data.paragraph.textSelection = null;
        _selectionStates.remove(data.paragraph);
        continue;
      }
      Offset modifiedSelectionEnd = selectionEnd;
        // If the selection end is below the bottom of the text, treat it as having a selection that
      // extends to the end of the paragraph. This logic has to change for LTR versus RTL.
      if (selectionEnd.dy > bounds.bottom) {
        modifiedSelectionEnd = Offset(bounds.right, selectionEnd.dy);
      }
      // Otherwise "snap" to the nearest text rect.

      final TextPosition startTextPosition = data.paragraph.getPositionForOffset(data.paragraph.globalToLocal(selectionStart));
      final TextPosition endTextPosition = data.paragraph.getPositionForOffset(data.paragraph.globalToLocal(modifiedSelectionEnd));
      if (startTextPosition == endTextPosition) {
        continue;
      }
      final TextSelection textSelection = TextSelection(baseOffset: startTextPosition.offset, extentOffset: endTextPosition.offset);
      data.paragraph.textSelection = textSelection;
      _selectionStates.add(data.paragraph);
    }
  }

  void _onKeyEvent(RawKeyEvent event) {
    if (event.isControlPressed && event.isKeyPressed(LogicalKeyboardKey.keyC)) {
      _onCopy();
    }
  }

  void _onCopy() {
    if (_selectionStates.isEmpty)
      return;
    // The order in which these should be concatenated is ???. For now this
    // sorts by the top left corner.
    final List<_CopyData> paragraphs = <_CopyData>[];
    for (final RenderParagraph paragraph in _selectionStates) {
      // This should be handled in the inline span.
      final TextSelection? textSelection = paragraph.textSelection;
      if (textSelection == null) {
        continue;
      }
      final String plainText = paragraph.text.toPlainText(includePlaceholders: true, includeSemanticsLabels: false);
      final _RegistrantData? registrantData = _selectionCandidates[paragraph];
      if (registrantData == null) {
        continue;
      }
      paragraphs.add(_CopyData(registrantData.bounds!.topLeft, plainText.substring(textSelection.start, textSelection.end)));
    }
    paragraphs.sort();
    final StringBuffer buffer = StringBuffer();
    for (final _CopyData data in paragraphs) {
      buffer.write(data.data);
      buffer.write(' ');
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
  }

  @override
  void dispose() {
    RawKeyboard.instance.removeListener(_onKeyEvent);
    for (final RenderParagraph paragraph in _selectionStates) {
      paragraph.textSelection = null;
    }
    _selectionStates.clear();
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

class _CopyData implements Comparable<_CopyData> {
  _CopyData(this.topLeft, this.data);

  final Offset topLeft;
  final String data;

  @override
  int compareTo(_CopyData other) {
    if (other.topLeft.dy < topLeft.dy) {
      return -1;
    } else if (other.topLeft.dy > topLeft.dy) {
      return 1;
    } else if (other.topLeft.dx < topLeft.dx) {
      return -1;
    } else if (other.topLeft.dx > topLeft.dx) {
      return 1;
    }
    return 0;
  }
}
