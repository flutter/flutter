// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import 'test_widgets.dart';

void main() {
  testWidgets('Stateful widget smoke test', (WidgetTester tester) async {

    void checkTree(BoxDecoration expectedDecoration) {
      final SingleChildRenderObjectElement element = tester.element(
        find.byElementPredicate((Element element) => element is SingleChildRenderObjectElement)
      );
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      final RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(expectedDecoration));
    }

    await tester.pumpWidget(
      const FlipWidget(
        left: DecoratedBox(decoration: kBoxDecorationA),
        right: DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationA);

    await tester.pumpWidget(
      const FlipWidget(
        left: DecoratedBox(decoration: kBoxDecorationB),
        right: DecoratedBox(decoration: kBoxDecorationA)
      )
    );

    checkTree(kBoxDecorationB);

    flipStatefulWidget(tester);

    await tester.pump();

    checkTree(kBoxDecorationA);

    await tester.pumpWidget(
      const FlipWidget(
        left: DecoratedBox(decoration: kBoxDecorationA),
        right: DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationB);
  });

  testWidgets('Don\'t rebuild subwidgets', (WidgetTester tester) async {
    await tester.pumpWidget(
      FlipWidget(
        key: const Key('rebuild test'),
        left: TestBuildCounter(),
        right: const DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    expect(TestBuildCounter.buildCount, equals(1));

    flipStatefulWidget(tester);

    await tester.pump();

    expect(TestBuildCounter.buildCount, equals(1));
  });
}
