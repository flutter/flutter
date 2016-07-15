// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';

enum _DragTarget {
  start,
  end
}

class _Background extends CustomPainter {
  _Background({
    Animation<double> repaint,
    this.arc,
    this.themeData
  }) : _repaint = repaint, super(repaint: repaint);

  static final double pointRadius = 6.0;

  final MaterialRectArc arc;
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
    drawRect(canvas, arc.begin, Colors.green[500]);
    drawRect(canvas, arc.end, Colors.red[500]);

    //Point corner = _cornerFor(materialRect.start, materialRect._diagonal.endId);
    //drawPoint(canvas, corner, Colors.red[500]);

    drawRect(canvas, arc.transform(_repaint.value), Colors.blue[500]);
  }

  @override
  bool shouldRepaint(_Background oldBackground) => true;
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

  @override
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
    final MaterialRectArc arc = new MaterialRectArc(begin: _start, end: _end);
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: new Text('Animation'),
        actions: <Widget>[
          new IconButton(
              icon: new Icon(Icons.rotate_90_degrees_ccw),
            tooltip: 'Toggle arc path',
            onPressed: () {
              /*
              setState(() {
                _simpleInterpolation = !_simpleInterpolation;
              });
              */
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
            arc: arc
          )
        )
      )
    );
  }
}
