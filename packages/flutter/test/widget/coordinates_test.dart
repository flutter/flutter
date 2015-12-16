// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {
  test('Comparing coordinates', () {
    testWidgets((WidgetTester tester) {
      Key keyA = new GlobalKey();
      Key keyB = new GlobalKey();

      tester.pumpWidget(
        new Stack(<Widget>[
          new Positioned(
            top: 100.0,
            left: 100.0,
            child: new SizedBox(
              key: keyA,
              width: 10.0,
              height: 10.0
            )
          ),
          new Positioned(
            left: 100.0,
            top: 200.0,
            child: new SizedBox(
              key: keyB,
              width: 20.0,
              height: 10.0
            )
          ),
        ])
      );

      expect((tester.findElementByKey(keyA).renderObject as RenderBox).localToGlobal(const Point(0.0, 0.0)),
             equals(const Point(100.0, 100.0)));

      expect((tester.findElementByKey(keyB).renderObject as RenderBox).localToGlobal(const Point(0.0, 0.0)),
             equals(const Point(100.0, 200.0)));

      expect((tester.findElementByKey(keyB).renderObject as RenderBox).globalToLocal(const Point(110.0, 205.0)),
             equals(const Point(10.0, 5.0)));
    });
  });
}
