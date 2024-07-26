// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/chip/deletable_chip_attributes.on_deleted.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Chip.onDeleted can be used to delete chips', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.OnDeletedExampleApp(),
    );

    expect(find.widgetWithText(AppBar, 'DeletableChipAttributes.onDeleted Sample'), findsOne);
    expect(find.widgetWithText(Chip, 'Aaron Burr'), findsOne);
    expect(find.widgetWithText(Chip, 'Alexander Hamilton'), findsOne);
    expect(find.widgetWithText(Chip, 'Eliza Hamilton'), findsOne);
    expect(find.widgetWithText(Chip, 'James Madison'), findsOne);

    // Delete Alexander Hamilton.
    await tester.tap(
      find.descendant(of: find.widgetWithText(Chip, 'Alexander Hamilton'), matching: find.byIcon(Icons.cancel)),
    );
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Aaron Burr'), findsOne);
    expect(find.widgetWithText(Chip, 'Alexander Hamilton'), findsNothing);
    expect(find.widgetWithText(Chip, 'Eliza Hamilton'), findsOne);
    expect(find.widgetWithText(Chip, 'James Madison'), findsOne);

    // Delete James Madison.
    await tester.tap(
      find.descendant(of: find.widgetWithText(Chip, 'James Madison'), matching: find.byIcon(Icons.cancel)),
    );
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Aaron Burr'), findsOne);
    expect(find.widgetWithText(Chip, 'Alexander Hamilton'), findsNothing);
    expect(find.widgetWithText(Chip, 'Eliza Hamilton'), findsOne);
    expect(find.widgetWithText(Chip, 'James Madison'), findsNothing);

    // Delete Aaron Burr.
    await tester.tap(
      find.descendant(of: find.widgetWithText(Chip, 'Aaron Burr'), matching: find.byIcon(Icons.cancel)),
    );
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Aaron Burr'), findsNothing);
    expect(find.widgetWithText(Chip, 'Alexander Hamilton'), findsNothing);
    expect(find.widgetWithText(Chip, 'Eliza Hamilton'), findsOne);
    expect(find.widgetWithText(Chip, 'James Madison'), findsNothing);

    // Delete Eliza Hamilton.
    await tester.tap(
      find.descendant(of: find.widgetWithText(Chip, 'Eliza Hamilton'), matching: find.byIcon(Icons.cancel)),
    );
    await tester.pump();

    expect(find.widgetWithText(Chip, 'Aaron Burr'), findsNothing);
    expect(find.widgetWithText(Chip, 'Alexander Hamilton'), findsNothing);
    expect(find.widgetWithText(Chip, 'Eliza Hamilton'), findsNothing);
    expect(find.widgetWithText(Chip, 'James Madison'), findsNothing);
  });
}
