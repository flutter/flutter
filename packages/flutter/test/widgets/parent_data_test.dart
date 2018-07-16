// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

class TestParentData {
  TestParentData({ this.top, this.right, this.bottom, this.left });

  final double top;
  final double right;
  final double bottom;
  final double left;
}

void checkTree(WidgetTester tester, List<TestParentData> expectedParentData) {
  final MultiChildRenderObjectElement element = tester.element(
    find.byElementPredicate((Element element) => element is MultiChildRenderObjectElement)
  );
  expect(element, isNotNull);
  expect(element.renderObject is RenderStack, isTrue);
  final RenderStack renderObject = element.renderObject;
  try {
    RenderObject child = renderObject.firstChild;
    for (TestParentData expected in expectedParentData) {
      expect(child is RenderDecoratedBox, isTrue);
      final RenderDecoratedBox decoratedBox = child;
      expect(decoratedBox.parentData is StackParentData, isTrue);
      final StackParentData parentData = decoratedBox.parentData;
      expect(parentData.top, equals(expected.top));
      expect(parentData.right, equals(expected.right));
      expect(parentData.bottom, equals(expected.bottom));
      expect(parentData.left, equals(expected.left));
      final StackParentData decoratedBoxParentData = decoratedBox.parentData;
      child = decoratedBoxParentData.nextSibling;
    }
    expect(child, isNull);
  } catch (e) {
    print(renderObject.toStringDeep());
    rethrow;
  }
}

final TestParentData kNonPositioned = new TestParentData();

void main() {
  testWidgets('ParentDataWidget control test', (WidgetTester tester) async {

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const DecoratedBox(decoration: kBoxDecorationA),
          const Positioned(
            top: 10.0,
            left: 10.0,
            child: const DecoratedBox(decoration: kBoxDecorationB),
          ),
          const DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      kNonPositioned,
      new TestParentData(top: 10.0, left: 10.0),
      kNonPositioned,
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            bottom: 5.0,
            right: 7.0,
            child: const DecoratedBox(decoration: kBoxDecorationA),
          ),
          const Positioned(
            top: 10.0,
            left: 10.0,
            child: const DecoratedBox(decoration: kBoxDecorationB),
          ),
          const DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(bottom: 5.0, right: 7.0),
      new TestParentData(top: 10.0, left: 10.0),
      kNonPositioned,
    ]);

    const DecoratedBox kDecoratedBoxA = const DecoratedBox(decoration: kBoxDecorationA);
    const DecoratedBox kDecoratedBoxB = const DecoratedBox(decoration: kBoxDecorationB);
    const DecoratedBox kDecoratedBoxC = const DecoratedBox(decoration: kBoxDecorationC);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            bottom: 5.0,
            right: 7.0,
            child: kDecoratedBoxA,
          ),
          const Positioned(
            top: 10.0,
            left: 10.0,
            child: kDecoratedBoxB,
          ),
          kDecoratedBoxC,
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(bottom: 5.0, right: 7.0),
      new TestParentData(top: 10.0, left: 10.0),
      kNonPositioned,
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            bottom: 6.0,
            right: 8.0,
            child: kDecoratedBoxA,
          ),
          const Positioned(
            left: 10.0,
            right: 10.0,
            child: kDecoratedBoxB,
          ),
          kDecoratedBoxC,
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(bottom: 6.0, right: 8.0),
      new TestParentData(left: 10.0, right: 10.0),
      kNonPositioned,
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          kDecoratedBoxA,
          new Positioned(
            left: 11.0,
            right: 12.0,
            child: new Container(child: kDecoratedBoxB),
          ),
          kDecoratedBoxC,
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      kNonPositioned,
      new TestParentData(left: 11.0, right: 12.0),
      kNonPositioned,
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          kDecoratedBoxA,
          new Positioned(
            right: 10.0,
            child: new Container(child: kDecoratedBoxB),
          ),
          new Container(
            child: const Positioned(
              top: 8.0,
              child: kDecoratedBoxC,
            ),
          ),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      kNonPositioned,
      new TestParentData(right: 10.0),
      new TestParentData(top: 8.0),
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            right: 10.0,
            child: const FlipWidget(left: kDecoratedBoxA, right: kDecoratedBoxB),
          ),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(right: 10.0),
    ]);

    flipStatefulWidget(tester);
    await tester.pump();

    checkTree(tester, <TestParentData>[
      new TestParentData(right: 10.0),
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            top: 7.0,
            child: const FlipWidget(left: kDecoratedBoxA, right: kDecoratedBoxB),
          ),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(top: 7.0),
    ]);

    flipStatefulWidget(tester);
    await tester.pump();

    checkTree(tester, <TestParentData>[
      new TestParentData(top: 7.0),
    ]);

    await tester.pumpWidget(
      new Stack(textDirection: TextDirection.ltr)
    );

    checkTree(tester, <TestParentData>[]);
  });

  testWidgets('ParentDataWidget conflicting data', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: const <Widget>[
          const Positioned(
            top: 5.0,
            bottom: 8.0,
            child: const Positioned(
              top: 6.0,
              left: 7.0,
              child: const DecoratedBox(decoration: kBoxDecorationB),
            ),
          ),
        ],
      ),
    );
    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(new Stack(textDirection: TextDirection.ltr));

    checkTree(tester, <TestParentData>[]);

    await tester.pumpWidget(
      new Container(
        child: new Row(
          children: const <Widget>[
            const Positioned(
              top: 6.0,
              left: 7.0,
              child: const DecoratedBox(decoration: kBoxDecorationB),
            ),
          ],
        ),
      ),
    );
    expect(tester.takeException(), isFlutterError);

    await tester.pumpWidget(
      new Stack(textDirection: TextDirection.ltr)
    );

    checkTree(tester, <TestParentData>[]);
  });

  testWidgets('ParentDataWidget interacts with global keys', (WidgetTester tester) async {
    final GlobalKey key = new GlobalKey();

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Positioned(
            top: 10.0,
            left: 10.0,
            child: new DecoratedBox(key: key, decoration: kBoxDecorationA),
          ),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(top: 10.0, left: 10.0),
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Positioned(
            top: 10.0,
            left: 10.0,
            child: new DecoratedBox(
              decoration: kBoxDecorationB,
              child: new DecoratedBox(key: key, decoration: kBoxDecorationA),
            ),
          ),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(top: 10.0, left: 10.0),
    ]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Positioned(
            top: 10.0,
            left: 10.0,
            child: new DecoratedBox(key: key, decoration: kBoxDecorationA),
          ),
        ],
      ),
    );

    checkTree(tester, <TestParentData>[
      new TestParentData(top: 10.0, left: 10.0),
    ]);
  });

  testWidgets('Parent data invalid ancestor', (WidgetTester tester) async {
    await tester.pumpWidget(new Row(
      children: <Widget>[
        new Stack(
        textDirection: TextDirection.ltr,
          children: <Widget>[
            new Expanded(
              child: new Container()
            ),
          ],
        ),
      ],
    ));

    expect(tester.takeException(), isFlutterError);
  });
}
