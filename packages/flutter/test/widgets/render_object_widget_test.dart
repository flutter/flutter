// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

final BoxDecoration kBoxDecorationA = new BoxDecoration(border: nonconst(null));
final BoxDecoration kBoxDecorationB = new BoxDecoration(border: nonconst(null));
final BoxDecoration kBoxDecorationC = new BoxDecoration(border: nonconst(null));

class TestWidget extends StatelessWidget {
  const TestWidget({ this.child });

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class TestOrientedBox extends SingleChildRenderObjectWidget {
  const TestOrientedBox({ Key key, Widget child }) : super(key: key, child: child);

  Decoration _getDecoration(BuildContext context) {
    final Orientation orientation = MediaQuery.of(context).orientation;
    switch (orientation) {
      case Orientation.landscape:
        return const BoxDecoration(color: const Color(0xFF00FF00));
      case Orientation.portrait:
        return const BoxDecoration(color: const Color(0xFF0000FF));
    }
    assert(orientation != null);
    return null;
  }

  @override
  RenderDecoratedBox createRenderObject(BuildContext context) => new RenderDecoratedBox(decoration: _getDecoration(context));

  @override
  void updateRenderObject(BuildContext context, RenderDecoratedBox renderObject) {
    renderObject.decoration = _getDecoration(context);
  }
}

void main() {
  testWidgets('RenderObjectWidget smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(new DecoratedBox(decoration: kBoxDecorationA));
    SingleChildRenderObjectElement element =
        tester.element(find.byElementType(SingleChildRenderObjectElement));
    expect(element, isNotNull);
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    RenderDecoratedBox renderObject = element.renderObject;
    expect(renderObject.decoration, equals(kBoxDecorationA));
    expect(renderObject.position, equals(DecorationPosition.background));

    await tester.pumpWidget(new DecoratedBox(decoration: kBoxDecorationB));
    element = tester.element(find.byElementType(SingleChildRenderObjectElement));
    expect(element, isNotNull);
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    renderObject = element.renderObject;
    expect(renderObject.decoration, equals(kBoxDecorationB));
    expect(renderObject.position, equals(DecorationPosition.background));
  });

  testWidgets('RenderObjectWidget can add and remove children', (WidgetTester tester) async {

    void checkFullTree() {
      final SingleChildRenderObjectElement element =
          tester.firstElement(find.byElementType(SingleChildRenderObjectElement));
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      final RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(kBoxDecorationA));
      expect(renderObject.position, equals(DecorationPosition.background));
      expect(renderObject.child, isNotNull);
      expect(renderObject.child is RenderDecoratedBox, isTrue);
      final RenderDecoratedBox child = renderObject.child;
      expect(child.decoration, equals(kBoxDecorationB));
      expect(child.position, equals(DecorationPosition.background));
      expect(child.child, isNull);
    }

    void childBareTree() {
      final SingleChildRenderObjectElement element =
          tester.element(find.byElementType(SingleChildRenderObjectElement));
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      final RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(kBoxDecorationA));
      expect(renderObject.position, equals(DecorationPosition.background));
      expect(renderObject.child, isNull);
    }

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new DecoratedBox(
        decoration: kBoxDecorationB
      )
    ));

    checkFullTree();

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new TestWidget(
        child: new DecoratedBox(
          decoration: kBoxDecorationB
        )
      )
    ));

    checkFullTree();

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new DecoratedBox(
        decoration: kBoxDecorationB
      )
    ));

    checkFullTree();

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA
    ));

    childBareTree();

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new TestWidget(
        child: new TestWidget(
          child: new DecoratedBox(
            decoration: kBoxDecorationB
          )
        )
      )
    ));

    checkFullTree();

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA
    ));

    childBareTree();
  });

  testWidgets('Detached render tree is intact', (WidgetTester tester) async {

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new DecoratedBox(
        decoration: kBoxDecorationB,
        child: new DecoratedBox(
          decoration: kBoxDecorationC
        )
      )
    ));

    SingleChildRenderObjectElement element =
        tester.firstElement(find.byElementType(SingleChildRenderObjectElement));
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    final RenderDecoratedBox parent = element.renderObject;
    expect(parent.child is RenderDecoratedBox, isTrue);
    final RenderDecoratedBox child = parent.child;
    expect(child.decoration, equals(kBoxDecorationB));
    expect(child.child is RenderDecoratedBox, isTrue);
    final RenderDecoratedBox grandChild = child.child;
    expect(grandChild.decoration, equals(kBoxDecorationC));
    expect(grandChild.child, isNull);

    await tester.pumpWidget(new DecoratedBox(
      decoration: kBoxDecorationA
    ));

    element =
        tester.element(find.byElementType(SingleChildRenderObjectElement));
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    expect(element.renderObject, equals(parent));
    expect(parent.child, isNull);

    expect(child.parent, isNull);
    expect(child.decoration, equals(kBoxDecorationB));
    expect(child.child, equals(grandChild));
    expect(grandChild.parent, equals(child));
    expect(grandChild.decoration, equals(kBoxDecorationC));
    expect(grandChild.child, isNull);
  });

  testWidgets('Can watch inherited widgets', (WidgetTester tester) async {
    final Key boxKey = new UniqueKey();
    final TestOrientedBox box = new TestOrientedBox(key: boxKey);

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(size: const Size(400.0, 300.0)),
      child: box
    ));

    final RenderDecoratedBox renderBox = tester.renderObject(find.byKey(boxKey));
    BoxDecoration decoration = renderBox.decoration;
    expect(decoration.color, equals(const Color(0xFF00FF00)));

    await tester.pumpWidget(new MediaQuery(
      data: const MediaQueryData(size: const Size(300.0, 400.0)),
      child: box
    ));

    decoration = renderBox.decoration;
    expect(decoration.color, equals(const Color(0xFF0000FF)));
  });
}
