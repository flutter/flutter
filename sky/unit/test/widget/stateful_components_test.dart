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

    InnerComponent inner;
    OuterContainer outer;

    tester.pumpFrame(() {
      return new OuterContainer(child: new InnerComponent());
    });

    tester.pumpFrame(() {
      inner = new InnerComponent();
      outer = new OuterContainer(child: inner);
      return outer;
    });

    expect(inner._didInitState, isFalse);
    expect(inner.parent, isNull);

    outer.setState(() {});
    scheduler.beginFrame(0.0);

    expect(inner._didInitState, isFalse);
    expect(inner.parent, isNull);

  });
}
