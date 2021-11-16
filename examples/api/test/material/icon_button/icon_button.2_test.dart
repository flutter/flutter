// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_api_samples/material/icon_button/icon_button.2.dart' as example;
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Ensure IconButton has two Material ancestors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const example.MyApp(),
    );

    final Finder finder = find.ancestor(
      of: find.byType(IconButton),
      matching: find.byType(Material),
    );
    expect(finder, findsNWidgets(2));
  });
}
