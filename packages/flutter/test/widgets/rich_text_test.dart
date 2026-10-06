// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const languages = <String, List<(String, TextDirection)>>{
    'Russian': <(String, TextDirection)>[('мир', TextDirection.ltr)],
    'Arabic': <(String, TextDirection)>[('نص', TextDirection.rtl)],
    'Hebrew': <(String, TextDirection)>[('עם', TextDirection.rtl)],
    'mixed Russian, Arabic and Hebrew': <(String, TextDirection)>[
      ('мир', TextDirection.ltr),
      ('نص', TextDirection.rtl),
      ('עם', TextDirection.rtl),
    ],
  };
  for (final sample in languages.entries) {
    for (final TextDirection direction in TextDirection.values) {
      testWidgets('${sample.key} WidgetSpans preserve script order and hit targets: $direction', (
        WidgetTester tester,
      ) async {
        final keys = <GlobalKey>[];
        final tapped = <int>[];
        final spans = <InlineSpan>[];
        for (final (String word, TextDirection _) in sample.value) {
          for (var i = 0; i < 3; i++) {
            spans.add(TextSpan(text: '$word '));
            if (i < 2) {
              final int index = keys.length;
              final GlobalKey key = GlobalKey();
              keys.add(key);
              spans.add(
                WidgetSpan(
                  child: GestureDetector(
                    key: key,
                    behavior: HitTestBehavior.opaque,
                    onTap: () => tapped.add(index),
                    child: SizedBox(width: 20.0 + 10 * index, height: 20),
                  ),
                ),
              );
            }
          }
        }
        for (final width in <double>[800, 80, 800]) {
          await tester.pumpWidget(
            Directionality(
              textDirection: direction,
              child: Center(
                child: SizedBox(
                  width: width,
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(fontFamily: 'Ahem', fontSize: 10),
                      children: spans,
                    ),
                  ),
                ),
              ),
            ),
          );
          final List<Rect> rects = keys
              .map((GlobalKey key) => tester.getRect(find.byKey(key)))
              .toList();
          tapped.clear();
          for (var i = 0; i < rects.length; i++) {
            expect(rects[i].width, 20.0 + 10 * i);
            if (width == 800 && i.isEven) {
              expect(rects[i].top, rects[i + 1].top);
              expect(
                rects[i].left < rects[i + 1].left,
                sample.value[i ~/ 2].$2 == TextDirection.ltr,
              );
            }
            await tester.tapAt(rects[i].center);
          }
          expect(tapped, List<int>.generate(keys.length, (int index) => index));
        }
      });
    }
  }

  testWidgets('RTL WidgetSpans keep their positions and hit targets after reflow', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/54400.
    final keys = List<GlobalKey>.generate(3, (int index) => GlobalKey());
    final tapped = <int>[];
    for (final width in <double>[500, 80, 500]) {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.rtl,
          child: Center(
            child: SizedBox(
              width: width,
              child: RichText(
                text: TextSpan(
                  children: <InlineSpan>[
                    for (var i = 0; i < keys.length; i++)
                      WidgetSpan(
                        child: GestureDetector(
                          key: keys[i],
                          behavior: HitTestBehavior.opaque,
                          onTap: () => tapped.add(i),
                          child: SizedBox(width: 30.0 + 20 * i, height: 20),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      final List<Rect> rects = keys
          .map((GlobalKey key) => tester.getRect(find.byKey(key)))
          .toList();
      expect(rects[0].top, rects[1].top);
      expect(rects[0].left, greaterThan(rects[1].left));
      if (width == 80) {
        expect(rects[2].top, greaterThan(rects[1].top));
        expect(rects[2].right, rects[0].right);
      } else {
        expect(rects[2].top, rects[1].top);
        expect(rects[1].left, greaterThan(rects[2].left));
      }
      tapped.clear();
      for (var i = 0; i < rects.length; i++) {
        expect(rects[i].width, 30.0 + 20 * i);
        await tester.tapAt(rects[i].center);
      }
      expect(tapped, <int>[0, 1, 2]);
    }
  });

  testWidgets('RTL Arabic text positions WidgetSpans in reading order', (
    WidgetTester tester,
  ) async {
    final keys = List<GlobalKey>.generate(3, (int index) => GlobalKey());
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: SizedBox(
            width: 800,
            child: Text.rich(
              TextSpan(
                text: 'هذا اختبار',
                style: const TextStyle(fontSize: 20),
                children: <InlineSpan>[
                  WidgetSpan(child: SizedBox(key: keys[0], width: 30, height: 20)),
                  const TextSpan(text: ' و '),
                  WidgetSpan(child: SizedBox(key: keys[1], width: 50, height: 20)),
                  const TextSpan(text: ' ثم '),
                  WidgetSpan(child: SizedBox(key: keys[2], width: 70, height: 20)),
                  const TextSpan(text: ' ، لكنه معطل'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final List<Rect> rects = keys.map((GlobalKey key) => tester.getRect(find.byKey(key))).toList();
    expect(rects[0].top, rects[1].top);
    expect(rects[1].top, rects[2].top);
    expect(rects[0].left, greaterThan(rects[1].left));
    expect(rects[1].left, greaterThan(rects[2].left));
  });

  testWidgets('RichText with recognizers without handlers does not throw', (
    WidgetTester tester,
  ) async {
    final recognizer1 = TapGestureRecognizer();
    addTearDown(recognizer1.dispose);
    final recognizer2 = LongPressGestureRecognizer();
    addTearDown(recognizer2.dispose);
    final recognizer3 = DoubleTapGestureRecognizer();
    addTearDown(recognizer3.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(
            text: 'root',
            children: <InlineSpan>[
              TextSpan(text: 'one', recognizer: recognizer1),
              TextSpan(text: 'two', recognizer: recognizer2),
              TextSpan(text: 'three', recognizer: recognizer3),
            ],
          ),
        ),
      ),
    );

    expect(
      tester.getSemantics(find.byType(RichText)),
      matchesSemantics(
        children: <Matcher>[
          matchesSemantics(label: 'root'),
          matchesSemantics(label: 'one'),
          matchesSemantics(label: 'two'),
          matchesSemantics(label: 'three'),
        ],
      ),
    );
  });

  testWidgets('TextSpan Locale works', (WidgetTester tester) async {
    final recognizer1 = TapGestureRecognizer();
    addTearDown(recognizer1.dispose);
    final recognizer2 = DoubleTapGestureRecognizer();
    addTearDown(recognizer2.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(
            text: 'root',
            locale: const Locale('es', 'MX'),
            children: <InlineSpan>[
              TextSpan(text: 'one', recognizer: recognizer1),
              const WidgetSpan(child: SizedBox()),
              TextSpan(text: 'three', recognizer: recognizer2),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(RichText)),
      matchesSemantics(
        children: <Matcher>[
          matchesSemantics(
            attributedLabel: AttributedString(
              'root',
              attributes: <StringAttribute>[
                LocaleStringAttribute(
                  range: const TextRange(start: 0, end: 4),
                  locale: const Locale('es', 'MX'),
                ),
              ],
            ),
          ),
          matchesSemantics(
            attributedLabel: AttributedString(
              'one',
              attributes: <StringAttribute>[
                LocaleStringAttribute(
                  range: const TextRange(start: 0, end: 3),
                  locale: const Locale('es', 'MX'),
                ),
              ],
            ),
          ),
          matchesSemantics(
            attributedLabel: AttributedString(
              'three',
              attributes: <StringAttribute>[
                LocaleStringAttribute(
                  range: const TextRange(start: 0, end: 5),
                  locale: const Locale('es', 'MX'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('TextSpan spellOut works', (WidgetTester tester) async {
    final recognizer1 = TapGestureRecognizer();
    addTearDown(recognizer1.dispose);
    final recognizer2 = DoubleTapGestureRecognizer();
    addTearDown(recognizer2.dispose);

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(
            text: 'root',
            spellOut: true,
            children: <InlineSpan>[
              TextSpan(text: 'one', recognizer: recognizer1),
              const WidgetSpan(child: SizedBox()),
              TextSpan(text: 'three', recognizer: recognizer2),
            ],
          ),
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(RichText)),
      matchesSemantics(
        children: <Matcher>[
          matchesSemantics(
            attributedLabel: AttributedString(
              'root',
              attributes: <StringAttribute>[
                SpellOutStringAttribute(range: const TextRange(start: 0, end: 4)),
              ],
            ),
          ),
          matchesSemantics(
            attributedLabel: AttributedString(
              'one',
              attributes: <StringAttribute>[
                SpellOutStringAttribute(range: const TextRange(start: 0, end: 3)),
              ],
            ),
          ),
          matchesSemantics(
            attributedLabel: AttributedString(
              'three',
              attributes: <StringAttribute>[
                SpellOutStringAttribute(range: const TextRange(start: 0, end: 5)),
              ],
            ),
          ),
        ],
      ),
    );
  });

  testWidgets('WidgetSpan calculate correct intrinsic heights', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ColoredBox(
            color: const Color(0xff00ff00),
            child: IntrinsicHeight(
              child: RichText(
                text: const TextSpan(
                  children: <InlineSpan>[
                    TextSpan(text: 'Start\n', style: TextStyle(height: 1.0, fontSize: 16)),
                    WidgetSpan(child: Row(children: <Widget>[SizedBox(height: 16, width: 16)])),
                    TextSpan(text: 'End', style: TextStyle(height: 1.0, fontSize: 16)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    expect(tester.getSize(find.byType(IntrinsicHeight)).height, 3 * 16);
  });

  testWidgets('RichText implements debugFillProperties', (WidgetTester tester) async {
    final builder = DiagnosticPropertiesBuilder();
    RichText(
      text: const TextSpan(text: 'rich text'),
      textAlign: TextAlign.center,
      textDirection: TextDirection.rtl,
      softWrap: false,
      overflow: TextOverflow.ellipsis,
      textScaleFactor: 1.3,
      maxLines: 1,
      locale: const Locale('zh', 'HK'),
      strutStyle: const StrutStyle(fontSize: 16),
      textWidthBasis: TextWidthBasis.longestLine,
      textHeightBehavior: const TextHeightBehavior(applyHeightToFirstAscent: false),
      hyphens: Hyphens.hidden,
    ).debugFillProperties(builder);

    final List<String> description = builder.properties
        .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
        .map((DiagnosticsNode node) => node.toString())
        .toList();

    expect(
      description,
      unorderedMatches(<Matcher>[
        contains('textAlign: center'),
        contains('textDirection: rtl'),
        contains('softWrap: no wrapping except at line break characters'),
        contains('overflow: ellipsis'),
        contains('textScaler: linear (1.3x)'),
        contains('maxLines: 1'),
        contains('textWidthBasis: longestLine'),
        contains('text: "rich text"'),
        contains('locale: zh_HK'),
        allOf(startsWith('strutStyle: StrutStyle('), contains('size: 16.0')),
        allOf(
          startsWith('textHeightBehavior: TextHeightBehavior('),
          contains('applyHeightToFirstAscent: false'),
          contains('applyHeightToLastDescent: true'),
        ),
        contains('hyphens: hidden'),
      ]),
    );
  });

  testWidgets('RichText propagates devicePixelRatio', (WidgetTester tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 3.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RichText(text: const TextSpan(text: 'Hello')),
        ),
      ),
    );

    RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
    expect(paragraph.devicePixelRatio, 3.0);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(devicePixelRatio: 4.0),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: RichText(text: const TextSpan(text: 'Hello')),
        ),
      ),
    );

    paragraph = tester.renderObject(find.byType(RichText));
    expect(paragraph.devicePixelRatio, 4.0);
  });

  testWidgets('RichText propagates devicePixelRatio from View', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(text: const TextSpan(text: 'Hello')),
      ),
    );

    RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
    expect(paragraph.devicePixelRatio, 3.0);

    tester.view.devicePixelRatio = 4.0;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(text: const TextSpan(text: 'Hello')),
      ),
    );

    paragraph = tester.renderObject(find.byType(RichText));
    expect(paragraph.devicePixelRatio, 4.0);
  });

  testWidgets('RichText defaults to 1.0 devicePixelRatio when no View or MediaQuery is present', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      RawView(
        view: tester.view,
        child: LookupBoundary(
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RichText(text: const TextSpan(text: 'Hello')),
          ),
        ),
      ),
      wrapWithView: false,
    );

    final RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
    expect(paragraph.devicePixelRatio, 1.0);
  });

  testWidgets('RichText does not crash at zero area', (WidgetTester tester) async {
    tester.view.physicalSize = Size.zero;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RichText(text: const TextSpan(text: 'text')),
        ),
      ),
    );
    expect(tester.getSize(find.byType(RichText)), Size.zero);
  });
}
