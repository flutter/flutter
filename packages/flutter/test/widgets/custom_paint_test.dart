// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class TestCustomPainter extends CustomPainter {
  TestCustomPainter({ this.log, this.name });

  final List<String> log;
  final String name;

  @override
  void paint(Canvas canvas, Size size) {
    log.add(name);
  }

  @override
  bool shouldRepaint(TestCustomPainter oldPainter) => true;
}

void main() {
  testWidgets('Control test for custom painting', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(new CustomPaint(
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

  testWidgets('CustomPaint sizing', (WidgetTester tester) async {
    final GlobalKey target = new GlobalKey();

    await tester.pumpWidget(new Center(
      child: new CustomPaint(key: target)
    ));
    expect(target.currentContext.size, Size.zero);

    await tester.pumpWidget(new Center(
      child: new CustomPaint(key: target, child: new Container())
    ));
    expect(target.currentContext.size, const Size(800.0, 600.0));

    await tester.pumpWidget(new Center(
      child: new CustomPaint(key: target, size: const Size(20.0, 20.0))
    ));
    expect(target.currentContext.size, const Size(20.0, 20.0));

    await tester.pumpWidget(new Center(
      child: new CustomPaint(key: target, size: const Size(2000.0, 100.0))
    ));
    expect(target.currentContext.size, const Size(800.0, 100.0));

    await tester.pumpWidget(new Center(
      child: new CustomPaint(key: target, size: Size.zero, child: new Container())
    ));
    expect(target.currentContext.size, const Size(800.0, 600.0));

    await tester.pumpWidget(new Center(
      child: new CustomPaint(key: target, child: new Container(height: 0.0, width: 0.0))
    ));
    expect(target.currentContext.size, Size.zero);

  });

  testWidgets('Raster cache hints', (WidgetTester tester) async {
    final GlobalKey target = new GlobalKey();

    final List<String> log = <String>[];
    await tester.pumpWidget(new CustomPaint(
      key: target,
      isComplex: true,
      painter: new TestCustomPainter(log: log),
    ));
    RenderCustomPaint renderCustom = target.currentContext.findRenderObject();
    expect(renderCustom.isComplex, true);
    expect(renderCustom.willChange, false);

    await tester.pumpWidget(new CustomPaint(
      key: target,
      willChange: true,
      foregroundPainter: new TestCustomPainter(log: log),
    ));
    renderCustom = target.currentContext.findRenderObject();
    expect(renderCustom.isComplex, false);
    expect(renderCustom.willChange, true);
  });
}
