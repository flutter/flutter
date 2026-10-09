// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

// Regression coverage for https://github.com/flutter/flutter/issues/54400.
void main() {
  for (final TextDirection direction in TextDirection.values) {
    for (final align in <TextAlign>[TextAlign.start, TextAlign.end, TextAlign.center]) {
      test('TextPainter preserves logical placeholder order with $direction and $align', () {
        final painter = TextPainter(
          textDirection: direction,
          textAlign: align,
          text: TextSpan(
            style: const TextStyle(fontFamily: 'Ahem', fontSize: 20),
            children: <InlineSpan>[
              const WidgetSpan(child: SizedBox()),
              TextSpan(
                text: direction == TextDirection.rtl ? '\u202a' : '\u202b',
                children: const <InlineSpan>[
                  WidgetSpan(child: SizedBox()),
                  WidgetSpan(child: SizedBox()),
                  TextSpan(text: '\u202c'),
                ],
              ),
              const WidgetSpan(child: SizedBox()),
            ],
          ),
        );
        addTearDown(painter.dispose);
        painter.setPlaceholderDimensions(<PlaceholderDimensions>[
          for (var i = 0; i < 4; i++)
            PlaceholderDimensions(
              size: Size(30.0 + 20 * i, 20),
              alignment: ui.PlaceholderAlignment.bottom,
            ),
        ]);
        for (final width in <double>[500, 300, 500]) {
          painter.layout(minWidth: width, maxWidth: width);
          final double shift = switch (align) {
            TextAlign.center => (width - 240) / 2,
            TextAlign.start => direction == TextDirection.rtl ? width - 240 : 0,
            TextAlign.end => direction == TextDirection.ltr ? width - 240 : 0,
            _ => throw StateError('Unexpected alignment'),
          };
          final visualOffsets = direction == TextDirection.ltr
              ? <double>[0, 100, 30, 150]
              : <double>[210, 90, 140, 0];
          final TextDirection embeddedDirection = direction == TextDirection.ltr
              ? TextDirection.rtl
              : TextDirection.ltr;
          const offsets = <int>[0, 2, 3, 5];
          final List<ui.TextBox> boxes = painter.inlinePlaceholderBoxes!;
          expect(boxes, hasLength(4));
          for (var i = 0; i < boxes.length; i++) {
            expect(boxes[i].left, shift + visualOffsets[i]);
            expect(boxes[i].toRect().size, Size(30.0 + 20 * i, 20));
            expect(boxes[i].direction, i == 1 || i == 2 ? embeddedDirection : direction);
            final ui.TextBox selectionBox = painter
                .getBoxesForSelection(
                  TextSelection(baseOffset: offsets[i], extentOffset: offsets[i] + 1),
                )
                .single;
            expect(boxes[i], selectionBox);
            _expectHitPositions(painter, boxes[i], offsets[i]);
          }
        }
      });
    }

    test(
      'TextPainter keeps placeholder identities across soft and hard line breaks: $direction',
      () {
        final painter = TextPainter(
          textDirection: direction,
          text: const TextSpan(
            style: TextStyle(fontFamily: 'Ahem', fontSize: 10),
            children: <InlineSpan>[
              WidgetSpan(child: SizedBox()),
              TextSpan(
                children: <InlineSpan>[
                  WidgetSpan(child: SizedBox()),
                  TextSpan(text: '\n'),
                  WidgetSpan(child: SizedBox()),
                ],
              ),
              WidgetSpan(child: SizedBox()),
            ],
          ),
        );
        addTearDown(painter.dispose);
        painter.setPlaceholderDimensions(<PlaceholderDimensions>[
          for (var i = 0; i < 4; i++)
            PlaceholderDimensions(
              size: Size(20.0 + 10 * i, 20),
              alignment: ui.PlaceholderAlignment.bottom,
            ),
        ]);
        for (final width in <double>[200, 50, 200]) {
          painter.layout(minWidth: width, maxWidth: width);
          final List<ui.TextBox> boxes = painter.inlinePlaceholderBoxes!;
          expect(boxes, hasLength(4));
          expect(painter.computeLineMetrics(), hasLength(width == 50 ? 3 : 2));
          const offsets = <int>[0, 1, 3, 4];
          final logicalLefts = <double>[0, 20, 0, if (width == 50) 0 else 40];
          for (var i = 0; i < boxes.length; i++) {
            final double placeholderWidth = 20.0 + 10 * i;
            expect(
              boxes[i].left,
              direction == TextDirection.ltr
                  ? logicalLefts[i]
                  : width - logicalLefts[i] - placeholderWidth,
            );
            expect(boxes[i].toRect().size, Size(placeholderWidth, 20));
            expect(boxes[i].direction, direction);
            expect(
              boxes[i],
              painter
                  .getBoxesForSelection(
                    TextSelection(baseOffset: offsets[i], extentOffset: offsets[i] + 1),
                  )
                  .single,
            );
            _expectHitPositions(painter, boxes[i], offsets[i]);
          }
          expect(boxes[0].top, boxes[1].top);
          expect(boxes[2].top, greaterThan(boxes[1].top));
          expect(boxes[3].top, width == 50 ? greaterThan(boxes[2].top) : boxes[2].top);
        }
      },
    );
  }
}

void _expectHitPositions(TextPainter painter, ui.TextBox box, int offset) {
  final Rect rect = box.toRect();
  final double startX = box.direction == TextDirection.ltr
      ? rect.left + rect.width / 4
      : rect.right - rect.width / 4;
  expect(painter.getPositionForOffset(Offset(startX, rect.center.dy)).offset, offset);
  expect(
    painter.getPositionForOffset(Offset(rect.left + rect.right - startX, rect.center.dy)).offset,
    offset + 1,
  );
}
