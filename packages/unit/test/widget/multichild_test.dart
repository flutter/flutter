// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

void checkTree(WidgetTester tester, List<BoxDecoration> expectedDecorations) {
  MultiChildRenderObjectElement element =
      tester.findElement((Element element) => element is MultiChildRenderObjectElement);
  expect(element, isNotNull);
  expect(element.renderObject is RenderStack, isTrue);
  RenderStack renderObject = element.renderObject;
  try {
    RenderObject child = renderObject.firstChild;
    for (BoxDecoration decoration in expectedDecorations) {
      expect(child is RenderDecoratedBox, isTrue);
      RenderDecoratedBox decoratedBox = child;
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
  test('MultiChildRenderObjectElement control test', () {
    testWidgets((WidgetTester tester) {

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(key: new Key('b'), decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(key: new Key('b'), decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
          new DecoratedBox(key: new Key('a'), decoration: kBoxDecorationA),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationC, kBoxDecorationA]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(key: new Key('a'), decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationC),
          new DecoratedBox(key: new Key('b'), decoration: kBoxDecorationB),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationC, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[])
      );

      checkTree(tester, <BoxDecoration>[]);

    });
  });

  test('MultiChildRenderObjectElement with stateless components', () {
    testWidgets((WidgetTester tester) {

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new Container(
            child: new Container(
              child: new DecoratedBox(decoration: kBoxDecorationB)
            )
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new Container(
            child: new Container(
              child: new DecoratedBox(decoration: kBoxDecorationB)
            )
          ),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationA)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationA, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationA)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationA, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new Container(
            key: new Key('b'),
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new Container(
            key: new Key('a'),
            child: new DecoratedBox(decoration: kBoxDecorationA)
          ),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationA]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new Container(
            key: new Key('a'),
            child: new DecoratedBox(decoration: kBoxDecorationA)
          ),
          new Container(
            key: new Key('b'),
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack(<Widget>[])
      );

      checkTree(tester, <BoxDecoration>[]);
    });
  });

  test('MultiChildRenderObjectElement with stateful components', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new FlipComponent(
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationA, kBoxDecorationC]);

      flipStatefulComponent(tester);
      tester.pump();

      checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new FlipComponent(
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationB]);

      flipStatefulComponent(tester);
      tester.pump();

      checkTree(tester, <BoxDecoration>[kBoxDecorationA]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new FlipComponent(
            key: new Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      tester.pumpWidget(
        new Stack(<Widget>[
          new DecoratedBox(key: new Key('c'), decoration: kBoxDecorationC),
          new FlipComponent(
            key: new Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationC, kBoxDecorationA]);

      flipStatefulComponent(tester);
      tester.pump();

      checkTree(tester, <BoxDecoration>[kBoxDecorationC, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack(<Widget>[
          new FlipComponent(
            key: new Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(key: new Key('c'), decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, <BoxDecoration>[kBoxDecorationB, kBoxDecorationC]);
    });
  });
}
