// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/radio_list_tile/custom_labeled_radio.0.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('LinkedLabelRadio contains RichText and Radio', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const example.LabeledRadioApp());

    // Label text is in a RichText widget with the correct text.
    final RichText richText = tester.widget(find.byType(RichText).first);
    expect(richText.text.toPlainText(), 'First tappable label text');

    RadioGroup<bool> group = tester.widget<RadioGroup<bool>>(
      find.byType(RadioGroup<bool>),
    );
    // Second radio is checked.
    expect(group.groupValue, isFalse);

    // Tap the first radio.
    await tester.tap(find.byType(Radio<bool>).first);
    await tester.pump();

    // First Radio is now checked.
    group = tester.widget<RadioGroup<bool>>(find.byType(RadioGroup<bool>));
    expect(group.groupValue, true);
  });
}
