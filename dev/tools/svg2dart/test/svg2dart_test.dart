// Copyright 2017 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math';

import 'package:svg2dart/svg2dart.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as path;

const String kPackagePath = '.';

void main() {

  test('parsePixels', () {
    expect(parsePixels('23px'), 23);
    expect(parsePixels('9px'), 9);
    expect(() { parsePixels('9pt'); }, throwsA(const isInstanceOf<ArgumentError>()));
  });

  test('parsePoints', () {
    expect(parsePoints('1.0, 2.0'),
        const <Point<double>> [const Point<double>(1.0, 2.0)]
    );
    expect(parsePoints('12.0, 34.0 5.0, 6.6'),
        const <Point<double>> [
          const Point<double>(12.0, 34.0),
          const Point<double>(5.0, 6.6),
        ]
    );
  });

  group('parseSvg', () {
    test('empty SVGs', () {
      interpretSvg(testAsset('empty_svg_1_48x48.svg'));
      interpretSvg(testAsset('empty_svg_2_100x50.svg'));
    });

    test('illegal SVGs', () {
      expect(
        () { interpretSvg(testAsset('illegal_svg_multiple_roots.svg')); },
        throwsA(anything)
      );
    });

    test('SVG size', () {
      expect(
          interpretSvg(testAsset('empty_svg_1_48x48.svg')).size,
          const Point<double>(48.0, 48.0)
      );

      expect(
          interpretSvg(testAsset('empty_svg_2_100x50.svg')).size,
          const Point<double>(100.0, 50.0)
      );
    });

    test('horizontal bar', () {
      FrameData frameData = interpretSvg(testAsset('horizontal_bar.svg'));
      expect(frameData.paths, [
        const SvgPath('path_1', const<SvgPathCommand> [
          const SvgPathCommand('M', const [const Point<double>(0.0, 19.0)]),
          const SvgPathCommand('L', const [const Point<double>(48.0, 19.0)]),
          const SvgPathCommand('L', const [const Point<double>(48.0, 29.0)]),
          const SvgPathCommand('L', const [const Point<double>(0.0, 29.0)]),
          const SvgPathCommand('Z', const []),
        ]),
      ]);
    });
  });
}

String testAsset(String name) {
  return path.join(kPackagePath, 'test_assets', name);
}

