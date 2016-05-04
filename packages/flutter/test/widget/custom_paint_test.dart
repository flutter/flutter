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

  @override
  void paint(Canvas canvas, Size size) {
    log.add(name);
  }

  @override
  bool shouldRepaint(TestCustomPainter oldPainter) => true;
}

void main() {
  testWidgets('Control test for custom painting', (WidgetTester tester) {
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

    expect(log, equals(<String>['background', 'child', 'foreground']));
  });
}
