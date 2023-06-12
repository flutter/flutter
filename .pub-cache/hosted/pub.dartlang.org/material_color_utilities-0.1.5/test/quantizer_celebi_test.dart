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

import 'package:material_color_utilities/quantize/quantizer_celebi.dart';
import 'package:test/test.dart';

const red = 0xffff0000;
const green = 0xff00ff00;
const blue = 0xff0000ff;
const white = 0xffffffff;
const random = 0xff426088;
const maxColors = 256;

void main() {
  test('1R', () async {
    final celebi = QuantizerCelebi();
    final result = await celebi.quantize(<int>[red], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(red));
  });
  test('1G', () async {
    final celebi = QuantizerCelebi();
    final result = await celebi.quantize(<int>[green], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(green));
  });
  test('1B', () async {
    final celebi = QuantizerCelebi();
    final result = await celebi.quantize(<int>[blue], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(blue));
  });

  test('5B', () async {
    final celebi = QuantizerCelebi();
    final result =
        await celebi.quantize(<int>[blue, blue, blue, blue, blue], maxColors);
    final colors = result.colorToCount.keys.toList();
    expect(colors.length, equals(1));
    expect(colors[0], equals(blue));
  });

  test('1R 1G 1B', () async {
    final celebi = QuantizerCelebi();
    final result = await celebi.quantize(<int>[red, green, blue], maxColors);
    final colors = result.colorToCount.keys.toList();
    print('1r 1g 1b colors: $colors');

    expect(Set.from(colors).length, equals(3));
    expect(colors[0], blue);
    expect(colors[1], red);
    expect(colors[2], green);
  });

  test('2R 3G', () async {
    final celebi = QuantizerCelebi();
    final result =
        await celebi.quantize(<int>[red, red, green, green, green], maxColors);
    final colors = result.colorToCount.keys.toList();
    print('2r 3g colors: $colors');
    expect(Set.from(colors).length, equals(2));

    expect(colors[0], green);
    expect(colors[1], red);
  });
}
