// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

const int _nbSamples = 100;
final List<double> _splinePosition = List<double>.filled(_nbSamples + 1, 0.0);
final List<double> _splineTime = List<double>.filled(_nbSamples + 1, 0.0);
const double _startTension = 0.5;
const double _endTension = 1.0;
const double _inflexion = 0.35;

// Generate the spline data used in ClampingScrollSimulation.
//
// This logic is a translation of the 2-dimensional logic found in
// https://android.googlesource.com/platform/frameworks/base/+/master/core/java/android/widget/Scroller.java.
//
// The output of this program should be copied over to [_splinePosition] in
// flutter/packages/flutter/lib/src/widgets/scroll_simulation.dart.
void main() {
  const double p1 = _startTension * _inflexion;
  const double p2 = 1.0 - _endTension * (1.0 - _inflexion);
  double xMin = 0.0;
  double yMin = 0.0;
  for (int i = 0; i < _nbSamples; i++) {
    final double alpha = i / _nbSamples;
    double xMax = 1.0;
    double x, tx, coef;
    while (true) {
      x = xMin + (xMax - xMin) / 2.0;
      coef = 3.0 * x * (1.0 - x);
      tx = coef * ((1.0 - x) * p1 + x * p2) + x * x * x;
      if ((tx - alpha).abs() < 1e-5) {
        break;
      }
      if (tx > alpha) {
        xMax = x;
      } else {
        xMin = x;
      }
    }
    _splinePosition[i] = coef * ((1.0 - x) * _startTension + x) + x * x * x;
    double yMax = 1.0;
    double y, dy;
    while (true) {
      y = yMin + (yMax - yMin) / 2.0;
      coef = 3.0 * y * (1.0 - y);
      dy = coef * ((1.0 - y) * _startTension + y) + y * y * y;
      if ((dy - alpha).abs() < 1e-5) {
        break;
      }
      if (dy > alpha) {
        yMax = y;
      } else {
        yMin = y;
      }
    }
    _splineTime[i] = coef * ((1.0 - y) * p1 + y * p2) + y * y * y;
  }
  _splinePosition[_nbSamples] = _splineTime[_nbSamples] = 1.0;
  print(_splinePosition);
}
