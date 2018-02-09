// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../rendering/rendering_tester.dart';

class TestPaintingContext implements PaintingContext {
  final List<Invocation> invocations = <Invocation>[];

  @override
    void noSuchMethod(Invocation invocation) {
      invocations.add(invocation);
    }
}

void main() {
  testWidgets('Can construct an empty Stack', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(),
      ),
    );
  });

  testWidgets('Can construct an empty Centered Stack', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(child: new Stack()),
      ),
    );
  });

  testWidgets('Can change position data', (WidgetTester tester) async {
    const Key key = const Key('container');

    await tester.pumpWidget(
      new Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          new Positioned(
            left: 10.0,
            child: new Container(
              key: key,
              width: 10.0,
              height: 10.0,
            ),
          ),
        ],
      ),
    );

    Element container;
    StackParentData parentData;

    container = tester.element(find.byKey(key));
    parentData = container.renderObject.parentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, equals(10.0));
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);

    await tester.pumpWidget(
      new Stack(
        alignment: Alignment.topLeft,
        children: <Widget>[
          new Positioned(
            right: 10.0,
            child: new Container(
              key: key,
              width: 10.0,
              height: 10.0,
            ),
          ),
        ],
      ),
    );

    container = tester.element(find.byKey(key));
    parentData = container.renderObject.parentData;
    expect(parentData.top, isNull);
    expect(parentData.right, equals(10.0));
    expect(parentData.bottom, isNull);
    expect(parentData.left, isNull);
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);
  });

  testWidgets('Can remove parent data', (WidgetTester tester) async {
    const Key key = const Key('container');
    final Container container = new Container(key: key, width: 10.0, height: 10.0);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[ new Positioned(left: 10.0, child: container) ],
      ),
    );
    Element containerElement = tester.element(find.byKey(key));

    StackParentData parentData;
    parentData = containerElement.renderObject.parentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, equals(10.0));
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[ container ],
      ),
    );
    containerElement = tester.element(find.byKey(key));

    parentData = containerElement.renderObject.parentData;
    expect(parentData.top, isNull);
    expect(parentData.right, isNull);
    expect(parentData.bottom, isNull);
    expect(parentData.left, isNull);
    expect(parentData.width, isNull);
    expect(parentData.height, isNull);
  });

  testWidgets('Can align non-positioned children (LTR)', (WidgetTester tester) async {
    const Key child0Key = const Key('child0');
    const Key child1Key = const Key('child1');

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Stack(
            alignment: Alignment.center,
            children: <Widget>[
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    final Element child0 = tester.element(find.byKey(child0Key));
    final StackParentData child0RenderObjectParentData = child0.renderObject.parentData;
    expect(child0RenderObjectParentData.offset, equals(const Offset(0.0, 0.0)));

    final Element child1 = tester.element(find.byKey(child1Key));
    final StackParentData child1RenderObjectParentData = child1.renderObject.parentData;
    expect(child1RenderObjectParentData.offset, equals(const Offset(5.0, 5.0)));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: <Widget>[
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    expect(child0RenderObjectParentData.offset, equals(const Offset(0.0, 0.0)));
    expect(child1RenderObjectParentData.offset, equals(const Offset(10.0, 10.0)));
  });

  testWidgets('Can align non-positioned children (RTL)', (WidgetTester tester) async {
    const Key child0Key = const Key('child0');
    const Key child1Key = const Key('child1');

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Stack(
            alignment: Alignment.center,
            children: <Widget>[
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    final Element child0 = tester.element(find.byKey(child0Key));
    final StackParentData child0RenderObjectParentData = child0.renderObject.parentData;
    expect(child0RenderObjectParentData.offset, equals(const Offset(0.0, 0.0)));

    final Element child1 = tester.element(find.byKey(child1Key));
    final StackParentData child1RenderObjectParentData = child1.renderObject.parentData;
    expect(child1RenderObjectParentData.offset, equals(const Offset(5.0, 5.0)));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Center(
          child: new Stack(
            alignment: AlignmentDirectional.bottomEnd,
            children: <Widget>[
              new Container(key: child0Key, width: 20.0, height: 20.0),
              new Container(key: child1Key, width: 10.0, height: 10.0),
            ],
          ),
        ),
      ),
    );

    expect(child0RenderObjectParentData.offset, equals(const Offset(0.0, 0.0)));
    expect(child1RenderObjectParentData.offset, equals(const Offset(0.0, 10.0)));
  });

  testWidgets('Can construct an empty IndexedStack', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new IndexedStack(),
      ),
    );
  });

  testWidgets('Can construct an empty Centered IndexedStack', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(child: new IndexedStack()),
      ),
    );
  });

  testWidgets('Can construct an IndexedStack', (WidgetTester tester) async {
    const int itemCount = 3;
    List<int> itemsPainted;

    Widget buildFrame(int index) {
      itemsPainted = <int>[];
      final List<Widget> items = new List<Widget>.generate(itemCount, (int i) {
        return new CustomPaint(
          child: new Text('$i', textDirection: TextDirection.ltr),
          painter: new TestCallbackPainter(
            onPaint: () { itemsPainted.add(i); }
          ),
        );
      });
      return new Center(
        child: new IndexedStack(
          alignment: Alignment.topLeft,
          children: items,
          index: index,
        ),
      );
    }

    await tester.pumpWidget(buildFrame(0));
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(itemsPainted, equals(<int>[0]));

    await tester.pumpWidget(buildFrame(1));
    expect(itemsPainted, equals(<int>[1]));

    await tester.pumpWidget(buildFrame(2));
    expect(itemsPainted, equals(<int>[2]));
  });

  testWidgets('Can hit test an IndexedStack', (WidgetTester tester) async {
    const Key key = const Key('indexedStack');
    const int itemCount = 3;
    List<int> itemsTapped;

    Widget buildFrame(int index) {
      itemsTapped = <int>[];
      final List<Widget> items = new List<Widget>.generate(itemCount, (int i) {
        return new GestureDetector(child: new Text('$i', textDirection: TextDirection.ltr), onTap: () { itemsTapped.add(i); });
      });
      return new Center(
        child: new IndexedStack(
          alignment: Alignment.topLeft,
          children: items,
          key: key,
          index: index,
        ),
      );
    }

    await tester.pumpWidget(buildFrame(0));
    expect(itemsTapped, isEmpty);
    await tester.tap(find.byKey(key));
    expect(itemsTapped, <int>[0]);

    await tester.pumpWidget(buildFrame(2));
    expect(itemsTapped, isEmpty);
    await tester.tap(find.byKey(key));
    expect(itemsTapped, <int>[2]);
  });

  testWidgets('Can set width and height', (WidgetTester tester) async {
    const Key key = const Key('container');

    const BoxDecoration kBoxDecoration = const BoxDecoration(
      color: const Color(0xFF00FF00),
    );

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            left: 10.0,
            width: 11.0,
            height: 12.0,
            child: const DecoratedBox(key: key, decoration: kBoxDecoration),
          ),
        ],
      ),
    );

    Element box;
    RenderBox renderBox;
    StackParentData parentData;

    box = tester.element(find.byKey(key));
    renderBox = box.renderObject;
    parentData = renderBox.parentData;
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
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            right: 10.0,
            width: 11.0,
            height: 12.0,
            child: const DecoratedBox(key: key, decoration: kBoxDecoration),
          ),
        ],
      ),
    );

    box = tester.element(find.byKey(key));
    renderBox = box.renderObject;
    parentData = renderBox.parentData;
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

  testWidgets('IndexedStack with null index', (WidgetTester tester) async {
    bool tapped;

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new IndexedStack(
            index: null,
            children: <Widget>[
              new GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () { tapped = true; },
                child: const SizedBox(
                  width: 200.0,
                  height: 200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IndexedStack));
    final RenderBox box = tester.renderObject(find.byType(IndexedStack));
    expect(box.size, equals(const Size(200.0, 200.0)));
    expect(tapped, isNull);
  });

  testWidgets('Stack clip test', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Stack(
            children: <Widget>[
              new Container(
                width: 100.0,
                height: 100.0,
              ),
              new Positioned(
                top: 0.0,
                left: 0.0,
                child: new Container(
                  width: 200.0,
                  height: 200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    RenderBox box = tester.renderObject(find.byType(Stack));
    TestPaintingContext context = new TestPaintingContext();
    box.paint(context, Offset.zero);
    expect(context.invocations.first.memberName, equals(#pushClipRect));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new Stack(
            overflow: Overflow.visible,
            children: <Widget>[
              new Container(
                width: 100.0,
                height: 100.0,
              ),
              new Positioned(
                top: 0.0,
                left: 0.0,
                child: new Container(
                  width: 200.0,
                  height: 200.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    box = tester.renderObject(find.byType(Stack));
    context = new TestPaintingContext();
    box.paint(context, Offset.zero);
    expect(context.invocations.first.memberName, equals(#paintChild));
  });

  testWidgets('Stack sizing: default', (WidgetTester tester) async {
    final List<String> logs = <String>[];
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 2.0,
              maxWidth: 3.0,
              minHeight: 5.0,
              maxHeight: 7.0,
            ),
            child: new Stack(
              children: <Widget>[
                new LayoutBuilder(
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
    final List<String> logs = <String>[];
    Widget buildStack(StackFit sizing) {
      return new Directionality(
        textDirection: TextDirection.ltr,
        child: new Center(
          child: new ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: 2.0,
              maxWidth: 3.0,
              minHeight: 5.0,
              maxHeight: 7.0,
            ),
            child: new Stack(
              fit: sizing,
              children: <Widget>[
                new LayoutBuilder(
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
      'BoxConstraints(2.0<=w<=3.0, 5.0<=h<=7.0)'
    ]);
  });

  testWidgets('Positioned.directional control test', (WidgetTester tester) async {
    final Key key = new UniqueKey();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned.directional(
              textDirection: TextDirection.rtl,
              start: 50.0,
              child: new Container(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(675.0, 0.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new Positioned.directional(
              textDirection: TextDirection.ltr,
              start: 50.0,
              child: new Container(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      ),
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(50.0, 0.0));
  });

  testWidgets('PositionedDirectional control test', (WidgetTester tester) async {
    final Key key = new UniqueKey();
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Stack(
          children: <Widget>[
            new PositionedDirectional(
              start: 50.0,
              child: new Container(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      )
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(675.0, 0.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          children: <Widget>[
            new PositionedDirectional(
              start: 50.0,
              child: new Container(key: key, width: 75.0, height: 175.0),
            ),
          ],
        ),
      )
    );

    expect(tester.getTopLeft(find.byKey(key)), const Offset(50.0, 0.0));
  });

  testWidgets('Can change the text direction of a Stack', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Stack(
        alignment: Alignment.center,
      ),
    );
    await tester.pumpWidget(
      new Stack(
        alignment: AlignmentDirectional.topStart,
        textDirection: TextDirection.rtl,
      ),
    );
    await tester.pumpWidget(
      new Stack(
        alignment: Alignment.center,
      ),
    );
  });

  testWidgets('Alignment with partially-positioned children', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.rtl,
        child: new Stack(
          alignment: Alignment.center,
          children: const <Widget>[
            const SizedBox(width: 100.0, height: 100.0),
            const Positioned(left: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(right: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(start: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(end: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(tester.getRect(find.byType(SizedBox).at(0)), new Rect.fromLTWH(350.0, 250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(1)), new Rect.fromLTWH(0.0,   250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(2)), new Rect.fromLTWH(700.0, 250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(3)), new Rect.fromLTWH(350.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(4)), new Rect.fromLTWH(350.0, 500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(5)), new Rect.fromLTWH(700.0, 250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(6)), new Rect.fromLTWH(0.0,   250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(7)), new Rect.fromLTWH(350.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(8)), new Rect.fromLTWH(350.0, 500.0, 100.0, 100.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          alignment: Alignment.center,
          children: const <Widget>[
            const SizedBox(width: 100.0, height: 100.0),
            const Positioned(left: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(right: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(start: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(end: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(tester.getRect(find.byType(SizedBox).at(0)), new Rect.fromLTWH(350.0, 250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(1)), new Rect.fromLTWH(0.0,   250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(2)), new Rect.fromLTWH(700.0, 250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(3)), new Rect.fromLTWH(350.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(4)), new Rect.fromLTWH(350.0, 500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(5)), new Rect.fromLTWH(0.0,   250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(6)), new Rect.fromLTWH(700.0, 250.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(7)), new Rect.fromLTWH(350.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(8)), new Rect.fromLTWH(350.0, 500.0, 100.0, 100.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          alignment: Alignment.bottomRight,
          children: const <Widget>[
            const SizedBox(width: 100.0, height: 100.0),
            const Positioned(left: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(right: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(start: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(end: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(tester.getRect(find.byType(SizedBox).at(0)), new Rect.fromLTWH(700.0, 500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(1)), new Rect.fromLTWH(0.0,   500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(2)), new Rect.fromLTWH(700.0, 500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(3)), new Rect.fromLTWH(700.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(4)), new Rect.fromLTWH(700.0, 500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(5)), new Rect.fromLTWH(0.0,   500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(6)), new Rect.fromLTWH(700.0, 500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(7)), new Rect.fromLTWH(700.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(8)), new Rect.fromLTWH(700.0, 500.0, 100.0, 100.0));

    await tester.pumpWidget(
      new Directionality(
        textDirection: TextDirection.ltr,
        child: new Stack(
          alignment: Alignment.topLeft,
          children: const <Widget>[
            const SizedBox(width: 100.0, height: 100.0),
            const Positioned(left: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(right: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const Positioned(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(start: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(end: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(top: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
            const PositionedDirectional(bottom: 0.0, child: const SizedBox(width: 100.0, height: 100.0)),
          ],
        ),
      ),
    );
    expect(tester.getRect(find.byType(SizedBox).at(0)), new Rect.fromLTWH(0.0,   0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(1)), new Rect.fromLTWH(0.0,   0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(2)), new Rect.fromLTWH(700.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(3)), new Rect.fromLTWH(0.0,   0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(4)), new Rect.fromLTWH(0.0,   500.0, 100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(5)), new Rect.fromLTWH(0.0,   0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(6)), new Rect.fromLTWH(700.0, 0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(7)), new Rect.fromLTWH(0.0,   0.0,   100.0, 100.0));
    expect(tester.getRect(find.byType(SizedBox).at(8)), new Rect.fromLTWH(0.0,   500.0, 100.0, 100.0));
  });
}
