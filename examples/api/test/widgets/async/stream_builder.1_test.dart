// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/async/stream_builder.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('StreamBuilder starts on the fast stream in a waiting state', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.StreamBuilderExampleApp());

    expect(find.text('Fast stream'), findsOneWidget);
    expect(find.text('waiting...'), findsOneWidget);
    expect(find.text('Switch stream'), findsOneWidget);
  });

  testWidgets(
    'Switching streams resets to waiting via ObjectKey on the stream',
    (WidgetTester tester) async {
      await tester.pumpWidget(const example.StreamBuilderExampleApp());

      // Advance the fast stream so a value is displayed.
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('0'), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(find.text('1'), findsOneWidget);

      // Switch to the slow stream; ObjectKey forces a new StreamBuilder that
      // starts with no data, showing 'waiting...' instead of the fast stream's
      // last value (1).
      await tester.tap(find.text('Switch stream'));
      await tester.pump();

      expect(find.text('Slow stream'), findsOneWidget);
      expect(find.text('waiting...'), findsOneWidget);

      // Switch back without waiting for a slow-stream event; should still
      // reset to waiting, not retain the fast stream's last value either.
      await tester.tap(find.text('Switch stream'));
      await tester.pump();

      expect(find.text('Fast stream'), findsOneWidget);
      expect(find.text('waiting...'), findsOneWidget);
    },
  );

  testWidgets('StreamBuilder is keyed on the active stream', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.StreamBuilderExampleApp());

    final StreamBuilder<String> firstBuilder = tester.widget(
      find.byType(StreamBuilder<String>),
    );
    expect(firstBuilder.key, isA<ObjectKey>());
    final Object? firstKey = firstBuilder.key;

    await tester.tap(find.text('Switch stream'));
    await tester.pump();

    final StreamBuilder<String> secondBuilder = tester.widget(
      find.byType(StreamBuilder<String>),
    );
    expect(secondBuilder.key, isA<ObjectKey>());
    expect(secondBuilder.key, isNot(equals(firstKey)));
  });
}
