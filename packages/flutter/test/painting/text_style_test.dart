// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextStyle, ParagraphStyle;

import 'package:flutter/painting.dart';
import 'package:test/test.dart';

void main() {
  test('TextStyle control test', () {
    expect(
      const TextStyle(inherit: false).toString(),
      equals('TextStyle(inherit: false, <no style specified>)'),
    );
    expect(
      const TextStyle(inherit: true).toString(),
      equals('TextStyle(<all styles inherited>)'),
    );

    final TextStyle s1 = const TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
      height: 123.0,
    );
    expect(() { s1.fontFamily = 'test'; }, throwsA(isNoSuchMethodError)); // ignore: ASSIGNMENT_TO_FINAL
    expect(s1.fontFamily, isNull);
    expect(s1.fontSize, 10.0);
    expect(s1.fontWeight, FontWeight.w800);
    expect(s1.height, 123.0);
    expect(s1, equals(s1));
    expect(
      s1.toString(),
      equals('TextStyle(inherit: true, size: 10.0, weight: 800, height: 123.0x)'),
    );

    final TextStyle s2 = s1.copyWith(color: const Color(0xFF00FF00), height: 100.0);
    expect(s1.fontFamily, isNull);
    expect(s1.fontSize, 10.0);
    expect(s1.fontWeight, FontWeight.w800);
    expect(s1.height, 123.0);
    expect(s1.color, isNull);
    expect(s2.fontFamily, isNull);
    expect(s2.fontSize, 10.0);
    expect(s2.fontWeight, FontWeight.w800);
    expect(s2.height, 100.0);
    expect(s2.color, const Color(0xFF00FF00));
    expect(s2, isNot(equals(s1)));
    expect(
      s2.toString(),
      equals(
        'TextStyle(inherit: true, color: Color(0xff00ff00), size: 10.0, weight: 800, height: 100.0x)',
      ),
    );

    final TextStyle s3 = s1.apply(fontSizeFactor: 2.0, fontSizeDelta: -2.0, fontWeightDelta: -4);
    expect(s1.fontFamily, isNull);
    expect(s1.fontSize, 10.0);
    expect(s1.fontWeight, FontWeight.w800);
    expect(s1.height, 123.0);
    expect(s1.color, isNull);
    expect(s3.fontFamily, isNull);
    expect(s3.fontSize, 18.0);
    expect(s3.fontWeight, FontWeight.w400);
    expect(s3.height, 123.0);
    expect(s3.color, isNull);
    expect(s3, isNot(equals(s1)));

    expect(s1.apply(fontWeightDelta: -10).fontWeight, FontWeight.w100);
    expect(s1.apply(fontWeightDelta: 2).fontWeight, FontWeight.w900);
    expect(s1.merge(null), equals(s1));

    final TextStyle s4 = s2.merge(s1);
    expect(s1.fontFamily, isNull);
    expect(s1.fontSize, 10.0);
    expect(s1.fontWeight, FontWeight.w800);
    expect(s1.height, 123.0);
    expect(s1.color, isNull);
    expect(s2.fontFamily, isNull);
    expect(s2.fontSize, 10.0);
    expect(s2.fontWeight, FontWeight.w800);
    expect(s2.height, 100.0);
    expect(s2.color, const Color(0xFF00FF00));
    expect(s2, isNot(equals(s1)));
    expect(s2, isNot(equals(s4)));
    expect(s4.fontFamily, isNull);
    expect(s4.fontSize, 10.0);
    expect(s4.fontWeight, FontWeight.w800);
    expect(s4.height, 123.0);
    expect(s4.color, const Color(0xFF00FF00));

    final TextStyle s5 = TextStyle.lerp(s1, s3, 0.25);
    expect(s1.fontFamily, isNull);
    expect(s1.fontSize, 10.0);
    expect(s1.fontWeight, FontWeight.w800);
    expect(s1.height, 123.0);
    expect(s1.color, isNull);
    expect(s3.fontFamily, isNull);
    expect(s3.fontSize, 18.0);
    expect(s3.fontWeight, FontWeight.w400);
    expect(s3.height, 123.0);
    expect(s3.color, isNull);
    expect(s3, isNot(equals(s1)));
    expect(s3, isNot(equals(s5)));
    expect(s5.fontFamily, isNull);
    expect(s5.fontSize, 12.0);
    expect(s5.fontWeight, FontWeight.w700);
    expect(s5.height, 123.0);
    expect(s5.color, isNull);

    final ui.TextStyle ts5 = s5.getTextStyle();
    expect(ts5, equals(new ui.TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0, height: 123.0)));
    expect(ts5.toString(), 'TextStyle(color: unspecified, decoration: unspecified, decorationColor: unspecified, decorationStyle: unspecified, fontWeight: FontWeight.w700, fontStyle: unspecified, textBaseline: unspecified, fontFamily: unspecified, fontSize: 12.0, letterSpacing: unspecified, wordSpacing: unspecified, height: 123.0x)');
    final ui.TextStyle ts2 = s2.getTextStyle();
    expect(ts2, equals(new ui.TextStyle(color: const Color(0xFF00FF00), fontWeight: FontWeight.w800, fontSize: 10.0, height: 100.0)));
    expect(ts2.toString(), 'TextStyle(color: Color(0xff00ff00), decoration: unspecified, decorationColor: unspecified, decorationStyle: unspecified, fontWeight: FontWeight.w800, fontStyle: unspecified, textBaseline: unspecified, fontFamily: unspecified, fontSize: 10.0, letterSpacing: unspecified, wordSpacing: unspecified, height: 100.0x)');

    final ui.ParagraphStyle ps2 = s2.getParagraphStyle(textAlign: TextAlign.center);
    expect(ps2, equals(new ui.ParagraphStyle(textAlign: TextAlign.center, fontWeight: FontWeight.w800, fontSize: 10.0, lineHeight: 100.0)));
    expect(ps2.toString(), 'ParagraphStyle(textAlign: TextAlign.center, textDirection: unspecified, fontWeight: FontWeight.w800, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: 10.0, lineHeight: 100.0x, ellipsis: unspecified)');
    final ui.ParagraphStyle ps5 = s5.getParagraphStyle();
    expect(ps5, equals(new ui.ParagraphStyle(fontWeight: FontWeight.w700, fontSize: 12.0, lineHeight: 123.0)));
    expect(ps5.toString(), 'ParagraphStyle(textAlign: unspecified, textDirection: unspecified, fontWeight: FontWeight.w700, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: 12.0, lineHeight: 123.0x, ellipsis: unspecified)');

    final ui.ParagraphStyle ps6 = const TextStyle().getParagraphStyle(textDirection: TextDirection.ltr);
    expect(ps6, equals(new ui.ParagraphStyle(textDirection: TextDirection.ltr)));
    expect(ps6.toString(), 'ParagraphStyle(textAlign: unspecified, textDirection: TextDirection.ltr, fontWeight: unspecified, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: unspecified, lineHeight: unspecified, ellipsis: unspecified)');

    final ui.ParagraphStyle ps7 = const TextStyle().getParagraphStyle(textDirection: TextDirection.rtl);
    expect(ps7, equals(new ui.ParagraphStyle(textDirection: TextDirection.rtl)));
    expect(ps7.toString(), 'ParagraphStyle(textAlign: unspecified, textDirection: TextDirection.rtl, fontWeight: unspecified, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: unspecified, lineHeight: unspecified, ellipsis: unspecified)');
  });
}
