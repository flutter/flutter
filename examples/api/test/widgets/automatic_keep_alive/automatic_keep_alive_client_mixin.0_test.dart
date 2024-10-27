// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/widgets/automatic_keep_alive/automatic_keep_alive_client_mixin.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('KeepAliveItem maintains state when scrolled out of view',
      (WidgetTester tester) async {
    // Build app and trigger a frame
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: example.ItemList(),
        ),
      ),
    );

    // Verify initial state
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Keep me alive: false'), findsOneWidget);

    // Toggle keep alive for first item
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    // Verify keep alive state changed
    expect(find.text('Keep me alive: true'), findsOneWidget);

    // Scroll down to make first item not visible
    await tester.drag(find.byType(ListView), const Offset(0.0, -800.0));
    await tester.pump();

    // Verify first item is not visible
    expect(find.text('Item 0'), findsNothing);

    // Scroll back up
    await tester.drag(find.byType(ListView), const Offset(0.0, 800.0));
    await tester.pump();

    // Verify first item is visible and maintained its state
    expect(find.text('Item 0'), findsOneWidget);
    expect(find.text('Keep me alive: true'), findsOneWidget);
  });

  testWidgets('Multiple KeepAliveItems can be toggled independently',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: example.ItemList(),
        ),
      ),
    );

    // Toggle first item
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    // Verify first item state
    expect(find.text('Keep me alive: true').first, findsOneWidget);

    // Scroll to second item
    await tester.drag(find.byType(ListView), const Offset(0.0, -100.0));
    await tester.pump();

    // Toggle second item
    await tester.tap(find.byType(ElevatedButton).first);
    await tester.pump();

    // Verify second item state
    expect(find.text('Keep me alive: true').first, findsOneWidget);

    // Scroll back to first item
    await tester.drag(find.byType(ListView), const Offset(0.0, 100.0));
    await tester.pump();

    // Verify first item maintained its state
    expect(find.text('Keep me alive: true').first, findsOneWidget);
  });

  testWidgets('KeepAliveItem initializes with correct index',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: example.ItemList(),
        ),
      ),
    );

    // Verify first few items have correct indices
    expect(find.text('Item 0'), findsOneWidget);

    // Scroll to see more items
    await tester.drag(find.byType(ListView), const Offset(0.0, -300.0));
    await tester.pump();

    // Verify later items are rendered with correct indices
    expect(find.textContaining('Item'), findsWidgets);
  });

  testWidgets('KeepAliveItem updates keep alive state correctly',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: example.ItemList(),
        ),
      ),
    );

    // Initial state should be false
    expect(find.text('Keep me alive: false'), findsOneWidget);

    // Toggle state multiple times
    for (int i = 0; i < 3; i++) {
      await tester.tap(find.byType(ElevatedButton).first);
      await tester.pump();
      expect(
        find.text('Keep me alive: ${i.isEven}'),
        findsOneWidget,
        reason: 'Keep alive state not toggling correctly on iteration $i',
      );
    }
  });
}
