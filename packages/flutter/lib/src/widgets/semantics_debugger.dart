// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:sky_services/semantics/semantics.mojom.dart' as mojom;

import 'basic.dart';
import 'framework.dart';
import 'gesture_detector.dart';

/// Visualizes the semantics for the child.
///
/// This widget is useful for understand how an app presents itself to
/// accessibility technology.
class SemanticsDebugger extends StatefulWidget {
  const SemanticsDebugger({ Key key, this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _SemanticsDebuggerState createState() => new _SemanticsDebuggerState();
}

class _SemanticsDebuggerState extends State<SemanticsDebugger> {
  @override
  void initState() {
    super.initState();
    _SemanticsDebuggerListener.ensureInstantiated();
    _SemanticsDebuggerListener.instance.addListener(_update);
  }

  @override
  void dispose() {
    _SemanticsDebuggerListener.instance.removeListener(_update);
    super.dispose();
  }

  void _update() {
    setState(() {
      // the generation of the _SemanticsDebuggerListener has changed
    });
  }

  Point _lastPointerDownLocation;
  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _lastPointerDownLocation = event.position;
    });
  }

  void _handleTap() {
    assert(_lastPointerDownLocation != null);
    _SemanticsDebuggerListener.instance.handleTap(_lastPointerDownLocation);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }
  void _handleLongPress() {
    assert(_lastPointerDownLocation != null);
    _SemanticsDebuggerListener.instance.handleLongPress(_lastPointerDownLocation);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }
  void _handlePanEnd(Velocity velocity) {
    assert(_lastPointerDownLocation != null);
    _SemanticsDebuggerListener.instance.handlePanEnd(_lastPointerDownLocation, velocity);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      foregroundPainter: new _SemanticsDebuggerPainter(_SemanticsDebuggerListener.instance.generation, _lastPointerDownLocation),
      child: new GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onPanEnd: _handlePanEnd,
        excludeFromSemantics: true, // otherwise if you don't hit anything, we end up receiving it, which causes an infinite loop...
        child: new Listener(
          onPointerDown: _handlePointerDown,
          behavior: HitTestBehavior.opaque,
          child: new IgnorePointer(
            ignoringSemantics: false,
            child: config.child
          )
        )
      )
    );
  }
}

typedef bool _SemanticsDebuggerEntryFilter(_SemanticsDebuggerEntry entry);

class _SemanticsDebuggerEntry {
  _SemanticsDebuggerEntry(this.id);

  final int id;
  bool canBeTapped = false;
  bool canBeLongPressed = false;
  bool canBeScrolledHorizontally = false;
  bool canBeScrolledVertically = false;
  bool hasCheckedState = false;
  bool isChecked = false;
  String label;
  Matrix4 transform;
  Rect rect;
  List<_SemanticsDebuggerEntry> children;

  @override
  String toString() {
    return '_SemanticsDebuggerEntry($id; $rect; "$label"'
           '${canBeTapped ? "; canBeTapped" : ""}'
           '${canBeLongPressed ? "; canBeLongPressed" : ""}'
           '${canBeScrolledHorizontally ? "; canBeScrolledHorizontally" : ""}'
           '${canBeScrolledVertically ? "; canBeScrolledVertically" : ""}'
           '${hasCheckedState ? isChecked ? "; checked" : "; unchecked" : ""}'
           ')';
  }
  String toStringDeep([ String prefix = '']) {
    if (prefix.length > 20)
      return '$prefix<ABORTED>\n';
    String result = '$prefix$this\n';
    for (_SemanticsDebuggerEntry child in children.reversed) {
      prefix += '  ';
      result += '${child.toStringDeep(prefix)}';
    }
    return result;
  }

  int findDepth() {
    if (children == null || children.isEmpty)
      return 1;
    return children.map((_SemanticsDebuggerEntry e) => e.findDepth()).reduce((int runningDepth, int nextDepth) {
      return math.max(runningDepth, nextDepth);
    }) + 1;
  }

  static const TextStyle textStyles = const TextStyle(
    color: const Color(0xFF000000),
    fontSize: 10.0,
    height: 0.8,
    textAlign: TextAlign.center
  );

  TextPainter textPainter;
  void updateMessage() {
    List<String> annotations = <String>[];
    bool wantsTap = false;
    if (hasCheckedState) {
      annotations.add(isChecked ? 'checked' : 'unchecked');
      wantsTap = true;
    }
    if (canBeTapped) {
      if (!wantsTap)
        annotations.add('button');
    } else {
      if (wantsTap)
        annotations.add('disabled');
    }
    if (canBeLongPressed)
      annotations.add('long-pressable');
    if (canBeScrolledHorizontally || canBeScrolledVertically)
      annotations.add('scrollable');
    String message;
    if (annotations.isEmpty) {
      assert(label != null);
      message = label;
    } else {
      if (label == '') {
        message = annotations.join('; ');
      } else {
        message = '$label (${annotations.join('; ')})';
      }
    }
    message = message.trim();
    if (message != '') {
      textPainter ??= new TextPainter();
      textPainter
        ..text = new TextSpan(style: textStyles, text: message)
        ..layout(maxWidth: rect.width);
    } else {
      textPainter = null;
    }
  }

  void paint(Canvas canvas, int rank) {
    canvas.save();
    if (transform != null)
      canvas.transform(transform.storage);
    if (!rect.isEmpty) {
      Color lineColor = new Color(0xFF000000 + new math.Random(id).nextInt(0xFFFFFF));
      Rect innerRect = rect.deflate(rank * 1.0);
      if (innerRect.isEmpty) {
        Paint fill = new Paint()
         ..color = lineColor
         ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fill);
      } else {
        Paint fill = new Paint()
         ..color = const Color(0xFFFFFFFF)
         ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fill);
        Paint line = new Paint()
         ..strokeWidth = rank * 2.0
         ..color = lineColor
         ..style = PaintingStyle.stroke;
        canvas.drawRect(innerRect, line);
      }
      if (textPainter != null) {
        canvas.save();
        canvas.clipRect(rect);
        textPainter.paint(canvas, rect.topLeft.toOffset());
        canvas.restore();
      }
    }
    for (_SemanticsDebuggerEntry child in children)
      child.paint(canvas, rank - 1);
    canvas.restore();
  }

  _SemanticsDebuggerEntry hitTest(Point position, _SemanticsDebuggerEntryFilter filter) {
    if (transform != null) {
      Matrix4 invertedTransform = new Matrix4.identity();
      double determinant = invertedTransform.copyInverse(transform);
      if (determinant == 0.0)
        return null;
      position = MatrixUtils.transformPoint(invertedTransform, position);
    }
    if (!rect.contains(position))
      return null;
    _SemanticsDebuggerEntry result;
    for (_SemanticsDebuggerEntry child in children.reversed) {
      result = child.hitTest(position, filter);
      if (result != null)
        break;
    }
    if (result == null || !filter(result))
      result = this;
    return result;
  }
}

class _SemanticsDebuggerListener implements mojom.SemanticsListener {
  _SemanticsDebuggerListener._() {
    SemanticsNode.addListener(this);
  }

  static _SemanticsDebuggerListener instance;
  static final SemanticsServer _server = new SemanticsServer();
  static void ensureInstantiated() {
    instance ??= new _SemanticsDebuggerListener._();
  }

  Set<VoidCallback> _listeners = new Set<VoidCallback>();
  void addListener(VoidCallback callback) {
    assert(!_listeners.contains(callback));
    _listeners.add(callback);
  }
  void removeListener(VoidCallback callback) {
    _listeners.remove(callback);
  }

  Map<int, _SemanticsDebuggerEntry> nodes = <int, _SemanticsDebuggerEntry>{};

  _SemanticsDebuggerEntry _updateNode(mojom.SemanticsNode node) {
    _SemanticsDebuggerEntry entry = nodes.putIfAbsent(node.id, () => new _SemanticsDebuggerEntry(node.id));
    if (node.flags != null) {
      entry.canBeTapped = node.flags.canBeTapped;
      entry.canBeLongPressed = node.flags.canBeLongPressed;
      entry.canBeScrolledHorizontally = node.flags.canBeScrolledHorizontally;
      entry.canBeScrolledVertically = node.flags.canBeScrolledVertically;
      entry.hasCheckedState = node.flags.hasCheckedState;
      entry.isChecked = node.flags.isChecked;
    }
    if (node.strings != null) {
      assert(node.strings.label != null);
      entry.label = node.strings.label;
    } else {
      assert(entry.label != null);
    }
    if (node.geometry != null) {
      if (node.geometry.transform != null) {
        assert(node.geometry.transform.length == 16);
        // TODO(ianh): Replace this with a cleaner call once
        //  https://github.com/google/vector_math.dart/issues/159
        // is fixed.
        List<double> array = node.geometry.transform;
        entry.transform = new Matrix4(
          array[0],  array[1],  array[2],  array[3],
          array[4],  array[5],  array[6],  array[7],
          array[8],  array[9],  array[10], array[11],
          array[12], array[13], array[14], array[15]
        );
      } else {
        entry.transform = null;
      }
      entry.rect = new Rect.fromLTWH(node.geometry.left, node.geometry.top, node.geometry.width, node.geometry.height);
    }
    entry.updateMessage();
    if (node.children != null) {
      Set<_SemanticsDebuggerEntry> oldChildren = new Set<_SemanticsDebuggerEntry>.from(entry.children ?? const <_SemanticsDebuggerEntry>[]);
      entry.children?.clear();
      entry.children ??= new List<_SemanticsDebuggerEntry>();
      for (mojom.SemanticsNode child in node.children)
        entry.children.add(_updateNode(child));
      Set<_SemanticsDebuggerEntry> newChildren = new Set<_SemanticsDebuggerEntry>.from(entry.children);
      Set<_SemanticsDebuggerEntry> removedChildren = oldChildren.difference(newChildren);
      for (_SemanticsDebuggerEntry oldChild in removedChildren)
        nodes.remove(oldChild.id);
    }
    return entry;
  }

  int generation = 0;

  @override
  void updateSemanticsTree(List<mojom.SemanticsNode> nodes) {
    generation += 1;
    for (mojom.SemanticsNode node in nodes)
      _updateNode(node);
    for (VoidCallback listener in _listeners)
      listener();
  }

  _SemanticsDebuggerEntry _hitTest(Point position, _SemanticsDebuggerEntryFilter filter) {
    return nodes[0]?.hitTest(position, filter);
  }

  void handleTap(Point position) {
    _server.tap(_hitTest(position, (_SemanticsDebuggerEntry entry) => entry.canBeTapped)?.id ?? 0);
  }
  void handleLongPress(Point position) {
    _server.longPress(_hitTest(position, (_SemanticsDebuggerEntry entry) => entry.canBeLongPressed)?.id ?? 0);
  }
  void handlePanEnd(Point position, Velocity velocity) {
    double vx = velocity.pixelsPerSecond.dx;
    double vy = velocity.pixelsPerSecond.dy;
    if (vx.abs() == vy.abs())
      return;
    if (vx.abs() > vy.abs()) {
      if (vx.sign < 0)
        _server.scrollLeft(_hitTest(position, (_SemanticsDebuggerEntry entry) => entry.canBeScrolledHorizontally)?.id ?? 0);
      else
        _server.scrollRight(_hitTest(position, (_SemanticsDebuggerEntry entry) => entry.canBeScrolledHorizontally)?.id ?? 0);
    } else {
      if (vy.sign < 0)
        _server.scrollUp(_hitTest(position, (_SemanticsDebuggerEntry entry) => entry.canBeScrolledVertically)?.id ?? 0);
      else
        _server.scrollDown(_hitTest(position, (_SemanticsDebuggerEntry entry) => entry.canBeScrolledVertically)?.id ?? 0);
    }
  }
}

class _SemanticsDebuggerPainter extends CustomPainter {
  const _SemanticsDebuggerPainter(this.generation, this.pointerPosition);

  final int generation;
  final Point pointerPosition;

  @override
  void paint(Canvas canvas, Size size) {
    _SemanticsDebuggerListener.instance.nodes[0]?.paint(
      canvas,
      _SemanticsDebuggerListener.instance.nodes[0].findDepth()
    );
    if (pointerPosition != null) {
      Paint paint = new Paint();
      paint.color = const Color(0x7F0090FF);
      canvas.drawCircle(pointerPosition, 10.0, paint);
    }
  }

  @override
  bool shouldRepaint(_SemanticsDebuggerPainter oldDelegate) {
    return generation != oldDelegate.generation
        || pointerPosition != oldDelegate.pointerPosition;
  }
}
