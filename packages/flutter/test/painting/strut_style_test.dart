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
}
