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

import 'point_provider.dart';

class PointProviderLab implements PointProvider {
  const PointProviderLab();

  @override
  List<double> fromInt(int argb) {
    return ColorUtils.labFromArgb(argb);
  }

  @override
  int toInt(List<double> lab) {
    return ColorUtils.argbFromLab(lab[0], lab[1], lab[2]);
  }

  @override
  double distance(List<double> one, List<double> two) {
    final dL = (one[0] - two[0]);
    final dA = (one[1] - two[1]);
    final dB = (one[2] - two[2]);
    // Standard CIE 1976 delta E formula also takes the square root, unneeded
    // here. This method is used by quantization algorithms to compare distance,
    // and the relative ordering is the same, with or without a square root.

    // This relatively minor optimization is helpful because this method is
    // called at least once for each pixel in an image.
    return (dL * dL + dA * dA + dB * dB);
  }
}
