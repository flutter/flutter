// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class _GesturePainter extends CustomPainter {
  const _GesturePainter({
    this.zoom,
    this.offset,
    this.swatch,
    this.forward,
    this.scaleEnabled,
    this.tapEnabled,
    this.doubleTapEnabled,
    this.longPressEnabled
  });

  final double zoom;
  final Offset offset;
  final MaterialColor swatch;
  final bool forward;
  final bool scaleEnabled;
  final bool tapEnabled;
  final bool doubleTapEnabled;
  final bool longPressEnabled;

  @override
  void paint(Canvas canvas, Size size) {
    final Point center = (size.center(Point.origin).toOffset() * zoom + offset).toPoint();
    final double radius = size.width / 2.0 * zoom;
    final Gradient gradient = new RadialGradient(
      colors: forward ? <Color>[swatch.shade50, swatch.shade900]
                      : <Color>[swatch.shade900, swatch.shade50]
    );
    final Paint paint = new Paint()
      ..shader = gradient.createShader(new Rect.fromLTWH(
        center.x - radius,
        center.y - radius,
        radius * 2.0,
        radius * 2.0
      ));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(_GesturePainter oldPainter) {
    return oldPainter.zoom != zoom
        || oldPainter.offset != offset
        || oldPainter.swatch != swatch
        || oldPainter.forward != forward
        || oldPainter.scaleEnabled != scaleEnabled
        || oldPainter.tapEnabled != tapEnabled
        || oldPainter.doubleTapEnabled != doubleTapEnabled
        || oldPainter.longPressEnabled != longPressEnabled;
  }
}

class GestureDemo extends StatefulWidget {
  @override
  _GestureDemoState createState() => new _GestureDemoState();
}

class _GestureDemoState extends State<GestureDemo> {

  Point _startingFocalPoint;

  Offset _previousOffset;
  Offset _offset = Offset.zero;

  double _previousZoom;
  double _zoom = 1.0;

  MaterialColor _swatch = Colors.blue;

  bool _forward = true;
  bool _scaleEnabled = true;
  bool _tapEnabled = true;
  bool _doubleTapEnabled = true;
  bool _longPressEnabled = true;

  void _handleScaleStart(ScaleStartDetails details) {
    setState(() {
      _startingFocalPoint = details.focalPoint;
      _previousOffset = _offset;
      _previousZoom = _zoom;
    });
  }

  void _handleScaleUpdate(ScaleUpdateDetails details) {
    setState(() {
      _zoom = (_previousZoom * details.scale);

      // Ensure that item under the focal point stays in the same place despite zooming
      final Offset normalizedOffset = (_startingFocalPoint.toOffset() - _previousOffset) / _previousZoom;
      _offset = details.focalPoint.toOffset() - normalizedOffset * _zoom;
    });
  }

  void _handleScaleReset() {
    setState(() {
      _zoom = 1.0;
      _offset = Offset.zero;
    });
  }

  void _handleColorChange() {
    setState(() {
      if (_swatch == Colors.blueGrey)
        _swatch = Colors.red;
      else if (_swatch == Colors.red)
        _swatch = Colors.pink;
      else if (_swatch == Colors.pink)
        _swatch = Colors.purple;
      else if (_swatch == Colors.purple)
        _swatch = Colors.deepPurple;
      else if (_swatch == Colors.deepPurple)
        _swatch = Colors.indigo;
      else if (_swatch == Colors.indigo)
        _swatch = Colors.blue;
      else if (_swatch == Colors.blue)
        _swatch = Colors.lightBlue;
      else if (_swatch == Colors.lightBlue)
        _swatch = Colors.cyan;
      else if (_swatch == Colors.teal)
        _swatch = Colors.green;
      else if (_swatch == Colors.green)
        _swatch = Colors.lightGreen;
      else if (_swatch == Colors.lightGreen)
        _swatch = Colors.lime;
      else if (_swatch == Colors.lime)
        _swatch = Colors.yellow;
      else if (_swatch == Colors.yellow)
        _swatch = Colors.amber;
      else if (_swatch == Colors.amber)
        _swatch = Colors.orange;
      else if (_swatch == Colors.orange)
        _swatch = Colors.deepOrange;
      else if (_swatch == Colors.deepOrange)
        _swatch = Colors.brown;
      else if (_swatch == Colors.brown)
        _swatch = Colors.grey;
      else if (_swatch == Colors.grey)
        _swatch = Colors.blueGrey;
    });
  }

  void _handleDirectionChange() {
    setState(() {
      _forward = !_forward;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Stack(
      children: <Widget>[
        new GestureDetector(
          onScaleStart: _scaleEnabled ? _handleScaleStart : null,
          onScaleUpdate: _scaleEnabled ? _handleScaleUpdate : null,
          onTap: _tapEnabled ? _handleColorChange : null,
          onDoubleTap: _doubleTapEnabled ? _handleScaleReset : null,
          onLongPress: _longPressEnabled ? _handleDirectionChange : null,
          child: new CustomPaint(
            painter: new _GesturePainter(
              zoom: _zoom,
              offset: _offset,
              swatch: _swatch,
              forward: _forward,
              scaleEnabled: _scaleEnabled,
              tapEnabled: _tapEnabled,
              doubleTapEnabled: _doubleTapEnabled,
              longPressEnabled: _longPressEnabled
            )
          )
        ),
        new Positioned(
          bottom: 0.0,
          left: 0.0,
          child: new Card(
            child: new Container(
              padding: const EdgeInsets.all(4.0),
              child: new Column(
                children: <Widget>[
                  new Row(
                    children: <Widget>[
                      new Checkbox(
                        value: _scaleEnabled,
                        onChanged: (bool value) { setState(() { _scaleEnabled = value; }); }
                      ),
                      const Text('Scale'),
                    ]
                  ),
                  new Row(
                    children: <Widget>[
                      new Checkbox(
                        value: _tapEnabled,
                        onChanged: (bool value) { setState(() { _tapEnabled = value; }); }
                      ),
                      const Text('Tap'),
                    ]
                  ),
                  new Row(
                    children: <Widget>[
                      new Checkbox(
                        value: _doubleTapEnabled,
                        onChanged: (bool value) { setState(() { _doubleTapEnabled = value; }); }
                      ),
                      const Text('Double Tap'),
                    ]
                  ),
                  new Row(
                    children: <Widget>[
                      new Checkbox(
                        value: _longPressEnabled,
                        onChanged: (bool value) { setState(() { _longPressEnabled = value; }); }
                      ),
                      const Text('Long Press'),
                    ]
                  ),
                ],
                crossAxisAlignment: CrossAxisAlignment.start
              )
            )
          )
        ),
      ]
    );
  }
}

void main() {
  runApp(new MaterialApp(
    theme: new ThemeData.dark(),
    home: new Scaffold(
      appBar: new AppBar(title: const Text('Gestures Demo')),
      body: new GestureDemo()
    )
  ));
}
