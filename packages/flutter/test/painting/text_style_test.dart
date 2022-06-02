// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui show TextStyle, ParagraphStyle, FontFeature, FontVariation, Shadow;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

// This matcher verifies ui.TextStyle.toString (from dart:ui) reports a superset
// of the given TextStyle's (from painting.dart) properties.
class _DartUiTextStyleToStringMatcher extends Matcher {
  _DartUiTextStyleToStringMatcher(this.textStyle);

  final TextStyle textStyle;

  late final List<String> propertiesInOrder = <String>[
    _propertyToString('color', textStyle.color),
    _propertyToString('decoration', textStyle.decoration),
    _propertyToString('decorationColor', textStyle.decorationColor),
    _propertyToString('decorationStyle', textStyle.decorationStyle),
    _propertyToString('decorationThickness', textStyle.decorationThickness),
    _propertyToString('fontWeight', textStyle.fontWeight),
    _propertyToString('fontStyle', textStyle.fontStyle),
    _propertyToString('textBaseline', textStyle.textBaseline),
    _propertyToString('fontFamily', textStyle.fontFamily),
    _propertyToString('fontFamilyFallback', textStyle.fontFamilyFallback),
    _propertyToString('fontSize', textStyle.fontSize),
    _propertyToString('letterSpacing', textStyle.letterSpacing),
    _propertyToString('wordSpacing', textStyle.wordSpacing),
    _propertyToString('height', textStyle.height),
    // TODO(LongCatIsLooong): web support for
    // https://github.com/flutter/flutter/issues/72521
    if (!kIsWeb) _propertyToString('leadingDistribution', textStyle.leadingDistribution),
    _propertyToString('locale', textStyle.locale),
    _propertyToString('background', textStyle.background),
    _propertyToString('foreground', textStyle.foreground),
    _propertyToString('shadows', textStyle.shadows),
    _propertyToString('fontFeatures', textStyle.fontFeatures),
    _propertyToString('fontVariations', textStyle.fontVariations),
  ];

  static String _propertyToString(String name, Object? property) => '$name: ${property ?? 'unspecified'}';

  @override
  Description describe(Description description) => description.add('is a superset of $textStyle.');

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final String description = item.toString();
    const String prefix = 'TextStyle(';
    const String suffix = ')';
    if (!description.startsWith(prefix) || !description.endsWith(suffix)) {
      return false;
    }

    final String propertyDescription = description.substring(
      prefix.length,
      description.length - suffix.length,
    );
    int startIndex = 0;
    for (final String property in propertiesInOrder) {
      startIndex = propertyDescription.indexOf(property, startIndex);
      if (startIndex < 0) {
        matchState['missingProperty'] = property;
        return false;
      }
      startIndex += property.length;
    }
    return true;
  }

  @override
  Description describeMismatch(dynamic item, Description mismatchDescription, Map<dynamic, dynamic> matchState, bool verbose) {
    final Description description = super.describeMismatch(item, mismatchDescription, matchState, verbose);
    final String? property = matchState['missingProperty'] as String?;
    if (property != null) {
      description.add("expect property: '$property'");
      final int propertyIndex = propertiesInOrder.indexOf(property);
      if (propertyIndex > 0) {
        description.add(" after: '${propertiesInOrder[propertyIndex - 1]}'");
      }
      description.add('\n');
    }
    return description;
  }
}

Matcher matchesToStringOf(TextStyle textStyle) => _DartUiTextStyleToStringMatcher(textStyle);

void main() {
  test('TextStyle control test', () {
    expect(
      const TextStyle(inherit: false).toString(),
      equals('TextStyle(inherit: false, <no style specified>)'),
    );
    expect(
      const TextStyle().toString(),
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

    // Check that the inherit flag can be set with copyWith().
    expect(
      s1.copyWith(inherit: false).toString(),
      equals('TextStyle(inherit: false, size: 10.0, weight: 800, height: 123.0x)'),
    );

    final TextStyle s2 = s1.copyWith(
      color: const Color(0xFF00FF00),
      height: 100.0,
      leadingDistribution: TextLeadingDistribution.even,
    );
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
    expect(s2.leadingDistribution, TextLeadingDistribution.even);
    expect(s2, isNot(equals(s1)));
    expect(
      s2.toString(),
      equals(
        'TextStyle(inherit: true, color: Color(0xff00ff00), size: 10.0, weight: 800, height: 100.0x, leadingDistribution: even)',
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
    expect(s2.leadingDistribution, TextLeadingDistribution.even);
    expect(s2, isNot(equals(s1)));
    expect(s2, isNot(equals(s4)));
    expect(s4.fontFamily, isNull);
    expect(s4.fontSize, 10.0);
    expect(s4.fontWeight, FontWeight.w800);
    expect(s4.height, 123.0);
    expect(s4.color, const Color(0xFF00FF00));
    expect(s4.leadingDistribution, TextLeadingDistribution.even);

    final TextStyle s5 = TextStyle.lerp(s1, s3, 0.25)!;
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

    final TextStyle s6 = TextStyle.lerp(null, s3, 0.25)!;
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

    final TextStyle s7 = TextStyle.lerp(null, s3, 0.75)!;
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

    final TextStyle s8 = TextStyle.lerp(s3, null, 0.25)!;
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

    final TextStyle s9 = TextStyle.lerp(s3, null, 0.75)!;
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
    expect(ts5, matchesToStringOf(s5));
    final ui.TextStyle ts2 = s2.getTextStyle();
    expect(ts2, equals(ui.TextStyle(color: const Color(0xFF00FF00), fontWeight: FontWeight.w800, fontSize: 10.0, height: 100.0, leadingDistribution: TextLeadingDistribution.even)));
    expect(ts2, matchesToStringOf(s2));

    final ui.ParagraphStyle ps2 = s2.getParagraphStyle(textAlign: TextAlign.center);
    expect(
      ps2,
      equals(ui.ParagraphStyle(textAlign: TextAlign.center, fontWeight: FontWeight.w800, fontSize: 10.0, height: 100.0, textHeightBehavior: const TextHeightBehavior(leadingDistribution: TextLeadingDistribution.even))),
    );
    final ui.ParagraphStyle ps5 = s5.getParagraphStyle();
    expect(
      ps5,
      equals(ui.ParagraphStyle(fontWeight: FontWeight.w700, fontSize: 12.0, height: 123.0)),
    );
  });

  test('TextStyle with text direction', () {
    final ui.ParagraphStyle ps6 = const TextStyle().getParagraphStyle(textDirection: TextDirection.ltr);
    expect(ps6, equals(ui.ParagraphStyle(textDirection: TextDirection.ltr, fontSize: 14.0)));

    final ui.ParagraphStyle ps7 = const TextStyle().getParagraphStyle(textDirection: TextDirection.rtl);
    expect(ps7, equals(ui.ParagraphStyle(textDirection: TextDirection.rtl, fontSize: 14.0)));
  });

  test('TextStyle using package font', () {
    const TextStyle s6 = TextStyle(fontFamily: 'test');
    expect(s6.fontFamily, 'test');
    expect(s6.getTextStyle(), matchesToStringOf(s6));

    const TextStyle s7 = TextStyle(fontFamily: 'test', package: 'p');
    expect(s7.fontFamily, 'packages/p/test');
    expect(s7.getTextStyle(), matchesToStringOf(s7));

    const TextStyle s8 = TextStyle(fontFamilyFallback: <String>['test', 'test2'], package: 'p');
    expect(s8.fontFamilyFallback![0], 'packages/p/test');
    expect(s8.fontFamilyFallback![1], 'packages/p/test2');
    expect(s8.fontFamilyFallback!.length, 2);

    const TextStyle s9 = TextStyle(package: 'p');
    expect(s9.fontFamilyFallback, null);

    const TextStyle s10 = TextStyle(fontFamilyFallback: <String>[], package: 'p');
    expect(s10.fontFamilyFallback, <String>[]);
  });

  test('TextStyle font family fallback', () {
    const TextStyle s1 = TextStyle(fontFamilyFallback: <String>['Roboto', 'test']);
    expect(s1.fontFamilyFallback![0], 'Roboto');
    expect(s1.fontFamilyFallback![1], 'test');
    expect(s1.fontFamilyFallback!.length, 2);

    const TextStyle s2 = TextStyle(fontFamily: 'foo', fontFamilyFallback: <String>['Roboto', 'test']);
    expect(s2.fontFamilyFallback![0], 'Roboto');
    expect(s2.fontFamilyFallback![1], 'test');
    expect(s2.fontFamily, 'foo');
    expect(s2.fontFamilyFallback!.length, 2);

    const TextStyle s3 = TextStyle(fontFamily: 'foo');
    expect(s3.fontFamily, 'foo');
    expect(s3.fontFamilyFallback, null);

    const TextStyle s4 = TextStyle(fontFamily: 'foo', fontFamilyFallback: <String>[]);
    expect(s4.fontFamily, 'foo');
    expect(s4.fontFamilyFallback, <String>[]);
    expect(s4.fontFamilyFallback!.isEmpty, true);

    final ui.TextStyle uis1 = s2.getTextStyle();
    expect(uis1, matchesToStringOf(s2));

    expect(s2.apply().fontFamily, 'foo');
    expect(s2.apply().fontFamilyFallback, const <String>['Roboto', 'test']);
    expect(s2.apply(fontFamily: 'bar').fontFamily, 'bar');
    expect(s2.apply(fontFamilyFallback: const <String>['Banana']).fontFamilyFallback, const <String>['Banana']);
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
    expect(TextStyle.lerp(foo, bar, 0.5)!.debugLabel, 'lerp(foo ⎯0.5→ bar)');
    expect(TextStyle.lerp(foo.merge(bar), baz, 0.51)!.copyWith().debugLabel, '(lerp((foo).merge(bar) ⎯0.5→ baz)).copyWith');
  });

  test('TextStyle.hashCode', () {
    const TextStyle a = TextStyle(
        fontFamilyFallback: <String>['Roboto'],
        shadows: <ui.Shadow>[ui.Shadow()],
        fontFeatures: <ui.FontFeature>[ui.FontFeature('abcd')],
        fontVariations: <ui.FontVariation>[ui.FontVariation('wght', 123.0)],
    );
    const TextStyle b = TextStyle(
        fontFamilyFallback: <String>['Noto'],
        shadows: <ui.Shadow>[ui.Shadow()],
        fontFeatures: <ui.FontFeature>[ui.FontFeature('abcd')],
        fontVariations: <ui.FontVariation>[ui.FontVariation('wght', 123.0)],
    );
    expect(a.hashCode, a.hashCode);
    expect(a.hashCode, isNot(equals(b.hashCode)));

    const TextStyle c = TextStyle(leadingDistribution: TextLeadingDistribution.even);
    const TextStyle d = TextStyle(leadingDistribution: TextLeadingDistribution.proportional);
    expect(c.hashCode, c.hashCode);
    expect(c.hashCode, isNot(d.hashCode));
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
    expect(redPaintTextStyle.apply(color: blue).foreground!.color, red);
    expect(redTextStyle.apply(color: blue).color, blue);

    // lerp
    expect(TextStyle.lerp(redTextStyle, blueTextStyle, .25)!.color, Color.lerp(red, blue, .25));
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .25)!.color, isNull);
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .25)!.foreground!.color, red);
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .75)!.foreground!.color, blue);

    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .25)!.color, isNull);
    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .25)!.foreground!.color, red);
    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .75)!.foreground!.color, blue);
  });

  test('backgroundColor', () {
    const TextStyle s1 = TextStyle();
    expect(s1.backgroundColor, isNull);
    expect(s1.toString(), 'TextStyle(<all styles inherited>)');

    const TextStyle s2 = TextStyle(backgroundColor: Color(0xFF00FF00));
    expect(s2.backgroundColor, const Color(0xFF00FF00));
    expect(s2.toString(), 'TextStyle(inherit: true, backgroundColor: Color(0xff00ff00))');

    final ui.TextStyle ts2 = s2.getTextStyle();
    expect(ts2.toString(), contains('background: Paint(Color(0xff00ff00))'));
  });

  test('TextStyle background and backgroundColor combos', () {
    const Color red = Color.fromARGB(255, 255, 0, 0);
    const Color blue = Color.fromARGB(255, 0, 0, 255);
    const TextStyle redTextStyle = TextStyle(backgroundColor: red);
    const TextStyle blueTextStyle = TextStyle(backgroundColor: blue);
    final TextStyle redPaintTextStyle = TextStyle(background: Paint()..color = red);
    final TextStyle bluePaintTextStyle = TextStyle(background: Paint()..color = blue);

    // merge/copyWith
    final TextStyle redBlueBothForegroundMerged = redTextStyle.merge(blueTextStyle);
    expect(redBlueBothForegroundMerged.backgroundColor, blue);
    expect(redBlueBothForegroundMerged.foreground, isNull);

    final TextStyle redBlueBothPaintMerged = redPaintTextStyle.merge(bluePaintTextStyle);
    expect(redBlueBothPaintMerged.backgroundColor, null);
    expect(redBlueBothPaintMerged.background, bluePaintTextStyle.background);

    final TextStyle redPaintBlueColorMerged = redPaintTextStyle.merge(blueTextStyle);
    expect(redPaintBlueColorMerged.backgroundColor, null);
    expect(redPaintBlueColorMerged.background, redPaintTextStyle.background);

    final TextStyle blueColorRedPaintMerged = blueTextStyle.merge(redPaintTextStyle);
    expect(blueColorRedPaintMerged.backgroundColor, null);
    expect(blueColorRedPaintMerged.background, redPaintTextStyle.background);

    // apply
    expect(redPaintTextStyle.apply(backgroundColor: blue).backgroundColor, isNull);
    expect(redPaintTextStyle.apply(backgroundColor: blue).background!.color, red);
    expect(redTextStyle.apply(backgroundColor: blue).backgroundColor, blue);

    // lerp
    expect(TextStyle.lerp(redTextStyle, blueTextStyle, .25)!.backgroundColor, Color.lerp(red, blue, .25));
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .25)!.backgroundColor, isNull);
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .25)!.background!.color, red);
    expect(TextStyle.lerp(redTextStyle, bluePaintTextStyle, .75)!.background!.color, blue);

    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .25)!.backgroundColor, isNull);
    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .25)!.background!.color, red);
    expect(TextStyle.lerp(redPaintTextStyle, bluePaintTextStyle, .75)!.background!.color, blue);
  });

  test('TextStyle strut textScaleFactor', () {
    const TextStyle style0 = TextStyle(fontSize: 10);
    final ui.ParagraphStyle paragraphStyle0 = style0.getParagraphStyle(textScaleFactor: 2.5);

    const TextStyle style1 = TextStyle(fontSize: 25);
    final ui.ParagraphStyle paragraphStyle1 = style1.getParagraphStyle();

    expect(paragraphStyle0 == paragraphStyle1, true);
  });

  test('TextStyle apply', () {
    const TextStyle style = TextStyle(
      fontSize: 10,
      shadows: <ui.Shadow>[],
      fontStyle: FontStyle.normal,
      fontFeatures: <ui.FontFeature>[],
      fontVariations: <ui.FontVariation>[],
      textBaseline: TextBaseline.alphabetic,
      leadingDistribution: TextLeadingDistribution.even,
    );
    expect(style.apply().shadows, const <ui.Shadow>[]);
    expect(style.apply(shadows: const <ui.Shadow>[ui.Shadow(blurRadius: 2.0)]).shadows, const <ui.Shadow>[ui.Shadow(blurRadius: 2.0)]);
    expect(style.apply().fontStyle, FontStyle.normal);
    expect(style.apply(fontStyle: FontStyle.italic).fontStyle, FontStyle.italic);
    expect(style.apply().locale, isNull);
    expect(style.apply(locale: const Locale.fromSubtags(languageCode: 'es')).locale, const Locale.fromSubtags(languageCode: 'es'));
    expect(style.apply().fontFeatures, const <ui.FontFeature>[]);
    expect(style.apply(fontFeatures: const <ui.FontFeature>[ui.FontFeature.enable('test')]).fontFeatures, const <ui.FontFeature>[ui.FontFeature.enable('test')]);
    expect(style.apply().fontVariations, const <ui.FontVariation>[]);
    expect(style.apply(fontVariations: const <ui.FontVariation>[ui.FontVariation('test', 100.0)]).fontVariations, const <ui.FontVariation>[ui.FontVariation('test', 100.0)]);
    expect(style.apply().textBaseline, TextBaseline.alphabetic);
    expect(style.apply(textBaseline: TextBaseline.ideographic).textBaseline, TextBaseline.ideographic);
    expect(style.apply().leadingDistribution, TextLeadingDistribution.even);
    expect(
      style.apply(leadingDistribution: TextLeadingDistribution.proportional).leadingDistribution,
      TextLeadingDistribution.proportional,
    );
  });

  test('TextStyle fontFamily and package', () {
    expect(const TextStyle(fontFamily: 'fontFamily', package: 'foo') != const TextStyle(fontFamily: 'fontFamily', package: 'bar'), true);
    expect(const TextStyle(fontFamily: 'fontFamily', package: 'foo').hashCode != const TextStyle(package: 'bar', fontFamily: 'fontFamily').hashCode, true);
    expect(const TextStyle(fontFamily: 'fontFamily').fontFamily, 'fontFamily');
    expect(const TextStyle(fontFamily: 'fontFamily').fontFamily, 'fontFamily');
    expect(const TextStyle(fontFamily: 'fontFamily').copyWith(package: 'bar').fontFamily, 'packages/bar/fontFamily');
    expect(const TextStyle(fontFamily: 'fontFamily', package: 'foo').fontFamily, 'packages/foo/fontFamily');
    expect(const TextStyle(fontFamily: 'fontFamily', package: 'foo').copyWith(package: 'bar').fontFamily, 'packages/bar/fontFamily');
    expect(const TextStyle().merge(const TextStyle(fontFamily: 'fontFamily', package: 'bar')).fontFamily, 'packages/bar/fontFamily');
    expect(const TextStyle().apply(fontFamily: 'fontFamily', package: 'foo').fontFamily, 'packages/foo/fontFamily');
    expect(const TextStyle(fontFamily: 'fontFamily', package: 'foo').apply(fontFamily: 'fontFamily', package: 'bar').fontFamily, 'packages/bar/fontFamily');
  });
}
