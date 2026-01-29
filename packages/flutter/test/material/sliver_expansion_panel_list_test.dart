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
}
