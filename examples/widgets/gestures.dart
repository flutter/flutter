// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScaleApp extends StatefulComponent {
  ScaleAppState createState() => new ScaleAppState();
}

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
  final Map<int, Color> swatch;
  final bool forward;
  final bool scaleEnabled;
  final bool tapEnabled;
  final bool doubleTapEnabled;
  final bool longPressEnabled;

  void paint(Canvas canvas, Size size) {
    Point center = (size.center(Point.origin).toOffset() * zoom + offset).toPoint();
    double radius = size.width / 2.0 * zoom;
    Gradient gradient = new RadialGradient(
      center: center, radius: radius,
      colors: forward ? <Color>[swatch[50], swatch[900]]
                      : <Color>[swatch[900], swatch[50]]
    );
    Paint paint = new Paint()
      ..shader = gradient.createShader();
    canvas.drawCircle(center, radius, paint);
  }

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

class ScaleAppState extends State<ScaleApp> {

  Point _startingFocalPoint;

  Offset _previousOffset;
  Offset _offset = Offset.zero;

  double _previousZoom;
  double _zoom = 1.0;

  Map<int, Color> _swatch = Colors.blue;

  bool _forward = true;
  bool _scaleEnabled = true;
  bool _tapEnabled = true;
  bool _doubleTapEnabled = true;
  bool _longPressEnabled = true;

  void _handleScaleStart(Point focalPoint) {
    setState(() {
      _startingFocalPoint = focalPoint;
      _previousOffset = _offset;
      _previousZoom = _zoom;
    });
  }

  void _handleScaleUpdate(double scale, Point focalPoint) {
    setState(() {
      _zoom = (_previousZoom * scale);

      // Ensure that item under the focal point stays in the same place despite zooming
      Offset normalizedOffset = (_startingFocalPoint.toOffset() - _previousOffset) / _previousZoom;
      _offset = focalPoint.toOffset() - normalizedOffset * _zoom;
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
      switch (_swatch) {
        case Colors.blueGrey:   _swatch = Colors.red; break;
        case Colors.red:        _swatch = Colors.pink; break;
        case Colors.pink:       _swatch = Colors.purple; break;
        case Colors.purple:     _swatch = Colors.deepPurple; break;
        case Colors.deepPurple: _swatch = Colors.indigo; break;
        case Colors.indigo:     _swatch = Colors.blue; break;
        case Colors.blue:       _swatch = Colors.lightBlue; break;
        case Colors.lightBlue:  _swatch = Colors.cyan; break;
        case Colors.cyan:       _swatch = Colors.teal; break;
        case Colors.teal:       _swatch = Colors.green; break;
        case Colors.green:      _swatch = Colors.lightGreen; break;
        case Colors.lightGreen: _swatch = Colors.lime; break;
        case Colors.lime:       _swatch = Colors.yellow; break;
        case Colors.yellow:     _swatch = Colors.amber; break;
        case Colors.amber:      _swatch = Colors.orange; break;
        case Colors.orange:     _swatch = Colors.deepOrange; break;
        case Colors.deepOrange: _swatch = Colors.brown; break;
        case Colors.brown:      _swatch = Colors.grey; break;
        case Colors.grey:       _swatch = Colors.blueGrey; break;
        default:                assert(false);
      }
    });
  }

  void _handleDirectionChange() {
    setState(() {
      _forward = !_forward;
    });
  }


  Widget build(BuildContext context) {
    return new Theme(
      data: new ThemeData.dark(),
      child: new Scaffold(
        toolBar: new ToolBar(
            center: new Text('Gestures Demo')),
        body: new Stack([
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
                padding: new EdgeDims.all(4.0),
                child: new Column([
                    new Row([
                      new Checkbox(
                        value: _scaleEnabled,
                        onChanged: (bool value) { setState(() { _scaleEnabled = value; }); }
                      ),
                      new Text('Scale'),
                    ]),
                    new Row([
                      new Checkbox(
                        value: _tapEnabled,
                        onChanged: (bool value) { setState(() { _tapEnabled = value; }); }
                      ),
                      new Text('Tap'),
                    ]),
                    new Row([
                      new Checkbox(
                        value: _doubleTapEnabled,
                        onChanged: (bool value) { setState(() { _doubleTapEnabled = value; }); }
                      ),
                      new Text('Double Tap'),
                    ]),
                    new Row([
                      new Checkbox(
                        value: _longPressEnabled,
                        onChanged: (bool value) { setState(() { _longPressEnabled = value; }); }
                      ),
                      new Text('Long Press'),
                    ]),
                  ],
                  alignItems: FlexAlignItems.start
                )
              )
            )
          ),
        ])
      )
    );
  }
}

void main() => runApp(new ScaleApp());
