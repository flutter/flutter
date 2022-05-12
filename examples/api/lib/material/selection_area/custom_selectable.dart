// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// This sample demonstrates how to create an adapter widget that makes any child
// widget selectable.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String _title = 'Flutter Code Sample';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: _title,
      home: SelectionArea(
        child: Scaffold(
          appBar: AppBar(title: const Text(_title)),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const <Widget>[
                Text('Select this icon'),
                MySelectableAdapter(child: Icon(Icons.key)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MySelectableAdapter extends StatelessWidget {
  const MySelectableAdapter({Key? key, required this.child}) : super(key: key);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SelectionRegistrar? registrar = SelectionRegistrarScope.maybeOf(context);
    if (registrar == null) {
      return child;
    }
    return MouseRegion(
      cursor: SystemMouseCursors.text,
      child: _SelectableAdapter(
        registrar: registrar,
        child: child,
      ),
    );
  }
}

class _SelectableAdapter extends SingleChildRenderObjectWidget {
  const _SelectableAdapter({
    required this.registrar,
    required Widget child,
  }) : super(child: child);

  final SelectionRegistrar registrar;

  @override
  _RenderSelectableAdapter createRenderObject(BuildContext context) {
    return _RenderSelectableAdapter(
      DefaultSelectionStyle.of(context).selectionColor!,
      registrar,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderSelectableAdapter renderObject) {
    renderObject
      ..selectionColor = DefaultSelectionStyle.of(context).selectionColor!
      ..registrar = registrar;
  }
}

class _RenderSelectableAdapter extends RenderProxyBox with Selectable, SelectionRegistrant {
  _RenderSelectableAdapter(
    Color selectionColor,
    SelectionRegistrar registrar,
  ) : _selectionColor = selectionColor,
      _geometry = ValueNotifier<SelectionGeometry>(_noSelection) {
    this.registrar = registrar;
    _geometry.addListener(markNeedsPaint);
  }

  static const SelectionGeometry _noSelection = SelectionGeometry(status: SelectionStatus.none, hasContent: true);
  final ValueNotifier<SelectionGeometry> _geometry;

  Color get selectionColor => _selectionColor;
  late Color _selectionColor;
  set selectionColor(Color value) {
    if (_selectionColor == value) {
      return;
    }
    _selectionColor = value;
    markNeedsPaint();
  }

  // ValueListenable APIs

  @override
  void addListener(VoidCallback listener) => _geometry.addListener(listener);

  @override
  void removeListener(VoidCallback listener) => _geometry.removeListener(listener);

  @override
  SelectionGeometry get value => _geometry.value;

  // Selectable APIs.

  Rect getCurrentRect() => Rect.fromLTWH(0, 0, size.width, size.height);

  Offset? _start;
  Offset? _end;
  void _updateGeometry() {
    if (_start == null || _end == null) {
      _geometry.value = _noSelection;
      return;
    }
    final Rect renderObjectRect = getCurrentRect();
    final Rect selectionRect = Rect.fromPoints(_start!, _end!);
    if (renderObjectRect.intersect(selectionRect).isEmpty) {
      _geometry.value = _noSelection;
    } else {
      final SelectionPoint firstSelectionPoint = SelectionPoint(
        localPosition: Offset(0, size.height),
        lineHeight: size.height,
        handleType: TextSelectionHandleType.left,
      );
      final SelectionPoint secondSelectionPoint = SelectionPoint(
        localPosition: Offset(size.width, size.height),
        lineHeight: size.height,
        handleType: TextSelectionHandleType.right,
      );
      _geometry.value = SelectionGeometry(
        status: SelectionStatus.uncollapsed,
        hasContent: true,
        startSelectionPoint: _start!.dy < _start!.dy ? firstSelectionPoint : secondSelectionPoint,
        endSelectionPoint: _start!.dy < _start!.dy ? secondSelectionPoint : firstSelectionPoint,
      );
    }
  }

  @override
  SelectionResult dispatchSelectionEvent(SelectionEvent event) {
    SelectionResult result = SelectionResult.none;
    switch (event.type) {
      case SelectionEventType.startEdgeUpdate:
      case SelectionEventType.endEdgeUpdate:
        final Rect renderObjectRect = getCurrentRect();
        // Normalize offset in case it is out side of the rect.
        final Offset point = globalToLocal((event as SelectionEdgeUpdateEvent).globalPosition);
        final Offset adjustedPoint = SelectionUtil.adjustDragOffset(renderObjectRect, point);
        if (event.type == SelectionEventType.startEdgeUpdate) {
          _start = adjustedPoint;
        } else {
          _end = adjustedPoint;
        }
        result = SelectionUtil.getResultBasedOnRect(renderObjectRect, point);
        break;
      case SelectionEventType.clear:
        _start = _end = null;
        break;
      case SelectionEventType.selectAll:
      case SelectionEventType.selectWord:
        _start = Offset.zero;
        _end = Offset.infinite;
        break;
    }
    _updateGeometry();
    return result;
  }

  @override
  SelectedContent? getSelectedContent() {
    // Text that will be copied.
    return value.hasSelection ? const SelectedContent(plainText: 'Custom Text') : null;
  }

  LayerLink? _startHandle;
  LayerLink? _endHandle;

  @override
  void pushHandleLayers(LayerLink? startHandle, LayerLink? endHandle) {
    if (_startHandle == startHandle && _endHandle == endHandle) {
      return;
    }
    _startHandle = startHandle;
    _endHandle = endHandle;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);
    if (!_geometry.value.hasSelection) {
      return;
    }
    // Draw the selection highlight.
    final Paint selectionPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _selectionColor;
    context.canvas.drawRect(getCurrentRect().shift(offset), selectionPaint);

    // Push the layer links if any.
    if (_startHandle != null) {
      context.pushLayer(
        LeaderLayer(
          link: _startHandle!,
          offset: offset + value.startSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) { },
        Offset.zero,
      );
    }
    if (_endHandle != null) {
      context.pushLayer(
        LeaderLayer(
          link: _endHandle!,
          offset: offset + value.endSelectionPoint!.localPosition,
        ),
        (PaintingContext context, Offset offset) { },
        Offset.zero,
      );
    }
  }

  @override
  void dispose() {
    _geometry.dispose();
    super.dispose();
  }
}
