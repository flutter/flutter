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

class OutterContainer extends StatefulComponent {
  OutterContainer({ this.child });

  InnerComponent child;

  void syncConstructorArguments(OutterContainer source) {
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
    OutterContainer outter;

    tester.pumpFrame(() {
      return new OutterContainer(child: new InnerComponent());
    });

    tester.pumpFrame(() {
      inner = new InnerComponent();
      outter = new OutterContainer(child: inner);
      return outter;
    });

    expect(inner._didInitState, isFalse);
    expect(inner.parent, isNull);

    outter.setState(() {});
    scheduler.beginFrame(0.0);

    expect(inner._didInitState, isFalse);
    expect(inner.parent, isNull);

  });
}
