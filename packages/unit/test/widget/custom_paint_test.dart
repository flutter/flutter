// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

class TestCustomPainter extends CustomPainter {
  TestCustomPainter({ this.log, this.name });

  List<String> log;
  String name;

  void paint(Canvas canvas, Size size) {
    log.add(name);
  }

  bool shouldRepaint(TestCustomPainter oldPainter) => true;
}

void main() {
  test('Control test for custom painting', () {
    testWidgets((WidgetTester tester) {
      List<String> log = <String>[];
      tester.pumpWidget(new CustomPaint(
        painter: new TestCustomPainter(
          log: log,
          name: 'background'
        ),
        foregroundPainter: new TestCustomPainter(
          log: log,
          name: 'foreground'
        ),
        child: new CustomPaint(
          painter: new TestCustomPainter(
            log: log,
            name: 'child'
          )
        )
      ));

      expect(log, equals(['background', 'child', 'foreground']));
    });
  });
}
