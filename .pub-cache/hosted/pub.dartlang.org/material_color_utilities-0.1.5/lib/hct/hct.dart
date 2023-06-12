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

import 'package:material_color_utilities/utils/color_utils.dart';

import 'cam16.dart';
import 'cam_solver.dart';

/// HCT, hue, chroma, and tone. A color system that provides a perceptually
/// accurate color measurement system that can also accurately render what
/// colors will appear as in different lighting environments.
class Hct {
  late double _hue;
  late double _chroma;
  late double _tone;
  late int _argb;

  /// 0 <= [hue] < 360; invalid values are corrected.
  /// 0 <= [chroma] <= ?; Informally, colorfulness. The color returned may be
  ///    lower than the requested chroma. Chroma has a different maximum for any
  ///    given hue and tone.
  /// 0 <= [tone] <= 100; informally, lightness. Invalid values are corrected.
  static Hct from(double hue, double chroma, double tone) {
    final argb = CamSolver.solveToInt(hue, chroma, tone);
    return Hct._(argb);
  }

  @override
  bool operator ==(o) {
    if (o is! Hct) {
      return false;
    }
    return o._argb == _argb;
  }

  @override
  String toString() {
    return 'H${hue.round().toString()} C${chroma.round()} T${tone.round().toString()}';
  }

  /// HCT representation of [argb].
  static Hct fromInt(int argb) {
    return Hct._(argb);
  }

  int toInt() {
    return _argb;
  }

  /// A number, in degrees, representing ex. red, orange, yellow, etc.
  /// Ranges from 0 <= [hue] < 360
  double get hue {
    return _hue;
  }

  /// 0 <= [newHue] < 360; invalid values are corrected.
  /// After setting hue, the color is mapped from HCT to the more
  /// limited sRGB gamut for display. This will change its ARGB/integer
  /// representation. If the HCT color is outside of the sRGB gamut, chroma
  /// will decrease until it is inside the gamut.
  set hue(double newHue) {
    _argb = CamSolver.solveToInt(newHue, chroma, tone);
    final cam16 = Cam16.fromInt(_argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  double get chroma {
    return _chroma;
  }

  /// 0 <= [newChroma] <= ?
  /// After setting chroma, the color is mapped from HCT to the more
  /// limited sRGB gamut for display. This will change its ARGB/integer
  /// representation. If the HCT color is outside of the sRGB gamut, chroma
  /// will decrease until it is inside the gamut.
  set chroma(double newChroma) {
    _argb = CamSolver.solveToInt(hue, newChroma, tone);
    final cam16 = Cam16.fromInt(_argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  /// Lightness. Ranges from 0 to 100.
  double get tone {
    return _tone;
  }

  /// 0 <= [newTone] <= 100; invalid values are corrected.
  /// After setting tone, the color is mapped from HCT to the more
  /// limited sRGB gamut for display. This will change its ARGB/integer
  /// representation. If the HCT color is outside of the sRGB gamut, chroma
  /// will decrease until it is inside the gamut.
  set tone(double newTone) {
    _argb = CamSolver.solveToInt(hue, chroma, newTone);
    final cam16 = Cam16.fromInt(_argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }

  Hct._(int argb) {
    _argb = argb;
    final cam16 = Cam16.fromInt(argb);
    _hue = cam16.hue;
    _chroma = cam16.chroma;
    _tone = ColorUtils.lstarFromArgb(_argb);
  }
}
