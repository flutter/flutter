// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';

// This file contains tests for the deprecated TextSpan.recognizer from various files.
// ignore: deprecated_member_use

void main() {
  testWidgets('Can tap a hyperlink', (WidgetTester tester) async {
    bool didTapLeft = false;
    final TapGestureRecognizer tapLeft = TapGestureRecognizer()
      ..onTap = () {
        didTapLeft = true;
      };

    bool didTapRight = false;
    final TapGestureRecognizer tapRight = TapGestureRecognizer()
      ..onTap = () {
        didTapRight = true;
      };

    const Key textKey = Key('text');

    await tester.pumpWidget(
      Center(
        child: RichText(
          key: textKey,
          textDirection: TextDirection.ltr,
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text: 'xxxxxxxx',
                recognizer: tapLeft,
              ),
              const TextSpan(text: 'yyyyyyyy'),
              TextSpan(
                text: 'zzzzzzzzz',
                recognizer: tapRight,
              ),
            ],
          ),
        ),
      ),
    );

    final RenderBox box = tester.renderObject(find.byKey(textKey));

    expect(didTapLeft, isFalse);
    expect(didTapRight, isFalse);

    await tester.tapAt(box.localToGlobal(Offset.zero) + const Offset(2.0, 2.0));

    expect(didTapLeft, isTrue);
    expect(didTapRight, isFalse);

    didTapLeft = false;

    await tester.tapAt(box.localToGlobal(Offset.zero) + const Offset(30.0, 2.0));

    expect(didTapLeft, isTrue);
    expect(didTapRight, isFalse);

    didTapLeft = false;

    await tester.tapAt(box.localToGlobal(Offset(box.size.width, 0.0)) + const Offset(-2.0, 2.0));

    expect(didTapLeft, isFalse);
    expect(didTapRight, isTrue);
  });

  testWidgets('RichText with recognizers without handlers does not throw', (WidgetTester tester) async {
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RichText(
          text: TextSpan(text: 'root', children: <InlineSpan>[
            TextSpan(text: 'one', recognizer: TapGestureRecognizer()),
            TextSpan(text: 'two', recognizer: LongPressGestureRecognizer()),
            TextSpan(text: 'three', recognizer: DoubleTapGestureRecognizer()),
          ]),
        ),
      ),
    );

    expect(tester.getSemantics(find.byType(RichText)), matchesSemantics(
      children: <Matcher>[
        matchesSemantics(
          label: 'root',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
        matchesSemantics(
          label: 'one',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
        matchesSemantics(
          label: 'two',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
        matchesSemantics(
          label: 'three',
          hasTapAction: false,
          hasLongPressAction: false,
        ),
      ],
    ));
  });

  testWidgets('text span with tap gesture recognizer works in selectable rich text', (WidgetTester tester) async {
    int spyTaps = 0;
    final TapGestureRecognizer spyRecognizer = TapGestureRecognizer()
      ..onTap = () {
        spyTaps += 1;
      };
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: SelectableText.rich(
              TextSpan(
                children: <TextSpan>[
                  const TextSpan(text: 'Atwater '),
                  TextSpan(text: 'Peel', recognizer: spyRecognizer),
                  const TextSpan(text: ' Sherbrooke Bonaventure'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(spyTaps, 0);
    final Offset selectableTextStart = tester.getTopLeft(find.byType(SelectableText));

    await tester.tapAt(selectableTextStart + const Offset(150.0, 5.0));
    expect(spyTaps, 1);

    // Waits for a while to avoid double taps.
    await tester.pump(const Duration(seconds: 1));

    // Starts a long press.
    final TestGesture gesture =
      await tester.startGesture(selectableTextStart + const Offset(150.0, 5.0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pump();
    final EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);

    final TextEditingController controller = editableTextWidget.controller;
    // Long press still triggers selection.
    expect(
      controller.selection,
      const TextSelection(baseOffset: 8, extentOffset: 12),
    );
    // Long press does not trigger gesture recognizer.
    expect(spyTaps, 1);
  });

  testWidgets('text span with long press gesture recognizer works in selectable rich text', (WidgetTester tester) async {
    int spyLongPress = 0;
    final LongPressGestureRecognizer spyRecognizer = LongPressGestureRecognizer()
      ..onLongPress = () {
        spyLongPress += 1;
      };
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Center(
            child: SelectableText.rich(
              TextSpan(
                children: <TextSpan>[
                  const TextSpan(text: 'Atwater '),
                  TextSpan(text: 'Peel', recognizer: spyRecognizer),
                  const TextSpan(text: ' Sherbrooke Bonaventure'),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    expect(spyLongPress, 0);
    final Offset selectableTextStart = tester.getTopLeft(find.byType(SelectableText));

    await tester.tapAt(selectableTextStart + const Offset(150.0, 5.0));
    expect(spyLongPress, 0);

    // Waits for a while to avoid double taps.
    await tester.pump(const Duration(seconds: 1));

    // Starts a long press.
    final TestGesture gesture =
    await tester.startGesture(selectableTextStart + const Offset(150.0, 5.0));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pump();
    final EditableText editableTextWidget = tester.widget(find.byType(EditableText).first);

    final TextEditingController controller = editableTextWidget.controller;
    // Long press does not trigger selection if there is text span with long
    // press recognizer.
    expect(
      controller.selection,
      const TextSelection(baseOffset: 11, extentOffset: 11, affinity: TextAffinity.upstream),
    );
    // Long press triggers gesture recognizer.
    expect(spyLongPress, 1);
  });
}

