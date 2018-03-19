// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class ExampleDragTarget extends StatefulWidget {
  @override
  ExampleDragTargetState createState() => new ExampleDragTargetState();
}

class ExampleDragTargetState extends State<ExampleDragTarget> {
  Color _color = Colors.grey;

  void _handleAccept(Color data) {
    setState(() {
      _color = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new DragTarget<Color>(
      onAccept: _handleAccept,
      builder: (BuildContext context, List<Color> data, List<dynamic> rejectedData) {
        return new Container(
          height: 100.0,
          margin: const EdgeInsets.all(10.0),
          decoration: new BoxDecoration(
            color: data.isEmpty ? _color : Colors.grey.shade200,
            border: new Border.all(
              width: 3.0,
              color: data.isEmpty ? Colors.white : Colors.blue
            ),
          )
        );
      }
    );
  }
}

class Dot extends StatefulWidget {
  const Dot({ Key key, this.color, this.size, this.child, this.tappable: false }) : super(key: key);

  final Color color;
  final double size;
  final Widget child;
  final bool tappable;

  @override
  DotState createState() => new DotState();
}
class DotState extends State<Dot> {
  int taps = 0;

  @override
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: widget.tappable ? () { setState(() { taps += 1; }); } : null,
      child: new Container(
        width: widget.size,
        height: widget.size,
        decoration: new BoxDecoration(
          color: widget.color,
          border: new Border.all(width: taps.toDouble()),
          shape: BoxShape.circle
        ),
        child: widget.child
      )
    );
  }
}

class ExampleDragSource extends StatelessWidget {
  const ExampleDragSource({
    Key key,
    this.color,
    this.heavy: false,
    this.under: true,
    this.child
  }) : super(key: key);

  final Color color;
  final bool heavy;
  final bool under;
  final Widget child;

  static const double kDotSize = 50.0;
  static const double kHeavyMultiplier = 1.5;
  static const double kFingerSize = 50.0;

  @override
  Widget build(BuildContext context) {
    double size = kDotSize;
    if (heavy)
      size *= kHeavyMultiplier;

    final Widget contents = new DefaultTextStyle(
      style: Theme.of(context).textTheme.body1,
      textAlign: TextAlign.center,
      child: new Dot(
        color: color,
        size: size,
        child: new Center(child: child)
      )
    );

    Widget feedback = new Opacity(
      opacity: 0.75,
      child: contents
    );

    Offset feedbackOffset;
    DragAnchor anchor;
    if (!under) {
      feedback = new Transform(
        transform: new Matrix4.identity()
                     ..translate(-size / 2.0, -(size / 2.0 + kFingerSize)),
        child: feedback
      );
      feedbackOffset = const Offset(0.0, -kFingerSize);
      anchor = DragAnchor.pointer;
    } else {
      feedbackOffset = Offset.zero;
      anchor = DragAnchor.child;
    }

    if (heavy) {
      return new LongPressDraggable<Color>(
        data: color,
        child: contents,
        feedback: feedback,
        feedbackOffset: feedbackOffset,
        dragAnchor: anchor
      );
    } else {
      return new Draggable<Color>(
        data: color,
        child: contents,
        feedback: feedback,
        feedbackOffset: feedbackOffset,
        dragAnchor: anchor
      );
    }
  }
}

class DashOutlineCirclePainter extends CustomPainter {
  const DashOutlineCirclePainter();

  static const int segments = 17;
  static const double deltaTheta = math.pi * 2 / segments; // radians
  static const double segmentArc = deltaTheta / 2.0; // radians
  static const double startOffset = 1.0; // radians

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = size.shortestSide / 2.0;
    final Paint paint = new Paint()
      ..color = const Color(0xFF000000)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius / 10.0;
    final Path path = new Path();
    final Rect box = Offset.zero & size;
    for (double theta = 0.0; theta < math.pi * 2.0; theta += deltaTheta)
      path.addArc(box, theta + startOffset, segmentArc);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(DashOutlineCirclePainter oldPainter) => false;
}

class MovableBall extends StatelessWidget {
  const MovableBall(this.position, this.ballPosition, this.callback);

  final int position;
  final int ballPosition;
  final ValueChanged<int> callback;

  static final GlobalKey kBallKey = new GlobalKey();
  static const double kBallSize = 50.0;

  @override
  Widget build(BuildContext context) {
    final Widget ball = new DefaultTextStyle(
      style: Theme.of(context).primaryTextTheme.body1,
      textAlign: TextAlign.center,
      child: new Dot(
        key: kBallKey,
        color: Colors.blue.shade700,
        size: kBallSize,
        tappable: true,
        child: const Center(child: const Text('BALL'))
      )
    );
    final Widget dashedBall = new Container(
      width: kBallSize,
      height: kBallSize,
      child: const CustomPaint(
        painter: const DashOutlineCirclePainter()
      )
    );
    if (position == ballPosition) {
      return new Draggable<bool>(
        data: true,
        child: ball,
        childWhenDragging: dashedBall,
        feedback: ball,
        maxSimultaneousDrags: 1
      );
    } else {
      return new DragTarget<bool>(
        onAccept: (bool data) { callback(position); },
        builder: (BuildContext context, List<bool> accepted, List<dynamic> rejected) {
          return dashedBall;
        }
      );
    }
  }
}

class DragAndDropApp extends StatefulWidget {
  @override
  DragAndDropAppState createState() => new DragAndDropAppState();
}

class DragAndDropAppState extends State<DragAndDropApp> {
  int position = 1;

  void moveBall(int newPosition) {
    setState(() { position = newPosition; });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Drag and Drop Flutter Demo')
      ),
      body: new Column(
        children: <Widget>[
          new Expanded(
            child: new Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                new ExampleDragSource(
                  color: Colors.yellow.shade300,
                  under: true,
                  heavy: false,
                  child: const Text('under')
                ),
                new ExampleDragSource(
                  color: Colors.green.shade300,
                  under: false,
                  heavy: true,
                  child: const Text('long-press above')
                ),
                new ExampleDragSource(
                  color: Colors.indigo.shade300,
                  under: false,
                  heavy: false,
                  child: const Text('above')
                ),
              ],
            )
          ),
          new Expanded(
            child: new Row(
              children: <Widget>[
                new Expanded(child: new ExampleDragTarget()),
                new Expanded(child: new ExampleDragTarget()),
                new Expanded(child: new ExampleDragTarget()),
                new Expanded(child: new ExampleDragTarget()),
              ]
            )
          ),
          new Expanded(
            child: new Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: <Widget>[
                new MovableBall(1, position, moveBall),
                new MovableBall(2, position, moveBall),
                new MovableBall(3, position, moveBall),
              ],
            )
          ),
        ]
      )
    );
  }
}

void main() {
  runApp(new MaterialApp(
    title: 'Drag and Drop Flutter Demo',
    home: new DragAndDropApp()
  ));
}
