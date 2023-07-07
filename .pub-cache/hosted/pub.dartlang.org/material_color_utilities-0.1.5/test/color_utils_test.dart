// Copyright 2021 Google LLC
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:math';
import 'package:material_color_utilities/utils/color_utils.dart';
import 'package:test/test.dart';

double _lstarFromY(double y) {
  final scaledY = y / 100.0;
  final e = 216.0 / 24389.0;
  if (scaledY <= e) {
    return 24389.0 / 27.0 * scaledY;
  } else {
    final yIntermediate = pow(scaledY, 1.0 / 3.0).toDouble();
    return 116.0 * yIntermediate - 16.0;
  }
}

List<double> _range(double start, double stop, int caseCount) {
  double stepSize = (stop - start) / (caseCount - 1);
  return List.generate(caseCount, (index) => start + stepSize * index);
}

List<int> get rgbRange =>
    _range(0.0, 255.0, 8).map((element) => element.round()).toList();

List<int> get fullRgbRange => List<int>.generate(256, (index) => index);

void main() {
  test('range_integrity', () {
    final range = _range(3.0, 9999.0, 1234);
    for (var i = 0; i < 1234; i++) {
      expect(range[i], closeTo(3 + 8.1070559611 * i, 1e-5));
    }
  });

  test('y_to_lstar_to_y', () {
    for (final y in _range(0, 100, 1001)) {
      expect(ColorUtils.yFromLstar(_lstarFromY(y)), closeTo(y, 1e-5));
    }
  });

  test('lstar_to_y_to_lstar', () {
    for (final lstar in _range(0, 100, 1001)) {
      expect(_lstarFromY(ColorUtils.yFromLstar(lstar)), closeTo(lstar, 1e-5));
    }
  });

  test('y_continuity', () {
    final epsilon = 1e-6;
    final delta = 1e-8;
    final left = 8.0 - delta;
    final mid = 8.0;
    final right = 8.0 + delta;
    expect(
      ColorUtils.yFromLstar(left),
      closeTo(ColorUtils.yFromLstar(mid), epsilon),
    );
    expect(
      ColorUtils.yFromLstar(right),
      closeTo(ColorUtils.yFromLstar(mid), epsilon),
    );
  });

  test('rgb_to_xyz_to_rgb', () {
    for (final r in rgbRange) {
      for (final g in rgbRange) {
        for (final b in rgbRange) {
          final argb = ColorUtils.argbFromRgb(r, g, b);
          final xyz = ColorUtils.xyzFromArgb(argb);
          final converted = ColorUtils.argbFromXyz(xyz[0], xyz[1], xyz[2]);
          expect(ColorUtils.redFromArgb(converted), closeTo(r, 1.5));
          expect(ColorUtils.greenFromArgb(converted), closeTo(g, 1.5));
          expect(ColorUtils.blueFromArgb(converted), closeTo(b, 1.5));
        }
      }
    }
  });

  test('rgb_to_lab_to_rgb', () {
    for (final r in rgbRange) {
      for (final g in rgbRange) {
        for (final b in rgbRange) {
          final argb = ColorUtils.argbFromRgb(r, g, b);
          final lab = ColorUtils.labFromArgb(argb);
          final converted = ColorUtils.argbFromLab(lab[0], lab[1], lab[2]);
          expect(ColorUtils.redFromArgb(converted), closeTo(r, 1.5));
          expect(ColorUtils.greenFromArgb(converted), closeTo(g, 1.5));
          expect(ColorUtils.blueFromArgb(converted), closeTo(b, 1.5));
        }
      }
    }
  });

  test('rgb_to_lstar_to_rgb', () {
    for (final component in fullRgbRange) {
      final argb = ColorUtils.argbFromRgb(component, component, component);
      final lstar = ColorUtils.lstarFromArgb(argb);
      final converted = ColorUtils.argbFromLstar(lstar);
      expect(converted, argb);
    }
  });

  test('linearize_delinearize', () {
    for (final rgbComponent in fullRgbRange) {
      final converted =
          ColorUtils.delinearized(ColorUtils.linearized(rgbComponent));
      expect(converted, rgbComponent);
    }
  });
}
