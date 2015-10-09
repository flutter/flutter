// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:sky' as sky;

import 'package:sky/animation.dart';
import 'package:sky/rendering.dart';

import 'basic.dart';
import 'binding.dart';
import 'framework.dart';
import 'navigator.dart';

typedef bool DragTargetWillAccept<T>(T data);
typedef void DragTargetAccept<T>(T data);
typedef Widget DragTargetBuilder<T>(BuildContext context, List<T> candidateData, List<dynamic> rejectedData);
typedef void DragFinishedNotification();

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

class Draggable extends StatefulComponent {
  Draggable({
    Key key,
    this.navigator,
    this.data,
    this.child,
    this.feedback,
    this.feedbackOffset: Offset.zero,
    this.dragAnchor: DragAnchor.child
  }) : super(key: key) {
    assert(navigator != null);
    assert(child != null);
    assert(feedback != null);
  }

  final NavigatorState navigator;
  final dynamic data;
  final Widget child;
  final Widget feedback;

  /// The feedbackOffset can be used to set the hit test target point for the
  /// purposes of finding a drag target. It is especially useful if the feedback
  /// is transformed compared to the child.
  final Offset feedbackOffset;
  final DragAnchor dragAnchor;

  _DraggableState createState() => new _DraggableState();
}

class _DraggableState extends State<Draggable> {
  DragRoute _route;

  void _startDrag(sky.PointerEvent event) {
    if (_route != null)
      return; // TODO(ianh): once we switch to using gestures, just hand the gesture to the route so it can do everything itself. then we can have multiple drags at the same time.
    final Point point = new Point(event.x, event.y);
    Point dragStartPoint;
    switch (config.dragAnchor) {
      case DragAnchor.child:
        final RenderBox renderObject = context.findRenderObject();
        dragStartPoint = renderObject.globalToLocal(point);
        break;
      case DragAnchor.pointer:
        dragStartPoint = Point.origin;
        break;
    }
    assert(dragStartPoint != null);
    _route = new DragRoute(
      data: config.data,
      dragStartPoint: dragStartPoint,
      feedback: config.feedback,
      feedbackOffset: config.feedbackOffset,
      onDragFinished: () {
        _route = null;
      }
    );
    _route.update(point);
    config.navigator.push(_route);
  }

  void _updateDrag(sky.PointerEvent event) {
    if (_route != null) {
      config.navigator.setState(() {
        _route.update(new Point(event.x, event.y));
      });
    }
  }

  void _cancelDrag(sky.PointerEvent event) {
    if (_route != null) {
      config.navigator.popRoute(_route, DragEndKind.canceled);
      assert(_route == null);
    }
  }

  void _drop(sky.PointerEvent event) {
    if (_route != null) {
      _route.update(new Point(event.x, event.y));
      config.navigator.popRoute(_route, DragEndKind.dropped);
      assert(_route == null);
    }
  }

  Widget build(BuildContext context) {
    // TODO(abarth): We should be using a GestureDetector
    return new Listener(
      onPointerDown: _startDrag,
      onPointerMove: _updateDrag,
      onPointerCancel: _cancelDrag,
      onPointerUp: _drop,
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
                            new UnmodifiableListView<dynamic>(_rejectedData))
    );
  }
}


enum DragEndKind { dropped, canceled }

class DragRoute extends Route {
  DragRoute({
    this.data,
    this.dragStartPoint: Point.origin,
    this.feedback,
    this.feedbackOffset: Offset.zero,
    this.onDragFinished
  }) {
    assert(feedbackOffset != null);
  }

  final dynamic data;
  final Point dragStartPoint;
  final Widget feedback;
  final Offset feedbackOffset;
  final DragFinishedNotification onDragFinished;

  DragTargetState _activeTarget;
  bool _activeTargetWillAcceptDrop = false;
  Offset _lastOffset;

  void update(Point globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
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
    // TODO(abarth): Why do we reverse the path here?
    for (HitTestEntry entry in path.reversed) {
      if (entry.target is RenderMetaData) {
        RenderMetaData renderMetaData = entry.target;
        if (renderMetaData.metaData is DragTargetState)
          return renderMetaData.metaData;
      }
    }
    return null;
  }

  void didPop([DragEndKind endKind]) {
    if (_activeTarget != null) {
      if (endKind == DragEndKind.dropped && _activeTargetWillAcceptDrop)
        _activeTarget.didDrop(data);
      else
        _activeTarget.didLeave(data);
    }
    _activeTarget = null;
    _activeTargetWillAcceptDrop = false;
    if (onDragFinished != null)
      onDragFinished();
    super.didPop(endKind);
  }

  bool get ephemeral => true;
  bool get modal => false;
  bool get opaque => false;

  Widget build(NavigatorState navigator, PerformanceView nextRoutePerformance) {
    return new Positioned(
      left: _lastOffset.dx,
      top: _lastOffset.dy,
      child: new IgnorePointer(
        child: feedback
      )
    );
  }
}
