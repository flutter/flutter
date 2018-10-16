// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextStyle, ParagraphStyle;

import 'package:flutter/painting.dart';
import '../flutter_test_alternative.dart';

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

    const TextStyle s1 = TextStyle(
      fontSize: 10.0,
      fontWeight: FontWeight.w800,
      height: 123.0,
    );
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

    expect(TextStyle.lerp(null, null, 0.5), isNull);

    final TextStyle s6 = TextStyle.lerp(null, s3, 0.25);
    expect(s3.fontFamily, isNull);
    expect(s3.fontSize, 18.0);
    expect(s3.fontWeight, FontWeight.w400);
    expect(s3.height, 123.0);
    expect(s3.color, isNull);
    expect(s3, isNot(equals(s6)));
    expect(s6.fontFamily, isNull);
    expect(s6.fontSize, isNull);
    expect(s6.fontWeight, FontWeight.w400);
    expect(s6.height, isNull);
    expect(s6.color, isNull);

    final TextStyle s7 = TextStyle.lerp(null, s3, 0.75);
    expect(s3.fontFamily, isNull);
    expect(s3.fontSize, 18.0);
    expect(s3.fontWeight, FontWeight.w400);
    expect(s3.height, 123.0);
    expect(s3.color, isNull);
    expect(s3, equals(s7));
    expect(s7.fontFamily, isNull);
    expect(s7.fontSize, 18.0);
    expect(s7.fontWeight, FontWeight.w400);
    expect(s7.height, 123.0);
    expect(s7.color, isNull);

    final TextStyle s8 = TextStyle.lerp(s3, null, 0.25);
    expect(s3.fontFamily, isNull);
    expect(s3.fontSize, 18.0);
    expect(s3.fontWeight, FontWeight.w400);
    expect(s3.height, 123.0);
    expect(s3.color, isNull);
    expect(s3, equals(s8));
    expect(s8.fontFamily, isNull);
    expect(s8.fontSize, 18.0);
    expect(s8.fontWeight, FontWeight.w400);
    expect(s8.height, 123.0);
    expect(s8.color, isNull);

    final TextStyle s9 = TextStyle.lerp(s3, null, 0.75);
    expect(s3.fontFamily, isNull);
    expect(s3.fontSize, 18.0);
    expect(s3.fontWeight, FontWeight.w400);
    expect(s3.height, 123.0);
    expect(s3.color, isNull);
    expect(s3, isNot(equals(s9)));
    expect(s9.fontFamily, isNull);
    expect(s9.fontSize, isNull);
    expect(s9.fontWeight, FontWeight.w400);
    expect(s9.height, isNull);
    expect(s9.color, isNull);

    final ui.TextStyle ts5 = s5.getTextStyle();
    expect(ts5, equals(ui.TextStyle(fontWeight: FontWeight.w700, fontSize: 12.0, height: 123.0)));
    expect(ts5.toString(), 'TextStyle(color: unspecified, decoration: unspecified, decorationColor: unspecified, decorationStyle: unspecified, fontWeight: FontWeight.w700, fontStyle: unspecified, textBaseline: unspecified, fontFamily: unspecified, fontSize: 12.0, letterSpacing: unspecified, wordSpacing: unspecified, height: 123.0x, locale: unspecified, background: unspecified, foreground: unspecified, shadows: unspecified)');
    final ui.TextStyle ts2 = s2.getTextStyle();
    expect(ts2, equals(ui.TextStyle(color: const Color(0xFF00FF00), fontWeight: FontWeight.w800, fontSize: 10.0, height: 100.0)));
    expect(ts2.toString(), 'TextStyle(color: Color(0xff00ff00), decoration: unspecified, decorationColor: unspecified, decorationStyle: unspecified, fontWeight: FontWeight.w800, fontStyle: unspecified, textBaseline: unspecified, fontFamily: unspecified, fontSize: 10.0, letterSpacing: unspecified, wordSpacing: unspecified, height: 100.0x, locale: unspecified, background: unspecified, foreground: unspecified, shadows: unspecified)');

    final ui.ParagraphStyle ps2 = s2.getParagraphStyle(textAlign: TextAlign.center);
    expect(ps2, equals(ui.ParagraphStyle(textAlign: TextAlign.center, fontWeight: FontWeight.w800, fontSize: 10.0, lineHeight: 100.0)));
    expect(ps2.toString(), 'ParagraphStyle(textAlign: TextAlign.center, textDirection: unspecified, fontWeight: FontWeight.w800, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: 10.0, lineHeight: 100.0x, ellipsis: unspecified, locale: unspecified)');
    final ui.ParagraphStyle ps5 = s5.getParagraphStyle();
    expect(ps5, equals(ui.ParagraphStyle(fontWeight: FontWeight.w700, fontSize: 12.0, lineHeight: 123.0)));
    expect(ps5.toString(), 'ParagraphStyle(textAlign: unspecified, textDirection: unspecified, fontWeight: FontWeight.w700, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: 12.0, lineHeight: 123.0x, ellipsis: unspecified, locale: unspecified)');
  });

  test('TextStyle with text direction', () {
    final ui.ParagraphStyle ps6 = const TextStyle().getParagraphStyle(textDirection: TextDirection.ltr);
    expect(ps6, equals(ui.ParagraphStyle(textDirection: TextDirection.ltr, fontSize: 14.0)));
    expect(ps6.toString(), 'ParagraphStyle(textAlign: unspecified, textDirection: TextDirection.ltr, fontWeight: unspecified, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: 14.0, lineHeight: unspecified, ellipsis: unspecified, locale: unspecified)');

    final ui.ParagraphStyle ps7 = const TextStyle().getParagraphStyle(textDirection: TextDirection.rtl);
    expect(ps7, equals(ui.ParagraphStyle(textDirection: TextDirection.rtl, fontSize: 14.0)));
    expect(ps7.toString(), 'ParagraphStyle(textAlign: unspecified, textDirection: TextDirection.rtl, fontWeight: unspecified, fontStyle: unspecified, maxLines: unspecified, fontFamily: unspecified, fontSize: 14.0, lineHeight: unspecified, ellipsis: unspecified, locale: unspecified)');
  });

  test('TextStyle using package font', () {
    const TextStyle s6 = TextStyle(fontFamily: 'test');
    expect(s6.fontFamily, 'test');
    expect(s6.getTextStyle().toString(), 'TextStyle(color: unspecified, decoration: unspecified, decorationColor: unspecified, decorationStyle: unspecified, fontWeight: unspecified, fontStyle: unspecified, textBaseline: unspecified, fontFamily: test, fontSize: unspecified, letterSpacing: unspecified, wordSpacing: unspecified, height: unspecified, locale: unspecified, background: unspecified, foreground: unspecified, shadows: unspecified)');

    const TextStyle s7 = TextStyle(fontFamily: 'test', package: 'p');
    expect(s7.fontFamily, 'packages/p/test');
    expect(s7.getTextStyle().toString(), 'TextStyle(color: unspecified, decoration: unspecified, decorationColor: unspecified, decorationStyle: unspecified, fontWeight: unspecified, fontStyle: unspecified, textBaseline: unspecified, fontFamily: packages/p/test, fontSize: unspecified, letterSpacing: unspecified, wordSpacing: unspecified, height: unspecified, locale: unspecified, background: unspecified, foreground: unspecified, shadows: unspecified)');
  });

  test('TextStyle.debugLabel', () {
    const TextStyle unknown = TextStyle();
    const TextStyle foo = TextStyle(debugLabel: 'foo', fontSize: 1.0);
    const TextStyle bar = TextStyle(debugLabel: 'bar', fontSize: 2.0);
    const TextStyle baz = TextStyle(debugLabel: 'baz', fontSize: 3.0);

    expect(unknown.debugLabel, null);
    expect(unknown.toString(), 'TextStyle(<all styles inherited>)');
    expect(unknown.copyWith().debugLabel, null);
    expect(unknown.apply().debugLabel, null);

    expect(foo.debugLabel, 'foo');
    expect(foo.toString(), 'TextStyle(debugLabel: foo, inherit: true, size: 1.0)');
    expect(foo.merge(bar).debugLabel, '(foo).merge(bar)');
    expect(foo.merge(bar).merge(baz).debugLabel, '((foo).merge(bar)).merge(baz)');
    expect(foo.copyWith().debugLabel, '(foo).copyWith');
    expect(foo.apply().debugLabel, '(foo).apply');
    expect(TextStyle.lerp(foo, bar, 0.5).debugLabel, 'lerp(foo ⎯0.5→ bar)');
    expect(TextStyle.lerp(foo.merge(bar), baz, 0.51).copyWith().debugLabel, '(lerp((foo).merge(bar) ⎯0.5→ baz)).copyWith');
  });

  test('TextStyle foreground and color combos', () {
    const Color red = Color.fromARGB(255, 255, 0, 0);
    const Color blue = Color.fromARGB(255, 0, 0, 255);
    const TextStyle redTextStyle = TextStyle(color: red);
    const TextStyle blueTextStyle = TextStyle(color: blue);
    final TextStyle redPaintTextStyle = TextStyle(foreground: Paint()..color = red);
    final TextStyle bluePaintTextStyle = TextStyle(foreground: Paint()..color = blue);

    // merge/copyWith
    final TextStyle redBlueBothForegroundMerged = redTextStyle.merge(blueTextStyle);
    expect(redBlueBothForegroundMerged.color, blue);
    expect(redBlueBothForegroundMerged.foreground, isNull);

    final TextStyle redBlueBothPaintMerged = redPaintTextStyle.merge(bluePaintTextStyle);
    expect(redBlueBothPaintMerged.color, null);
    expect(redBlueBothPaintMerged.foreground, bluePaintTextStyle.foreground);

    final TextStyle redPaintBlueColorMerged = redPaintTextStyle.merge(blueTextStyle);
    expect(redPaintBlueColorMerged.color, null);
    expect(redPaintBlueColorMerged.foreground, redPaintTextStyle.foreground);

    final TextStyle blueColorRedPaintMerged = blueTextStyle.merge(redPaintTextStyle);
    expect(blueColorRedPaintMerged.color, null);
    expect(blueColorRedPaintMerged.foreground, redPaintTextStyle.foreground);

    // apply
    expect(redPaintTextStyle.apply(color: blue).color, isNull);
    expect(redPaintTextStyle.apply(color: blue).foreground.color, red);
    expect(redTextStyle.apply(color: blue).color, blue);

    // lerp
    expect(TextStyle.lerp(redTextStyle, blueTextStyle, .25).color, Color.lerp(red, blue, .25));
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .25).color, isNull);
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .25).foreground.color, red);
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .75).foreground.color, blue);

    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .25).color, isNull);
    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .25).foreground.color, red);
    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .75).foreground.color, blue);
  });
}
