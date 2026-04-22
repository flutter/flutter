// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

class TestPaintingContext implements PaintingContext {
  final List<Invocation> invocations = <Invocation>[];

  @override
  void noSuchMethod(Invocation invocation) {
    invocations.add(invocation);
  }
}

void main() {
  testWidgets('Can construct an empty Stack', (WidgetTester tester) async {
    await tester.pumpWidget(const Directionality(textDirection: TextDirection.ltr, child: Stack()));
  });

  testWidgets('Can construct an empty Centered Stack', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: Stack()),
      ),
    );
  });

  testWidgets('Can change position data', (WidgetTester tester) async {
    const key = Key('container');

    await tester.pumpWidget(
      const Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          Positioned(left: 10.0, child: SizedBox(key: key, width: 10.0, height: 10.0)),
        ],
      ),
    );

    Element container;
    StackParentData parentData;

    container = tester.element(find.byKey(key));
    parentData = container.renderObject!.parentData! as StackParentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, equals(10.0));
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);

    await tester.pumpWidget(
      const Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          Positioned(right: 10.0, child: SizedBox(key: key, width: 10.0, height: 10.0)),
        ],
      ),
    );

    container = tester.element(find.byKey(key));
    parentData = container.renderObject!.parentData! as StackParentData;
    expect(parentData.top, isNull);
    expect(parentData.right, equals(10.0));
    expect(parentData.bottom, isNull);
    expect(parentData.left, isNull);
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);
  });

  testWidgets('Can remove parent data', (WidgetTester tester) async {
    const key = Key('container');
    const sizedBox = SizedBox(key: key, width: 10.0, height: 10.0);

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[Positioned(left: 10.0, child: sizedBox)],
      ),
    );
    Element containerElement = tester.element(find.byKey(key));

    StackParentData parentData;
    parentData = containerElement.renderObject!.parentData! as StackParentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, equals(10.0));
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);

    await tester.pumpWidget(
      const Stack(textDirection: TextDirection.ltr, children: <Widget>[sizedBox]),
    );
    containerElement = tester.element(find.byKey(key));

    parentData = containerElement.renderObject!.parentData! as StackParentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, isNull);
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);
  });

  testWidgets('Can align non-positioned children (LTR)', (WidgetTester tester) async {
    const child0Key = Key('child0');
    const child1Key = Key('child1');

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(key: child0Key, width: 20.0, height: 20.0),
              SizedBox(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    final Element child0 = tester.element(find.byKey(child0Key));
    final child0RenderObjectParentData = child0.renderObject!.parentData! as StackParentData;
    expect(child0RenderObjectParentData.offset, equals(Offset.zero));

    final Element child1 = tester.element(find.byKey(child1Key));
    final child1RenderObjectParentData = child1.renderObject!.parentData! as StackParentData;
    expect(child1RenderObjectParentData.offset, equals(const Offset(5.0, 5.0)));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: <Widget>[
              SizedBox(key: child0Key, width: 20.0, height: 20.0),
              SizedBox(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    expect(child0RenderObjectParentData.offset, equals(Offset.zero));
    expect(child1RenderObjectParentData.offset, equals(const Offset(10.0, 10.0)));
  });

  testWidgets('Can align non-positioned children (RTL)', (WidgetTester tester) async {
    const child0Key = Key('child0');
    const child1Key = Key('child1');

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox(key: child0Key, width: 20.0, height: 20.0),
              SizedBox(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    final Element child0 = tester.element(find.byKey(child0Key));
    final child0RenderObjectParentData = child0.renderObject!.parentData! as StackParentData;
    expect(child0RenderObjectParentData.offset, equals(Offset.zero));

    final Element child1 = tester.element(find.byKey(child1Key));
    final child1RenderObjectParentData = child1.renderObject!.parentData! as StackParentData;
    expect(child1RenderObjectParentData.offset, equals(const Offset(5.0, 5.0)));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Center(
          child: Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: <Widget>[
              SizedBox(key: child0Key, width: 20.0, height: 20.0),
              SizedBox(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    expect(child0RenderObjectParentData.offset, equals(Offset.zero));
    expect(child1RenderObjectParentData.offset, equals(const Offset(0.0, 10.0)));
  });

  testWidgets('Can set width and height', (WidgetTester tester) async {
    const key = Key('container');

    const kBoxDecoration = BoxDecoration(color: Color(0xFF00FF00));

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Positioned(
            left: 10.0,
            width: 11.0,
            height: 12.0,
            child: DecoratedBox(key: key, decoration: kBoxDecoration),
          ),
        ],
      ),
    );

    Element box;
    RenderBox renderBox;
    StackParentData parentData;

    box = tester.element(find.byKey(key));
    renderBox = box.renderObject! as RenderBox;
    parentData = renderBox.parentData! as StackParentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, equals(10.0));
    expect(parentData.width, equals(11.0));
    expect(parentData.height, equals(12.0));
    expect(parentData.offset.dx, equals(10.0));
    expect(parentData.offset.dy, equals(0.0));
    expect(renderBox.size.width, equals(11.0));
    expect(renderBox.size.height, equals(12.0));

    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Positioned(
            right: 10.0,
            width: 11.0,
            height: 12.0,
            child: DecoratedBox(key: key, decoration: kBoxDecoration),
          ),
        ],
      ),
    );

    box = tester.element(find.byKey(key));
    renderBox = box.renderObject! as RenderBox;
    parentData = renderBox.parentData! as StackParentData;
    expect(parentData.top, isNull);
    expect(parentData.right, equals(10.0));
    expect(parentData.bottom, isNull);
    expect(parentData.left, isNull);
    expect(parentData.width, equals(11.0));
    expect(parentData.height, equals(12.0));
    expect(parentData.offset.dx, equals(779.0));
    expect(parentData.offset.dy, equals(0.0));
    expect(renderBox.size.width, equals(11.0));
    expect(renderBox.size.height, equals(12.0));
  });

  testWidgets('Can set and update clipBehavior', (WidgetTester tester) async {
    await tester.pumpWidget(const Stack(textDirection: TextDirection.ltr));
    final RenderStack renderObject = tester.allRenderObjects.whereType<RenderStack>().first;
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    await tester.pumpWidget(const Stack(textDirection: TextDirection.ltr));
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));
  });

  testWidgets('Clip.none is respected by describeApproximateClip', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          Positioned(left: 1000, right: 2000, child: SizedBox(width: 2000, height: 2000)),
        ],
      ),
    );
    final RenderStack renderObject = tester.allRenderObjects.whereType<RenderStack>().first;
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    var visited = false;
    renderObject.visitChildren((RenderObject child) {
      visited = true;
      expect(
        renderObject.describeApproximatePaintClip(child),
        const Rect.fromLTRB(0.0, 0.0, 800.0, 600.0),
      );
    });
    expect(visited, true);
    visited = false;
    renderObject.clipBehavior = Clip.none;
    renderObject.visitChildren((RenderObject child) {
      visited = true;
      expect(renderObject.describeApproximatePaintClip(child), null);
    });
    expect(visited, true);
  });

  testWidgets('Stack clip test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Stack(
            children: <Widget>[
              SizedBox(width: 100.0, height: 100.0),
              Positioned(top: 0.0, left: 0.0, child: SizedBox(width: 200.0, height: 200.0)),
            ],
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(Stack));
    var context = TestPaintingContext();
    box.paint(context, Offset.zero);
    expect(context.invocations.first.memberName, equals(#pushClipRect));

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              SizedBox(width: 100.0, height: 100.0),
              Positioned(top: 0.0, left: 0.0, child: SizedBox(width: 200.0, height: 200.0)),
            ],
          ),
        ),
      ),
    );

    box = tester.renderObject(find.byType(Stack));
    context = TestPaintingContext();
    box.paint(context, Offset.zero);
    expect(context.invocations.first.memberName, equals(#paintChild));
  });

  testWidgets('Stack sizing: default', (WidgetTester tester) async {
    final logs = <String>[];
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 2.0,
              maxWidth: 3.0,
              minHeight: 5.0,
              maxHeight: 7.0,
            ),
            child: Stack(
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    logs.add(constraints.toString());
                    return const Placeholder();
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
    expect(logs, <String>['BoxConstraints(0.0<=w<=3.0, 0.0<=h<=7.0)']);
  });

  testWidgets('Stack sizing: explicit', (WidgetTester tester) async {
    final logs = <String>[];
    Widget buildStack(StackFit sizing) {
      return Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 2.0,
              maxWidth: 3.0,
              minHeight: 5.0,
              maxHeight: 7.0,
            ),
            child: Stack(
              fit: sizing,
              children: <Widget>[
                LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    logs.add(constraints.toString());
                    return const Placeholder();
                  },
                ),
              ],
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(buildStack(StackFit.loose));
    logs.add('=1=');
    await tester.pumpWidget(buildStack(StackFit.expand));
    logs.add('=2=');
    await tester.pumpWidget(buildStack(StackFit.passthrough));
    expect(logs, <String>[
      'BoxConstraints(0.0<=w<=3.0, 0.0<=h<=7.0)',
      '=1=',
      'BoxConstraints(w=3.0, h=7.0)',
      '=2=',
      'BoxConstraints(2.0<=w<=3.0, 5.0<=h<=7.0)',
    ]);
  });

  testWidgets('Positioned.directional control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned.directional(
              textDirection: TextDirection.rtl,
              start: 50.0,
              child: SizedBox(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(675.0, 0.0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            Positioned.directional(
              textDirection: TextDirection.ltr,
              start: 50.0,
              child: SizedBox(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(50.0, 0.0));
  });

  testWidgets('PositionedDirectional control test', (WidgetTester tester) async {
    final Key key = UniqueKey();
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              start: 50.0,
              child: SizedBox(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(675.0, 0.0));

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          children: <Widget>[
            PositionedDirectional(
              start: 50.0,
              child: SizedBox(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(50.0, 0.0));
  });

  testWidgets('Can change the text direction of a Stack', (WidgetTester tester) async {
    await tester.pumpWidget(const Stack(alignment: Alignment.center));
    await tester.pumpWidget(const Stack(textDirection: TextDirection.rtl));
    await tester.pumpWidget(const Stack(alignment: Alignment.center));
  });

  testWidgets('Alignment with partially-positioned children', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.rtl,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(width: 100.0, height: 100.0),
            Positioned(left: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(right: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(start: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(end: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(0)),
      const Rect.fromLTWH(350.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(1)),
      const Rect.fromLTWH(0.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(2)),
      const Rect.fromLTWH(700.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(3)),
      const Rect.fromLTWH(350.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(4)),
      const Rect.fromLTWH(350.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(5)),
      const Rect.fromLTWH(700.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(6)),
      const Rect.fromLTWH(0.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(7)),
      const Rect.fromLTWH(350.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(8)),
      const Rect.fromLTWH(350.0, 500.0, 100.0, 100.0),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            SizedBox(width: 100.0, height: 100.0),
            Positioned(left: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(right: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(start: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(end: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(0)),
      const Rect.fromLTWH(350.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(1)),
      const Rect.fromLTWH(0.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(2)),
      const Rect.fromLTWH(700.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(3)),
      const Rect.fromLTWH(350.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(4)),
      const Rect.fromLTWH(350.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(5)),
      const Rect.fromLTWH(0.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(6)),
      const Rect.fromLTWH(700.0, 250.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(7)),
      const Rect.fromLTWH(350.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(8)),
      const Rect.fromLTWH(350.0, 500.0, 100.0, 100.0),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          alignment: Alignment.bottomRight,
          children: <Widget>[
            SizedBox(width: 100.0, height: 100.0),
            Positioned(left: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(right: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(start: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(end: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(0)),
      const Rect.fromLTWH(700.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(1)),
      const Rect.fromLTWH(0.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(2)),
      const Rect.fromLTWH(700.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(3)),
      const Rect.fromLTWH(700.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(4)),
      const Rect.fromLTWH(700.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(5)),
      const Rect.fromLTWH(0.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(6)),
      const Rect.fromLTWH(700.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(7)),
      const Rect.fromLTWH(700.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(8)),
      const Rect.fromLTWH(700.0, 500.0, 100.0, 100.0),
    );

    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Stack(
          alignment: Alignment.topLeft,
          children: <Widget>[
            SizedBox(width: 100.0, height: 100.0),
            Positioned(left: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(right: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            Positioned(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(start: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(end: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(top: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
            PositionedDirectional(bottom: 0.0, child: SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(0)),
      const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(1)),
      const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(2)),
      const Rect.fromLTWH(700.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(3)),
      const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(4)),
      const Rect.fromLTWH(0.0, 500.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(5)),
      const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(6)),
      const Rect.fromLTWH(700.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(7)),
      const Rect.fromLTWH(0.0, 0.0, 100.0, 100.0),
    );
    expect(
      tester.getRect(find.byType(SizedBox).at(8)),
      const Rect.fromLTWH(0.0, 500.0, 100.0, 100.0),
    );
  });

  testWidgets(
    'Stack error messages',
    experimentalLeakTesting: LeakTesting.settings
        .withIgnoredAll(), // leaking by design because of exception
    (WidgetTester tester) async {
      await tester.pumpWidget(const Stack());
      final exception = tester.takeException().toString();

      expect(
        exception,
        startsWith(
          'No Directionality widget found.\n'
          "Stack widgets require a Directionality widget ancestor to resolve the 'alignment' argument.\n"
          "The default value for 'alignment' is AlignmentDirectional.topStart, which requires a text direction.\n"
          'The specific widget that could not find a Directionality ancestor was:\n'
          '  Stack\n'
          'The ownership chain for the affected widget is: "Stack ← ', // Omitted full ownership chain because it is not relevant for the test.
        ),
      );
      expect(
        exception,
        endsWith(
          '_ViewScope ← ⋯"\n' // End of ownership chain.
          'Typically, the Directionality widget is introduced by the MaterialApp or WidgetsApp widget at the '
          'top of your application widget tree. It determines the ambient reading direction and is used, for '
          'example, to determine how to lay out text, how to interpret "start" and "end" values, and to resolve '
          'EdgeInsetsDirectional, AlignmentDirectional, and other *Directional objects.\n'
          'Instead of providing a Directionality widget, another solution would be passing a non-directional '
          "'alignment', or an explicit 'textDirection', to the Stack.",
        ),
      );
    },
  );
}
