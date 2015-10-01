import 'package:sky/rendering.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'test_widgets.dart';
import 'widget_tester.dart';

void checkTree(WidgetTester tester, List<BoxDecoration> expectedDecorations) {
  MultiChildRenderObjectElement element =
      tester.findElement((element) => element is MultiChildRenderObjectElement);
  expect(element, isNotNull);
  expect(element.renderObject is RenderStack, isTrue);
  RenderStack renderObject = element.renderObject;
  try {
    RenderObject child = renderObject.firstChild;
    for (BoxDecoration decoration in expectedDecorations) {
      expect(child is RenderDecoratedBox, isTrue);
      RenderDecoratedBox decoratedBox = child;
      expect(decoratedBox.decoration, equals(decoration));
      child = decoratedBox.parentData.nextSibling;
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
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(key: new Key('b'), decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(key: new Key('b'), decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
          new DecoratedBox(key: new Key('a'), decoration: kBoxDecorationA),
        ])
      );

      checkTree(tester, [kBoxDecorationB, kBoxDecorationC, kBoxDecorationA]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(key: new Key('a'), decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationC),
          new DecoratedBox(key: new Key('b'), decoration: kBoxDecorationB),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationC, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([])
      );

      checkTree(tester, []);

    });
  });

  test('MultiChildRenderObjectElement with stateless components', () {
    testWidgets((WidgetTester tester) {

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new Container(
            child: new Container(
              child: new DecoratedBox(decoration: kBoxDecorationB)
            )
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
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

      checkTree(tester, [kBoxDecorationB, kBoxDecorationA, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new Container(
            child: new DecoratedBox(decoration: kBoxDecorationA)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationB, kBoxDecorationA, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
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

      checkTree(tester, [kBoxDecorationB, kBoxDecorationA]);

      tester.pumpWidget(
        new Stack([
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

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack([ ])
      );

      checkTree(tester, []);
    });
  });

  test('MultiChildRenderObjectElement with stateful components', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Stack([
          new DecoratedBox(decoration: kBoxDecorationA),
          new DecoratedBox(decoration: kBoxDecorationB),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack([
          new FlipComponent(
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationA, kBoxDecorationC]);

      flipStatefulComponent(tester);
      tester.pump();

      checkTree(tester, [kBoxDecorationB, kBoxDecorationC]);

      tester.pumpWidget(
        new Stack([
          new FlipComponent(
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      checkTree(tester, [kBoxDecorationB]);

      flipStatefulComponent(tester);
      tester.pump();

      checkTree(tester, [kBoxDecorationA]);

      tester.pumpWidget(
        new Stack([
          new FlipComponent(
            key: new Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      tester.pumpWidget(
        new Stack([
          new DecoratedBox(key: new Key('c'), decoration: kBoxDecorationC),
          new FlipComponent(
            key: new Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
        ])
      );

      checkTree(tester, [kBoxDecorationC, kBoxDecorationA]);

      flipStatefulComponent(tester);
      tester.pump();

      checkTree(tester, [kBoxDecorationC, kBoxDecorationB]);

      tester.pumpWidget(
        new Stack([
          new FlipComponent(
            key: new Key('flip'),
            left: new DecoratedBox(decoration: kBoxDecorationA),
            right: new DecoratedBox(decoration: kBoxDecorationB)
          ),
          new DecoratedBox(key: new Key('c'), decoration: kBoxDecorationC),
        ])
      );

      checkTree(tester, [kBoxDecorationB, kBoxDecorationC]);
    });
  });
}
