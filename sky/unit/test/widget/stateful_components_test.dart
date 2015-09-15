import 'package:sky/animation.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class InnerComponent extends StatefulComponent {
  InnerComponent();

  bool _didInitState = false;

  void initState() {
    _didInitState = true;
  }

  void syncConstructorArguments(InnerComponent source) {
  }

  Widget build() {
    return new Container();
  }
}

class OuterContainer extends StatefulComponent {
  OuterContainer({ this.child });

  InnerComponent child;

  void syncConstructorArguments(OuterContainer source) {
    child = source.child;
  }

  Widget build() {
    return child;
  }
}

void main() {
  test('resync stateful widget', () {

    WidgetTester tester = new WidgetTester();

    InnerComponent inner1;
    InnerComponent inner2;
    OuterContainer outer;

    tester.pumpFrame(() {
      inner1 = new InnerComponent();
      outer = new OuterContainer(child: inner1);
      return outer;
    });

    expect(inner1._didInitState, isTrue);
    expect(inner1.parent, isNotNull);

    tester.pumpFrame(() {
      inner2 = new InnerComponent();
      return new OuterContainer(child: inner2);
    });

    expect(inner1._didInitState, isTrue);
    expect(inner1.parent, isNotNull);
    expect(inner2._didInitState, isFalse);
    expect(inner2.parent, isNull);

    outer.setState(() {});
    tester.pumpFrameWithoutChange(0.0);

    expect(inner1._didInitState, isTrue);
    expect(inner1.parent, isNotNull);
    expect(inner2._didInitState, isFalse);
    expect(inner2.parent, isNull);

  });
}
