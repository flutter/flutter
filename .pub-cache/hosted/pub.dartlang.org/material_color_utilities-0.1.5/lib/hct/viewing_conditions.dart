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

import 'dart:math' as math;

import 'package:material_color_utilities/utils/color_utils.dart';
import 'package:material_color_utilities/utils/math_utils.dart';

/// In traditional color spaces, a color can be identified solely by the
/// observer's measurement of the color. Color appearance models such as CAM16
/// also use information about the environment where the color was
/// observed, known as the viewing conditions.
///
/// For example, white under the traditional assumption of a midday sun white
/// point is accurately measured as a slightly chromatic blue by CAM16.
/// (roughly, hue 203, chroma 3, lightness 100)
///
/// This class caches intermediate values of the CAM16 conversion process that
/// depend only on viewing conditions, enabling speed ups.
class ViewingConditions {
  static final standard = sRgb;
  static final sRgb = ViewingConditions.make();

  final List<double> whitePoint;
  final double adaptingLuminance;
  final double backgroundLstar;
  final double surround;
  final bool discountingIlluminant;

  final double backgroundYTowhitePointY;
  final double aw;
  final double nbb;
  final double ncb;
  final double c;
  final double nC;
  final List<double> drgbInverse;
  final List<double> rgbD;
  final double fl;
  final double fLRoot;
  final double z;

  const ViewingConditions(
      {required this.whitePoint,
      required this.adaptingLuminance,
      required this.backgroundLstar,
      required this.surround,
      required this.discountingIlluminant,
      required this.backgroundYTowhitePointY,
      required this.aw,
      required this.nbb,
      required this.ncb,
      required this.c,
      required this.nC,
      required this.drgbInverse,
      required this.rgbD,
      required this.fl,
      required this.fLRoot,
      required this.z});

  factory ViewingConditions.make(
      {List<double>? whitePoint,
      double adaptingLuminance = -1.0,
      double backgroundLstar = 50.0,
      double surround = 2.0,
      bool discountingIlluminant = false}) {
    whitePoint ??= ColorUtils.whitePointD65();

    adaptingLuminance = (adaptingLuminance > 0.0)
        ? adaptingLuminance
        : (200.0 / math.pi * ColorUtils.yFromLstar(50.0) / 100.0);
    backgroundLstar = math.max(30.0, backgroundLstar);
    // Transform test illuminant white in XYZ to 'cone'/'rgb' responses
    final xyz = whitePoint;
    final rW = xyz[0] * 0.401288 + xyz[1] * 0.650173 + xyz[2] * -0.051461;
    final gW = xyz[0] * -0.250268 + xyz[1] * 1.204414 + xyz[2] * 0.045854;
    final bW = xyz[0] * -0.002079 + xyz[1] * 0.048952 + xyz[2] * 0.953127;

    // Scale input surround, domain (0, 2), to CAM16 surround, domain (0.8, 1.0)
    assert(surround >= 0.0 && surround <= 2.0);
    final f = 0.8 + (surround / 10.0);
    // "Exponential non-linearity"
    final c = (f >= 0.9)
        ? MathUtils.lerp(0.59, 0.69, ((f - 0.9) * 10.0))
        : MathUtils.lerp(0.525, 0.59, ((f - 0.8) * 10.0));
    // Calculate degree of adaptation to illuminant
    var d = discountingIlluminant
        ? 1.0
        : f *
            (1.0 -
                ((1.0 / 3.6) * math.exp((-adaptingLuminance - 42.0) / 92.0)));
    // Per Li et al, if D is greater than 1 or less than 0, set it to 1 or 0.
    d = (d > 1.0)
        ? 1.0
        : (d < 0.0)
            ? 0.0
            : d;
    // chromatic induction factor
    final nc = f;

    // Cone responses to the whitePoint, r/g/b/W, adjusted for discounting.
    //
    // Why use 100.0 instead of the white point's relative luminance?
    //
    // Some papers and implementations, for both CAM02 and CAM16, use the Y
    // value of the reference white instead of 100. Fairchild's Color Appearance
    // Models (3rd edition) notes that this is in error: it was included in the
    // CIE 2004a report on CIECAM02, but, later parts of the conversion process
    // account for scaling of appearance relative to the white point relative
    // luminance. This part should simply use 100 as luminance.
    final rgbD = <double>[
      d * (100.0 / rW) + 1.0 - d,
      d * (100.0 / gW) + 1.0 - d,
      d * (100.0 / bW) + 1.0 - d,
    ];

    // Factor used in calculating meaningful factors
    final k = 1.0 / (5.0 * adaptingLuminance + 1.0);
    final k4 = k * k * k * k;
    final k4F = 1.0 - k4;

    // Luminance-level adaptation factor
    final fl = (k4 * adaptingLuminance) +
        (0.1 * k4F * k4F * math.pow(5.0 * adaptingLuminance, 1.0 / 3.0));
    // Intermediate factor, ratio of background relative luminance to white relative luminance
    final n = ColorUtils.yFromLstar(backgroundLstar) / whitePoint[1];

    // Base exponential nonlinearity
    // note Schlomer 2018 has a typo and uses 1.58, the correct factor is 1.48
    final z = 1.48 + math.sqrt(n);

    // Luminance-level induction factors
    final nbb = 0.725 / math.pow(n, 0.2);
    final ncb = nbb;

    // Discounted cone responses to the white point, adjusted for post-saturationtic
    // adaptation perceptual nonlinearities.
    final rgbAFactors = [
      math.pow(fl * rgbD[0] * rW / 100.0, 0.42),
      math.pow(fl * rgbD[1] * gW / 100.0, 0.42),
      math.pow(fl * rgbD[2] * bW / 100.0, 0.42)
    ];

    final rgbA = [
      (400.0 * rgbAFactors[0]) / (rgbAFactors[0] + 27.13),
      (400.0 * rgbAFactors[1]) / (rgbAFactors[1] + 27.13),
      (400.0 * rgbAFactors[2]) / (rgbAFactors[2] + 27.13),
    ];

    final aw = (40.0 * rgbA[0] + 20.0 * rgbA[1] + rgbA[2]) / 20.0 * nbb;

    return ViewingConditions(
      whitePoint: whitePoint,
      adaptingLuminance: adaptingLuminance,
      backgroundLstar: backgroundLstar,
      surround: surround,
      discountingIlluminant: discountingIlluminant,
      backgroundYTowhitePointY: n,
      aw: aw,
      nbb: nbb,
      ncb: ncb,
      c: c,
      nC: nc,
      drgbInverse: [0.0, 0.0, 0.0],
      rgbD: rgbD,
      fl: fl,
      fLRoot: math.pow(fl, 0.25).toDouble(),
      z: z,
    );
  }
}
