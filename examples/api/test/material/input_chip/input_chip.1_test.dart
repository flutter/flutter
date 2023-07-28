// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_api_samples/material/input_chip/input_chip.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  final String replacementChar =
      String.fromCharCode(example.ChipsInputState.kObjectReplacementChar);

  testWidgets('', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.EditableChipFieldApp(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(example.EditableChipFieldApp), findsNWidgets(1));
    expect(find.byType(example.ChipsInput<String>), findsNWidgets(1));
    expect(find.byType(InputChip), findsNWidgets(1));

    example.ChipsInputState<String> state =
        tester.state(find.byType(example.ChipsInput<String>));
    expect(state.text, '');

    await tester.tap(find.byType(example.ChipsInput<String>));
    await tester.pumpAndSettle();
    expect(tester.testTextInput.isVisible, true);
    // simulating text typing on input field
    tester.testTextInput.enterText('${replacementChar}ham');
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(1));

    state = tester.state(find.byType(example.ChipsInput<String>));
    await tester.pumpAndSettle();
    expect(state.text, 'ham');

    // add new InputChip by sending "done" action
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(state.text, '');

    expect(find.byType(InputChip), findsNWidgets(2));

    //simulate item deletion
    await tester.tap(find.descendant(
        of: find.byType(InputChip), matching: find.byType(InkWell).last));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(1));

    await tester.tap(find.descendant(
        of: find.byType(InputChip), matching: find.byType(InkWell).last));
    await tester.pumpAndSettle();
    expect(find.byType(InputChip), findsNWidgets(0));
  });
}
