// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  group('selection registrar', () {
    Widget richText(
      SelectionRegistrar? registrar, {
      Key? key,
      Color color = const Color(0x660000FF),
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          key: key,
          selectionRegistrar: registrar,
          selectionColor: color,
          text: const TextSpan(
            text: 'hello ',
            children: <InlineSpan>[
              WidgetSpan(child: _InitCounter()),
              TextSpan(text: ' world'),
            ],
          ),
        ),
      );
    }

    setUp(() {
      _InitCounter.initCount = 0;
    });

    testWidgets('registers one grouped selectable and follows registrar changes', (
      WidgetTester tester,
    ) async {
      final a = _RecordingRegistrar();
      final b = _RecordingRegistrar();

      await tester.pumpWidget(richText(a));
      expect(a.selectables, hasLength(1));
      expect(b.selectables, isEmpty);

      await tester.pumpWidget(richText(b));
      expect(a.selectables, isEmpty);
      expect(b.selectables, hasLength(1));

      await tester.pumpWidget(richText(b, color: const Color(0x6600FF00)));
      expect(b.selectables, hasLength(1));
      // Changing between non-null registrars keeps the state of WidgetSpans.
      expect(_InitCounter.initCount, 1);

      await tester.pumpWidget(richText(null));
      expect(a.selectables, isEmpty);
      expect(b.selectables, isEmpty);

      await tester.pumpWidget(richText(a));
      expect(a.selectables, hasLength(1));

      await tester.pumpWidget(const SizedBox());
      expect(a.selectables, isEmpty);
    });

    testWidgets('moves its registration when reparented with a GlobalKey', (
      WidgetTester tester,
    ) async {
      final a = _RecordingRegistrar();
      final b = _RecordingRegistrar();
      final GlobalKey key = GlobalKey();

      await tester.pumpWidget(Column(children: <Widget>[richText(a, key: key)]));
      expect(a.selectables, hasLength(1));

      await tester.pumpWidget(
        Column(
          children: <Widget>[
            const SizedBox(),
            Padding(
              padding: const EdgeInsets.all(4),
              child: richText(b, key: key),
            ),
          ],
        ),
      );
      expect(a.selectables, isEmpty);
      expect(b.selectables, hasLength(1));
      expect(_InitCounter.initCount, 1);
    });
  });
}

class _RecordingRegistrar extends SelectionRegistrar {
  final Set<Selectable> selectables = <Selectable>{};

  @override
  void add(Selectable selectable) => selectables.add(selectable);

  @override
  void remove(Selectable selectable) => selectables.remove(selectable);
}

class _InitCounter extends StatefulWidget {
  const _InitCounter();

  static int initCount = 0;

  @override
  State<_InitCounter> createState() => _InitCounterState();
}

class _InitCounterState extends State<_InitCounter> {
  @override
  void initState() {
    super.initState();
    _InitCounter.initCount += 1;
  }

  @override
  Widget build(BuildContext context) => const SizedBox(width: 10, height: 10);
}
