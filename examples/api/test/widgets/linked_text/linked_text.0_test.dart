// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/painting.dart';
import 'package:flutter_api_samples/widgets/linked_text/linked_text.0.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('pressing shouldPop button changes shouldPop', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.LinkedTextApp(),
    );

    expect(find.byType(InlineLinkedText), findsNWidgets(3));
  });
}
