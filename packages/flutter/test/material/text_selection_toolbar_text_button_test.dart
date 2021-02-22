// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('position in the toolbar changes width', (WidgetTester tester) async {
    late StateSetter setState;
    int index = 1;
    int total = 3;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setter) {
                setState = setter;
                return TextSelectionToolbarTextButton(
                  child: const Text('button'),
                  padding: TextSelectionToolbarTextButton.getPadding(index, total),
                );
              },
            ),
          ),
        ),
      ),
    );

    final Size middleSize = tester.getSize(find.byType(TextSelectionToolbarTextButton));

    setState(() {
      index = 0;
      total = 3;
    });
    await tester.pump();
    final Size firstSize = tester.getSize(find.byType(TextSelectionToolbarTextButton));
    expect(firstSize.width, greaterThan(middleSize.width));

    setState(() {
      index = 2;
      total = 3;
    });
    await tester.pump();
    final Size lastSize = tester.getSize(find.byType(TextSelectionToolbarTextButton));
    expect(lastSize.width, greaterThan(middleSize.width));
    expect(lastSize.width, equals(firstSize.width));

    setState(() {
      index = 0;
      total = 1;
    });
    await tester.pump();
    final Size onlySize = tester.getSize(find.byType(TextSelectionToolbarTextButton));
    expect(onlySize.width, greaterThan(middleSize.width));
    expect(onlySize.width, greaterThan(firstSize.width));
    expect(onlySize.width, greaterThan(lastSize.width));
  });
}
