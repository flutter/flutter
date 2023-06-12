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
import 'package:material_color_utilities/palettes/core_palette.dart';
import 'package:material_color_utilities/palettes/tonal_palette.dart';
import 'package:test/test.dart';

void main() {
  group('TonalPalette', () {
    group('[.of constructor]', () {
      test('tones of blue', () async {
        final hct = Hct.fromInt(0xff0000ff);
        final tones = TonalPalette.of(hct.hue, hct.chroma);

        expect(tones.get(0), 0xff000000);
        expect(tones.get(10), 0xff00006e);
        expect(tones.get(20), 0xff0001ac);
        expect(tones.get(30), 0xff0000ef);
        expect(tones.get(40), 0xff343dff);
        expect(tones.get(50), 0xff5a64ff);
        expect(tones.get(60), 0xff7c84ff);
        expect(tones.get(70), 0xff9da3ff);
        expect(tones.get(80), 0xffbec2ff);
        expect(tones.get(90), 0xffe0e0ff);
        expect(tones.get(95), 0xfff1efff);
        expect(tones.get(99), 0xfffffbff);
        expect(tones.get(100), 0xffffffff);

        /// Tone not in [TonalPalette.commonTones]
        expect(tones.get(3), 0xff00003c);
      });

      test('asList', () {
        final hct = Hct.fromInt(0xff0000ff);
        final tones = TonalPalette.of(hct.hue, hct.chroma);

        expect(tones.asList, [
          0xff000000,
          0xff00006e,
          0xff0001ac,
          0xff0000ef,
          0xff343dff,
          0xff5a64ff,
          0xff7c84ff,
          0xff9da3ff,
          0xffbec2ff,
          0xffe0e0ff,
          0xfff1efff,
          0xfffffbff,
          0xffffffff,
        ]);
      });

      test('operator == and hashCode', () {
        final hctAB = Hct.fromInt(0xff0000ff);
        final tonesA = TonalPalette.of(hctAB.hue, hctAB.chroma);
        final tonesB = TonalPalette.of(hctAB.hue, hctAB.chroma);
        final hctC = Hct.fromInt(0xff123456);
        final tonesC = TonalPalette.of(hctC.hue, hctC.chroma);

        expect(tonesA, tonesB);
        expect(tonesB, isNot(tonesC));

        expect(tonesA.hashCode, tonesB.hashCode);
        expect(tonesB.hashCode, isNot(tonesC.hashCode));
      });
    });

    group('[.fromList constructor]', () {
      test('tones of i', () async {
        final ints = List.generate(TonalPalette.commonSize, (i) => i);
        final tones = TonalPalette.fromList(ints);

        expect(tones.get(100), 12);
        expect(tones.get(99), 11);
        expect(tones.get(95), 10);
        expect(tones.get(90), 9);
        expect(tones.get(80), 8);
        expect(tones.get(70), 7);
        expect(tones.get(60), 6);
        expect(tones.get(50), 5);
        expect(tones.get(40), 4);
        expect(tones.get(30), 3);
        expect(tones.get(20), 2);
        expect(tones.get(10), 1);
        expect(tones.get(0), 0);

        /// Tone not in [TonalPalette.commonTones]
        expect(() => tones.get(3), throwsA(isA<ArgumentError>()));
      });

      test('asList', () {
        final ints = List.generate(TonalPalette.commonSize, (i) => i);
        final tones = TonalPalette.fromList(ints);
        expect(tones.asList, ints);
      });

      test('operator == and hashCode', () {
        final intsAB = List.generate(TonalPalette.commonSize, (i) => i);
        final tonesA = TonalPalette.fromList(intsAB);
        final tonesB = TonalPalette.fromList(intsAB);
        final intsC = List.generate(TonalPalette.commonSize, (i) => 1);
        final tonesC = TonalPalette.fromList(intsC);

        expect(tonesA, tonesB);
        expect(tonesB, isNot(tonesC));

        expect(tonesA.hashCode, tonesB.hashCode);
        expect(tonesB.hashCode, isNot(tonesC.hashCode));
      });
    });
  });

  group('CorePalette', () {
    test('asList', () {
      final ints =
          List.generate(CorePalette.size * TonalPalette.commonSize, (i) => i);
      final corePalette = CorePalette.fromList(ints);
      expect(corePalette.asList(), ints);
    });

    test('operator == and hashCode', () {
      final corePaletteA = CorePalette.of(0xff0000ff);
      final corePaletteB = CorePalette.of(0xff0000ff);
      final corePaletteC = CorePalette.of(0xff123456);

      expect(corePaletteA, corePaletteB);
      expect(corePaletteB, isNot(corePaletteC));

      expect(corePaletteA.hashCode, corePaletteB.hashCode);
      expect(corePaletteB.hashCode, isNot(corePaletteC.hashCode));
    });
  });
}
