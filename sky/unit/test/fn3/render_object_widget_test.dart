import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

final BoxDecoration kBoxDecorationA = new BoxDecoration();
final BoxDecoration kBoxDecorationB = new BoxDecoration();
final BoxDecoration kBoxDecorationC = new BoxDecoration();

class TestComponent extends StatelessComponent {
  const TestComponent({ this.child });
  final Widget child;
  Widget build() => child;
}

void main() {
  test('RenderObjectWidget smoke test', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(new DecoratedBox(decoration: kBoxDecorationA));
    OneChildRenderObjectElement element =
        tester.findElement((element) => element is OneChildRenderObjectElement);
    expect(element, isNotNull);
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    RenderDecoratedBox renderObject = element.renderObject;
    expect(renderObject.decoration, equals(kBoxDecorationA));
    expect(renderObject.position, equals(BoxDecorationPosition.background));

    tester.pumpFrame(new DecoratedBox(decoration: kBoxDecorationB));
    element = tester.findElement((element) => element is OneChildRenderObjectElement);
    expect(element, isNotNull);
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    renderObject = element.renderObject;
    expect(renderObject.decoration, equals(kBoxDecorationB));
    expect(renderObject.position, equals(BoxDecorationPosition.background));
  });

  test('RenderObjectWidget can add and remove children', () {
    WidgetTester tester = new WidgetTester();

    void checkFullTree() {
      OneChildRenderObjectElement element =
          tester.findElement((element) => element is OneChildRenderObjectElement);
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(kBoxDecorationA));
      expect(renderObject.position, equals(BoxDecorationPosition.background));
      expect(renderObject.child, isNotNull);
      expect(renderObject.child is RenderDecoratedBox, isTrue);
      RenderDecoratedBox child = renderObject.child;
      expect(child.decoration, equals(kBoxDecorationB));
      expect(child.position, equals(BoxDecorationPosition.background));
      expect(child.child, isNull);
    }

    void childBareTree() {
      OneChildRenderObjectElement element =
          tester.findElement((element) => element is OneChildRenderObjectElement);
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(kBoxDecorationA));
      expect(renderObject.position, equals(BoxDecorationPosition.background));
      expect(renderObject.child, isNull);
    }

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new DecoratedBox(
        decoration: kBoxDecorationB
      )
    ));

    checkFullTree();

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new TestComponent(
        child: new DecoratedBox(
          decoration: kBoxDecorationB
        )
      )
    ));

    checkFullTree();

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new DecoratedBox(
        decoration: kBoxDecorationB
      )
    ));

    checkFullTree();

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA
    ));

    childBareTree();

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new TestComponent(
        child: new TestComponent(
          child: new DecoratedBox(
            decoration: kBoxDecorationB
          )
        )
      )
    ));

    checkFullTree();

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA
    ));

    childBareTree();
  });

  test('Detached render tree is intact', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA,
      child: new DecoratedBox(
        decoration: kBoxDecorationB,
        child: new DecoratedBox(
          decoration: kBoxDecorationC
        )
      )
    ));

    OneChildRenderObjectElement element =
        tester.findElement((element) => element is OneChildRenderObjectElement);
    expect(element.renderObject is RenderDecoratedBox, isTrue);
    RenderDecoratedBox parent = element.renderObject;
    expect(parent.child is RenderDecoratedBox, isTrue);
    RenderDecoratedBox child = parent.child;
    expect(child.decoration, equals(kBoxDecorationB));
    expect(child.child is RenderDecoratedBox, isTrue);
    RenderDecoratedBox grandChild = child.child;
    expect(grandChild.decoration, equals(kBoxDecorationC));
    expect(grandChild.child, isNull);

    tester.pumpFrame(new DecoratedBox(
      decoration: kBoxDecorationA
    ));

    element =
        tester.findElement((element) => element is OneChildRenderObjectElement);
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
}
