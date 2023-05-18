// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'gesture_detector.dart';
import 'view.dart';

/// A widget that visualizes the semantics for the child.
///
/// This widget is useful for understand how an app presents itself to
/// accessibility technology.
class SemanticsDebugger extends StatefulWidget {
  /// Creates a widget that visualizes the semantics for the child.
  ///
  /// The [child] argument must not be null.
  ///
  /// [labelStyle] dictates the [TextStyle] used for the semantics labels.
  const SemanticsDebugger({
    super.key,
    required this.child,
    this.labelStyle = const TextStyle(
      color: Color(0xFF000000),
      fontSize: 10.0,
      height: 0.8,
    ),
  });

  /// The widget below this widget in the tree.
  ///
  /// {@macro flutter.widgets.ProxyWidget.child}
  final Widget child;

  /// The [TextStyle] to use when rendering semantics labels.
  final TextStyle labelStyle;

  @override
  State<SemanticsDebugger> createState() => _SemanticsDebuggerState();
}

class _SemanticsDebuggerState extends State<SemanticsDebugger> with WidgetsBindingObserver {
  late _SemanticsClient _client;

  @override
  void initState() {
    super.initState();
    // TODO(abarth): We shouldn't reach out to the WidgetsBinding.instance
    // static here because we might not be in a tree that's attached to that
    // binding. Instead, we should find a way to get to the PipelineOwner from
    // the BuildContext.
    _client = _SemanticsClient(WidgetsBinding.instance.pipelineOwner)
      ..addListener(_update);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _client
      ..removeListener(_update)
      ..dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeMetrics() {
    setState(() {
      // The root transform may have changed, we have to repaint.
    });
  }

  void _update() {
    SchedulerBinding.instance.addPostFrameCallback((Duration timeStamp) {
      // Semantic information are only available at the end of a frame and our
      // only chance to paint them on the screen is the next frame. To achieve
      // this, we call setState() in a post-frame callback.
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

  Offset? _lastPointerDownLocation;
  void _handlePointerDown(PointerDownEvent event) {
    setState(() {
      _lastPointerDownLocation = event.position * View.of(context).devicePixelRatio;
    });
    // TODO(ianh): Use a gesture recognizer so that we can reset the
    // _lastPointerDownLocation when none of the other gesture recognizers win.
  }

  void _handleTap() {
    assert(_lastPointerDownLocation != null);
    _performAction(_lastPointerDownLocation!, SemanticsAction.tap);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  void _handleLongPress() {
    assert(_lastPointerDownLocation != null);
    _performAction(_lastPointerDownLocation!, SemanticsAction.longPress);
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  void _handlePanEnd(DragEndDetails details) {
    final double vx = details.velocity.pixelsPerSecond.dx;
    final double vy = details.velocity.pixelsPerSecond.dy;
    if (vx.abs() == vy.abs()) {
      return;
    }
    if (vx.abs() > vy.abs()) {
      if (vx.sign < 0) {
        _performAction(_lastPointerDownLocation!, SemanticsAction.decrease);
        _performAction(_lastPointerDownLocation!, SemanticsAction.scrollLeft);
      } else {
        _performAction(_lastPointerDownLocation!, SemanticsAction.increase);
        _performAction(_lastPointerDownLocation!, SemanticsAction.scrollRight);
      }
    } else {
      if (vy.sign < 0) {
        _performAction(_lastPointerDownLocation!, SemanticsAction.scrollUp);
      } else {
        _performAction(_lastPointerDownLocation!, SemanticsAction.scrollDown);
      }
    }
    setState(() {
      _lastPointerDownLocation = null;
    });
  }

  void _performAction(Offset position, SemanticsAction action) {
    _pipelineOwner.semanticsOwner?.performActionAt(position, action);
  }

  // TODO(abarth): This shouldn't be a static. We should get the pipeline owner
  // from [context] somehow.
  PipelineOwner get _pipelineOwner => WidgetsBinding.instance.pipelineOwner;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: _SemanticsDebuggerPainter(
        _pipelineOwner,
        _client.generation,
        _lastPointerDownLocation, // in physical pixels
        View.of(context).devicePixelRatio,
        widget.labelStyle,
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onPanEnd: _handlePanEnd,
        excludeFromSemantics: true, // otherwise if you don't hit anything, we end up receiving it, which causes an infinite loop...
        child: Listener(
          onPointerDown: _handlePointerDown,
          behavior: HitTestBehavior.opaque,
          child: _IgnorePointerWithSemantics(
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

class _SemanticsClient extends ChangeNotifier {
  _SemanticsClient(PipelineOwner pipelineOwner) {
    _semanticsHandle = pipelineOwner.ensureSemantics(
      listener: _didUpdateSemantics,
    );
  }

  SemanticsHandle? _semanticsHandle;

  @override
  void dispose() {
    _semanticsHandle!.dispose();
    _semanticsHandle = null;
    super.dispose();
  }

  int generation = 0;

  void _didUpdateSemantics() {
    generation += 1;
    notifyListeners();
  }
}

class _SemanticsDebuggerPainter extends CustomPainter {
  const _SemanticsDebuggerPainter(this.owner, this.generation, this.pointerPosition, this.devicePixelRatio, this.labelStyle);

  final PipelineOwner owner;
  final int generation;
  final Offset? pointerPosition; // in physical pixels
  final double devicePixelRatio;
  final TextStyle labelStyle;

  SemanticsNode? get _rootSemanticsNode {
    return owner.semanticsOwner?.rootSemanticsNode;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final SemanticsNode? rootNode = _rootSemanticsNode;
    canvas.save();
    canvas.scale(1.0 / devicePixelRatio, 1.0 / devicePixelRatio);
    if (rootNode != null) {
      _paint(canvas, rootNode, _findDepth(rootNode));
    }
    if (pointerPosition != null) {
      final Paint paint = Paint();
      paint.color = const Color(0x7F0090FF);
      canvas.drawCircle(pointerPosition!, 10.0 * devicePixelRatio, paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SemanticsDebuggerPainter oldDelegate) {
    return owner != oldDelegate.owner
        || generation != oldDelegate.generation
        || pointerPosition != oldDelegate.pointerPosition;
  }

  @visibleForTesting
  String getMessage(SemanticsNode node) {
    final SemanticsData data = node.getSemanticsData();
    final List<String> annotations = <String>[];

    bool wantsTap = false;
    if (data.hasFlag(SemanticsFlag.hasCheckedState)) {
      annotations.add(data.hasFlag(SemanticsFlag.isChecked) ? 'checked' : 'unchecked');
      wantsTap = true;
    }
    if (data.hasFlag(SemanticsFlag.isTextField)) {
      annotations.add('textfield');
      wantsTap = true;
    }

    if (data.hasAction(SemanticsAction.tap)) {
      if (!wantsTap) {
        annotations.add('button');
      }
    } else {
      if (wantsTap) {
        annotations.add('disabled');
      }
    }

    if (data.hasAction(SemanticsAction.longPress)) {
      annotations.add('long-pressable');
    }

    final bool isScrollable = data.hasAction(SemanticsAction.scrollLeft)
        || data.hasAction(SemanticsAction.scrollRight)
        || data.hasAction(SemanticsAction.scrollUp)
        || data.hasAction(SemanticsAction.scrollDown);

    final bool isAdjustable = data.hasAction(SemanticsAction.increase)
        || data.hasAction(SemanticsAction.decrease);

    if (isScrollable) {
      annotations.add('scrollable');
    }

    if (isAdjustable) {
      annotations.add('adjustable');
    }

    final String message;
    // Android will avoid pronouncing duplicating tooltip and label.
    // Therefore, having two identical strings is the same as having a single
    // string.
    final bool shouldIgnoreDuplicatedLabel = defaultTargetPlatform == TargetPlatform.android && data.attributedLabel.string == data.tooltip;
    final String tooltipAndLabel = <String>[
      if (data.tooltip.isNotEmpty)
        data.tooltip,
      if (data.attributedLabel.string.isNotEmpty && !shouldIgnoreDuplicatedLabel)
        data.attributedLabel.string,
    ].join('\n');
    if (tooltipAndLabel.isEmpty) {
      message = annotations.join('; ');
    } else {
      final String effectivelabel;
      if (data.textDirection == null) {
        effectivelabel = '${Unicode.FSI}$tooltipAndLabel${Unicode.PDI}';
        annotations.insert(0, 'MISSING TEXT DIRECTION');
      } else {
        switch (data.textDirection!) {
          case TextDirection.rtl:
            effectivelabel = '${Unicode.RLI}$tooltipAndLabel${Unicode.PDF}';
          case TextDirection.ltr:
            effectivelabel = tooltipAndLabel;
        }
      }
      if (annotations.isEmpty) {
        message = effectivelabel;
      } else {
        message = '$effectivelabel (${annotations.join('; ')})';
      }
    }

    return message.trim();
  }

  void _paintMessage(Canvas canvas, SemanticsNode node) {
    final String message = getMessage(node);
    if (message.isEmpty) {
      return;
    }
    final Rect rect = node.rect;
    canvas.save();
    canvas.clipRect(rect);
    final TextPainter textPainter = TextPainter()
      ..text = TextSpan(
        style: labelStyle,
        text: message,
      )
      ..textDirection = TextDirection.ltr // _getMessage always returns LTR text, even if node.label is RTL
      ..textAlign = TextAlign.center
      ..layout(maxWidth: rect.width);

    textPainter.paint(canvas, Alignment.center.inscribe(textPainter.size, rect).topLeft);
    textPainter.dispose();
    canvas.restore();
  }

  int _findDepth(SemanticsNode node) {
    if (!node.hasChildren || node.mergeAllDescendantsIntoThisNode) {
      return 1;
    }
    int childrenDepth = 0;
    node.visitChildren((SemanticsNode child) {
      childrenDepth = math.max(childrenDepth, _findDepth(child));
      return true;
    });
    return childrenDepth + 1;
  }

  void _paint(Canvas canvas, SemanticsNode node, int rank) {
    canvas.save();
    if (node.transform != null) {
      canvas.transform(node.transform!.storage);
    }
    final Rect rect = node.rect;
    if (!rect.isEmpty) {
      final Color lineColor = Color(0xFF000000 + math.Random(node.id).nextInt(0xFFFFFF));
      final Rect innerRect = rect.deflate(rank * 1.0);
      if (innerRect.isEmpty) {
        final Paint fill = Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fill);
      } else {
        final Paint fill = Paint()
          ..color = const Color(0xFFFFFFFF)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, fill);
        final Paint line = Paint()
          ..strokeWidth = rank * 2.0
          ..color = lineColor
          ..style = PaintingStyle.stroke;
        canvas.drawRect(innerRect, line);
      }
      _paintMessage(canvas, node);
    }
    if (!node.mergeAllDescendantsIntoThisNode) {
      final int childRank = rank - 1;
      node.visitChildren((SemanticsNode child) {
        _paint(canvas, child, childRank);
        return true;
      });
    }
    canvas.restore();
  }
}

/// A widget ignores pointer event but still keeps semantics actions.
class _IgnorePointerWithSemantics extends SingleChildRenderObjectWidget {
  const _IgnorePointerWithSemantics({
    super.child,
  });

  @override
  _RenderIgnorePointerWithSemantics createRenderObject(BuildContext context) {
    return _RenderIgnorePointerWithSemantics();
  }
}

class _RenderIgnorePointerWithSemantics extends RenderProxyBox {
  _RenderIgnorePointerWithSemantics();

  @override
  bool hitTest(BoxHitTestResult result, { required Offset position }) => false;
}
