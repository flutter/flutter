// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/material/expansible/expansible.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('displays FAQ questions', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ExpansibleExampleApp());

    expect(find.text('Expansible FAQ Sample'), findsOneWidget);
    expect(find.text('Frequently Asked Questions'), findsOneWidget);
    expect(find.text('What is Flutter?'), findsOneWidget);
    expect(find.text('How does Expansible work?'), findsOneWidget);
    expect(find.text('Can I customize the appearance?'), findsOneWidget);
  });

  testWidgets('tapping question toggles answer visibility', (WidgetTester tester) async {
    await tester.pumpWidget(const example.ExpansibleExampleApp());

    final Finder question = find.text('What is Flutter?');
    final Finder answerFinder = find.textContaining(
      'Flutter is an open-source UI software development kit created by Google.',
    );

    expect(answerFinder, findsNothing);

    await tester.tap(question);
    await tester.pumpAndSettle();

    expect(answerFinder, findsOneWidget);

    await tester.tap(question);
    await tester.pumpAndSettle();

    expect(answerFinder, findsNothing);
  });
}
