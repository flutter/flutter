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

import 'package:material_color_utilities/blend/blend.dart';
import 'package:test/test.dart';

import './utils/color_matcher.dart';

const red = 0xffff0000;
const blue = 0xff0000ff;
const green = 0xff00ff00;
const yellow = 0xffffff00;
void main() {
  group('Harmonize', () {
    test('redToBlue', () {
      final answer = Blend.harmonize(red, blue);
      expect(answer, isColor(0xffFB0057));
    });

    test('redToGreen', () {
      final answer = Blend.harmonize(red, green);
      expect(answer, isColor(0xffD85600));
    });

    test('redToYellow', () {
      final answer = Blend.harmonize(red, yellow);
      expect(answer, isColor(0xffD85600));
    });

    test('blueToGreen', () {
      final answer = Blend.harmonize(blue, green);
      expect(answer, isColor(0xff0047A3));
    });

    test('blueToRed', () {
      final answer = Blend.harmonize(blue, red);
      expect(answer, isColor(0xff5700DC));
    });

    test('blueToYellow', () {
      final answer = Blend.harmonize(blue, yellow);
      expect(answer, isColor(0xff0047A3));
    });

    test('greenToBlue', () {
      final answer = Blend.harmonize(green, blue);
      expect(answer, isColor(0xff00FC94));
    });

    test('greenToRed', () {
      final answer = Blend.harmonize(green, red);
      expect(answer, isColor(0xffB1F000));
    });

    test('greenToYellow', () {
      final answer = Blend.harmonize(green, yellow);
      expect(answer, isColor(0xffB1F000));
    });

    test('yellowToBlue', () {
      final answer = Blend.harmonize(yellow, blue);
      expect(answer, isColor(0xffEBFFBA));
    });

    test('yellowToGreen', () {
      final answer = Blend.harmonize(yellow, green);
      expect(answer, isColor(0xffEBFFBA));
    });

    test('yellowToRed', () {
      final answer = Blend.harmonize(yellow, red);
      expect(answer, isColor(0xffFFF6E3));
    });
  });
}
