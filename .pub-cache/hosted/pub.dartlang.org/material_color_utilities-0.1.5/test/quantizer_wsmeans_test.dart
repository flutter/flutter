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

import 'package:material_color_utilities/quantize/quantizer_wsmeans.dart';
import 'package:test/test.dart';

const red = 0xffff0000;
const green = 0xff00ff00;
const blue = 0xff0000ff;
const white = 0xffffffff;
const random = 0xff426088;
const maxColors = 256;

void main() {
  test('1Rando', () {
    final result = QuantizerWsmeans.quantize(<int>[0xff141216], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(0xff141216));
  });

  test('1R', () {
    final result = QuantizerWsmeans.quantize(<int>[red], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
  });
  test('1R', () {
    final result = QuantizerWsmeans.quantize(<int>[red], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(red));
  });
  test('1G', () {
    final result = QuantizerWsmeans.quantize(<int>[green], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(green));
  });
  test('1B', () {
    final result = QuantizerWsmeans.quantize(<int>[blue], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(blue));
  });

  test('5B', () {
    final result = QuantizerWsmeans.quantize(
        <int>[blue, blue, blue, blue, blue], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(blue));
  });
}
