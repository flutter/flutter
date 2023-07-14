// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/input_chip/input_chip.1.dart'
    as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.EditableChipFieldApp(),
    );
    await tester.pumpAndSettle();

    expect(find.byType(example.EditableChipFieldApp), findsNWidgets(1));
  });
}
