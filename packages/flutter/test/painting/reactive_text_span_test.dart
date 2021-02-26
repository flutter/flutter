// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReactiveTextSpan equals', () {
    const TextSpan a1 = TextSpan(text: 'a');
    const TextSpan a2 = TextSpan(text: 'a');
    const TextSpan b1 = TextSpan(children: <TextSpan>[ a1 ]);
    const TextSpan b2 = TextSpan(children: <TextSpan>[ a2 ]);
    const TextSpan c1 = TextSpan(text: null);
    const TextSpan c2 = TextSpan(text: null);

    expect(a1 == a2, isTrue);
    expect(b1 == b2, isTrue);
    expect(c1 == c2, isTrue);

    expect(a1 == b2, isFalse);
    expect(b1 == c2, isFalse);
    expect(c1 == a2, isFalse);

    expect(a1 == c2, isFalse);
    expect(b1 == a2, isFalse);
    expect(c1 == b2, isFalse);
  });

  test('ReactiveTextSpan toStringDeep', () {
    const TextSpan test = TextSpan(
      text: 'a',
      style: TextStyle(
        fontSize: 10.0,
      ),
      children: <TextSpan>[
        TextSpan(
          text: 'b',
          children: <TextSpan>[
            TextSpan(),
          ],
        ),
        TextSpan(
          text: 'c',
        ),
      ],
    );
    expect(test.toStringDeep(), equals(
      'TextSpan:\n'
      '  inherit: true\n'
      '  size: 10.0\n'
      '  "a"\n'
      '  TextSpan:\n'
      '    "b"\n'
      '    TextSpan:\n'
      '      (empty)\n'
      '  TextSpan:\n'
      '    "c"\n'
    ));
  });

  test('ReactiveTextSpan toPlainText', () {
    const TextSpan textSpan = TextSpan(
      text: 'a',
      children: <TextSpan>[
        TextSpan(text: 'b'),
        TextSpan(text: 'c'),
      ],
    );
    expect(textSpan.toPlainText(), 'abc');
  });

  testWidgets('handles mouse cursor', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Text.rich(
          TextSpan(
            text: 'xxxxx',
            children: <InlineSpan>[
              ReactiveTextSpan(
                text: 'yyyyy',
                mouseCursor: SystemMouseCursors.forbidden,
              ),
              TextSpan(
                text: 'xxxxx',
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);

    await gesture.moveTo(tester.getCenter(find.byType(RichText)) - const Offset(40, 0));
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);

    await gesture.moveTo(tester.getCenter(find.byType(RichText)));
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.forbidden);

    await gesture.moveTo(tester.getCenter(find.byType(RichText)) + const Offset(40, 0));
    expect(RendererBinding.instance!.mouseTracker.debugDeviceActiveCursor(1), SystemMouseCursors.basic);
  });
}
