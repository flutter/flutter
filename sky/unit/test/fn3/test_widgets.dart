import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

final BoxDecoration kBoxDecorationA = new BoxDecoration(
  backgroundColor: const Color(0xFFFF0000)
);

final BoxDecoration kBoxDecorationB = new BoxDecoration(
  backgroundColor: const Color(0xFF00FF00)
);

final BoxDecoration kBoxDecorationC = new BoxDecoration(
  backgroundColor: const Color(0xFF0000FF)
);

class FlipComponent extends StatefulComponent {
  FlipComponent({ Key key, this.left, this.right }) : super(key: key);

  final Widget left;
  final Widget right;

  FlipComponentState createState() => new FlipComponentState(this);
}

class FlipComponentState extends ComponentState<FlipComponent> {
  FlipComponentState(FlipComponent config): super(config);
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
  expect(stateElement, isNotNull);
  expect(stateElement.state is FlipComponentState, isTrue);
  FlipComponentState state = stateElement.state;
  state.flip();
}
