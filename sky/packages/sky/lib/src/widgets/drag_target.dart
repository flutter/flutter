// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:collection';
import 'dart:sky' as sky;

import 'package:sky/rendering.dart';
import 'package:sky/src/widgets/basic.dart';
import 'package:sky/src/widgets/binding.dart';
import 'package:sky/src/widgets/framework.dart';
import 'package:sky/src/widgets/navigator.dart';

typedef bool DragTargetWillAccept<T>(T data);
typedef void DragTargetAccept<T>(T data);
typedef Widget DragTargetBuilder<T>(BuildContext context, List<T> candidateData, List<dynamic> rejectedData);
typedef void DragFinishedNotification();

class Draggable extends StatefulComponent {
  Draggable({ Key key, this.navigator, this.data, this.child, this.feedback }): super(key: key) {
    assert(navigator != null);
  }

  final NavigatorState navigator;
  final dynamic data;
  final Widget child;
  final Widget feedback;

  DraggableState createState() => new DraggableState();
}

class DraggableState extends State<Draggable> {
  DragRoute _route;

  void _startDrag(sky.PointerEvent event) {
    if (_route != null)
      return; // TODO(ianh): once we switch to using gestures, just hand the gesture to the route so it can do everything itself. then we can have multiple drags at the same time.
    Point point = new Point(event.x, event.y);
    RenderBox renderObject = context.findRenderObject();
    _route = new DragRoute(
      data: config.data,
      dragStartPoint: renderObject.globalToLocal(point),
      feedback: config.feedback,
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
  DragRoute({ this.data, this.dragStartPoint: Point.origin, this.feedback, this.onDragFinished });

  final dynamic data;
  final Point dragStartPoint;
  final Widget feedback;
  final DragFinishedNotification onDragFinished;

  DragTargetState _activeTarget;
  bool _activeTargetWillAcceptDrop = false;
  Offset _lastOffset;

  void update(Point globalPosition) {
    _lastOffset = globalPosition - dragStartPoint;
    HitTestResult result = WidgetFlutterBinding.instance.hitTest(globalPosition);
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

  Duration get transitionDuration => const Duration();
  bool get opaque => false;
  Widget build(Key key, NavigatorState navigator) {
    return new Positioned(
      left: _lastOffset.dx,
      top: _lastOffset.dy,
      child: new IgnorePointer(
        child: new Opacity(
          opacity: 0.5,
          child: feedback
        )
      )
    );
  }
}
