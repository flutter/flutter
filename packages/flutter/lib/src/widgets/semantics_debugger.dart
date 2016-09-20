// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:math' as math;

import 'package:flutter.services.semantics/semantics.mojom.dart' as mojom;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';

/// A widget that visualizes the semantics for the child.
///
/// This widget is useful for understand how an app presents itself to
/// accessibility technology.
class SemanticsDebugger extends StatefulWidget {
  /// Creates a widget that visualizes the semantics for the child.
  ///
  /// The [child] argument must not be null.
  const SemanticsDebugger({ Key key, this.child }) : super(key: key);

  /// The widget below this widget in the tree.
  final Widget child;

  @override
  _SemanticsDebuggerState createState() => new _SemanticsDebuggerState();
}

class _SemanticsDebuggerState extends State<SemanticsDebugger> {
  _SemanticsClient _client;

  @override
  void initState() {
    super.initState();
    // TODO(abarth): We shouldn't reach out to the WidgetsBinding.instance
    // static here because we might not be in a tree that's attached to that
    // binding. Instead, we should find a way to get to the PipelineOwner from
    // the BuildContext.
    _client = new _SemanticsClient(WidgetsBinding.instance.pipelineOwner)
      ..addListener(_update);
  }

  @override
  void dispose() {
    _client
      ..removeListener(_update)
      ..dispose();
    super.dispose();
  }

  void _update() {
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      // We want the update to take effect next frame, so to make that
      // explicit we call setState() in a post-frame callback.
      if (mounted) {
        // If we got disposed this frame, we will still get an update,
        // because the inactive list is flushed after the semantics updates
        // are transmitted to the semantics clients.
        setState(() {
          // The generation of the _SemanticsDebuggerListener has changed.
        });
      }
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
    _client._performAction(_lastPointerDownLocation, SemanticAction.tap);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }
  void _handleLongPress() {
    assert(_lastPointerDownLocation != null);
    _client._performAction(_lastPointerDownLocation, SemanticAction.longPress);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }
  void _handlePanEnd(DragEndDetails details) {
    assert(_lastPointerDownLocation != null);
    _client.handlePanEnd(_lastPointerDownLocation, details.velocity);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new CustomPaint(
      foregroundPainter: new _SemanticsDebuggerPainter(_client.generation, _client, _lastPointerDownLocation),
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
  final Set<SemanticAction> actions = new Set<SemanticAction>();
  bool hasCheckedState = false;
  bool isChecked = false;
  String label;
  Matrix4 transform;
  Rect rect;
  List<_SemanticsDebuggerEntry> children;

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write('_SemanticsDebuggerEntry($id; $rect; "$label"');
    for (SemanticAction action in actions)
      buffer.write('; $action');
    buffer
      ..write('${hasCheckedState ? isChecked ? "; checked" : "; unchecked" : ""}')
      ..write(')');
    return buffer.toString();
  }

  String toStringDeep([ String prefix = '']) {
    if (prefix.length > 20)
      return '$prefix<ABORTED>\n';
    String result = '$prefix$this\n';
    prefix += '  ';
    for (_SemanticsDebuggerEntry child in children) {
      result += '${child.toStringDeep(prefix)}';
    }
    return result;
  }

  void updateWith(mojom.SemanticsNode node) {
    if (node.flags != null) {
      hasCheckedState = node.flags.hasCheckedState;
      isChecked = node.flags.isChecked;
    }
    if (node.actions != null) {
      actions.clear();
      for (int encodedAction in node.actions)
        actions.add(SemanticAction.values[encodedAction]);
    }
    if (node.strings != null) {
      assert(node.strings.label != null);
      label = node.strings.label;
    } else {
      assert(label != null);
    }
    if (node.geometry != null) {
      if (node.geometry.transform != null) {
        assert(node.geometry.transform.length == 16);
        // TODO(ianh): Replace this with a cleaner call once
        //  https://github.com/google/vector_math.dart/issues/159
        // is fixed.
        List<double> array = node.geometry.transform;
        transform = new Matrix4(
          array[0],  array[1],  array[2],  array[3],
          array[4],  array[5],  array[6],  array[7],
          array[8],  array[9],  array[10], array[11],
          array[12], array[13], array[14], array[15]
        );
      } else {
        transform = null;
      }
      rect = new Rect.fromLTWH(node.geometry.left, node.geometry.top, node.geometry.width, node.geometry.height);
    }
    _updateMessage();
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
    height: 0.8
  );

  bool get _isScrollable {
    return actions.contains(SemanticAction.scrollLeft)
        || actions.contains(SemanticAction.scrollRight)
        || actions.contains(SemanticAction.scrollUp)
        || actions.contains(SemanticAction.scrollDown);
  }

  bool get _isAdjustable {
    return actions.contains(SemanticAction.increase)
        || actions.contains(SemanticAction.decrease);
  }

  TextPainter textPainter;
  void _updateMessage() {
    List<String> annotations = <String>[];
    bool wantsTap = false;
    if (hasCheckedState) {
      annotations.add(isChecked ? 'checked' : 'unchecked');
      wantsTap = true;
    }
    if (actions.contains(SemanticAction.tap)) {
      if (!wantsTap)
        annotations.add('button');
    } else {
      if (wantsTap)
        annotations.add('disabled');
    }
    if (actions.contains(SemanticAction.longPress))
      annotations.add('long-pressable');
    if (_isScrollable)
      annotations.add('scrollable');
    if (_isAdjustable)
      annotations.add('adjustable');
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
        ..textAlign = TextAlign.center
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

class _SemanticsClient extends ChangeNotifier {
  _SemanticsClient(PipelineOwner pipelineOwner) {
    _semanticsOwner = pipelineOwner.addSemanticsListener(_updateSemanticsTree);
  }

  SemanticsOwner _semanticsOwner;

  @override
  void dispose() {
    _semanticsOwner.removeListener(_updateSemanticsTree);
    _semanticsOwner = null;
    super.dispose();
  }

  _SemanticsDebuggerEntry get rootNode => _nodes[0];
  final Map<int, _SemanticsDebuggerEntry> _nodes = <int, _SemanticsDebuggerEntry>{};

  _SemanticsDebuggerEntry _updateNode(mojom.SemanticsNode node) {
    final int id = node.id;
    _SemanticsDebuggerEntry entry = _nodes.putIfAbsent(id, () => new _SemanticsDebuggerEntry(id));
    entry.updateWith(node);
    if (node.children != null) {
      if (entry.children != null)
        entry.children.clear();
      else
        entry.children = new List<_SemanticsDebuggerEntry>();
      for (mojom.SemanticsNode child in node.children)
        entry.children.add(_updateNode(child));
    }
    return entry;
  }

  void _removeDetachedNodes() {
    // TODO(abarth): We should be able to keep this table updated without
    // walking the entire tree.
    Set<int> detachedNodes = new Set<int>.from(_nodes.keys);
    Queue<_SemanticsDebuggerEntry> unvisited = new Queue<_SemanticsDebuggerEntry>();
    unvisited.add(rootNode);
    while (unvisited.isNotEmpty) {
      _SemanticsDebuggerEntry node = unvisited.removeFirst();
      detachedNodes.remove(node.id);
      if (node.children != null)
        unvisited.addAll(node.children);
    }
    for (int id in detachedNodes)
      _nodes.remove(id);
  }

  int generation = 0;

  void _updateSemanticsTree(List<mojom.SemanticsNode> nodes) {
    generation += 1;
    for (mojom.SemanticsNode node in nodes)
      _updateNode(node);
    _removeDetachedNodes();
    notifyListeners();
  }

  _SemanticsDebuggerEntry _hitTest(Point position, _SemanticsDebuggerEntryFilter filter) {
    return rootNode?.hitTest(position, filter);
  }

  void _performAction(Point position, SemanticAction action) {
    _SemanticsDebuggerEntry entry = _hitTest(position, (_SemanticsDebuggerEntry entry) => entry.actions.contains(action));
    _semanticsOwner.performAction(entry?.id ?? 0, action);
  }

  void handlePanEnd(Point position, Velocity velocity) {
    double vx = velocity.pixelsPerSecond.dx;
    double vy = velocity.pixelsPerSecond.dy;
    if (vx.abs() == vy.abs())
      return;
    if (vx.abs() > vy.abs()) {
      if (vx.sign < 0) {
        _performAction(position, SemanticAction.decrease);
        _performAction(position, SemanticAction.scrollLeft);
      } else {
        _performAction(position, SemanticAction.increase);
        _performAction(position, SemanticAction.scrollRight);
      }
    } else {
      if (vy.sign < 0)
        _performAction(position, SemanticAction.scrollUp);
      else
        _performAction(position, SemanticAction.scrollDown);
    }
  }
}

class _SemanticsDebuggerPainter extends CustomPainter {
  const _SemanticsDebuggerPainter(this.generation, this.client, this.pointerPosition);

  final int generation;
  final _SemanticsClient client;
  final Point pointerPosition;

  @override
  void paint(Canvas canvas, Size size) {
    _SemanticsDebuggerEntry rootNode = client.rootNode;
    rootNode?.paint(canvas, rootNode.findDepth());
    if (pointerPosition != null) {
      Paint paint = new Paint();
      paint.color = const Color(0x7F0090FF);
      canvas.drawCircle(pointerPosition, 10.0, paint);
    }
  }

  @override
  bool shouldRepaint(_SemanticsDebuggerPainter oldDelegate) {
    return generation != oldDelegate.generation
        || client != oldDelegate.client
        || pointerPosition != oldDelegate.pointerPosition;
  }
}
