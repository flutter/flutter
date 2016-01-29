// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('OverflowBox control test', () {
    testWidgets((WidgetTester tester) {
      GlobalKey inner = new GlobalKey();
      tester.pumpWidget(new Align(
        alignment: const FractionalOffset(1.0, 1.0),
        child: new SizedBox(
          width: 10.0,
          height: 20.0,
          child: new OverflowBox(
            minWidth: 0.0,
            maxWidth: 100.0,
            minHeight: 0.0,
            maxHeight: 50.0,
            child: new Container(
              key: inner
            )
          )
        )
      ));
      RenderBox box = inner.currentContext.findRenderObject();
      expect(box.localToGlobal(Point.origin), equals(const Point(745.0, 565.0)));
      expect(box.size, equals(const Size(100.0, 50.0)));
    });
  });
}
