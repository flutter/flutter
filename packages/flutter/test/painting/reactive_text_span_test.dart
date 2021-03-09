// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ReactiveTextSpan equals', () {
    void callback1(PointerEnterEvent _) {};
    void callback2(PointerEnterEvent _) {};
    const ReactiveTextSpan a1 = ReactiveTextSpan(text: 'a');
    final ReactiveTextSpan a2 = ReactiveTextSpan(text: 'a', onEnter: callback1);
    final ReactiveTextSpan a3 = ReactiveTextSpan(text: 'a', onEnter: callback1);
    final ReactiveTextSpan a4 = ReactiveTextSpan(text: 'a', onEnter: callback2);
    final ReactiveTextSpan a5 = ReactiveTextSpan(text: 'a', onEnter: callback2, mouseCursor: SystemMouseCursors.forbidden);
    final ReactiveTextSpan a6 = ReactiveTextSpan(text: 'a', onEnter: callback2, mouseCursor: SystemMouseCursors.forbidden);

    expect(a1 == a2, isFalse);
    expect(a2 == a3, isTrue);
    expect(a3 == a4, isFalse);
    expect(a4 == a5, isFalse);
    expect(a5 == a6, isTrue);
  });

  test('ReactiveTextSpan toStringDeep', () {
    const ReactiveTextSpan test1 = ReactiveTextSpan(
      text: 'a',
    );
    expect(test1.toStringDeep(), equals(
      'ReactiveTextSpan:\n'
      '  "a"\n'
    ));

    final ReactiveTextSpan test2 = ReactiveTextSpan(
      text: 'a',
      onEnter: (_) {},
      onExit: (_) {},
      mouseCursor: SystemMouseCursors.forbidden,
    );
    expect(test2.toStringDeep(), equals(
      'ReactiveTextSpan:\n'
      '  "a"\n'
      '  callbacks: enter, exit\n'
      '  mouseCursor: SystemMouseCursor(forbidden)\n'
    ));
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

  testWidgets('handles onEnter and onExit', (WidgetTester tester) async {
    final List<PointerEvent> logEvents = <PointerEvent>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Text.rich(
          TextSpan(
            text: 'xxxxx',
            children: <InlineSpan>[
              ReactiveTextSpan(
                text: 'yyyyy',
                onEnter: (PointerEnterEvent event) {
                  logEvents.add(event);
                },
                onExit: (PointerExitEvent event) {
                  logEvents.add(event);
                }
              ),
              const TextSpan(
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
    expect(logEvents, isEmpty);

    await gesture.moveTo(tester.getCenter(find.byType(RichText)));
    expect(logEvents.length, 1);
    expect(logEvents[0], isA<PointerEnterEvent>());

    await gesture.moveTo(tester.getCenter(find.byType(RichText)) + const Offset(40, 0));
    expect(logEvents.length, 2);
    expect(logEvents[1], isA<PointerExitEvent>());
  });
}
