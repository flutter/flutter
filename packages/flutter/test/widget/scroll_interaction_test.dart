// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('Scroll flings twice in a row does not crash', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Block(
        children: <Widget>[
          new Container(height: 100000.0)          
        ]
      ));

      ScrollableState<ScrollableViewport> scrollable =
          tester.stateOf/*<ScrollableState<ScrollableViewport>>*/(find.byType(ScrollableViewport));

      expect(scrollable.scrollOffset, equals(0.0));

      tester.flingFrom(new Point(200.0, 300.0), new Offset(0.0, -200.0), 500.0);
      tester.pump();
      tester.pump(const Duration(seconds: 5));

      expect(scrollable.scrollOffset, greaterThan(0.0));

      double oldOffset = scrollable.scrollOffset;

      tester.flingFrom(new Point(200.0, 300.0), new Offset(0.0, -200.0), 500.0);
      tester.pump();
      tester.pump(const Duration(seconds: 5));

      expect(scrollable.scrollOffset, greaterThan(oldOffset));
      
    });
  });
}
