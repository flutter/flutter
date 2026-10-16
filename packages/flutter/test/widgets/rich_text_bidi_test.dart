// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression coverage for https://github.com/flutter/flutter/issues/54400.
// Inline children are stored in logical order, even when bidi layout places
// them in a different visual order.
void main() {
  for (final useTextRich in <bool>[false, true]) {
    final widgetName = useTextRich ? 'Text.rich' : 'RichText';
    for (final equalWidths in <bool>[false, true]) {
      for (final TextDirection initialDirection in TextDirection.values) {
        testWidgets(
          '$widgetName preserves WidgetSpan identity through reflow and direction changes '
          '(equal widths: $equalWidths, $initialDirection)',
          (WidgetTester tester) async {
            final widths = equalWidths ? <double>[30, 30, 30] : <double>[30, 50, 70];
            final keys = List<GlobalKey>.generate(3, (int index) => GlobalKey());
            final tapped = <int>[];
            final text = TextSpan(
              children: <InlineSpan>[
                for (var i = 0; i < keys.length; i++) _widgetSpan(keys[i], widths[i], i, tapped),
              ],
            );
            final TextDirection opposite = initialDirection == TextDirection.ltr
                ? TextDirection.rtl
                : TextDirection.ltr;
            RenderParagraph? originalParagraph;
            for (final direction in <TextDirection>[initialDirection, opposite, initialDirection]) {
              for (final width in <double>[500, widths[0] + widths[1], 500]) {
                await tester.pumpWidget(_host(text, direction, width, useTextRich: useTextRich));
                final RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
                originalParagraph ??= paragraph;
                expect(paragraph, same(originalParagraph));
                final Offset origin = tester.getTopLeft(find.byType(RichText));
                final List<Rect> rects = keys
                    .map((GlobalKey key) => tester.getRect(find.byKey(key)).shift(-origin))
                    .toList();
                final bool wrapped = width < 500;
                final expectedLefts = <double>[
                  0,
                  widths[0],
                  if (wrapped) 0 else widths[0] + widths[1],
                ];
                for (var i = 0; i < rects.length; i++) {
                  final double left = direction == TextDirection.ltr
                      ? expectedLefts[i]
                      : width - expectedLefts[i] - widths[i];
                  expect(rects[i].left, left, reason: 'widget $i, width $width, $direction');
                  expect(rects[i].size, Size(widths[i], 20));
                  _expectSelectionAndHitPositions(paragraph, rects[i], i, direction);
                }
                expect(rects[0].top, rects[1].top);
                expect(rects[2].top, wrapped ? greaterThan(rects[1].top) : rects[1].top);
                tapped.clear();
                for (final rect in rects) {
                  await tester.tapAt(origin + rect.center);
                }
                expect(tapped, <int>[0, 1, 2]);
              }
            }
          },
        );
      }
    }

    for (final TextDirection direction in TextDirection.values) {
      testWidgets(
        '$widgetName maps nested opposite-direction WidgetSpans to their own boxes: $direction',
        (WidgetTester tester) async {
          final keys = List<GlobalKey>.generate(4, (int index) => GlobalKey());
          final tapped = <int>[];
          final text = TextSpan(
            style: const TextStyle(fontFamily: 'Ahem', fontSize: 20),
            children: <InlineSpan>[
              _widgetSpan(keys[0], 30, 0, tapped),
              TextSpan(
                text: direction == TextDirection.rtl ? '\u202a' : '\u202b',
                style: const TextStyle(color: Color(0xffff0000)),
                children: <InlineSpan>[
                  TextSpan(
                    children: <InlineSpan>[
                      _widgetSpan(keys[1], 50, 1, tapped),
                      TextSpan(
                        text: '',
                        children: <InlineSpan>[_widgetSpan(keys[2], 70, 2, tapped)],
                      ),
                    ],
                  ),
                  const TextSpan(text: '\u202c'),
                ],
              ),
              _widgetSpan(keys[3], 90, 3, tapped),
            ],
          );
          await tester.pumpWidget(_host(text, direction, 500, useTextRich: useTextRich));
          final RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
          final Offset origin = tester.getTopLeft(find.byType(RichText));
          final expectedLefts = direction == TextDirection.rtl
              ? <double>[470, 350, 400, 260]
              : <double>[0, 100, 30, 150];
          const offsets = <int>[0, 2, 3, 5];
          for (var i = 0; i < keys.length; i++) {
            final Rect rect = tester.getRect(find.byKey(keys[i])).shift(-origin);
            expect(rect.left, expectedLefts[i], reason: 'widget $i');
            expect(rect.width, 30 + 20 * i);
            _expectSelectionAndHitPositions(
              paragraph,
              rect,
              offsets[i],
              i == 1 || i == 2
                  ? direction == TextDirection.ltr
                        ? TextDirection.rtl
                        : TextDirection.ltr
                  : direction,
            );
            await tester.tapAt(origin + rect.center);
          }
          expect(tapped, <int>[0, 1, 2, 3]);
        },
      );

      for (final ellipsis in <bool>[false, true]) {
        testWidgets(
          '$widgetName hides and restores the correct bidi children (ellipsis: $ellipsis, $direction)',
          (WidgetTester tester) async {
            final keys = List<GlobalKey>.generate(3, (int index) => GlobalKey());
            final tapped = <int>[];
            final text = TextSpan(
              text: direction == TextDirection.rtl ? 'אב ' : 'AB ',
              style: const TextStyle(fontFamily: 'Ahem', fontSize: 20),
              children: <InlineSpan>[
                for (var i = 0; i < keys.length; i++)
                  _widgetSpan(keys[i], 30.0 + 20 * i, i, tapped),
              ],
            );
            RenderParagraph? originalParagraph;
            for (final width in <double>[500, 170, 500]) {
              await tester.pumpWidget(
                _host(
                  text,
                  direction,
                  width,
                  useTextRich: useTextRich,
                  maxLines: 1,
                  overflow: ellipsis ? TextOverflow.ellipsis : TextOverflow.clip,
                ),
              );
              final RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
              originalParagraph ??= paragraph;
              expect(paragraph, same(originalParagraph));
              final truncated = width == 170;
              expect(paragraph.didExceedMaxLines, truncated);
              final Offset origin = tester.getTopLeft(find.byType(RichText));
              RenderBox? child = paragraph.firstChild;
              final visibleRects = <Rect>[];
              tapped.clear();
              for (var i = 0; i < keys.length; i++) {
                final parentData = child!.parentData! as TextParentData;
                if (truncated && i == 2) {
                  expect(parentData.offset, isNull);
                  if (!ellipsis) {
                    expect(
                      paragraph.getBoxesForSelection(
                        const TextSelection(baseOffset: 5, extentOffset: 6),
                      ),
                      isEmpty,
                    );
                  }
                } else {
                  expect(parentData.offset, isNotNull);
                  final Rect rect = tester.getRect(find.byKey(keys[i])).shift(-origin);
                  visibleRects.add(rect);
                  expect(rect.size, Size(30.0 + 20 * i, 20));
                  // Ellipsized selection and text-position queries have a
                  // separate SkParagraph bug involving the synthetic ellipsis
                  // run. Check those queries before and after truncation; here
                  // verify the real children's geometry, visibility and taps.
                  if (!ellipsis || !truncated) {
                    _expectSelectionAndHitPositions(paragraph, rect, i + 3, direction);
                  }
                  await tester.tapAt(origin + rect.center);
                }
                child = parentData.nextSibling;
              }
              expect(visibleRects, hasLength(truncated ? 2 : 3));
              for (var i = 0; i < visibleRects.length - 1; i++) {
                expect(visibleRects[i].top, visibleRects[i + 1].top);
                expect(
                  visibleRects[i].left < visibleRects[i + 1].left,
                  direction == TextDirection.ltr,
                );
              }
              expect(tapped, truncated ? <int>[0, 1] : <int>[0, 1, 2]);
            }
          },
        );
      }
    }
  }

  const samples = <String, (String, String, TextDirection)>{
    'Latin': ('AB', 'CD', TextDirection.ltr),
    'Hebrew': ('אב', 'גד', TextDirection.rtl),
    'Arabic': ('نص', 'نص', TextDirection.rtl),
  };
  for (final sample in samples.entries) {
    for (final TextDirection direction in TextDirection.values) {
      for (final PlaceholderAlignment alignment in PlaceholderAlignment.values) {
        testWidgets(
          'styled ${sample.key} TextSpans and inline Text widgets: $direction, $alignment',
          (WidgetTester tester) async {
            final tapped = <int>[];
            final prefixTap = TapGestureRecognizer()..onTap = () => tapped.add(0);
            final suffixTap = TapGestureRecognizer()..onTap = () => tapped.add(3);
            addTearDown(prefixTap.dispose);
            addTearDown(suffixTap.dispose);
            final keys = List<GlobalKey>.generate(2, (int index) => GlobalKey());
            WidgetSpan inlineText(int index) => WidgetSpan(
              alignment: alignment,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                key: keys[index],
                behavior: HitTestBehavior.opaque,
                onTap: () => tapped.add(index + 1),
                child: SizedBox(
                  width: 20.0 + 10 * index,
                  height: 30,
                  child: Baseline(
                    baseline: 15,
                    baselineType: TextBaseline.alphabetic,
                    // The direction of text inside a widget must not affect the
                    // bidi ordering of placeholders in its enclosing paragraph.
                    child: Directionality(
                      textDirection: direction == TextDirection.ltr
                          ? TextDirection.rtl
                          : TextDirection.ltr,
                      child: Text(
                        '$index',
                        style: const TextStyle(fontFamily: 'Ahem', fontSize: 10),
                      ),
                    ),
                  ),
                ),
              ),
            );
            final text = TextSpan(
              style: const TextStyle(fontFamily: 'Ahem', fontSize: 10),
              text: sample.value.$1,
              recognizer: prefixTap,
              children: <InlineSpan>[
                TextSpan(
                  style: const TextStyle(color: Color(0xffff0000)),
                  children: <InlineSpan>[
                    inlineText(0),
                    TextSpan(text: '', children: <InlineSpan>[inlineText(1)]),
                  ],
                ),
                TextSpan(
                  text: sample.value.$2,
                  style: const TextStyle(fontSize: 20),
                  recognizer: suffixTap,
                ),
              ],
            );
            await tester.pumpWidget(_host(text, direction, 500, useTextRich: false));
            final Finder richText = find.byType(RichText).first;
            final RenderParagraph paragraph = tester.renderObject(richText);
            final Offset origin = tester.getTopLeft(richText);
            Rect textRect(int start, int end) => paragraph
                .getBoxesForSelection(TextSelection(baseOffset: start, extentOffset: end))
                .single
                .toRect();
            final Rect prefix = textRect(0, 2);
            final Rect suffix = textRect(4, 6);
            final List<Rect> rects = keys
                .map((GlobalKey key) => tester.getRect(find.byKey(key)).shift(-origin))
                .toList();
            final readingOrder = <Rect>[prefix, ...rects, suffix];
            for (var i = 0; i < readingOrder.length - 1; i++) {
              expect(
                sample.value.$3 == TextDirection.ltr ? readingOrder[i].right : readingOrder[i].left,
                closeTo(
                  sample.value.$3 == TextDirection.ltr
                      ? readingOrder[i + 1].left
                      : readingOrder[i + 1].right,
                  0.001,
                ),
              );
            }
            for (var i = 0; i < rects.length; i++) {
              expect(rects[i].size, Size(20.0 + 10 * i, 30));
              _expectSelectionAndHitPositions(paragraph, rects[i], i + 2, sample.value.$3);
            }
            for (final rect in readingOrder) {
              await tester.tapAt(origin + rect.center);
            }
            expect(tapped, <int>[0, 1, 2, 3]);
          },
        );
      }
    }
  }

  const fragments = <(String, TextDirection)>[
    ('AB', TextDirection.ltr),
    ('אב', TextDirection.rtl),
    ('نص', TextDirection.rtl),
    ('ми', TextDirection.ltr),
  ];
  const rows = <List<int>>[
    <int>[0, 1, 2, 3], // LTR, RTL, RTL, LTR.
    <int>[2, 3, 1, 0], // RTL, LTR, RTL, LTR.
    <int>[3, 2, 0, 1], // LTR, RTL, LTR, RTL.
  ];
  // Widget indices in visual order, from left to right, for each complete row.
  // These expectations come from the strong text surrounding each placeholder,
  // rather than from the direction or geometry returned by the paragraph.
  const ltrVisualOrder = <List<int>>[
    <int>[0, 1, 5, 4, 3, 2, 6, 7],
    <int>[1, 0, 2, 3, 5, 4, 6, 7],
    <int>[0, 1, 3, 2, 4, 5, 7, 6],
  ];
  const rtlVisualOrder = <List<int>>[
    <int>[6, 7, 5, 4, 3, 2, 0, 1],
    <int>[6, 7, 5, 4, 2, 3, 1, 0],
    <int>[7, 6, 4, 5, 3, 2, 0, 1],
  ];
  for (final TextDirection direction in TextDirection.values) {
    for (final hardBreaks in <bool>[false, true]) {
      for (final useTextRich in <bool>[false, true]) {
        final widgetName = useTextRich ? 'Text.rich' : 'RichText';
        testWidgets('$widgetName preserves WidgetSpan order in mixed-script text across reflow '
            '($direction, hard breaks: $hardBreaks)', (WidgetTester tester) async {
          final keys = <GlobalKey>[];
          final offsets = <int>[];
          final scriptDirections = <TextDirection>[];
          final tapped = <int>[];
          final spans = <InlineSpan>[];
          final int rowCount = hardBreaks ? rows.length : 1;
          var offset = 0;
          for (var row = 0; row < rowCount; row++) {
            if (row > 0) {
              spans.add(const TextSpan(text: '\n'));
              offset++;
            }
            for (var column = 0; column < rows[row].length; column++) {
              if (column > 0) {
                spans.add(const TextSpan(text: ' '));
                offset++;
              }
              final (String word, TextDirection scriptDirection) = fragments[rows[row][column]];
              final prefix = '$word ';
              final middle = ' $word ';
              final suffix = ' $word';
              WidgetSpan addWidget() {
                final int index = keys.length;
                final GlobalKey key = GlobalKey();
                keys.add(key);
                offsets.add(offset++);
                scriptDirections.add(scriptDirection);
                return _widgetSpan(key, 20.0 + 10 * (index % 3), index, tapped);
              }

              offset += prefix.length;
              final WidgetSpan first = addWidget();
              offset += middle.length;
              final WidgetSpan second = addWidget();
              offset += suffix.length;
              spans.add(
                TextSpan(
                  text: prefix,
                  children: <InlineSpan>[
                    first,
                    TextSpan(
                      text: middle,
                      style: const TextStyle(fontSize: 14, color: Color(0xffff0000)),
                    ),
                    TextSpan(
                      children: <InlineSpan>[
                        second,
                        TextSpan(text: suffix),
                      ],
                    ),
                  ],
                ),
              );
            }
          }
          final text = TextSpan(
            style: const TextStyle(fontFamily: 'Ahem', fontSize: 10),
            children: spans,
          );
          expect(text.toPlainText().length, offset);
          RenderParagraph? originalParagraph;
          for (final width in <double>[750, 150, 750]) {
            await tester.pumpWidget(_host(text, direction, width, useTextRich: useTextRich));
            final RenderParagraph paragraph = tester.renderObject(find.byType(RichText));
            originalParagraph ??= paragraph;
            expect(paragraph, same(originalParagraph));
            final Offset origin = tester.getTopLeft(find.byType(RichText));
            final List<Rect> rects = keys
                .map((GlobalKey key) => tester.getRect(find.byKey(key)).shift(-origin))
                .toList();
            if (width == 750) {
              for (var row = 0; row < rowCount; row++) {
                final indices = List<int>.generate(8, (int index) => row * 8 + index)
                  ..sort((int a, int b) => rects[a].left.compareTo(rects[b].left));
                final List<int> expected = direction == TextDirection.ltr
                    ? ltrVisualOrder[row]
                    : rtlVisualOrder[row];
                expect(indices, expected.map((int index) => row * 8 + index));
                for (final index in indices) {
                  expect(rects[index].top, rects[row * 8].top);
                }
                if (row > 0) {
                  expect(rects[row * 8].top, greaterThan(rects[(row - 1) * 8].top));
                }
              }
            } else {
              // This is a genuinely multiline layout, including soft wraps
              // within the mixed-direction rows, not just the explicit '\n'.
              expect(rects.map((Rect rect) => rect.top).toSet().length, greaterThan(rowCount));
            }
            _expectMixedScriptOrderOnEachLine(rects, scriptDirections, direction);
            tapped.clear();
            for (var i = 0; i < rects.length; i++) {
              expect(rects[i].size, Size(20.0 + 10 * (i % 3), 20));
              _expectSelectionAndHitPositions(paragraph, rects[i], offsets[i], scriptDirections[i]);
              if (i.isEven && rects[i].top == rects[i + 1].top) {
                expect(rects[i].left < rects[i + 1].left, scriptDirections[i] == TextDirection.ltr);
              }
              await tester.tapAt(origin + rects[i].center);
            }
            expect(tapped, List<int>.generate(keys.length, (int index) => index));
          }
        });
      }
    }
  }
}

void _expectMixedScriptOrderOnEachLine(
  List<Rect> rects,
  List<TextDirection> scriptDirections,
  TextDirection paragraphDirection,
) {
  final lines = <int, List<int>>{};
  for (var i = 0; i < rects.length; i++) {
    lines.putIfAbsent(rects[i].top.round(), () => <int>[]).add(i);
  }
  for (final List<int> logicalIndices in lines.values) {
    // Each placeholder is surrounded by strong text of its script direction.
    // An LTR paragraph reverses its RTL groups. An RTL paragraph reverses the
    // whole line, then restores the reading order within its LTR groups.
    final expected = <int>[
      if (paragraphDirection == TextDirection.rtl)
        ...logicalIndices.reversed
      else
        ...logicalIndices,
    ];
    final TextDirection reverseGroups = paragraphDirection == TextDirection.ltr
        ? TextDirection.rtl
        : TextDirection.ltr;
    for (var start = 0; start < expected.length;) {
      int end = start + 1;
      if (scriptDirections[expected[start]] == reverseGroups) {
        while (end < expected.length && scriptDirections[expected[end]] == reverseGroups) {
          end++;
        }
        expected.replaceRange(start, end, expected.sublist(start, end).reversed);
      }
      start = end;
    }
    final actual = List<int>.of(logicalIndices)
      ..sort((int a, int b) => rects[a].left.compareTo(rects[b].left));
    expect(
      actual,
      expected,
      reason: 'visual WidgetSpan order on the line at ${rects[actual.first].top}',
    );
  }
}

WidgetSpan _widgetSpan(GlobalKey key, double width, int index, List<int> tapped) {
  return WidgetSpan(
    child: GestureDetector(
      key: key,
      behavior: HitTestBehavior.opaque,
      onTap: () => tapped.add(index),
      child: SizedBox(width: width, height: 20),
    ),
  );
}

Widget _host(
  InlineSpan text,
  TextDirection direction,
  double width, {
  required bool useTextRich,
  int? maxLines,
  TextOverflow overflow = TextOverflow.clip,
}) {
  return Directionality(
    textDirection: direction,
    child: Center(
      child: SizedBox(
        width: width,
        child: useTextRich
            ? Text.rich(text, maxLines: maxLines, overflow: overflow)
            : RichText(text: text, maxLines: maxLines, overflow: overflow),
      ),
    ),
  );
}

void _expectSelectionAndHitPositions(
  RenderParagraph paragraph,
  Rect widgetRect,
  int offset,
  TextDirection direction,
) {
  final TextBox box = paragraph
      .getBoxesForSelection(TextSelection(baseOffset: offset, extentOffset: offset + 1))
      .single;
  expect(box.toRect(), widgetRect, reason: 'selection at $offset belongs to its inline widget');
  expect(box.direction, direction);
  final double startX = direction == TextDirection.ltr
      ? widgetRect.left + widgetRect.width / 4
      : widgetRect.right - widgetRect.width / 4;
  expect(
    paragraph.getPositionForOffset(Offset(startX, widgetRect.center.dy)).offset,
    offset,
    reason: 'leading half of placeholder at $offset',
  );
  expect(
    paragraph
        .getPositionForOffset(
          Offset(widgetRect.left + widgetRect.right - startX, widgetRect.center.dy),
        )
        .offset,
    offset + 1,
    reason: 'trailing half of placeholder at $offset',
  );
}
