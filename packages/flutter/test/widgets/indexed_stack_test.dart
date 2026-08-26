// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../rendering/rendering_tester.dart' show TestCallbackPainter;

void main() {
  testWidgets('Can construct an empty IndexedStack', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: IndexedStack()),
    );
  });

  testWidgets('Can construct an empty Centered IndexedStack', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: Center(child: IndexedStack()),
      ),
    );
  });

  testWidgets('Can construct an IndexedStack', (WidgetTester tester) async {
    const itemCount = 3;
    late List<int> itemsPainted;

    Widget buildFrame(int index) {
      itemsPainted = <int>[];
      final items = List<Widget>.generate(itemCount, (int i) {
        return CustomPaint(
          painter: TestCallbackPainter(
            onPaint: () {
              itemsPainted.add(i);
            },
          ),
          child: Text('$i', textDirection: TextDirection.ltr),
        );
      });
      return Center(
        child: IndexedStack(alignment: Alignment.topLeft, index: index, children: items),
      );
    }

    void expectFindsChild(int n) {
      for (var i = 0; i < 3; i++) {
        expect(find.text('$i', skipOffstage: false), findsOneWidget);

        if (i == n) {
          expect(find.text('$i'), findsOneWidget);
        } else {
          expect(find.text('$i'), findsNothing);
        }
      }
    }

    await tester.pumpWidget(buildFrame(0));
    expectFindsChild(0);
    expect(itemsPainted, equals(<int>[0]));

    await tester.pumpWidget(buildFrame(1));
    expectFindsChild(1);
    expect(itemsPainted, equals(<int>[1]));

    await tester.pumpWidget(buildFrame(2));
    expectFindsChild(2);
    expect(itemsPainted, equals(<int>[2]));
  });

  testWidgets('Can hit test an IndexedStack', (WidgetTester tester) async {
    const key = Key('indexedStack');
    const itemCount = 3;
    late List<int> itemsTapped;

    Widget buildFrame(int index) {
      itemsTapped = <int>[];
      final items = List<Widget>.generate(itemCount, (int i) {
        return GestureDetector(
          child: Text('$i', textDirection: TextDirection.ltr),
          onTap: () {
            itemsTapped.add(i);
          },
        );
      });
      return Center(
        child: IndexedStack(alignment: Alignment.topLeft, key: key, index: index, children: items),
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

  testWidgets('IndexedStack sets non-selected indexes to visible=false', (
    WidgetTester tester,
  ) async {
    Widget buildStack({required int itemCount, required int? selectedIndex}) {
      final children = List<Widget>.generate(itemCount, (int i) {
        return _ShowVisibility(index: i);
      });
      return Directionality(
        textDirection: TextDirection.ltr,
        child: IndexedStack(index: selectedIndex, children: children),
      );
    }

    await tester.pumpWidget(buildStack(itemCount: 3, selectedIndex: null));
    expect(find.text('index 0 is visible ? false', skipOffstage: false), findsOneWidget);
    expect(find.text('index 1 is visible ? false', skipOffstage: false), findsOneWidget);
    expect(find.text('index 2 is visible ? false', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(buildStack(itemCount: 3, selectedIndex: 0));
    expect(find.text('index 0 is visible ? true', skipOffstage: false), findsOneWidget);
    expect(find.text('index 1 is visible ? false', skipOffstage: false), findsOneWidget);
    expect(find.text('index 2 is visible ? false', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(buildStack(itemCount: 3, selectedIndex: 1));
    expect(find.text('index 0 is visible ? false', skipOffstage: false), findsOneWidget);
    expect(find.text('index 1 is visible ? true', skipOffstage: false), findsOneWidget);
    expect(find.text('index 2 is visible ? false', skipOffstage: false), findsOneWidget);

    await tester.pumpWidget(buildStack(itemCount: 3, selectedIndex: 2));
    expect(find.text('index 0 is visible ? false', skipOffstage: false), findsOneWidget);
    expect(find.text('index 1 is visible ? false', skipOffstage: false), findsOneWidget);
    expect(find.text('index 2 is visible ? true', skipOffstage: false), findsOneWidget);
  });

  testWidgets('IndexedStack with null index', (WidgetTester tester) async {
    bool? tapped;

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: IndexedStack(
            index: null,
            children: <Widget>[
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  tapped = true;
                },
                child: const SizedBox(width: 200.0, height: 200.0),
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(IndexedStack), warnIfMissed: false);
    final RenderBox box = tester.renderObject(find.byType(IndexedStack));
    expect(box.size, equals(const Size(200.0, 200.0)));
    expect(tapped, isNull);
  });

  testWidgets('IndexedStack reports hidden children as offstage', (WidgetTester tester) async {
    final children = <Widget>[for (int i = 0; i < 5; i++) Text('child $i')];

    Future<void> pumpIndexedStack(int? activeIndex) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: IndexedStack(index: activeIndex, children: children),
        ),
      );
    }

    final Finder finder = find.byType(Text);
    final Finder finderIncludingOffstage = find.byType(Text, skipOffstage: false);

    await pumpIndexedStack(null);
    expect(finder, findsNothing); // IndexedStack with null index shows nothing
    expect(finderIncludingOffstage, findsNWidgets(5));

    for (var i = 0; i < 5; i++) {
      await pumpIndexedStack(i);

      expect(finder, findsOneWidget);
      expect(finderIncludingOffstage, findsNWidgets(5));

      expect(find.text('child $i'), findsOneWidget);
    }
  });

  testWidgets('IndexedStack excludes focus for hidden children', (WidgetTester tester) async {
    const children = <Widget>[Focus(child: Text('child 0')), Focus(child: Text('child 1'))];

    Future<void> pumpIndexedStack(int? activeIndex) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: IndexedStack(index: activeIndex, children: children),
        ),
      );
    }

    Future<void> requestFocusAndPump(FocusNode node) async {
      node.requestFocus();
      await tester.pump();
    }

    await pumpIndexedStack(0);

    final Element child0 = tester.element(find.text('child 0', skipOffstage: false));
    final Element child1 = tester.element(find.text('child 1', skipOffstage: false));
    final FocusNode child0FocusNode = Focus.of(child0);
    final FocusNode child1FocusNode = Focus.of(child1);

    await requestFocusAndPump(child0FocusNode);

    expect(child0FocusNode.hasFocus, true);
    expect(child1FocusNode.hasFocus, false);

    await requestFocusAndPump(child1FocusNode);

    expect(child0FocusNode.hasFocus, true);
    expect(child1FocusNode.hasFocus, false);

    await pumpIndexedStack(1);
    await requestFocusAndPump(child1FocusNode);

    expect(child0FocusNode.hasFocus, false);
    expect(child1FocusNode.hasFocus, true);

    await requestFocusAndPump(child0FocusNode);

    expect(child0FocusNode.hasFocus, false);
    expect(child1FocusNode.hasFocus, true);
  });

  testWidgets('IndexedStack: hidden children can not receive tap events', (
    WidgetTester tester,
  ) async {
    var tapped = false;
    final children = <Widget>[
      const Text('child'),
      GestureDetector(onTap: () => tapped = true, child: const Text('hiddenChild')),
    ];

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: IndexedStack(children: children),
      ),
    );

    await tester.tap(find.text('hiddenChild', skipOffstage: false), warnIfMissed: false);
    await tester.pump();

    expect(tapped, false);
  });

  testWidgets('IndexedStack supports Positioned children', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/127553.
    const positionedKey = Key('positioned-child');
    const siblingKey = Key('sibling-child');
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IndexedStack(
          children: <Widget>[
            Positioned(
              left: 10.0,
              top: 20.0,
              width: 30.0,
              height: 40.0,
              child: SizedBox(key: positionedKey),
            ),
            SizedBox(key: siblingKey, width: 50.0, height: 50.0),
          ],
        ),
      ),
    );

    expect(tester.takeException(), isNull);

    final RenderBox positionedBox = tester.renderObject<RenderBox>(
      find.byKey(positionedKey, skipOffstage: false),
    );
    final parentData = positionedBox.parentData! as StackParentData;
    expect(parentData.left, 10.0);
    expect(parentData.top, 20.0);
    expect(parentData.width, 30.0);
    expect(parentData.height, 40.0);
    expect(positionedBox.size, const Size(30.0, 40.0));

    // The Positioned render object must be a direct child of the
    // RenderIndexedStack; no render object should sit between them.
    expect(positionedBox.parent, isA<RenderIndexedStack>());

    // Non-Positioned siblings still report correct visibility.
    final Element siblingElement = tester.element(find.byKey(siblingKey, skipOffstage: false));
    expect(Visibility.of(siblingElement), isFalse);
  });

  testWidgets('Can update clipBehavior of IndexedStack', (WidgetTester tester) async {
    await tester.pumpWidget(const IndexedStack(textDirection: TextDirection.ltr));
    final RenderIndexedStack renderObject = tester.renderObject<RenderIndexedStack>(
      find.byType(IndexedStack),
    );
    expect(renderObject.clipBehavior, equals(Clip.hardEdge));

    // Update clipBehavior to Clip.antiAlias

    await tester.pumpWidget(
      const IndexedStack(textDirection: TextDirection.ltr, clipBehavior: Clip.antiAlias),
    );
    final RenderIndexedStack renderIndexedObject = tester.renderObject<RenderIndexedStack>(
      find.byType(IndexedStack),
    );
    expect(renderIndexedObject.clipBehavior, equals(Clip.antiAlias));
  });

  testWidgets('IndexedStack sizing: explicit', (WidgetTester tester) async {
    final logs = <String>[];
    Widget buildIndexedStack(StackFit sizing) {
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
            child: IndexedStack(
              sizing: sizing,
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

    await tester.pumpWidget(buildIndexedStack(StackFit.loose));
    logs.add('=1=');
    await tester.pumpWidget(buildIndexedStack(StackFit.expand));
    logs.add('=2=');
    await tester.pumpWidget(buildIndexedStack(StackFit.passthrough));
    expect(logs, <String>[
      'BoxConstraints(0.0<=w<=3.0, 0.0<=h<=7.0)',
      '=1=',
      'BoxConstraints(w=3.0, h=7.0)',
      '=2=',
      'BoxConstraints(2.0<=w<=3.0, 5.0<=h<=7.0)',
    ]);
  });

  testWidgets('IndexedStack does not assert with the default parameters', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: IndexedStack()),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('IndexedStack does not assert when index is null', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IndexedStack(index: null, children: <Widget>[SizedBox.shrink(), SizedBox.shrink()]),
      ),
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('IndexedStack asserts when index is negative', (WidgetTester tester) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IndexedStack(index: -1, children: <Widget>[SizedBox.shrink(), SizedBox.shrink()]),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });

  testWidgets('IndexedStack asserts when index is not in children range', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: IndexedStack(index: 2, children: <Widget>[SizedBox.shrink(), SizedBox.shrink()]),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });
}

class _ShowVisibility extends StatelessWidget {
  const _ShowVisibility({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    return Text('index $index is visible ? ${Visibility.of(context)}');
  }
}
