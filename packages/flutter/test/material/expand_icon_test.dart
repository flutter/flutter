// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ExpandIcon test', (WidgetTester tester) async {
    bool expanded = false;

    await tester.pumpWidget(
      wrap(
          child: new ExpandIcon(
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
          )
      )
    );

    expect(expanded, isFalse);
    await tester.tap(find.byType(ExpandIcon));
    expect(expanded, isTrue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.byType(ExpandIcon));
    expect(expanded, isFalse);
  });

  testWidgets('ExpandIcon disabled', (WidgetTester tester) async {
    await tester.pumpWidget(
      wrap(
          child: const ExpandIcon(
            onPressed: null
          )
      )
    );

    final IconTheme iconTheme = tester.firstWidget(find.byType(IconTheme));
    expect(iconTheme.data.color, equals(Colors.black26));
  });

  testWidgets('ExpandIcon test isExpanded does not trigger callback', (WidgetTester tester) async {
    bool expanded = false;

    await tester.pumpWidget(
      wrap(
          child: new ExpandIcon(
            isExpanded: false,
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
          )
      )
    );

    await tester.pumpWidget(
      wrap(
          child: new ExpandIcon(
            isExpanded: true,
            onPressed: (bool isExpanded) {
              expanded = !expanded;
            }
        )
      )
    );

    expect(expanded, isFalse);
  });
}

Widget wrap({ Widget child }) {
  return new Directionality(
    textDirection: TextDirection.ltr,
    child: new Center(
      child: new Material(child: child),
    ),
  );
}
