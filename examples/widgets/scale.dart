// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:sky/rendering.dart';
import 'package:sky/theme/colors.dart' as colors;
import 'package:sky/widgets.dart';

class ScaleApp extends App {

  Point _startingFocalPoint;

  Offset _previousOffset;
  Offset _offset;

  double _previousZoom;
  double _zoom;

  void initState() {
    _offset = Offset.zero;
    _zoom = 1.0;
  }

  void _handleScaleStart(Point focalPoint) {
    setState(() {
      _startingFocalPoint = focalPoint;
      _previousOffset = _offset;
      _previousZoom = _zoom;
    });
  }

  void _handleScaleUpdate(double scale, Point focalPoint) {
    setState(() {
      _zoom = _previousZoom * scale;
      _offset = _previousOffset + (focalPoint - _startingFocalPoint) / _zoom;
    });
  }

  void callback(PaintingCanvas canvas, Size size) {
    Point center = size.center(Point.origin) + _offset * _zoom;
    double radius = size.width / 2.0 * _zoom;
    Gradient gradient = new RadialGradient(
      center: center, radius: radius,
      colors: [colors.Blue[200], colors.Blue[800]]
    );
    Paint paint = new Paint()
      ..shader = gradient.createShader();
    canvas.drawCircle(center, radius, paint);
  }

  Widget build() {
    return new Theme(
      data: new ThemeData.dark(),
      child: new Scaffold(
        toolbar: new ToolBar(
            center: new Text('Scale Demo')),
        body: new Material(
          type: MaterialType.canvas,
          child: new GestureDetector(
            onScaleStart: _handleScaleStart,
            onScaleUpdate: _handleScaleUpdate,
            child: new CustomPaint(callback: callback)
          )
        )
      )
    );
  }
}

void main() => runApp(new ScaleApp());
