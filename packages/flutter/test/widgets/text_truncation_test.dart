// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'semantics_tester.dart';

// In the test font, every glyph (including the ellipsis) is a square whose
// width equals the font size.
const TextStyle _kStyle = TextStyle(fontSize: 10.0);
const String _kText = 'verylongusername@gmail.com'; // 26 glyphs, 260px wide.

// Elides the end of the local part of an email address, keeping the domain.
class _EmailTruncation extends TextTruncation {
  const _EmailTruncation();

  static int elideCount = 0;

  @override
  int maxLevel(String text) {
    final int at = text.indexOf('@');
    return at < 0 ? 0 : text.substring(0, at).characters.length;
  }

  @override
  List<TextElision> elide(String text, int level) {
    elideCount += 1;
    if (level == 0) {
      return const <TextElision>[];
    }
    final int at = text.indexOf('@');
    final Characters user = text.substring(0, at).characters;
    final int keep = user.take(user.length - level).string.length;
    return <TextElision>[TextElision(TextRange(start: keep, end: at))];
  }

  @override
  bool operator ==(Object other) => other is _EmailTruncation;

  @override
  int get hashCode => (_EmailTruncation).hashCode;
}

Widget _boilerplate({required double width, required Widget child}) {
  return Directionality(
    textDirection: TextDirection.ltr,
    child: Align(
      alignment: Alignment.topLeft,
      child: SizedBox(width: width, child: child),
    ),
  );
}

RenderParagraph _paragraph(WidgetTester tester) {
  return tester.renderObject<RenderParagraph>(find.byType(RichText));
}

void main() {
  testWidgets('Text truncates an email address before the @', (WidgetTester tester) async {
    await tester.pumpWidget(
      _boilerplate(
        width: 205,
        child: const Text(
          _kText,
          style: _kStyle,
          maxLines: 1,
          overflow: TextOverflow.truncate(_EmailTruncation()),
        ),
      ),
    );
    expect(_paragraph(tester).debugTruncatedText, 'verylongu…@gmail.com');
    expect(_paragraph(tester).didExceedMaxLines, isFalse);
    // The widget still exposes the original text.
    expect(find.text(_kText), findsOneWidget);
  });

  testWidgets('Text picks up truncation from DefaultTextStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      _boilerplate(
        width: 55,
        child: const DefaultTextStyle(
          style: _kStyle,
          maxLines: 1,
          overflow: TextOverflow.truncate(TextTruncation.middle()),
          child: Text('abcdefghij'),
        ),
      ),
    );
    expect(_paragraph(tester).debugTruncatedText, 'ab…ij');
  });

  testWidgets('Text picks up truncation from TextStyle.overflow', (WidgetTester tester) async {
    await tester.pumpWidget(
      _boilerplate(
        width: 55,
        child: const Text(
          'abcdefghij',
          maxLines: 1,
          style: TextStyle(fontSize: 10, overflow: TextOverflow.truncate(TextTruncation.start())),
        ),
      ),
    );
    expect(_paragraph(tester).debugTruncatedText, '…ghij');
  });

  testWidgets('Text re-truncates when its width changes', (WidgetTester tester) async {
    Widget build(double width) {
      return _boilerplate(
        width: width,
        child: const Text(
          'abcdefghij',
          style: _kStyle,
          maxLines: 1,
          overflow: TextOverflow.truncate(TextTruncation.end()),
        ),
      );
    }

    await tester.pumpWidget(build(55));
    expect(_paragraph(tester).debugTruncatedText, 'abcd…');
    await tester.pumpWidget(build(35));
    expect(_paragraph(tester).debugTruncatedText, 'ab…');
    await tester.pumpWidget(build(95));
    expect(_paragraph(tester).debugTruncatedText, 'abcdefgh…');
    await tester.pumpWidget(build(100));
    expect(_paragraph(tester).debugTruncatedText, isNull);
  });

  testWidgets('An equal truncation does not trigger relayout', (WidgetTester tester) async {
    Widget build() {
      // A new, non-const instance on every build.
      // ignore: prefer_const_constructors
      final overflow = TextOverflow.truncate(_EmailTruncation());
      return _boilerplate(
        width: 205,
        child: Text(_kText, style: _kStyle, maxLines: 1, overflow: overflow),
      );
    }

    await tester.pumpWidget(build());
    expect(_paragraph(tester).debugTruncatedText, 'verylongu…@gmail.com');
    _EmailTruncation.elideCount = 0;

    await tester.pumpWidget(build());
    expect(_EmailTruncation.elideCount, 0);
    expect(_paragraph(tester).debugTruncatedText, 'verylongu…@gmail.com');

    // Changing the truncation relayouts.
    await tester.pumpWidget(
      _boilerplate(
        width: 205,
        child: const Text(
          _kText,
          style: _kStyle,
          maxLines: 1,
          overflow: TextOverflow.truncate(TextTruncation.start()),
        ),
      ),
    );
    expect(_paragraph(tester).debugTruncatedText, '…gusername@gmail.com');
  });

  testWidgets('Semantics label is the original text', (WidgetTester tester) async {
    final semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      _boilerplate(
        width: 55,
        child: const Text(
          'abcdefghij',
          style: _kStyle,
          maxLines: 1,
          overflow: TextOverflow.truncate(TextTruncation.end()),
        ),
      ),
    );
    expect(_paragraph(tester).debugTruncatedText, 'abcd…');
    expect(semantics, includesNodeWith(label: 'abcdefghij'));
    semantics.dispose();
  });

  testWidgets('Diagnostics describe the overflow', (WidgetTester tester) async {
    const text = Text(
      'abcdefghij',
      maxLines: 1,
      overflow: TextOverflow.truncate(TextTruncation.end()),
    );
    expect(text.toDiagnosticsNode().toStringDeep(), contains('overflow: truncate'));
    expect(
      const Text('a', overflow: TextOverflow.ellipsis).toDiagnosticsNode().toStringDeep(),
      contains('overflow: ellipsis'),
    );
  });

  testWidgets('Truncated text can be selected in a SelectionArea', (WidgetTester tester) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    final selectionKey = GlobalKey<SelectableRegionState>();

    Widget build(double width) {
      return TestWidgetsApp(
        home: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: width,
            child: SelectableRegion(
              key: selectionKey,
              focusNode: focusNode,
              selectionControls: emptyTextSelectionControls,
              child: const Text(
                'abcdefghij',
                style: _kStyle,
                maxLines: 1,
                overflow: TextOverflow.truncate(TextTruncation.end()),
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(55));
    final RenderParagraph paragraph = _paragraph(tester);
    expect(paragraph.debugTruncatedText, 'abcd…');

    selectionKey.currentState!.selectAll();
    await tester.pump();
    expect(paragraph.selections, const <TextSelection>[
      TextSelection(baseOffset: 0, extentOffset: 5),
    ]);

    // Shrinking the text keeps the selection within the displayed text.
    await tester.pumpWidget(build(35));
    expect(paragraph.debugTruncatedText, 'ab…');
    expect(tester.takeException(), isNull);
    for (final TextSelection selection in paragraph.selections) {
      expect(selection.start, inInclusiveRange(0, 3));
      expect(selection.end, inInclusiveRange(0, 3));
    }
  });
}
