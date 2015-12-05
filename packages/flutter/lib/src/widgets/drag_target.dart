// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'overlay.dart';

typedef bool DragTargetWillAccept<T>(T data);
typedef void DragTargetAccept<T>(T data);
typedef Widget DragTargetBuilder<T>(BuildContext context, List<T> candidateData, List<dynamic> rejectedData);
typedef void DragStartCallback(Point position, int pointer);

enum DragAnchor {
  /// Display the feedback anchored at the position of the original child. If
  /// feedback is identical to the child, then this means the feedback will
  /// exactly overlap the original child when the drag starts.
  child,

  /// Display the feedback anchored at the position of the touch that started
  /// the drag. If feedback is identical to the child, then this means the top
  /// left of the feedback will be under the finger when the drag starts. This
  /// will likely not exactly overlap the original child, e.g. if the child is
  /// big and the touch was not centered. This mode is useful when the feedback
  /// is transformed so as to move the feedback to the left by half its width,
  /// and up by half its width plus the height of the finger, since then it
  /// appears as if putting the finger down makes the touch feedback appear
  /// above the finger. (It feels weird for it to appear offset from the
  /// original child if it's anchored to the child and not the finger.)
  pointer,
}

abstract class DraggableBase<T> extends StatefulComponent {
  DraggableBase({
    Key key,
    this.data,
    this.child,
    this.feedback,
    this.feedbackOffset: Offset.zero,
    this.dragAnchor: DragAnchor.child
  }) : super(key: key) {
    assert(child != null);
    assert(feedback != null);
  }

  final T data;
  final Widget child;
  final Widget feedback;

  /// The feedbackOffset can be used to set the hit test target point for the
  /// purposes of finding a drag target. It is especially useful if the feedback
  /// is transformed compared to the child.
  final Offset feedbackOffset;
  final DragAnchor dragAnchor;

  /// Should return a GestureRecognizer instance that is configured to call the starter
  /// argument when the drag is to begin. The arena for the pointer must not yet have
  /// resolved at the time that the callback is invoked, because the draggable itself
  /// is going to attempt to win the pointer's arena in that case.
  GestureRecognizer createRecognizer(PointerRouter router, DragStartCallback starter);

  _DraggableState<T> createState() => new _DraggableState<T>();
}

class Draggable<T> extends DraggableBase<T> {
  Draggable({
    Key key,
    T data,
    Widget child,
    Widget feedback,
    Offset feedbackOffset: Offset.zero,
    DragAnchor dragAnchor: DragAnchor.child
  }) : super(
    key: key,
    data: data,
    child: child,
    feedback: feedback,
    feedbackOffset: feedbackOffset,
    dragAnchor: dragAnchor
  );

  GestureRecognizer createRecognizer(PointerRouter router, DragStartCallback starter) {
    return new MultiTapGestureRecognizer(
      router: router,
      onTapDown: starter
    );
  }
}

class LongPressDraggable<T> extends DraggableBase<T> {
  LongPressDraggable({
    Key key,
    T data,
    Widget child,
    Widget feedback,
    Offset feedbackOffset: Offset.zero,
    DragAnchor dragAnchor: DragAnchor.child
  }) : super(
    key: key,
    data: data,
    child: child,
    feedback: feedback,
    feedbackOffset: feedbackOffset,
    dragAnchor: dragAnchor
  );

  GestureRecognizer createRecognizer(PointerRouter router, DragStartCallback starter) {
    return new MultiTapGestureRecognizer(
      router: router,
      longTapDelay: kLongPressTimeout,
      onLongTapDown: (Point position, int pointer) {
        userFeedback.performHapticFeedback(HapticFeedbackType.VIRTUAL_KEY);
        starter(position, pointer);
      }
    );
  }
}

class _DraggableState<T> extends State<DraggableBase<T>> implements GestureArenaMember {

  PointerRouter get router => FlutterBinding.instance.pointerRouter;

  void initState() {
    super.initState();
    _recognizer = config.createRecognizer(router, _startDrag);
  }

  GestureRecognizer _recognizer;
  Map<int, GestureArenaEntry> _activePointers = <int, GestureArenaEntry>{};

  void _routePointer(PointerEvent event) {
    _activePointers[event.pointer] = GestureArena.instance.add(event.pointer, this);
    _recognizer.addPointer(event);
  }

  void acceptGesture(int pointer) {
    _activePointers.remove(pointer);
  }

  void rejectGesture(int pointer) {
    _activePointers.remove(pointer);
  }

  void _startDrag(Point position, int pointer) {
    assert(_activePointers.containsKey(pointer));
    _activePointers[pointer].resolve(GestureDisposition.accepted);
    Point dragStartPoint;
    switch (config.dragAnchor) {
      case DragAnchor.child:
        final RenderBox renderObject = context.findRenderObject();
        dragStartPoint = renderObject.globalToLocal(position);
        break;
      case DragAnchor.pointer:
        dragStartPoint = Point.origin;
      break;
    }
    new _DragAvatar<T>(
      pointer: pointer,
      router: router,
      overlay: Overlay.of(context),
      data: config.data,
      initialPosition: position,
      dragStartPoint: dragStartPoint,
      feedback: config.feedback,
      feedbackOffset: config.feedbackOffset
    );
  }

  Widget build(BuildContext context) {
    return new Listener(
      onPointerDown: _routePointer,
      child: config.child
    );
  }
}


class DragTarget<T> extends StatefulComponent {
  const DragTarget({
    Key key,
    this.builder,
    this.onWillAccept,
    this.onAccept
  }) : super(key: key);

  final DragTargetBuilder<T> builder;
  final DragTargetWillAccept<T> onWillAccept;
  final DragTargetAccept<T> onAccept;

  DragTargetState<T> createState() => new DragTargetState<T>();
}

class DragTargetState<T> extends State<DragTarget<T>> {
  final List<T> _candidateData = new List<T>();
  final List<dynamic> _rejectedData = new List<dynamic>();

  bool didEnter(dynamic data) {
    assert(!_candidateData.contains(data));
    assert(!_rejectedData.contains(data));
    if (data is T && (config.onWillAccept == null || config.onWillAccept(data))) {
      setState(() {
        _candidateData.add(data);
      });
      return true;
    }
    _rejectedData.add(data);
    return false;
  }

  void didLeave(dynamic data) {
    assert(_candidateData.contains(data) || _rejectedData.contains(data));
    setState(() {
      _candidateData.remove(data);
      _rejectedData.remove(data);
    });
  }

  void didDrop(dynamic data) {
    assert(_candidateData.contains(data));
    setState(() {
      _candidateData.remove(data);
    });
    if (config.onAccept != null)
      config.onAccept(data);
  }

  Widget build(BuildContext context) {
    return new MetaData(
      metaData: this,
      child: config.builder(context,
                            new UnmodifiableListView<T>(_candidateData),
                            new UnmodifiableListView<dynamic>(_rejectedData)
      )
    );
  }
}


enum _DragEndKind { dropped, canceled }

// The lifetime of this object is a little dubious right now. Specifically, it
// lives as long as the pointer is down. Arguably it should self-immolate if the
// overlay goes away, or maybe even if the Draggable that created goes away.
// This will probably need to be changed once we have more experience with using
// this widget.
class _DragAvatar<T> {
  _DragAvatar({
    this.pointer,
    this.router,
    OverlayState overlay,
    this.data,
    Point initialPosition,
    this.dragStartPoint: Point.origin,
    this.feedback,
    this.feedbackOffset: Offset.zero
  }) {
    assert(pointer != null);
    assert(router != null);
    assert(overlay != null);
    assert(dragStartPoint != null);
    assert(feedbackOffset != null);
    router.addRoute(pointer, handleEvent);
    _entry = new OverlayEntry(builder: _build);
    overlay.insert(_entry);
    update(initialPosition);
  }

  final int pointer;
  final PointerRouter router;
  final T data;
  final Point dragStartPoint;
  final Widget feedback;
  final Offset feedbackOffset;

  DragTargetState _activeTarget;
  bool _activeTargetWillAcceptDrop = false;
  Offset _lastOffset;
  OverlayEntry _entry;

  void handleEvent(PointerEvent event) {
    if (event is PointerUpEvent) {
      update(event.position);
      finish(_DragEndKind.dropped);
    } else if (event is PointerCancelEvent) {
      finish(_DragEndKind.canceled);
    } else if (event is PointerMoveEvent) {
      update(event.position);
    }
  }

  void update(Point globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    _entry.markNeedsBuild();
    HitTestResult result = WidgetFlutterBinding.instance.hitTest(globalPosition + feedbackOffset);
    DragTargetState target = _getDragTarget(result.path);
    if (target == _activeTarget)
      return;
    if (_activeTarget != null)
      _activeTarget.didLeave(data);
    _activeTarget = target;
    _activeTargetWillAcceptDrop = _activeTarget != null && _activeTarget.didEnter(data);
  }

  DragTargetState _getDragTarget(List<HitTestEntry> path) {
    // Look for the RenderBox that corresponds to the hit target (the hit target
    // widget builds a RenderMetadata box for us for this purpose).
    for (HitTestEntry entry in path) {
      if (entry.target is RenderMetaData) {
        RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is DragTargetState)
          return renderMetaData.metaData;
      }
    }
    return null;
  }

  void finish(_DragEndKind endKind) {
    if (_activeTarget != null) {
      if (endKind == _DragEndKind.dropped && _activeTargetWillAcceptDrop)
        _activeTarget.didDrop(data);
      else
        _activeTarget.didLeave(data);
    }
    _activeTarget = null;
    _activeTargetWillAcceptDrop = false;
    _entry.remove();
    _entry = null;
    router.removeRoute(pointer, handleEvent);
  }

  Widget _build(BuildContext context) {
    return new Positioned(
      left: _lastOffset.dx,
      top: _lastOffset.dy,
      child: new IgnorePointer(
        child: feedback
      )
    );
  }
}
