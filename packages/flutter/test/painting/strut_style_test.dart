// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('StrutStyle diagnostics test', () {
    const s0 = StrutStyle(fontFamily: 'Serif', fontSize: 14);
    expect(s0.toString(), equals('StrutStyle(family: Serif, size: 14.0)'));

    const s1 = StrutStyle(fontFamily: 'Serif', fontSize: 14, forceStrutHeight: true);
    expect(s1.fontFamily, 'Serif');
    expect(s1.fontSize, 14.0);
    expect(s1, equals(s1));
    expect(s1.toString(), equals('StrutStyle(family: Serif, size: 14.0, <strut height forced>)'));

    const s2 = StrutStyle(fontFamily: 'Serif', fontSize: 14, forceStrutHeight: false);
    expect(s2.toString(), equals('StrutStyle(family: Serif, size: 14.0, <strut height normal>)'));

    const s3 = StrutStyle();
    expect(s3.toString(), equals('StrutStyle'));

    const s4 = StrutStyle(forceStrutHeight: false);
    expect(s4.toString(), equals('StrutStyle(<strut height normal>)'));

    const s5 = StrutStyle(forceStrutHeight: true);
    expect(s5.toString(), equals('StrutStyle(<strut height forced>)'));

    const s6 = StrutStyle(height: 14, leadingDistribution: TextLeadingDistribution.even);
    expect(s6.toString(), equals('StrutStyle(height: 14.0x, leadingDistribution: even)'));

    const s7 = StrutStyle(height: 14, leadingDistribution: TextLeadingDistribution.proportional);
    expect(s7.toString(), equals('StrutStyle(height: 14.0x, leadingDistribution: proportional)'));

    expect(s6, isNot(equals(s7)));
  });

  test('StrutStyle.merge keeps the package prefix of font families', () {
    const strut = StrutStyle(
      fontFamily: 'Inter',
      fontFamilyFallback: <String>['Noto'],
      package: 'my_fonts',
    );
    final StrutStyle merged = strut.merge(const StrutStyle(height: 1.5));
    expect(merged.fontFamily, 'packages/my_fonts/Inter');
    expect(merged.fontFamilyFallback, <String>['packages/my_fonts/Noto']);
    expect(merged.height, 1.5);

    final StrutStyle mergedInto = const StrutStyle(height: 1.5).merge(strut);
    expect(mergedInto.fontFamily, 'packages/my_fonts/Inter');
    expect(mergedInto.fontFamilyFallback, <String>['packages/my_fonts/Noto']);
  });

  test('StrutStyle.fromTextStyle applies the package prefix once', () {
    final strut = StrutStyle.fromTextStyle(
      const TextStyle(fontSize: 12),
      fontFamily: 'Inter',
      fontFamilyFallback: const <String>['Noto'],
      package: 'my_fonts',
    );
    expect(strut.fontFamily, 'packages/my_fonts/Inter');
    expect(strut.fontFamilyFallback, <String>['packages/my_fonts/Noto']);

    final inherited = StrutStyle.fromTextStyle(
      const TextStyle(fontFamily: 'Inter', package: 'my_fonts'),
      fontFamilyFallback: const <String>['Noto'],
      package: 'other_fonts',
    );
    expect(inherited.fontFamily, 'packages/my_fonts/Inter');
    expect(inherited.fontFamilyFallback, <String>['packages/other_fonts/Noto']);
  });
}
