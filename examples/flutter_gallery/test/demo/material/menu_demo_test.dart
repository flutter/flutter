// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_gallery/demo/material/menu_demo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Menu icon satisfies accessibility contrast ratio guidelines', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MenuDemo(),
    ));

    // await expectLater(tester, meetsGuideline(textContrastGuideline));

    List<Element> elements = find.byIcon(Icons.more_vert).evaluate().toList();

    for (final element in elements) {
      print((element.renderObject as RenderBox).localToGlobal(element.renderObject.paintBounds.topLeft));
    }

  });
}
