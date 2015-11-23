// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';

void main() {
  test('Stateful component smoke test', () {
    testWidgets((WidgetTester tester) {

      void checkTree(BoxDecoration expectedDecoration) {
        OneChildRenderObjectElement element =
            tester.findElement((Element element) => element is OneChildRenderObjectElement);
        expect(element, isNotNull);
        expect(element.renderObject is RenderDecoratedBox, isTrue);
        RenderDecoratedBox renderObject = element.renderObject;
        expect(renderObject.decoration, equals(expectedDecoration));
      }

      tester.pumpWidget(
        new FlipComponent(
          left: new DecoratedBox(decoration: kBoxDecorationA),
          right: new DecoratedBox(decoration: kBoxDecorationB)
        )
      );

      checkTree(kBoxDecorationA);

      tester.pumpWidget(
        new FlipComponent(
          left: new DecoratedBox(decoration: kBoxDecorationB),
          right: new DecoratedBox(decoration: kBoxDecorationA)
        )
      );

      checkTree(kBoxDecorationB);

      flipStatefulComponent(tester);

      tester.pump();

      checkTree(kBoxDecorationA);

      tester.pumpWidget(
        new FlipComponent(
          left: new DecoratedBox(decoration: kBoxDecorationA),
          right: new DecoratedBox(decoration: kBoxDecorationB)
        )
      );

      checkTree(kBoxDecorationB);
    });
  });

  test('Don\'t rebuild subcomponents', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new FlipComponent(
          key: new Key('rebuild test'), // this is so we don't get the state from the TestComponentConfig in the last test, but instead instantiate a new element with a new state.
          left: new TestBuildCounter(),
          right: new DecoratedBox(decoration: kBoxDecorationB)
        )
      );

      expect(TestBuildCounter.buildCount, equals(1));

      flipStatefulComponent(tester);

      tester.pump();

      expect(TestBuildCounter.buildCount, equals(1));
    });
  });
}
