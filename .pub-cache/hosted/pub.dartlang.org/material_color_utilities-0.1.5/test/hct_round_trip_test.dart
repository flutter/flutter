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

import 'package:material_color_utilities/hct/hct.dart';
import 'package:test/test.dart';

import './utils/color_matcher.dart';

void main() {
  // Estimated test time: 3 ~ 4 minutes.
  test('hct_preserves_original_color', () {
    for (int argb = 0xFF000000; argb <= 0xFFFFFFFF; argb++) {
      final hct = Hct.fromInt(argb);
      final reconstructedArgb =
          Hct.from(hct.hue, hct.chroma, hct.tone).toInt();

      expect(reconstructedArgb, isColor(argb));
    }
  });
}
