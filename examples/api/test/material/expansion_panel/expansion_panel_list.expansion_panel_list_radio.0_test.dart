// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/expansion_panel/expansion_panel_list.expansion_panel_list_radio.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  void expectExpandedItem(WidgetTester tester, int index) {
    for (int i = 0; i < 8; i++) {
      expect(
        tester.widget<ExpandIcon>(find.byType(ExpandIcon).at(i)).isExpanded,
        index == i,
        reason: 'Only the panel $index should be expanded',
      );
    }
  }

  testWidgets('ExpansionPanelList.radio can expand on item at the time', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.ExpansionPanelListRadioExampleApp(),
    );

    expect(find.widgetWithText(AppBar, 'ExpansionPanelList.radio Sample'), findsOne);
    expect(find.byType(ExpansionPanelList), findsOne);
    for (int i = 0; i < 8; i++) {
      expect(find.widgetWithText(ListTile, 'Panel $i'), findsOne);
    }

    expectExpandedItem(tester, 2); // The default expanded item is 2.

    // Open all the panels one by one.
    for (int i = 0; i < 8; i++) {
      await tester.ensureVisible(find.byType(ExpandIcon).at(i));
      await tester.tap(find.byType(ExpandIcon).at(i));
      await tester.pumpAndSettle();
      expectExpandedItem(tester, i);
    }
  });
}
