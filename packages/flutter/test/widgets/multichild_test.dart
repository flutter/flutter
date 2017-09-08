// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void checkTree(WidgetTester tester, List<BoxDecoration> expectedDecorations) {
  final MultiChildRenderObjectElement element = tester.element(find.byElementPredicate(
    (Element element) => element is MultiChildRenderObjectElement
  ));
  expect(element, isNotNull);
  expect(element.renderObject is RenderStack, isTrue);
  final RenderStack renderObject = element.renderObject;
  try {
    RenderObject child = renderObject.firstChild;
    for (BoxDecoration decoration in expectedDecorations) {
      expect(child is RenderDecoratedBox, isTrue);
      final RenderDecoratedBox decoratedBox = child;
      expect(decoratedBox.decoration, equals(decoration));
      final StackParentData decoratedBoxParentData = decoratedBox.parentData;
      child = decoratedBoxParentData.nextSibling;
    }
    expect(child, isNull);
  } catch (e) {
    print(renderObject.toStringDeep());
    rethrow;
  }
}

void main() {
  testWidgets('MultiChildRenderObjectElement control test', (WidgetTester tester) async {

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(key: const Key('b'), decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(key: const Key('b'), decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
          new DecoratedBox(key: const Key('a'), decoration: kBoxDecorationA),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationC, kBoxDecorationA]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(key: const Key('a'), decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationC),
          new DecoratedBox(key: const Key('b'), decoration: kBoxDecorationB),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationC, kBoxDecorationB]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(textDirection: TextDirection.ltr)
    );

    checkTree(tester, <BoxDecoration>[]);

  });

  testWidgets('MultiChildRenderObjectElement with stateless widgets', (WidgetTester tester) async {

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new Container(
            child: new Container(
              child: new DecoratedBox(decoration: kBoxDecorationB),
            ),
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Container(
            child: new Container(
              child: new DecoratedBox(decoration: kBoxDecorationB),
            ),
          ),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationA),
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationA, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationB),
          ),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationA),
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationA, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Container(
            key: const Key('b'),
            child: new DecoratedBox(decoration: kBoxDecorationB),
          ),
          new Container(
            key: const Key('a'),
            child: new DecoratedBox(decoration: kBoxDecorationA),
          ),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationA]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new Container(
            key: const Key('a'),
            child: new DecoratedBox(decoration: kBoxDecorationA),
          ),
          new Container(
            key: const Key('b'),
            child: new DecoratedBox(decoration: kBoxDecorationB),
          ),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB]);

    await tester.pumpWidget(
      new Stack(textDirection: TextDirection.ltr)
    );

    checkTree(tester, <BoxDecoration>[]);
  });

  testWidgets('MultiChildRenderObjectElement with stateful widgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new FlipWidget(
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB),
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationC]);

    flipStatefulWidget(tester);
    await tester.pump();

    checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationC]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new FlipWidget(
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB),
          ),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationB]);

    flipStatefulWidget(tester);
    await tester.pump();

    checkTree(tester, <BoxDecoration>[kBoxDecorationA]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new FlipWidget(
            key: const Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB),
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new DecoratedBox(key: const Key('c'), decoration: kBoxDecorationC),
          new FlipWidget(
            key: const Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB),
          ),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationC, kBoxDecorationA]);

    flipStatefulWidget(tester);
    await tester.pump();

    checkTree(tester, <BoxDecoration>[kBoxDecorationC, kBoxDecorationB]);

    await tester.pumpWidget(
      new Stack(
        textDirection: TextDirection.ltr,
        children: <Widget>[
          new FlipWidget(
            key: const Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB),
          ),
          new DecoratedBox(key: const Key('c'), decoration: kBoxDecorationC),
        ],
      ),
    );

    checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationC]);
  });
}
