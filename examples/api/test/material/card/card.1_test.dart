// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/card/card.1.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Card has clip applied', (WidgetTester tester) async {
    await tester.pumpWidget(const example.MyApp());

    final Card card = tester.firstWidget(find.byType(Card));
    expect(card.clipBehavior, Clip.hardEdge);
  });
}
