// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:meta/meta.dart'; // @required

bool _simpleInterpolation = false;

enum _DragTarget {
  start,
  end
}

enum _CornerId {
  topLeft,
  topRight,
  bottomLeft,
  bottomRight
}

class _Diagonal {
  const _Diagonal(this.startId, this.endId);
  final _CornerId startId;
  final _CornerId endId;
}

Point _cornerFor(Rect rect, _CornerId id) {
  switch(id) {
    case _CornerId.topLeft: return rect.topLeft;
    case _CornerId.topRight: return rect.topRight;
    case _CornerId.bottomLeft: return rect.bottomLeft;
    case _CornerId.bottomRight: return rect.bottomRight;
  }
  return Point.origin;
}

class MaterialRect {
  static final List<_Diagonal> _allDiagonals = <_Diagonal>[
    const _Diagonal(_CornerId.topLeft, _CornerId.bottomRight),
    const _Diagonal(_CornerId.bottomRight, _CornerId.topLeft),
    const _Diagonal(_CornerId.topRight, _CornerId.bottomLeft),
    const _Diagonal(_CornerId.bottomLeft, _CornerId.topRight),
  ];

  MaterialRect(this.start, this.end) {
    _centersVector = end.center - start.center;

    double maxSupport = 0.0;
    for (_Diagonal diagonal in _allDiagonals) {
      final double support = _diagonalSupport(diagonal);
      if (support > maxSupport) {
        _diagonal = diagonal;
        maxSupport = support;
      }
    }

    _startArc = new MaterialArc(_cornerFor(start, _diagonal.startId), _cornerFor(end, _diagonal.startId));
    _endArc = new MaterialArc(_cornerFor(start, _diagonal.endId), _cornerFor(end, _diagonal.endId));
  }

  final Rect start;
  final Rect end;

  Offset _centersVector;
  _Diagonal _diagonal;
  MaterialArc _startArc;
  MaterialArc _endArc;

  double _diagonalSupport(_Diagonal diagonal) {
    final Offset delta = _cornerFor(start, diagonal.endId) - _cornerFor(start, diagonal.startId);
    final double length = delta.distance;
    return _centersVector.dx * delta.dx / length + _centersVector.dy * delta.dy / length;
  }

  Rect transform(double t) {
    if (_simpleInterpolation)
      return Rect.lerp(start, end, t);
    Point startArcPoint = _startArc.transform(t);
    Point endArcPoint = _endArc.transform(t);
    double minX = math.min(startArcPoint.x, endArcPoint.x);
    double maxX = math.max(startArcPoint.x, endArcPoint.x);
    double minY = math.min(startArcPoint.y, endArcPoint.y);
    double maxY = math.max(startArcPoint.y, endArcPoint.y);
    return new Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}

class _Background extends CustomPainter {
  _Background({
    Animation<double> repaint,
    this.materialRect,
    this.themeData
  }) : _repaint = repaint, super(repaint: repaint);

  static final double pointRadius = 6.0;

  final MaterialRect materialRect;
  final ThemeData themeData;
  Animation<double> _repaint;

  void drawPoint(Canvas canvas, Point p, Color color) {
    final Paint paint = new Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(p, pointRadius, paint);
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(p, pointRadius + 1.0, paint);
  }

  void drawRect(Canvas canvas, Rect rect, Color color) {
    final Paint paint = new Paint()
      ..color = color.withOpacity(0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    canvas.drawRect(rect, paint);
    drawPoint(canvas, rect.center, color);
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawRect(canvas, materialRect.start, Colors.green[500]);
    drawRect(canvas, materialRect.end, Colors.red[500]);

    Point corner = _cornerFor(materialRect.start, materialRect._diagonal.endId);
    drawPoint(canvas, corner, Colors.red[500]);

    drawRect(canvas, materialRect.transform(_repaint.value), Colors.blue[500]);
  }

  @override
  bool shouldRepaint(_Background oldBackground) => true;
}

class MaterialArc {
  MaterialArc(this.a, this.b) {
    // An explanation with a diagram can be found at https://goo.gl/vMSdRg
    final Offset delta = b - a;
    final double deltaX = delta.dx.abs();
    final double deltaY = delta.dy.abs();
    final double distanceFromAtoB = delta.distance;
    final Point c = new Point(b.x, a.y);

    double sweepAngle() => 2.0 *  math.asin(distanceFromAtoB / (2.0 * _radius));

    if (deltaX > 2.0 && deltaY > 2.0) {
      if (deltaX < deltaY) {
        _radius = distanceFromAtoB * distanceFromAtoB / (c - a).distance / 2.0;
        _center = new Point(b.x + _radius * (a.x - b.x).sign, b.y);
        if (a.x < b.x) {
          _startAngle = sweepAngle() * (a.y - b.y).sign;
          _endAngle = 0.0;
        } else {
          _startAngle = math.PI + sweepAngle() * (b.y - a.y).sign;
          _endAngle = math.PI;
        }
      } else {
        _radius = distanceFromAtoB * distanceFromAtoB / (c - b).distance / 2.0;
        _center = new Point(a.x, a.y + (b.y - a.y).sign * _radius);
        if (a.y < b.y) {
          _startAngle = -math.PI / 2.0;
          _endAngle = _startAngle + sweepAngle() * (b.x - a.x).sign;
        } else {
          _startAngle = math.PI / 2.0;
          _endAngle = _startAngle + sweepAngle() * (a.x - b.x).sign;
        }
      }
    }
  }

  final Point a;
  final Point b;

  Point _center;
  double _radius;
  double _startAngle;
  double _endAngle;

  Point transform(double t) {
    if (_startAngle == null || _endAngle == null)
      return Point.lerp(a, b, t);
    final double angle = lerpDouble(_startAngle, _endAngle, t);
    final double x = math.cos(angle) * _radius;
    final double y = math.sin(angle) * _radius;
    return  _center + new Offset(x, y);
  }

  @override
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! MaterialArc)
      return false;
    final MaterialArc typedOther = other;
    return _center == typedOther._center
      && _radius == typedOther._radius
      && _startAngle == typedOther._startAngle
      && _endAngle == typedOther._endAngle;
  }

  @override
  int get hashCode => hashValues(_center, _radius, _startAngle, _endAngle);

  @override
  String toString() => '[MaterialArc center=$_center radius=$_radius startAngle=$_startAngle endAngle=$_endAngle]';
}


class MaterialArcAnimation extends Animation<Point> with AnimationWithParentMixin<double> {
  MaterialArcAnimation({
    @required this.parent,
    @required this.arc
  }) {
    assert(parent != null);
    assert(arc != null);
  }

  @override
  final Animation<double> parent;

  MaterialArc arc;

  @override
  Point get value {
    double t = parent.value;
    if (t == 0.0)
      return arc.a;
    if (t == 1.0)
      return arc.b;
    return arc.transform(t);
  }
}

class AnimationDemo extends StatefulWidget {
  AnimationDemo({ Key key }) : super(key: key);

  static const String routeName = '/animation';

  @override
  AnimationDemoState createState() => new AnimationDemoState();
}

class AnimationDemoState extends State<AnimationDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  final GlobalKey _backgroundKey = new GlobalKey();
  final AnimationController _controller = new AnimationController(duration: const Duration(milliseconds: 1000));

  CurvedAnimation _animation;
  _DragTarget _dragTarget;
  Rect _start = new Rect.fromLTWH(150.0, 100.0, 150.0, 100.0);
  Rect _end = new Rect.fromLTWH(200.0, 300.0, 100.0, 150.0);

  void initState() {
    super.initState();
    _animation = new CurvedAnimation(parent: _controller, curve: Curves.ease);
  }

  void _handlePointerDown(PointerDownEvent event) {
    final RenderBox box = _backgroundKey.currentContext.findRenderObject();
    final double startOffset = (box.localToGlobal(_start.center) - event.position).distance;
    final double endOffset = (box.localToGlobal(_end.center) - event.position).distance;
    if (startOffset < endOffset && startOffset < 50.0)
      _dragTarget = _DragTarget.start;
    else if (endOffset < 50.0)
      _dragTarget = _DragTarget.end;
    else
      _dragTarget = null;
  }

  void _handlePointerMove(PointerMoveEvent event) {
    switch (_dragTarget) {
      case _DragTarget.start:
        setState(() {
          _start = _start.shift(event.delta);
        });
        break;
      case _DragTarget.end:
        setState(() {
          _end = _end.shift(event.delta);
        });
        break;
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _dragTarget = null;
  }

  Future<Null> _play() async {
    await _controller.forward();
    return _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final MaterialRect materialRect = new MaterialRect(_start, _end);
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Animation - ${_simpleInterpolation ? "simple" : "arc"}'),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.rotate_90_degrees_ccw),
            tooltip: 'Toggle arc path',
            onPressed: () {
              setState(() {
                _simpleInterpolation = !_simpleInterpolation;
              });
            }
          )
        ]
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _play,
        child: new Icon(Icons.autorenew)
      ),
      body: new Listener(
        onPointerDown: _handlePointerDown,
        onPointerMove: _handlePointerMove,
        onPointerUp: _handlePointerUp,
        child: new CustomPaint(
          key: _backgroundKey,
          painter: new _Background(
            repaint: _animation,
            themeData: Theme.of(context),
            materialRect: materialRect
          )
        )
      )
    );
  }
}
