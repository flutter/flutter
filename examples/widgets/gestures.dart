// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class ScaleApp extends StatefulComponent {
  ScaleAppState createState() => new ScaleAppState();
}

class GesturesDemoPaintToken {
  GesturesDemoPaintToken(this.zoom, this.offset, this.swatch, this.forward, this.flag1, this.flag2, this.flag3, this.flag4);
  final Offset offset;
  final double zoom;
  final Map<int, Color> swatch;
  final bool forward;
  final bool flag1;
  final bool flag2;
  final bool flag3;
  final bool flag4;
  bool operator ==(dynamic other) {
    if (identical(this, other))
      return true;
    if (other is! GesturesDemoPaintToken)
      return false;
    final GesturesDemoPaintToken typedOther = other;
    return offset == typedOther.offset &&
           zoom == typedOther.zoom &&
           identical(swatch, typedOther.swatch) &&
           forward == typedOther.forward &&
           flag1 == typedOther.flag1 &&
           flag2 == typedOther.flag2 &&
           flag3 == typedOther.flag3 &&
           flag4 == typedOther.flag4;
  }
  int get hashCode {
    int value = 373;
    value = 37 * value + offset.hashCode;
    value = 37 * value + zoom.hashCode;
    value = 37 * value + identityHashCode(swatch);
    value = 37 * value + forward.hashCode;
    value = 37 * value + flag1.hashCode;
    value = 37 * value + flag2.hashCode;
    value = 37 * value + flag3.hashCode;
    value = 37 * value + flag4.hashCode;
    return value;
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

  void paint(PaintingCanvas canvas, Size size) {
    Point center = (size.center(Point.origin).toOffset() * _zoom + _offset).toPoint();
    double radius = size.width / 2.0 * _zoom;
    Gradient gradient = new RadialGradient(
      center: center, radius: radius,
      colors: _forward ? <Color>[_swatch[50], _swatch[900]]
                       : <Color>[_swatch[900], _swatch[50]]
    );
    Paint paint = new Paint()
      ..shader = gradient.createShader();
    canvas.drawCircle(center, radius, paint);
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
              onPaint: paint,
              token: new GesturesDemoPaintToken(_zoom, _offset, _swatch, _forward,
                                                _scaleEnabled, _tapEnabled, _doubleTapEnabled,
                                                _longPressEnabled)
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
