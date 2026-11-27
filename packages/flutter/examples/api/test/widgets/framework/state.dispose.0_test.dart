// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_api_samples/widgets/framework/state.dispose.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('CountDisplay shows the latest value from its stream', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.StateDisposeExampleApp());
    expect(find.text('Count: 0'), findsOne);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Count: 1'), findsOne);

    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Count: 3'), findsOne);
  });

  testWidgets('CountDisplay resubscribes when given a new stream', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.StateDisposeExampleApp());
    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Count: 3'), findsOne);

    await tester.tap(find.text('Restart'));
    await tester.pump();
    expect(find.text('Count: 0'), findsOne);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Count: 1'), findsOne);
  });

  testWidgets('CountDisplay cancels its subscription when disposed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.StateDisposeExampleApp());
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Count: 1'), findsOne);

    await tester.tap(find.text('Remove counter'));
    await tester.pump();
    expect(find.byType(example.CountDisplay), findsNothing);
    expect(find.text('Counter removed'), findsOne);

    // If the subscription were still active, this would call setState on a
    // disposed State and throw.
    await tester.pump(const Duration(seconds: 3));
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Show counter'));
    await tester.pump();
    expect(find.text('Count: 0'), findsOne);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Count: 1'), findsOne);
  });
}
