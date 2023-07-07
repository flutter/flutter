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

import 'quantizer.dart';

class QuantizerMap implements Quantizer {
  @override
  Future<QuantizerResult> quantize(Iterable<int> pixels, int maxColors) async {
    final countByColor = <int, int>{};
    for (final pixel in pixels) {
      final alpha = ColorUtils.alphaFromArgb(pixel);
      if (alpha < 255) {
        continue;
      }
      countByColor[pixel] = (countByColor[pixel] ?? 0) + 1;
    }
    return QuantizerResult(countByColor);
  }
}
