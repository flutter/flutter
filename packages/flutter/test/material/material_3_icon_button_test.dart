// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material_3.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('material_3 IconButton is the same as material IconButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Scaffold(
          body: Center(
            child: IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
          ),
        ),
      ),
    );

    expect(find.byType(IconButton), findsOneWidget);
  });
}
