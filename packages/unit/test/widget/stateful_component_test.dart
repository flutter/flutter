import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';
import 'test_widgets.dart';

void main() {
  test('Stateful component smoke test', () {
    WidgetTester tester = new WidgetTester();

    void checkTree(BoxDecoration expectedDecoration) {
      OneChildRenderObjectElement element =
          tester.findElement((element) => element is OneChildRenderObjectElement);
      expect(element, isNotNull);
      expect(element.renderObject is RenderDecoratedBox, isTrue);
      RenderDecoratedBox renderObject = element.renderObject;
      expect(renderObject.decoration, equals(expectedDecoration));
    }

    tester.pumpFrame(
      new FlipComponent(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationA);

    tester.pumpFrame(
      new FlipComponent(
        left: new DecoratedBox(decoration: kBoxDecorationB),
        right: new DecoratedBox(decoration: kBoxDecorationA)
      )
    );

    checkTree(kBoxDecorationB);

    flipStatefulComponent(tester);

    tester.pumpFrameWithoutChange();

    checkTree(kBoxDecorationA);

    tester.pumpFrame(
      new FlipComponent(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationB);

  });

  test('Don\'t rebuild subcomponents', () {
    WidgetTester tester = new WidgetTester();
    tester.pumpFrame(
      new FlipComponent(
        key: new Key('rebuild test'), // this is so we don't get the state from the TestComponentConfig in the last test, but instead instantiate a new element with a new state.
        left: new TestBuildCounter(),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    expect(TestBuildCounter.buildCount, equals(1));

    flipStatefulComponent(tester);

    tester.pumpFrameWithoutChange();

    expect(TestBuildCounter.buildCount, equals(1));
  });
}
