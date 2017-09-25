// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('Text respects media query', (WidgetTester tester) async {
    await tester.pumpWidget(const MediaQuery(
      data: const MediaQueryData(textScaleFactor: 1.5),
      child: const Center(
        child: const Text('Hello', textDirection: TextDirection.ltr)
      )
    ));

    RichText text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.5);

    await tester.pumpWidget(const Center(
      child: const Text('Hello', textDirection: TextDirection.ltr)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 1.0);

    await tester.pumpWidget(const Center(
      child: const Text('Hello', textScaleFactor: 3.0, textDirection: TextDirection.ltr)
    ));

    text = tester.firstWidget(find.byType(RichText));
    expect(text, isNotNull);
    expect(text.textScaleFactor, 3.0);
  });

  testWidgets('Text throws a nice error message if there\'s no Directionality', (WidgetTester tester) async {
    await tester.pumpWidget(const Text('Hello'));
    final String message = tester.takeException().toString();
    expect(message, contains('Directionality'));
    expect(message, contains(' Text '));
  });
}
