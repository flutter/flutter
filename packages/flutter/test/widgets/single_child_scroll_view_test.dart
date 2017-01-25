// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';

void main() {
  testWidgets('SingleChildScrollView control test', (WidgetTester tester) async {
    await tester.pumpWidget(new SingleChildScrollView(
      child: new Container(
        height: 2000.0,
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFF00FF00),
        ),
      ),
    ));

    RenderBox box = tester.renderObject(find.byType(Container));
    expect(box.localToGlobal(Point.origin), equals(Point.origin));

    await tester.scroll(find.byType(SingleChildScrollView), const Offset(-200.0, -200.0));

    expect(box.localToGlobal(Point.origin), equals(const Point(0.0, -200.0)));
  });
}
