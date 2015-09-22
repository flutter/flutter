import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class TestComponentConfig extends StatefulComponent {
  TestComponentConfig({ this.left, this.right });

  final Widget left;
  final Widget right;

  TestComponentState createState() => new TestComponentState(this);
}

class TestComponentState extends ComponentState<TestComponentConfig> {
  TestComponentState(TestComponentConfig config): super(config);
  bool _showLeft = true;

  void flip() {
    setState(() {
      _showLeft = !_showLeft;
    });
  }

  Widget build(BuildContext context) {
    return _showLeft ? config.left : config.right;
  }
}

final BoxDecoration kBoxDecorationA = new BoxDecoration();
final BoxDecoration kBoxDecorationB = new BoxDecoration();

class TestBuildCounter extends StatelessComponent {
  static int buildCount = 0;

  Widget build(BuildContext context) {
    ++buildCount;
    return new DecoratedBox(decoration: kBoxDecorationA);
  }
}

void flipStatefulComponent(WidgetTester tester) {
  StatefulComponentElement stateElement =
      tester.findElement((element) => element is StatefulComponentElement);
  (stateElement.state as TestComponentState).flip();
}

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

    flipStatefulComponent(tester);

    tester.pumpFrameWithoutChange();

    checkTree(kBoxDecorationA);

    tester.pumpFrame(
      new TestComponentConfig(
        left: new DecoratedBox(decoration: kBoxDecorationA),
        right: new DecoratedBox(decoration: kBoxDecorationB)
      )
    );

    checkTree(kBoxDecorationB);

  });

  test('Don\'t rebuild subcomponents', () {
    WidgetTester tester = new WidgetTester();
    tester.pumpFrame(
      new TestComponentConfig(
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
