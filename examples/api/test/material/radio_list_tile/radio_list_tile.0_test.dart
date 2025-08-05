// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/radio_list_tile/radio_list_tile.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Can update RadioListTile group value', (WidgetTester tester) async {
    await tester.pumpWidget(const example.RadioListTileApp());

    // Find the number of RadioListTiles.
    expect(find.byType(RadioListTile<example.SingingCharacter>), findsNWidgets(2));

    // The initial group value is lafayette.
    RadioGroup<example.SingingCharacter> group = tester
        .widget<RadioGroup<example.SingingCharacter>>(
          find.byType(RadioGroup<example.SingingCharacter>),
        );
    // Second radio is checked.
    expect(group.groupValue, example.SingingCharacter.lafayette);

    // Tap the last RadioListTile to change the group value to jefferson.
    await tester.tap(find.byType(RadioListTile<example.SingingCharacter>).last);
    await tester.pump();

    // The group value is now jefferson.
    group = tester.widget<RadioGroup<example.SingingCharacter>>(
      find.byType(RadioGroup<example.SingingCharacter>),
    );
    // Second radio is checked.
    expect(group.groupValue, example.SingingCharacter.jefferson);
  });
}
