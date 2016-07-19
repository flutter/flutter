// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

enum _DragTarget {
  start,
  end
}

class _PointDemoPainter extends CustomPainter {
  _PointDemoPainter({
    Animation<double> repaint,
    this.arc
  }) : _repaint = repaint, super(repaint: repaint);

  static final double pointRadius = 6.0;

  final MaterialPointArcTween arc;
  Animation<double> _repaint;

  void drawPoint(Canvas canvas, Point point, Color color) {
    final Paint paint = new Paint()
      ..color = color.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, pointRadius, paint);
    paint
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(point, pointRadius + 1.0, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = new Paint();

    if (arc.center != null)
      drawPoint(canvas, arc.center, Colors.blue[400]);

    paint
      ..color = Colors.green[500].withOpacity(0.25)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    if (arc.center != null && arc.radius != null)
      canvas.drawCircle(arc.center, arc.radius, paint);
    else {
      canvas.drawLine(arc.begin, arc.end, paint);
    }

    drawPoint(canvas, arc.begin, Colors.green[500]);
    drawPoint(canvas, arc.end, Colors.red[500]);

    paint
      ..color = Colors.green[500]
      ..style = PaintingStyle.fill;
    canvas.drawCircle(arc.lerp(_repaint.value), pointRadius, paint);
  }

  @override
  hitTest(Point position) {
    return (arc.begin - position).distance < 50.0 || (arc.end - position).distance < 50.0;
  }

  @override
  bool shouldRepaint(_PointDemoPainter oldPainter) => true;
}


class _PointDemo extends StatefulWidget {
  _PointDemo({ Key key, this.controller }) : super(key: key);

  final AnimationController controller;

  @override
  _PointDemoState createState() => new _PointDemoState();
}

class _PointDemoState extends State<_PointDemo> {
  final GlobalKey _painterKey = new GlobalKey();

  CurvedAnimation _animation;
  _DragTarget _dragTarget;
  Point _begin = const Point(180.0, 110.0);
  Point _end = const Point(37.0, 250.0);

  @override
  void initState() {
    super.initState();
    _animation = new CurvedAnimation(parent: config.controller, curve: Curves.ease);
  }

  @override
  void dispose() {
    config.controller.stop();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    final RenderBox box = _painterKey.currentContext.findRenderObject();
    final double startOffset = (box.localToGlobal(_begin) - event.position).distance;
    final double endOffset = (box.localToGlobal(_end) - event.position).distance;
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
          _begin = _begin + event.delta;
        });
        break;
      case _DragTarget.end:
        setState(() {
          _end = _end + event.delta;
        });
        break;
    }
  }

  void _handlePointerUp(PointerEvent event) {
    _dragTarget = null;
  }

  @override
  Widget build(BuildContext context) {
    final MaterialPointArcTween arc = new MaterialPointArcTween(begin: _begin, end: _end);
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: new CustomPaint(
        key: _painterKey,
        painter: new _PointDemoPainter(
          repaint: _animation,
          arc: arc
        ),
        child: new Padding(
          padding: const EdgeInsets.all(16.0),
          child: new Text(
            "Tap the refresh button to run the animation. Drag the green "
            "and red points to change the animation's path.",
            style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0)
          )
        )
      )
    );
  }
}

class _RectangleDemoPainter extends CustomPainter {
  _RectangleDemoPainter({
    Animation<double> repaint,
    this.arc
  }) : _repaint = repaint, super(repaint: repaint);

  static final double pointRadius = 6.0;

  final MaterialRectArcTween arc;
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
    drawRect(canvas, arc.begin, Colors.green[500]);
    drawRect(canvas, arc.end, Colors.red[500]);
    drawRect(canvas, arc.lerp(_repaint.value), Colors.blue[500]);
  }

  @override
  bool shouldRepaint(_RectangleDemoPainter oldPainter) => true;
}

class _RectangleDemo extends StatefulWidget {
  _RectangleDemo({ Key key, this.controller }) : super(key: key);

  final AnimationController controller;

  @override
  _RectangleDemoState createState() => new _RectangleDemoState();
}

class _RectangleDemoState extends State<_RectangleDemo> {
  final GlobalKey _painterKey = new GlobalKey();

  CurvedAnimation _animation;
  _DragTarget _dragTarget;
  Rect _begin = new Rect.fromLTRB(180.0, 100.0, 330.0, 200.0);
  Rect _end = new Rect.fromLTRB(32.0, 275.0, 132.0, 425.0);

  @override
  void initState() {
    super.initState();
    _animation = new CurvedAnimation(parent: config.controller, curve: Curves.ease);
  }

  @override
  void dispose() {
    config.controller.stop();
    super.dispose();
  }

  void _handlePointerDown(PointerDownEvent event) {
    final RenderBox box = _painterKey.currentContext.findRenderObject();
    final double startOffset = (box.localToGlobal(_begin.center) - event.position).distance;
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
          _begin = _begin.shift(event.delta);
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

  @override
  Widget build(BuildContext context) {
    final MaterialRectArcTween arc = new MaterialRectArcTween(begin: _begin, end: _end);
    return new Listener(
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _handlePointerUp,
      child: new CustomPaint(
        key: _painterKey,
        painter: new _RectangleDemoPainter(
          repaint: _animation,
          arc: arc
        ),
        child: new Padding(
          padding: const EdgeInsets.all(16.0),
          child: new Text(
            "Tap the refresh button to run the animation. Drag the rectangles "
            "to change the animation's path.",
            style: Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0)
          )
        )
      )
    );
  }
}

typedef Widget _DemoBuilder(_ArcDemo demo);

class _ArcDemo {
  _ArcDemo(String _title, this.builder) : title = _title, key = new GlobalKey(debugLabel: _title);

  final AnimationController controller = new AnimationController(duration: const Duration(milliseconds: 1000));
  final String title;
  final _DemoBuilder builder;
  final GlobalKey key;
}

class AnimationDemo extends StatefulWidget {
  AnimationDemo({ Key key }) : super(key: key);

  static const String routeName = '/animation';

  @override
  _AnimationDemoState createState() => new _AnimationDemoState();
}

class _AnimationDemoState extends State<AnimationDemo> {
  static final GlobalKey<TabBarSelectionState<_ArcDemo>> _tabsKey = new GlobalKey<TabBarSelectionState<_ArcDemo>>();

  static final List<_ArcDemo> _allDemos = <_ArcDemo>[
    new _ArcDemo('POINT', (_ArcDemo demo) {
      return new _PointDemo(
        key: demo.key,
        controller: demo.controller
      );
    }),
    new _ArcDemo('RECTANGLE', (_ArcDemo demo) {
      return new _RectangleDemo(
        key: demo.key,
        controller: demo.controller
      );
    })
  ];

  Future<Null> _play() async {
    _ArcDemo demo = _tabsKey.currentState.value;
    await demo.controller.forward();
    if (demo.key.currentState != null && demo.key.currentState.mounted)
      demo.controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<_ArcDemo>(
      key: _tabsKey,
      values: _allDemos,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Animation'),
          bottom: new TabBar<_ArcDemo>(
            labels: new Map<_ArcDemo, TabLabel>.fromIterable(_allDemos, value: (_ArcDemo demo) {
              return new TabLabel(text: demo.title);
            })
          )
        ),
        floatingActionButton: new FloatingActionButton(
          onPressed: _play,
          child: new Icon(Icons.refresh)
        ),
        body: new TabBarView<_ArcDemo>(
          children: _allDemos.map((_ArcDemo demo) => demo.builder(demo)).toList()
        )
      )
    );
  }
}
