// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Text respects media query', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.3),
      child: const Center(
        child: const Text('Hello', textDirection: TextDirection.ltr)
      )
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);

    await tester.pumpWidget(const Center(
      child: const Text('Hello', textDirection: TextDirection.ltr)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
  });

  testWidgets('Text respects textScaleFactor with default font size', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Center(child: const Text('Hello', textDirection: TextDirection.ltr))
    );

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final Size baseSize = tester.getSize(find.byType(RichText));
    expect(baseSize.width, equals(70.0));
    expect(baseSize.height, equals(14.0));

    await tester.pumpWidget(const Center(
      child: const Text('Hello', textScaleFactor: 1.5, textDirection: TextDirection.ltr)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.5);
    final Size largeSize = tester.getSize(find.byType(RichText));
    expect(largeSize.width, 105.0);
    expect(largeSize.height, equals(21.0));
  });

  testWidgets('Text respects textScaleFactor with explicit font size', (WidgetTester tester) async {
    await tester.pumpWidget(const Center(
      child: const Text('Hello',
        style: const TextStyle(fontSize: 20.0), textDirection: TextDirection.ltr)
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);
    final Size baseSize = tester.getSize(find.byType(RichText));
    expect(baseSize.width, equals(100.0));
    expect(baseSize.height, equals(20.0));

    await tester.pumpWidget(const Center(
      child: const Text('Hello',
        style: const TextStyle(fontSize: 20.0),
        textScaleFactor: 1.3,
        textDirection: TextDirection.ltr)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.3);
    final Size largeSize = tester.getSize(find.byType(RichText));
    expect(largeSize.width, anyOf(131.0, 130.0));
    expect(largeSize.height, equals(26.0));
  });

  testWidgets('Text throws a nice error message if there\'s no Directionality', (WidgetTester tester) async {
    await tester.pumpWidget(const Text('Hello'));
    final String message = tester.takeException().toString();
    expect(message, contains('Directionality'));
    expect(message, contains(' Text '));
  });

  testWidgets('Text can be created from TextSpans and uses defaultTextStyle', (WidgetTester tester) async {
    await tester.pumpWidget(
      const DefaultTextStyle(
        style: const TextStyle(
          fontSize: 20.0,
        ),
        child: const Text.rich(
          const TextSpan(
            text: 'Hello',
            children: const <TextSpan>[
              const TextSpan(text: ' beautiful ', style: const TextStyle(fontStyle: FontStyle.italic)),
              const TextSpan(text: 'world', style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          textDirection: TextDirection.ltr,
        ),
      ),
    );

    final RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.text.style.fontSize, 20.0);
  });
}
