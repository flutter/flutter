import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestComponentConfig extends ComponentConfiguration {
  TestComponentConfig({ this.left, this.right });

  final Widget left;
  final Widget right;

  TestComponentState createState() => new TestComponentState();
}

class TestComponentState extends ComponentState {
  TestComponentConfig get config => super.config;

  bool _showLeft = true;

  void flip() {
    setState(() {
      _showLeft = !_showLeft;
    });
  }

  Widget build() {
    return _showLeft ? config.left : config.right;
  }
}

final BoxDecoration kBoxDecorationA = new BoxDecoration();
final BoxDecoration kBoxDecorationB = new BoxDecoration();

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
      new TestComponentConfig(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationA);

    tester.pumpFrame(
      new TestComponentConfig(
        left: new DecoratedBox(decoration: kBoxDecorationB),
        right: new DecoratedBox(decoration: kBoxDecorationA)
      )
    );

    checkTree(kBoxDecorationB);

    ComponentStateElement stateElement =
        tester.findElement((element) => element is ComponentStateElement);
    (stateElement.state as TestComponentState).flip();

    Element.flushBuild();

    checkTree(kBoxDecorationA);

    tester.pumpFrame(
      new TestComponentConfig(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationB);

  });

}
