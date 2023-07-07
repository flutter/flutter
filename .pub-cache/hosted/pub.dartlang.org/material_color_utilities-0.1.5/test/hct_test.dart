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

import 'package:material_color_utilities/hct/cam16.dart';
import 'package:material_color_utilities/hct/hct.dart';
import 'package:material_color_utilities/hct/viewing_conditions.dart';
import 'package:material_color_utilities/utils/color_utils.dart';
import 'package:test/test.dart';

const black = 0xff000000;
const white = 0xffffffff;
const red = 0xffff0000;
const green = 0xff00ff00;
const blue = 0xff0000ff;
const midgray = 0xff777777;

void main() {
  test('conversions_areReflexive', () {
    final cam = Cam16.fromInt(red);
    final color = cam.viewed(ViewingConditions.standard);
    expect(color, equals(red));
  });

  test('y_midgray', () {
    expect(18.418, closeTo(ColorUtils.yFromLstar(50.0), 0.001));
  });

  test('y_black', () {
    expect(0.0, closeTo(ColorUtils.yFromLstar(0.0), 0.001));
  });

  test('y_white', () {
    expect(100.0, closeTo(ColorUtils.yFromLstar(100.0), 0.001));
  });

  test('cam_red', () {
    final cam = Cam16.fromInt(red);
    expect(46.445, closeTo(cam.j, 0.001));
    expect(113.357, closeTo(cam.chroma, 0.001));
    expect(27.408, closeTo(cam.hue, 0.001));
    expect(89.494, closeTo(cam.m, 0.001));
    expect(91.889, closeTo(cam.s, 0.001));
    expect(105.988, closeTo(cam.q, 0.001));
  });

  test('cam_green', () {
    final cam = Cam16.fromInt(green);
    expect(79.331, closeTo(cam.j, 0.001));
    expect(108.410, closeTo(cam.chroma, 0.001));
    expect(142.139, closeTo(cam.hue, 0.001));
    expect(85.587, closeTo(cam.m, 0.001));
    expect(78.604, closeTo(cam.s, 0.001));
    expect(138.520, closeTo(cam.q, 0.001));
  });

  test('cam_blue', () {
    final cam = Cam16.fromInt(blue);
    expect(25.465, closeTo(cam.j, 0.001));
    expect(87.230, closeTo(cam.chroma, 0.001));
    expect(282.788, closeTo(cam.hue, 0.001));
    expect(68.867, closeTo(cam.m, 0.001));
    expect(93.674, closeTo(cam.s, 0.001));
    expect(78.481, closeTo(cam.q, 0.001));
  });

  test('cam_black', () {
    final cam = Cam16.fromInt(black);
    expect(0.0, closeTo(cam.j, 0.001));
    expect(0.0, closeTo(cam.chroma, 0.001));
    expect(0.0, closeTo(cam.hue, 0.001));
    expect(0.0, closeTo(cam.m, 0.001));
    expect(0.0, closeTo(cam.s, 0.001));
    expect(0.0, closeTo(cam.q, 0.001));
  });

  test('cam_white', () {
    final cam = Cam16.fromInt(white);
    expect(100.0, closeTo(cam.j, 0.001));
    expect(2.869, closeTo(cam.chroma, 0.001));
    expect(209.492, closeTo(cam.hue, 0.001));
    expect(2.265, closeTo(cam.m, 0.001));
    expect(12.068, closeTo(cam.s, 0.001));
    expect(155.521, closeTo(cam.q, 0.001));
  });

  test('gamutMap_red', () {
    final colorToTest = red;
    final cam = Cam16.fromInt(colorToTest);
    final color =
        Hct.from(cam.hue, cam.chroma, ColorUtils.lstarFromArgb(colorToTest))
            .toInt();
    expect(colorToTest, equals(color));
  });

  test('gamutMap_green', () {
    final colorToTest = green;
    final cam = Cam16.fromInt(colorToTest);
    final color =
        Hct.from(cam.hue, cam.chroma, ColorUtils.lstarFromArgb(colorToTest))
            .toInt();
    expect(colorToTest, equals(color));
  });

  test('gamutMap_blue', () {
    final colorToTest = blue;
    final cam = Cam16.fromInt(colorToTest);
    final color =
        Hct.from(cam.hue, cam.chroma, ColorUtils.lstarFromArgb(colorToTest))
            .toInt();
    expect(colorToTest, equals(color));
  });

  test('gamutMap_white', () {
    final colorToTest = white;
    final cam = Cam16.fromInt(colorToTest);
    final color =
        Hct.from(cam.hue, cam.chroma, ColorUtils.lstarFromArgb(colorToTest))
            .toInt();
    expect(colorToTest, equals(color));
  });

  test('gamutMap_midgray', () {
    final colorToTest = green;
    final cam = Cam16.fromInt(colorToTest);
    final color =
        Hct.from(cam.hue, cam.chroma, ColorUtils.lstarFromArgb(colorToTest))
            .toInt();
    expect(colorToTest, equals(color));
  });
}
