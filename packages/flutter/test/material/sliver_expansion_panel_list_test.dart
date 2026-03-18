// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('SliverExpansionPanelList test', (WidgetTester tester) async {
    late int capturedIndex;
    late bool capturedIsExpanded;

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomScrollView(
            slivers: [
              SliverExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  capturedIndex = index;
                  capturedIsExpanded = isExpanded;
                },
                expansionPanels: <SliverExpansionPanel>[
                  SliverExpansionPanel(
                    key: const ValueKey('AB'),
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return Text(isExpanded ? 'B' : 'A');
                    },
                    body: const SizedBox(height: 100.0),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('A'), findsOneWidget);
    expect(find.text('B'), findsNothing);
    await tester.tap(find.byType(ExpandIcon));
    expect(capturedIndex, 0);
    expect(capturedIsExpanded, isTrue);

    // Now, expand the child panel.
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomScrollView(
            slivers: [
              SliverExpansionPanelList(
                expansionCallback: (int index, bool isExpanded) {
                  capturedIndex = index;
                  capturedIsExpanded = isExpanded;
                },
                expansionPanels: <SliverExpansionPanel>[
                  SliverExpansionPanel(
                    key: const ValueKey('AB'),
                    headerBuilder: (BuildContext context, bool isExpanded) {
                      return Text(isExpanded ? 'B' : 'A');
                    },
                    body: const SizedBox(height: 100.0),
                    isExpanded: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('A'), findsNothing);
    expect(find.text('B'), findsOneWidget);
  });

  testWidgets('SliverExpansionPanelList reordering test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomScrollView(
            slivers: [
              SliverExpansionPanelList(
                expansionCallback: (_, _) {},
                expansionPanels: <SliverExpansionPanel>[
                  SliverExpansionPanel(
                    key: const ValueKey('A'),
                    headerBuilder: (_, _) => const Text('Header A'),
                    body: const Text('Body A'),
                  ),
                  SliverExpansionPanel(
                    key: const ValueKey('B'),
                    headerBuilder: (_, _) => const Text('Header B'),
                    body: const Text('Body B'),
                    isExpanded: true, // B starts expanded
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Header A'), findsOneWidget);
    expect(find.text('Header B'), findsOneWidget);
    expect(find.text('Body B'), findsOneWidget);

    // Swap to [Panel B, Panel A]
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomScrollView(
            slivers: [
              SliverExpansionPanelList(
                expansionCallback: (_, _) {},
                expansionPanels: <SliverExpansionPanel>[
                  // Moved B to top
                  SliverExpansionPanel(
                    key: const ValueKey('B'),
                    headerBuilder: (_, _) => const Text('Header B'),
                    body: const Text('Body B'),
                    isExpanded: true,
                  ),
                  // Moved A to bottom
                  SliverExpansionPanel(
                    key: const ValueKey('A'),
                    headerBuilder: (_, _) => const Text('Header A'),
                    body: const Text('Body A'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify state persists after reorder
    expect(find.text('Header B'), findsOneWidget);
    expect(find.text('Header A'), findsOneWidget);
    expect(find.text('Body B'), findsOneWidget);
  });

  testWidgets('SliverExpansionPanelList complex multi-item update', (WidgetTester tester) async {
    int? capturedIndex;
    bool? capturedIsExpanded;

    // Initial State
    // Just [Panel A] (Collapsed)
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomScrollView(
            slivers: [
              SliverExpansionPanelList(
                expansionCallback: (index, isExpanded) {
                  capturedIndex = index;
                  capturedIsExpanded = isExpanded;
                },
                expansionPanels: <SliverExpansionPanel>[
                  SliverExpansionPanel(
                    key: const ValueKey('A'),
                    headerBuilder: (_, _) => const Text('Header A'),
                    body: const Text('Body A'),
                    canTapOnHeader: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Header A'), findsOneWidget);
    expect(find.text('Body A'), findsNothing);

    // Complex Update
    // - Insert 'New Top' at index 0
    // - 'A' shifts to index 1 AND gets expanded Programmatically
    // - Insert 'New Bottom' at index 2
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: CustomScrollView(
            slivers: [
              SliverExpansionPanelList(
                expansionCallback: (index, isExpanded) {
                  capturedIndex = index;
                  capturedIsExpanded = isExpanded;
                },
                expansionPanels: <SliverExpansionPanel>[
                  // New Item
                  SliverExpansionPanel(
                    key: const ValueKey('Top'),
                    headerBuilder: (_, _) => const Text('Header Top'),
                    body: const Text('Body Top'),
                  ),
                  // Existing Item (Expanded)
                  SliverExpansionPanel(
                    key: const ValueKey('A'),
                    headerBuilder: (_, _) => const Text('Header A'),
                    body: const Text('Body A'),
                    canTapOnHeader: true,
                    isExpanded: true, // Changed to Expanded!
                  ),
                  // New Item
                  SliverExpansionPanel(
                    key: const ValueKey('Bottom'),
                    headerBuilder: (_, _) => const Text('Header Bottom'),
                    body: const Text('Body Bottom'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify all items are present
    expect(find.text('Header Top'), findsOneWidget);
    expect(find.text('Header A'), findsOneWidget);
    expect(find.text('Header Bottom'), findsOneWidget);

    // Verify 'A' correctly expanded despite the index shift
    expect(find.text('Body A'), findsOneWidget);

    // Tap 'Header A'. It is now at index 1.
    await tester.tap(find.text('Header A'));
    await tester.pumpAndSettle();

    // Check if correct index is captured
    expect(capturedIndex, 1);
    // A was expanded. It should now be collapsed
    expect(capturedIsExpanded, false);
  });
}
