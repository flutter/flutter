// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget constrainedFlex({
    required Axis direction,
    required MainAxisAlignment mainAxisAlignment,
    required double spacing,
  }) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: SizedBox.square(
          dimension: 300.0,
          child: Flex(
            direction: direction,
            mainAxisAlignment: mainAxisAlignment,
            spacing: spacing,
            children: const <Widget>[
              SizedBox.square(dimension: 50.0),
              SizedBox.square(dimension: 50.0),
              SizedBox.square(dimension: 50.0),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('Can hit test flex children of stacks', (WidgetTester tester) async {
    var didReceiveTap = false;
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: ColoredBox(
          color: const Color(0xFF00FF00),
          child: Stack(
            children: <Widget>[
              Positioned(
                top: 10.0,
                left: 10.0,
                child: Column(
                  children: <Widget>[
                    GestureDetector(
                      onTap: () {
                        didReceiveTap = true;
                      },
                      child: Container(
                        color: const Color(0xFF0000FF),
                        width: 100.0,
                        height: 100.0,
                        child: const Center(child: Text('X', textDirection: TextDirection.ltr)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    expect(didReceiveTap, isTrue);
  });

  testWidgets('Flexible defaults to loose', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Row(
        textDirection: TextDirection.ltr,
        children: <Widget>[Flexible(child: SizedBox(width: 100.0, height: 200.0))],
      ),
    );

    final RenderBox box = tester.renderObject(find.byType(SizedBox));
    expect(box.size.width, 100.0);
  });

  testWidgets("Doesn't overflow because of floating point accumulated error", (
    WidgetTester tester,
  ) async {
    // both of these cases have failed in the past due to floating point issues
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 400.0,
          child: Column(
            children: <Widget>[
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(
      const Center(
        child: SizedBox(
          height: 199.0,
          child: Column(
            children: <Widget>[
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
              Expanded(child: SizedBox()),
            ],
          ),
        ),
      ),
    );
  });

  testWidgets('Error information is printed correctly', (WidgetTester tester) async {
    // We run this twice, the first time without an error, so that the second time
    // we only get a single exception. Otherwise we'd get two, the one we want and
    // an extra one when we discover we never computed a size.
    await tester.pumpWidget(
      const Column(children: <Widget>[Column()]),
      duration: Duration.zero,
      phase: EnginePhase.layout,
    );

    // Turn off intrinsics checking, which also fails with the same exception.
    debugCheckIntrinsicSizes = false;
    await tester.pumpWidget(
      Column(
        children: <Widget>[
          Column(children: <Widget>[Expanded(child: Container())]),
        ],
      ),
      duration: Duration.zero,
      phase: EnginePhase.layout,
    );
    debugCheckIntrinsicSizes = true;
    final message = tester.takeException().toString();
    expect(message, contains('\nSee also:'));
  });

  testWidgets('Can set and update clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(const Flex(direction: Axis.vertical));
    final RenderFlex renderObject = tester.allRenderObjects.whereType<RenderFlex>().first;
    expect(renderObject.clipBehavior, equals(Clip.none));

    await tester.pumpWidget(const Flex(direction: Axis.vertical, clipBehavior: Clip.antiAlias));
    expect(renderObject.clipBehavior, equals(Clip.antiAlias));
  });

  test('Flex/Column/Row can be const-constructed', () {
    const Flex(direction: Axis.vertical);
    const Column();
    const Row();
  });

  testWidgets('Default Flex.spacing value', (WidgetTester tester) async {
    await tester.pumpWidget(const Flex(direction: Axis.vertical));

    final Flex flex = tester.widget(find.byType(Flex));
    expect(flex.spacing, 0.0);
  });

  testWidgets('Can update Flex.spacing value', (WidgetTester tester) async {
    Widget buildFlex({required double spacing}) {
      return Center(
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: Flex(
            spacing: spacing,
            direction: Axis.vertical,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(height: 100.0, width: 100.0, color: const Color(0xFFFF0000)),
              Container(height: 100.0, width: 100.0, color: const Color(0xFF0000FF)),
              Container(height: 100.0, width: 100.0, color: const Color(0xff00FF00)),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(buildFlex(spacing: 8.0));

    RenderFlex renderObject = tester.allRenderObjects.whereType<RenderFlex>().first;
    expect(renderObject.spacing, equals(8.0));
    expect(tester.getSize(find.byType(Flex)).width, equals(100.0));
    expect(tester.getSize(find.byType(Flex)).height, equals(316.0));

    await tester.pumpWidget(buildFlex(spacing: 18.0));

    renderObject = tester.allRenderObjects.whereType<RenderFlex>().first;
    expect(renderObject.spacing, equals(18.0));
    expect(tester.getSize(find.byType(Flex)).width, equals(100.0));
    expect(tester.getSize(find.byType(Flex)).height, equals(336.0));
  });

  testWidgets('Overconstrained Flex with MainAxisAlignment.start and spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 50.0,
      ),
    );
    // 50.0 * 3 (children) + 50.0 * 2 (spacing) = 250.0 < 300.0 (constraints)
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.start,
        spacing: 100.0,
      ),
    );
    // 50.0 * 3 (children) + 100.0 * 2 (spacing) = 350.0 > 300.0 (constraints)
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Overconstrained Flex with MainAxisAlignment.end and spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 50.0,
      ),
    );
    // 50.0 * 3 (children) + 50.0 * 2 (spacing) = 250.0 < 300.0 (constraints)
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: 100.0,
      ),
    );
    // 50.0 * 3 (children) + 100.0 * 2 (spacing) = 350.0 > 300.0 (constraints)
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Overconstrained Flex with MainAxisAlignment.center and spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 50.0,
      ),
    );
    // 50.0 * 3 (children) + 50.0 * 2 (spacing) = 250.0 < 300.0 (constraints)
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 100.0,
      ),
    );
    // 50.0 * 3 (children) + 100.0 * 2 (spacing) = 350.0 > 300.0 (constraints)
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Overconstrained Flex with MainAxisAlignment.spaceAround and spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: 50.0,
      ),
    );
    // 50.0 * 3 (children) + 50.0 * 2 (spacing) = 250.0 < 300.0 (constraints)
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        spacing: 100.0,
      ),
    );
    // 50.0 * 3 (children) + 100.0 * 2 (spacing) = 350.0 > 300.0 (constraints)
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Overconstrained Flex with MainAxisAlignment.spaceEvenly and spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 50.0,
      ),
    );
    // 50.0 * 3 (children) + 50.0 * 2 (spacing) = 250.0 < 300.0 (constraints)
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        spacing: 100.0,
      ),
    );
    // 50.0 * 3 (children) + 100.0 * 2 (spacing) = 350.0 > 300.0 (constraints)
    expect(tester.takeException(), isAssertionError);
  });

  testWidgets('Overconstrained Flex with MainAxisAlignment.spaceBetween and spacing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 50.0,
      ),
    );
    // 50.0 * 3 (children) + 50.0 * 2 (spacing) = 250.0 < 300.0 (constraints)
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      constrainedFlex(
        direction: Axis.vertical,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        spacing: 100.0,
      ),
    );
    // 50.0 * 3 (children) + 100.0 * 2 (spacing) = 350.0 > 300.0 (constraints)
    expect(tester.takeException(), isAssertionError);
  });

  group('ignoreZeroSizeChildrenForSpacing', () {
    Widget column({
      required bool ignoreZeroSizeChildrenForSpacing,
      required List<Widget> children,
    }) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Align(
          alignment: Alignment.topLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 16.0,
            ignoreZeroSizeChildrenForSpacing: ignoreZeroSizeChildrenForSpacing,
            children: children,
          ),
        ),
      );
    }

    const childrenWithGap = <Widget>[
      SizedBox(key: Key('a'), width: 10.0, height: 20.0),
      SizedBox.shrink(),
      SizedBox(key: Key('b'), width: 10.0, height: 20.0),
    ];

    testWidgets('defaults to false so zero-size children still take spacing', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        column(ignoreZeroSizeChildrenForSpacing: false, children: childrenWithGap),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy, 52.0);
      expect(tester.getSize(find.byType(Column)).height, 72.0);
    });

    testWidgets('true removes the gap around a zero-size child', (WidgetTester tester) async {
      await tester.pumpWidget(
        column(ignoreZeroSizeChildrenForSpacing: true, children: childrenWithGap),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy, 36.0);
      expect(tester.getSize(find.byType(Column)).height, 56.0);
    });

    testWidgets('true ignores a child that builds to zero size at layout time', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        column(
          ignoreZeroSizeChildrenForSpacing: true,
          children: <Widget>[
            const SizedBox(key: Key('a'), width: 10.0, height: 20.0),
            Builder(builder: (BuildContext context) => const SizedBox.shrink()),
            const SizedBox(key: Key('b'), width: 10.0, height: 20.0),
          ],
        ),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy, 36.0);
      expect(tester.getSize(find.byType(Column)).height, 56.0);
    });

    testWidgets('true keeps spacing between every visible child', (WidgetTester tester) async {
      await tester.pumpWidget(
        column(
          ignoreZeroSizeChildrenForSpacing: true,
          children: const <Widget>[
            SizedBox(key: Key('a'), width: 10.0, height: 20.0),
            SizedBox(key: Key('b'), width: 10.0, height: 20.0),
            SizedBox(key: Key('c'), width: 10.0, height: 20.0),
          ],
        ),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy, 36.0);
      expect(tester.getTopLeft(find.byKey(const Key('c'))).dy, 72.0);
      expect(tester.getSize(find.byType(Column)).height, 92.0);
    });

    testWidgets('true distributes spaceBetween across visible children only', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 100.0,
              width: 10.0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                ignoreZeroSizeChildrenForSpacing: true,
                children: <Widget>[
                  SizedBox(key: Key('a'), width: 10.0, height: 20.0),
                  SizedBox.shrink(),
                  SizedBox(key: Key('b'), width: 10.0, height: 20.0),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(const Key('a'))).dy, 0.0);
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy, 80.0);
    });

    testWidgets('true still lays out Expanded children', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              height: 100.0,
              width: 10.0,
              child: Column(
                spacing: 16.0,
                ignoreZeroSizeChildrenForSpacing: true,
                children: <Widget>[
                  SizedBox(key: Key('a'), width: 10.0, height: 20.0),
                  SizedBox.shrink(),
                  Expanded(child: SizedBox(key: Key('b'), width: 10.0)),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dy, 36.0);
      expect(tester.getSize(find.byKey(const Key('b'))).height, 64.0);
    });

    testWidgets('true applies to a horizontal Row', (WidgetTester tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              spacing: 16.0,
              ignoreZeroSizeChildrenForSpacing: true,
              children: <Widget>[
                SizedBox(key: Key('a'), width: 20.0, height: 10.0),
                SizedBox.shrink(),
                SizedBox(key: Key('b'), width: 20.0, height: 10.0),
              ],
            ),
          ),
        ),
      );
      expect(tester.getTopLeft(find.byKey(const Key('b'))).dx, 36.0);
      expect(tester.getSize(find.byType(Row)).width, 56.0);
    });
  });
}
