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

  static SelectionRegistrant? of(BuildContext context) {
    final _SelectionAreaState? registrant = context.findAncestorStateOfType<_SelectionAreaState>();
    if (registrant == null || !registrant.widget.enabled) {
      return null;
    }
    return registrant;
  }
}

class _SelectionAreaState extends State<SelectionArea> implements SelectionRegistrant {
  final GlobalKey<RawGestureDetectorState> _gestureDetectorKey = GlobalKey<RawGestureDetectorState>();
  final Map<Type, GestureRecognizerFactory> _gestureRecognizers = <Type, GestureRecognizerFactory>{};
  final Map<Selectable<Object>, Rect> _selectionCandidates = <Selectable<Object>, Rect>{};
  final Set<Selectable<Object>> _selectionStates = <Selectable<Object>>{};

  Offset? _selectionStart;
  Offset? _selectionEnd;

  @override
  void update(Selectable<Object> selectable, Rect globalRect) {
    _selectionCandidates[selectable] = globalRect;
  }

  @override
  void remove(Selectable<Object> selectable) {
    _selectionCandidates.remove(selectable);
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

  void _handleDragEnd(DragEndDetails details) {}

  void _handleDragCancel() {
    _selectionStart = null;
    _selectionEnd = null;
    _maybeUpdateSelection();
  }

  void _handleTapDown(TapDownDetails details) {
    if (details.kind != PointerDeviceKind.mouse)
      return;
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
        for (final Selectable<Object> selectable in _selectionStates) {
          selectable.clear();
        }
        _selectionStates.clear();
      }
      return;
    }
    final Offset selectionStart = selectionStartT;
    final Offset selectionEnd = selectionEndT;
    for (final Selectable<Object> data in _selectionCandidates.keys) {
      final Rect? bounds = _selectionCandidates[data];
      if (bounds == null) {
        continue;
      }
      if (data.update(selectionStart, selectionEnd)) {
        _selectionStates.add(data);
      }
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
    final List<_CopyData<Object>> copyData = <_CopyData<Object>>[];
    for (final Selectable<Object> selectable in _selectionStates) {
      final Rect? bounds = _selectionCandidates[selectable];
      if (bounds == null) {
        continue;
      }
      final Object? data = selectable.copy();
      if (data == null) {
        continue;
      }
      copyData.add(_CopyData<Object>(bounds.topLeft, data));
    }
    copyData.sort();
    // TODO: support more types than strings
    final StringBuffer buffer = StringBuffer();
    for (final _CopyData<Object> data in copyData) {
      buffer.writeln(data.data); // Not sure what separator to use.
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
    for (final Selectable<Object> selectable in _selectionStates) {
      selectable.clear();
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

class _CopyData<T> implements Comparable<_CopyData<T>> {
  _CopyData(this.topLeft, this.data);

  final Offset topLeft;
  final T data;

  @override
  int compareTo(_CopyData<T> other) {
    if (other.topLeft.dy < topLeft.dy) {
      return 1;
    } else if (other.topLeft.dy > topLeft.dy) {
      return -1;
    } else if (other.topLeft.dx < topLeft.dx) {
      return 1;
    } else if (other.topLeft.dx > topLeft.dx) {
      return -1;
    }
    return 0;
  }
}
