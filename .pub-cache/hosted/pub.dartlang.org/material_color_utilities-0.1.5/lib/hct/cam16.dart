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

import 'dart:core';
import 'dart:math' as math;

import 'package:material_color_utilities/utils/color_utils.dart';
import 'package:material_color_utilities/utils/math_utils.dart';

import 'viewing_conditions.dart';

/// CAM16, a color appearance model. Colors are not just defined by their hex
/// code, but rather, a hex code and viewing conditions.
///
/// CAM16 instances also have coordinates in the CAM16-UCS space, called J*, a*,
/// b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
/// specification, and should be used when measuring distances between colors.
///
/// In traditional color spaces, a color can be identified solely by the
/// observer's measurement of the color. Color appearance models such as CAM16
/// also use information about the environment where the color was
/// observed, known as the viewing conditions.
///
/// For example, white under the traditional assumption of a midday sun white
/// point is accurately measured as a slightly chromatic blue by CAM16.
/// (roughly, hue 203, chroma 3, lightness 100)
/// CAM16, a color appearance model. Colors are not just defined by their hex
/// code, but rather, a hex code and viewing conditions.
///
/// CAM16 instances also have coordinates in the CAM16-UCS space, called J*, a*,
/// b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
/// specification, and should be used when measuring distances between colors.
///
/// In traditional color spaces, a color can be identified solely by the
/// observer's measurement of the color. Color appearance models such as CAM16
/// also use information about the environment where the color was
/// observed, known as the viewing conditions.
///
/// For example, white under the traditional assumption of a midday sun white
/// point is accurately measured as a slightly chromatic blue by CAM16.
/// (roughly, hue 203, chroma 3, lightness 100)
class Cam16 {
  /// Like red, orange, yellow, green, etc.
  final double hue;

  /// Informally, colorfulness / color intensity. Like saturation in HSL,
  /// except perceptually accurate.
  final double chroma;

  /// Lightness
  final double j;

  /// Brightness; ratio of lightness to white point's lightness
  final double q;

  /// Colorfulness
  final double m;

  /// Saturation; ratio of chroma to white point's chroma
  final double s;

  /// CAM16-UCS J coordinate
  final double jstar;

  /// CAM16-UCS a coordinate
  final double astar;

  /// CAM16-UCS b coordinate
  final double bstar;

  /// All of the CAM16 dimensions can be calculated from 3 of the dimensions, in
  /// the following combinations:
  ///     -  {j or q} and {c, m, or s} and hue
  ///     - jstar, astar, bstar
  /// Prefer using a static method that constructs from 3 of those dimensions.
  /// This constructor is intended for those methods to use to return all
  /// possible dimensions.
  const Cam16(this.hue, this.chroma, this.j, this.q, this.m, this.s, this.jstar,
      this.astar, this.bstar);

  /// CAM16 instances also have coordinates in the CAM16-UCS space, called J*,
  /// a*, b*, or jstar, astar, bstar in code. CAM16-UCS is included in the CAM16
  /// specification, and should be used when measuring distances between colors.
  double distance(Cam16 other) {
    final dJ = jstar - other.jstar;
    final dA = astar - other.astar;
    final dB = bstar - other.bstar;
    final dEPrime = math.sqrt(dJ * dJ + dA * dA + dB * dB);
    final dE = 1.41 * math.pow(dEPrime, 0.63);
    return dE;
  }

  /// Convert [argb] to CAM16, assuming the color was viewed in default viewing
  /// conditions.
  static Cam16 fromInt(int argb) {
    return fromIntInViewingConditions(argb, ViewingConditions.sRgb);
  }

  /// Given [viewingConditions], convert [argb] to CAM16.
  static Cam16 fromIntInViewingConditions(
      int argb, ViewingConditions viewingConditions) {
    // Transform ARGB int to XYZ
    final xyz = ColorUtils.xyzFromArgb(argb);
    final x = xyz[0];
    final y = xyz[1];
    final z = xyz[2];

    // Transform XYZ to 'cone'/'rgb' responses

    final rC = 0.401288 * x + 0.650173 * y - 0.051461 * z;
    final gC = -0.250268 * x + 1.204414 * y + 0.045854 * z;
    final bC = -0.002079 * x + 0.048952 * y + 0.953127 * z;

    // Discount illuminant
    final rD = viewingConditions.rgbD[0] * rC;
    final gD = viewingConditions.rgbD[1] * gC;
    final bD = viewingConditions.rgbD[2] * bC;

    // chromatic adaptation
    final rAF =
        math.pow(viewingConditions.fl * rD.abs() / 100.0, 0.42).toDouble();
    final gAF =
        math.pow(viewingConditions.fl * gD.abs() / 100.0, 0.42).toDouble();
    final bAF =
        math.pow(viewingConditions.fl * bD.abs() / 100.0, 0.42).toDouble();
    final rA = MathUtils.signum(rD) * 400.0 * rAF / (rAF + 27.13);
    final gA = MathUtils.signum(gD) * 400.0 * gAF / (gAF + 27.13);
    final bA = MathUtils.signum(bD) * 400.0 * bAF / (bAF + 27.13);

    // redness-greenness
    final a = (11.0 * rA + -12.0 * gA + bA) / 11.0;
    // yellowness-blueness
    final b = (rA + gA - 2.0 * bA) / 9.0;

    // auxiliary components
    final u = (20.0 * rA + 20.0 * gA + 21.0 * bA) / 20.0;
    final p2 = (40.0 * rA + 20.0 * gA + bA) / 20.0;

    // hue
    final atan2 = math.atan2(b, a);
    final atanDegrees = atan2 * 180.0 / math.pi;
    final hue = atanDegrees < 0
        ? atanDegrees + 360.0
        : atanDegrees >= 360
            ? atanDegrees - 360
            : atanDegrees;
    final hueRadians = hue * math.pi / 180.0;
    assert(hue >= 0 && hue < 360, 'hue was really $hue');

    // achromatic response to color
    final ac = p2 * viewingConditions.nbb;

    // CAM16 lightness and brightness
    final J = 100.0 *
        math.pow(ac / viewingConditions.aw,
            viewingConditions.c * viewingConditions.z);
    final Q = (4.0 / viewingConditions.c) *
        math.sqrt(J / 100.0) *
        (viewingConditions.aw + 4.0) *
        (viewingConditions.fLRoot);

    final huePrime = (hue < 20.14) ? hue + 360 : hue;
    final eHue =
        (1.0 / 4.0) * (math.cos(huePrime * math.pi / 180.0 + 2.0) + 3.8);
    final p1 =
        50000.0 / 13.0 * eHue * viewingConditions.nC * viewingConditions.ncb;
    final t = p1 * math.sqrt(a * a + b * b) / (u + 0.305);
    final alpha = math.pow(t, 0.9) *
        math.pow(
            1.64 - math.pow(0.29, viewingConditions.backgroundYTowhitePointY),
            0.73);
    // CAM16 chroma, colorfulness, chroma
    final C = alpha * math.sqrt(J / 100.0);
    final M = C * viewingConditions.fLRoot;
    final s = 50.0 *
        math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));

    // CAM16-UCS components
    final jstar = (1.0 + 100.0 * 0.007) * J / (1.0 + 0.007 * J);
    final mstar = math.log(1.0 + 0.0228 * M) / 0.0228;
    final astar = mstar * math.cos(hueRadians);
    final bstar = mstar * math.sin(hueRadians);
    return Cam16(hue, C, J, Q, M, s, jstar, astar, bstar);
  }

  /// Create a CAM16 color from lightness [j], chroma [c], and hue [h],
  /// assuming the color was viewed in default viewing conditions.
  static Cam16 fromJch(double j, double c, double h) {
    return fromJchInViewingConditions(j, c, h, ViewingConditions.sRgb);
  }

  /// Create a CAM16 color from lightness [j], chroma [c], and hue [h],
  /// in [viewingConditions].
  static Cam16 fromJchInViewingConditions(
      double J, double C, double h, ViewingConditions viewingConditions) {
    final Q = (4.0 / viewingConditions.c) *
        math.sqrt(J / 100.0) *
        (viewingConditions.aw + 4.0) *
        (viewingConditions.fLRoot);
    final M = C * viewingConditions.fLRoot;
    final alpha = C / math.sqrt(J / 100.0);
    final s = 50.0 *
        math.sqrt((alpha * viewingConditions.c) / (viewingConditions.aw + 4.0));

    final hueRadians = h * math.pi / 180.0;
    final jstar = (1.0 + 100.0 * 0.007) * J / (1.0 + 0.007 * J);
    final mstar = 1.0 / 0.0228 * math.log(1.0 + 0.0228 * M);
    final astar = mstar * math.cos(hueRadians);
    final bstar = mstar * math.sin(hueRadians);
    return Cam16(h, C, J, Q, M, s, jstar, astar, bstar);
  }

  /// Create a CAM16 color from CAM16-UCS coordinates [jstar], [astar], [bstar].
  /// assuming the color was viewed in default viewing conditions.
  static Cam16 fromUcs(double jstar, double astar, double bstar) {
    return fromUcsInViewingConditions(
        jstar, astar, bstar, ViewingConditions.standard);
  }

  /// Create a CAM16 color from CAM16-UCS coordinates [jstar], [astar], [bstar].
  /// in [viewingConditions].
  static Cam16 fromUcsInViewingConditions(double jstar, double astar,
      double bstar, ViewingConditions viewingConditions) {
    final a = astar;
    final b = bstar;
    final m = math.sqrt(a * a + b * b);
    final M = (math.exp(m * 0.0228) - 1.0) / 0.0228;
    final c = M / viewingConditions.fLRoot;
    var h = math.atan2(b, a) * (180.0 / math.pi);
    if (h < 0.0) {
      h += 360.0;
    }
    final j = jstar / (1 - (jstar - 100) * 0.007);

    return Cam16.fromJchInViewingConditions(j, c, h, viewingConditions);
  }

  /// ARGB representation of color, assuming the color was viewed in default
  /// viewing conditions.
  int toInt() {
    return viewed(ViewingConditions.sRgb);
  }

  /// ARGB representation of a color, given the color was viewed in
  /// [viewingConditions]
  int viewed(ViewingConditions viewingConditions) {
    final alpha =
        (chroma == 0.0 || j == 0.0) ? 0.0 : chroma / math.sqrt(j / 100.0);

    final t = math.pow(
        alpha /
            math.pow(
                1.64 -
                    math.pow(0.29, viewingConditions.backgroundYTowhitePointY),
                0.73),
        1.0 / 0.9);
    final hRad = hue * math.pi / 180.0;

    final eHue = 0.25 * (math.cos(hRad + 2.0) + 3.8);
    final ac = viewingConditions.aw *
        math.pow(j / 100.0, 1.0 / viewingConditions.c / viewingConditions.z);
    final p1 =
        eHue * (50000.0 / 13.0) * viewingConditions.nC * viewingConditions.ncb;

    final p2 = (ac / viewingConditions.nbb);

    final hSin = math.sin(hRad);
    final hCos = math.cos(hRad);

    final gamma = 23.0 *
        (p2 + 0.305) *
        t /
        (23.0 * p1 + 11 * t * hCos + 108.0 * t * hSin);
    final a = gamma * hCos;
    final b = gamma * hSin;
    final rA = (460.0 * p2 + 451.0 * a + 288.0 * b) / 1403.0;
    final gA = (460.0 * p2 - 891.0 * a - 261.0 * b) / 1403.0;
    final bA = (460.0 * p2 - 220.0 * a - 6300.0 * b) / 1403.0;

    final rCBase = math.max(0, (27.13 * rA.abs()) / (400.0 - rA.abs()));
    final rC = MathUtils.signum(rA) *
        (100.0 / viewingConditions.fl) *
        math.pow(rCBase, 1.0 / 0.42);
    final gCBase = math.max(0, (27.13 * gA.abs()) / (400.0 - gA.abs()));
    final gC = MathUtils.signum(gA) *
        (100.0 / viewingConditions.fl) *
        math.pow(gCBase, 1.0 / 0.42);
    final bCBase = math.max(0, (27.13 * bA.abs()) / (400.0 - bA.abs()));
    final bC = MathUtils.signum(bA) *
        (100.0 / viewingConditions.fl) *
        math.pow(bCBase, 1.0 / 0.42);
    final rF = rC / viewingConditions.rgbD[0];
    final gF = gC / viewingConditions.rgbD[1];
    final bF = bC / viewingConditions.rgbD[2];

    final x = 1.86206786 * rF - 1.01125463 * gF + 0.14918677 * bF;
    final y = 0.38752654 * rF + 0.62144744 * gF - 0.00897398 * bF;
    final z = -0.01584150 * rF - 0.03412294 * gF + 1.04996444 * bF;

    final argb = ColorUtils.argbFromXyz(x, y, z);
    return argb;
  }
}
