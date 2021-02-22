// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

void main() {
  group('PhysicalShape', () {
    testWidgets('properties', (WidgetTester tester) async {
      await tester.pumpWidget(
        const PhysicalShape(
          clipper: ShapeBorderClipper(shape: CircleBorder()),
          elevation: 2.0,
          color: Color(0xFF0000FF),
          shadowColor: Color(0xFF00FF00),
        ),
      );
      final RenderPhysicalShape renderObject = tester.renderObject(find.byType(PhysicalShape));
      expect(renderObject.clipper, const ShapeBorderClipper(shape: CircleBorder()));
      expect(renderObject.color, const Color(0xFF0000FF));
      expect(renderObject.shadowColor, const Color(0xFF00FF00));
      expect(renderObject.elevation, 2.0);
    });

    testWidgets('hit test', (WidgetTester tester) async {
      await tester.pumpWidget(
        PhysicalShape(
          clipper: const ShapeBorderClipper(shape: CircleBorder()),
          elevation: 2.0,
          color: const Color(0xFF0000FF),
          shadowColor: const Color(0xFF00FF00),
          child: Container(color: const Color(0xFF0000FF)),
        ),
      );

      final RenderPhysicalShape renderPhysicalShape =
        tester.renderObject(find.byType(PhysicalShape));

      // The viewport is 800x600, the CircleBorder is centered and fits
      // the shortest edge, so we get a circle of radius 300, centered at
      // (400, 300).
      //
      // We test by sampling a few points around the left-most point of the
      // circle (100, 300).

      expect(tester.hitTestOnBinding(const Offset(99.0, 300.0)), doesNotHit(renderPhysicalShape));
      expect(tester.hitTestOnBinding(const Offset(100.0, 300.0)), hits(renderPhysicalShape));
      expect(tester.hitTestOnBinding(const Offset(100.0, 299.0)), doesNotHit(renderPhysicalShape));
      expect(tester.hitTestOnBinding(const Offset(100.0, 301.0)), doesNotHit(renderPhysicalShape));
    });

  });

  group('FractionalTranslation', () {
    testWidgets('hit test - entirely inside the bounding box', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey();
      bool _pointerDown = false;

      await tester.pumpWidget(
        Center(
          child: FractionalTranslation(
            translation: Offset.zero,
            transformHitTests: true,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _pointerDown = true;
              },
              child: SizedBox(
                key: key1,
                width: 100.0,
                height: 100.0,
                child: Container(
                  color: const Color(0xFF0000FF)
                ),
              ),
            ),
          ),
        ),
      );
      expect(_pointerDown, isFalse);
      await tester.tap(find.byKey(key1));
      expect(_pointerDown, isTrue);
    });

    testWidgets('hit test - partially inside the bounding box', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey();
      bool _pointerDown = false;

      await tester.pumpWidget(
        Center(
          child: FractionalTranslation(
            translation: const Offset(0.5, 0.5),
            transformHitTests: true,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _pointerDown = true;
              },
              child: SizedBox(
                key: key1,
                width: 100.0,
                height: 100.0,
                child: Container(
                  color: const Color(0xFF0000FF)
                ),
              ),
            ),
          ),
        ),
      );
      expect(_pointerDown, isFalse);
      await tester.tap(find.byKey(key1));
      expect(_pointerDown, isTrue);
    });

    testWidgets('hit test - completely outside the bounding box', (WidgetTester tester) async {
      final GlobalKey key1 = GlobalKey();
      bool _pointerDown = false;

      await tester.pumpWidget(
        Center(
          child: FractionalTranslation(
            translation: const Offset(1.0, 1.0),
            transformHitTests: true,
            child: Listener(
              onPointerDown: (PointerDownEvent event) {
                _pointerDown = true;
              },
              child: SizedBox(
                key: key1,
                width: 100.0,
                height: 100.0,
                child: Container(
                  color: const Color(0xFF0000FF)
                ),
              ),
            ),
          ),
        ),
      );
      expect(_pointerDown, isFalse);
      await tester.tap(find.byKey(key1));
      expect(_pointerDown, isTrue);
    });

    testWidgets('semantics bounds are updated', (WidgetTester tester) async {
      final GlobalKey fractionalTranslationKey = GlobalKey();
      final GlobalKey textKey = GlobalKey();
      Offset offset = const Offset(0.4, 0.4);

      await tester.pumpWidget(
        StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Directionality(
              textDirection: TextDirection.ltr,
              child: Center(
                child: Semantics(
                  explicitChildNodes: true,
                  child: FractionalTranslation(
                    key: fractionalTranslationKey,
                    translation: offset,
                    transformHitTests: true,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          offset = const Offset(0.8, 0.8);
                        });
                      },
                      child: SizedBox(
                        width: 100.0,
                        height: 100.0,
                        child: Text(
                          'foo',
                          key: textKey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        )
      );

      expect(
        tester.getSemantics(find.byKey(textKey)).transform,
        Matrix4(
          3.0, 0.0, 0.0, 0.0,
          0.0, 3.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          1170.0, 870.0, 0.0, 1.0,
        ),
      );

      await tester.tap(find.byKey(fractionalTranslationKey), warnIfMissed: false); // RenderFractionalTranslation can't be hit
      await tester.pump();
      expect(
        tester.getSemantics(find.byKey(textKey)).transform,
        Matrix4(
          3.0, 0.0, 0.0, 0.0,
          0.0, 3.0, 0.0, 0.0,
          0.0, 0.0, 1.0, 0.0,
          1290.0, 990.0, 0.0, 1.0,
        ),
      );
    });
  });

  group('Row', () {
    testWidgets('multiple baseline aligned children', (WidgetTester tester) async {
      final UniqueKey key1 = UniqueKey();
      final UniqueKey key2 = UniqueKey();
      const double fontSize1 = 54;
      const double fontSize2 = 14;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text('big text',
                    key: key1,
                    style: const TextStyle(fontSize: fontSize1),
                  ),
                  Text('one\ntwo\nthree\nfour\nfive\nsix\nseven',
                    key: key2,
                    style: const TextStyle(fontSize: fontSize2),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final RenderBox textBox1 = tester.renderObject(find.byKey(key1));
      final RenderBox textBox2 = tester.renderObject(find.byKey(key2));
      final RenderBox rowBox = tester.renderObject(find.byType(Row));

      // The two Texts are baseline aligned, so some portion of them extends
      // both above and below the baseline. The first has a huge font size, so
      // it extends higher above the baseline than usual. The second has many
      // lines, but being aligned by the first line's baseline, they hang far
      // below the baseline. The size of the parent row is just enough to
      // contain both of them.
      const double ahemBaselineLocation = 0.8; // https://web-platform-tests.org/writing-tests/ahem.html
      const double aboveBaseline1 = fontSize1 * ahemBaselineLocation;
      const double belowBaseline1 = fontSize1 * (1 - ahemBaselineLocation);
      const double aboveBaseline2 = fontSize2 * ahemBaselineLocation;
      const double belowBaseline2 = fontSize2 * (1 - ahemBaselineLocation) + fontSize2 * 6;
      final double aboveBaseline = math.max(aboveBaseline1, aboveBaseline2);
      final double belowBaseline = math.max(belowBaseline1, belowBaseline2);
      expect(rowBox.size.height, greaterThan(textBox1.size.height));
      expect(rowBox.size.height, greaterThan(textBox2.size.height));
      expect(rowBox.size.height, moreOrLessEquals(aboveBaseline + belowBaseline, epsilon: .001));
      expect(tester.getTopLeft(find.byKey(key1)).dy, 0);
      expect(
        tester.getTopLeft(find.byKey(key2)).dy,
        moreOrLessEquals(aboveBaseline1 - aboveBaseline2, epsilon: .001),
      );
    });

    testWidgets('baseline aligned children account for a larger, no-baseline child size', (WidgetTester tester) async {
      // Regression test for https://github.com/flutter/flutter/issues/58898
      final UniqueKey key1 = UniqueKey();
      final UniqueKey key2 = UniqueKey();
      const double fontSize1 = 54;
      const double fontSize2 = 14;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Container(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: <Widget>[
                  Text('big text',
                    key: key1,
                    style: const TextStyle(fontSize: fontSize1),
                  ),
                  Text('one\ntwo\nthree\nfour\nfive\nsix\nseven',
                    key: key2,
                    style: const TextStyle(fontSize: fontSize2),
                  ),
                  const FlutterLogo(size: 250),
                ],
              ),
            ),
          ),
        ),
      );

      final RenderBox textBox1 = tester.renderObject(find.byKey(key1));
      final RenderBox textBox2 = tester.renderObject(find.byKey(key2));
      final RenderBox rowBox = tester.renderObject(find.byType(Row));

      // The two Texts are baseline aligned, so some portion of them extends
      // both above and below the baseline. The first has a huge font size, so
      // it extends higher above the baseline than usual. The second has many
      // lines, but being aligned by the first line's baseline, they hang far
      // below the baseline. The FlutterLogo extends further than both Texts,
      // so the size of the parent row should contain the FlutterLogo as well.
      const double ahemBaselineLocation = 0.8; // https://web-platform-tests.org/writing-tests/ahem.html
      const double aboveBaseline1 = fontSize1 * ahemBaselineLocation;
      const double aboveBaseline2 = fontSize2 * ahemBaselineLocation;
      expect(rowBox.size.height, greaterThan(textBox1.size.height));
      expect(rowBox.size.height, greaterThan(textBox2.size.height));
      expect(rowBox.size.height, 250);
      expect(tester.getTopLeft(find.byKey(key1)).dy, 0);
      expect(
        tester.getTopLeft(find.byKey(key2)).dy,
        moreOrLessEquals(aboveBaseline1 - aboveBaseline2, epsilon: .001),
      );
    });
  });

  test('UnconstrainedBox toString', () {
    expect(
      const UnconstrainedBox(constrainedAxis: Axis.vertical,).toString(),
      equals('UnconstrainedBox(alignment: Alignment.center, constrainedAxis: vertical)'),
    );
    expect(
      const UnconstrainedBox(constrainedAxis: Axis.horizontal, textDirection: TextDirection.rtl, alignment: Alignment.topRight).toString(),
      equals('UnconstrainedBox(alignment: Alignment.topRight, constrainedAxis: horizontal, textDirection: rtl)'),
    );
  });

  testWidgets('UnconstrainedBox can set and update clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(const UnconstrainedBox());
    final RenderUnconstrainedBox renderObject = tester.allRenderObjects.whereType<RenderUnconstrainedBox>().first;
    expect(renderObject.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(const UnconstrainedBox(clipBehavior: Clip.antiAlias));
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  group('ColoredBox', () {
    late _MockCanvas mockCanvas;
    late _MockPaintingContext mockContext;
    const Color colorToPaint = Color(0xFFABCDEF);

    setUp(() {
      mockContext = _MockPaintingContext();
      mockCanvas = mockContext.canvas;
    });

    testWidgets('ColoredBox - no size, no child', (WidgetTester tester) async {
      await tester.pumpWidget(Flex(
        direction: Axis.horizontal,
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          SizedBox.shrink(
            child: ColoredBox(color: colorToPaint),
          ),
        ],
      ));
      expect(find.byType(ColoredBox), findsOneWidget);
      final RenderObject renderColoredBox = tester.renderObject(find.byType(ColoredBox));

      renderColoredBox.paint(mockContext, Offset.zero);

      expect(mockCanvas.rects, isEmpty);
      expect(mockCanvas.paints, isEmpty);
      expect(mockContext.children, isEmpty);
      expect(mockContext.offets, isEmpty);
    });

    testWidgets('ColoredBox - no size, child', (WidgetTester tester) async {
      const ValueKey<int> key = ValueKey<int>(0);
      const Widget child = SizedBox.expand(key: key);
      await tester.pumpWidget(Flex(
        direction: Axis.horizontal,
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          SizedBox.shrink(
            child: ColoredBox(color: colorToPaint, child: child),
          ),
        ],
      ));
      expect(find.byType(ColoredBox), findsOneWidget);
      final RenderObject renderColoredBox = tester.renderObject(find.byType(ColoredBox));
      final RenderObject renderSizedBox = tester.renderObject(find.byKey(key));

      renderColoredBox.paint(mockContext, Offset.zero);

      expect(mockCanvas.rects, isEmpty);
      expect(mockCanvas.paints, isEmpty);
      expect(mockContext.children.single, renderSizedBox);
      expect(mockContext.offets.single, Offset.zero);
    });

    testWidgets('ColoredBox - size, no child', (WidgetTester tester) async {
      await tester.pumpWidget(const ColoredBox(color: colorToPaint));
      expect(find.byType(ColoredBox), findsOneWidget);
      final RenderObject renderColoredBox = tester.renderObject(find.byType(ColoredBox));

      renderColoredBox.paint(mockContext, Offset.zero);

      expect(mockCanvas.rects.single, const Rect.fromLTWH(0, 0, 800, 600));
      expect(mockCanvas.paints.single.color, colorToPaint);
      expect(mockContext.children, isEmpty);
      expect(mockContext.offets, isEmpty);
    });

    testWidgets('ColoredBox - size, child', (WidgetTester tester) async {
      const ValueKey<int> key = ValueKey<int>(0);
      const Widget child = SizedBox.expand(key: key);
      await tester.pumpWidget(const ColoredBox(color: colorToPaint, child: child));
      expect(find.byType(ColoredBox), findsOneWidget);
      final RenderObject renderColoredBox = tester.renderObject(find.byType(ColoredBox));
      final RenderObject renderSizedBox = tester.renderObject(find.byKey(key));

      renderColoredBox.paint(mockContext, Offset.zero);

      expect(mockCanvas.rects.single, const Rect.fromLTWH(0, 0, 800, 600));
      expect(mockCanvas.paints.single.color, colorToPaint);
      expect(mockContext.children.single, renderSizedBox);
      expect(mockContext.offets.single, Offset.zero);
    });

    testWidgets('ColoredBox - properties', (WidgetTester tester) async {
      const ColoredBox box = ColoredBox(color: colorToPaint);
      final DiagnosticPropertiesBuilder properties = DiagnosticPropertiesBuilder();
      box.debugFillProperties(properties);

      expect(properties.properties.first.value, colorToPaint);
    });
  });
  testWidgets('Inconsequential golden test', (WidgetTester tester) async {
    // The test validates the Flutter Gold integration. Any changes to the
    // golden file can be approved at any time.
    await tester.pumpWidget(RepaintBoundary(
      child: Container(
        color: const Color(0xABCDABCD),
      ),
    ));

    await tester.pumpAndSettle();
    await expectLater(
      find.byType(RepaintBoundary),
      matchesGoldenFile('inconsequential_golden_file.png'),
    );
  });

  testWidgets('IgnorePointer ignores pointers', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    Widget target({required bool ignoring}) => Align(
      alignment: Alignment.topLeft,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 100,
          height: 100,
          child: Listener(
            onPointerDown: (_) { logs.add('down1'); },
            child: MouseRegion(
              onEnter: (_) { logs.add('enter1'); },
              onExit: (_) { logs.add('exit1'); },
              cursor: SystemMouseCursors.forbidden,
              child: Stack(
                children: <Widget>[
                  Listener(
                    onPointerDown: (_) { logs.add('down2'); },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) { logs.add('enter2'); },
                      onExit: (_) { logs.add('exit2'); },
                    ),
                  ),
                  IgnorePointer(
                    ignoring: ignoring,
                    child: Listener(
                      onPointerDown: (_) { logs.add('down3'); },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.text,
                        onEnter: (_) { logs.add('enter3'); },
                        onExit: (_) { logs.add('exit3'); },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(pointer: 1, kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(200, 200));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(target(ignoring: true));
    expect(logs, isEmpty);

    await gesture.moveTo(const Offset(50, 50));
    expect(logs, <String>['enter1', 'enter2']);
    logs.clear();

    await gesture.down(const Offset(50, 50));
    expect(logs, <String>['down2', 'down1']);
    logs.clear();

    await gesture.up();
    expect(logs, isEmpty);

    await tester.pumpWidget(target(ignoring: false));
    expect(logs, <String>['exit2', 'enter3']);
    logs.clear();

    await gesture.down(const Offset(50, 50));
    expect(logs, <String>['down3', 'down1']);
    logs.clear();

    await gesture.up();
    expect(logs, isEmpty);

    await tester.pumpWidget(target(ignoring: true));
    expect(logs, <String>['exit3', 'enter2']);
    logs.clear();
  });

  testWidgets('AbsorbPointer absorbs pointers', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    Widget target({required bool absorbing}) => Align(
      alignment: Alignment.topLeft,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(
          width: 100,
          height: 100,
          child: Listener(
            onPointerDown: (_) { logs.add('down1'); },
            child: MouseRegion(
              onEnter: (_) { logs.add('enter1'); },
              onExit: (_) { logs.add('exit1'); },
              cursor: SystemMouseCursors.forbidden,
              child: Stack(
                children: <Widget>[
                  Listener(
                    onPointerDown: (_) { logs.add('down2'); },
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      onEnter: (_) { logs.add('enter2'); },
                      onExit: (_) { logs.add('exit2'); },
                    ),
                  ),
                  AbsorbPointer(
                    absorbing: absorbing,
                    child: Listener(
                      onPointerDown: (_) { logs.add('down3'); },
                      child: MouseRegion(
                        cursor: SystemMouseCursors.text,
                        onEnter: (_) { logs.add('enter3'); },
                        onExit: (_) { logs.add('exit3'); },
                      ),
                    ),
                  )
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.createGesture(pointer: 1, kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(200, 200));
    addTearDown(gesture.removePointer);

    await tester.pumpWidget(target(absorbing: true));
    expect(logs, isEmpty);

    await gesture.moveTo(const Offset(50, 50));
    expect(logs, <String>['enter1']);
    logs.clear();

    await gesture.down(const Offset(50, 50));
    expect(logs, <String>['down1']);
    logs.clear();

    await gesture.up();
    expect(logs, isEmpty);

    await tester.pumpWidget(target(absorbing: false));
    expect(logs, <String>['enter3']);
    logs.clear();

    await gesture.down(const Offset(50, 50));
    expect(logs, <String>['down3', 'down1']);
    logs.clear();

    await gesture.up();
    expect(logs, isEmpty);

    await tester.pumpWidget(target(absorbing: true));
    expect(logs, <String>['exit3']);
    logs.clear();
  });
}

HitsRenderBox hits(RenderBox renderBox) => HitsRenderBox(renderBox);

class HitsRenderBox extends Matcher {
  const HitsRenderBox(this.renderBox);

  final RenderBox renderBox;

  @override
  Description describe(Description description) =>
    description.add('hit test result contains ').addDescriptionOf(renderBox);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final HitTestResult hitTestResult = item as HitTestResult;
    return hitTestResult.path.where(
      (HitTestEntry entry) => entry.target == renderBox
    ).isNotEmpty;
  }
}

DoesNotHitRenderBox doesNotHit(RenderBox renderBox) => DoesNotHitRenderBox(renderBox);

class DoesNotHitRenderBox extends Matcher {
  const DoesNotHitRenderBox(this.renderBox);

  final RenderBox renderBox;

  @override
  Description describe(Description description) =>
    description.add("hit test result doesn't contain ").addDescriptionOf(renderBox);

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    final HitTestResult hitTestResult = item as HitTestResult;
    return hitTestResult.path.where(
      (HitTestEntry entry) => entry.target == renderBox
    ).isEmpty;
  }
}

class _MockPaintingContext extends Fake implements PaintingContext {
  final List<RenderObject> children = <RenderObject>[];
  final List<Offset> offets = <Offset>[];

  @override
  final _MockCanvas canvas = _MockCanvas();

  @override
  void paintChild(RenderObject child, Offset offset) {
    children.add(child);
    offets.add(offset);
  }
}

class _MockCanvas extends Fake implements Canvas {
  final List<Rect> rects = <Rect>[];
  final List<Paint> paints = <Paint>[];
  bool didPaint = false;

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    paints.add(paint);
  }
}
