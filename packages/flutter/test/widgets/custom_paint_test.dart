// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

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

class TestCustomPainterWithCustomSemanticsBuilder extends TestCustomPainter {
  TestCustomPainterWithCustomSemanticsBuilder() : super(log: <String>[]);

  @override
  SemanticsBuilderCallback get semanticsBuilder => (Size size) {
    const Key key = Key('0');
    const Rect rect = Rect.fromLTRB(0, 0, 0, 0);
    const SemanticsProperties semanticsProperties = SemanticsProperties();
    return <CustomPainterSemantics>[
      const CustomPainterSemantics(key: key, rect: rect, properties: semanticsProperties),
      const CustomPainterSemantics(key: key, rect: rect, properties: semanticsProperties),
    ];
  };
}

class MockCanvas extends Mock implements Canvas {}

class MockPaintingContext extends Mock implements PaintingContext {}

void main() {
  testWidgets('Control test for custom painting', (WidgetTester tester) async {
    final List<String> log = <String>[];
    await tester.pumpWidget(CustomPaint(
      painter: TestCustomPainter(
        log: log,
        name: 'background',
      ),
      foregroundPainter: TestCustomPainter(
        log: log,
        name: 'foreground',
      ),
      child: CustomPaint(
        painter: TestCustomPainter(
          log: log,
          name: 'child',
        ),
      ),
    ));

    expect(log, equals(<String>['background', 'child', 'foreground']));
  });

  testWidgets('Throws FlutterError on custom painter incorrect restore/save calls', (
      WidgetTester tester) async {
    final GlobalKey target = GlobalKey();
    final List<String> log = <String>[];
    await tester.pumpWidget(CustomPaint(
      key: target,
      isComplex: true,
      painter: TestCustomPainter(log: log),
    ));
    final RenderCustomPaint renderCustom = target.currentContext.findRenderObject() as RenderCustomPaint;
    final Canvas canvas = MockCanvas();
    int saveCount = 0;
    when(canvas.getSaveCount()).thenAnswer((_) => saveCount++);
    final PaintingContext paintingContext = MockPaintingContext();
    when(paintingContext.canvas).thenReturn(canvas);

    FlutterError getError() {
      FlutterError error;
      try {
        renderCustom.paint(paintingContext, const Offset(0, 0));
      } on FlutterError catch (e) {
        error = e;
      }
      return error;
    }

    FlutterError error = getError();
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   The TestCustomPainter#00000() custom painter called canvas.save()\n'
      '   or canvas.saveLayer() at least 1 more time than it called\n'
      '   canvas.restore().\n'
      '   This leaves the canvas in an inconsistent state and will probably\n'
      '   result in a broken display.\n'
      '   You must pair each call to save()/saveLayer() with a later\n'
      '   matching call to restore().\n'
    ));

    when(canvas.getSaveCount()).thenAnswer((_) => saveCount--);
    error = getError();
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   The TestCustomPainter#00000() custom painter called\n'
      '   canvas.restore() 1 more time than it called canvas.save() or\n'
      '   canvas.saveLayer().\n'
      '   This leaves the canvas in an inconsistent state and will result\n'
      '   in a broken display.\n'
      '   You should only call restore() if you first called save() or\n'
      '   saveLayer().\n'
    ));

    when(canvas.getSaveCount()).thenAnswer((_) => saveCount += 2);
    error = getError();
    expect(error.toStringDeep(), contains('2 more times'));

    when(canvas.getSaveCount()).thenAnswer((_) => saveCount -= 2);
    error = getError();
    expect(error.toStringDeep(), contains('2 more times'));
  });

  testWidgets('assembleSemanticsNode throws FlutterError', (WidgetTester tester) async {
    final List<String> log = <String>[];
    final GlobalKey target = GlobalKey();
    await tester.pumpWidget(CustomPaint(
      key: target,
      isComplex: true,
      painter: TestCustomPainter(log: log),
    ));
    final RenderCustomPaint renderCustom = target.currentContext.findRenderObject() as RenderCustomPaint;
    dynamic error;
    try {
      renderCustom.assembleSemanticsNode(
        null,
        null,
        <SemanticsNode>[SemanticsNode()],
      );
    } on FlutterError catch (e) {
      error = e;
    }
    expect(error, isNotNull);
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   RenderCustomPaint does not have a child widget but received a\n'
      '   non-empty list of child SemanticsNode:\n'
      '   SemanticsNode#1(Rect.fromLTRB(0.0, 0.0, 0.0, 0.0), invisible)\n'
    ));

    await tester.pumpWidget(CustomPaint(
      key: target,
      isComplex: true,
      painter: TestCustomPainterWithCustomSemanticsBuilder(),
    ));
    final dynamic exception = tester.takeException();
    expect(exception, isFlutterError);
    error = exception;
    expect(error.toStringDeep(), equalsIgnoringHashCodes(
      'FlutterError\n'
      '   Failed to update the list of CustomPainterSemantics:\n'
      "   - duplicate key [<'0'>] found at position 1\n"
    ));
  });

  testWidgets('CustomPaint sizing', (WidgetTester tester) async {
    final GlobalKey target = GlobalKey();

    await tester.pumpWidget(Center(
      child: CustomPaint(key: target),
    ));
    expect(target.currentContext.size, Size.zero);

    await tester.pumpWidget(Center(
      child: CustomPaint(key: target, child: Container()),
    ));
    expect(target.currentContext.size, const Size(800.0, 600.0));

    await tester.pumpWidget(Center(
      child: CustomPaint(key: target, size: const Size(20.0, 20.0)),
    ));
    expect(target.currentContext.size, const Size(20.0, 20.0));

    await tester.pumpWidget(Center(
      child: CustomPaint(key: target, size: const Size(2000.0, 100.0)),
    ));
    expect(target.currentContext.size, const Size(800.0, 100.0));

    await tester.pumpWidget(Center(
      child: CustomPaint(key: target, size: Size.zero, child: Container()),
    ));
    expect(target.currentContext.size, const Size(800.0, 600.0));

    await tester.pumpWidget(Center(
      child: CustomPaint(key: target, child: Container(height: 0.0, width: 0.0)),
    ));
    expect(target.currentContext.size, Size.zero);

  });

  testWidgets('Raster cache hints', (WidgetTester tester) async {
    final GlobalKey target = GlobalKey();

    final List<String> log = <String>[];
    await tester.pumpWidget(CustomPaint(
      key: target,
      isComplex: true,
      painter: TestCustomPainter(log: log),
    ));
    RenderCustomPaint renderCustom = target.currentContext.findRenderObject() as RenderCustomPaint;
    expect(renderCustom.isComplex, true);
    expect(renderCustom.willChange, false);

    await tester.pumpWidget(CustomPaint(
      key: target,
      willChange: true,
      foregroundPainter: TestCustomPainter(log: log),
    ));
    renderCustom = target.currentContext.findRenderObject() as RenderCustomPaint;
    expect(renderCustom.isComplex, false);
    expect(renderCustom.willChange, true);
  });

  test('Raster cache hints cannot be set with null painters', () {
    expect(() => CustomPaint(isComplex: true), throwsAssertionError);
    expect(() => CustomPaint(willChange: true), throwsAssertionError);
  });
}
