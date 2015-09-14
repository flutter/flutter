import 'package:sky/animation.dart';
import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class FirstComponent extends Component {
  FirstComponent(this.navigator);

  final Navigator navigator;

  Widget build() {
    return new GestureDetector(
      onTap: () {
        navigator.pushNamed('/second');
      },
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: new Color(0xFFFFFF00)
        ),
        child: new Text('X')
      )
    );
  }
}

class SecondComponent extends StatefulComponent {
  SecondComponent(this.navigator);

  Navigator navigator;

  void syncConstructorArguments(SecondComponent source) {
    navigator = source.navigator;
  }

  Widget build() {
    return new GestureDetector(
      onTap: navigator.pop,
      child: new Container(
        decoration: new BoxDecoration(
          backgroundColor: new Color(0xFFFF00FF)
        ),
        child: new Text('Y')
      )
    );
  }
}

void main() {
  test('Can navigator navigate to and from a stateful component', () {
    WidgetTester tester = new WidgetTester();

    final NavigationState routes = new NavigationState([
      new Route(
        name: '/',
        builder: (navigator, route) => new FirstComponent(navigator)
      ),
      new Route(
        name: '/second',
        builder: (navigator, route) => new SecondComponent(navigator)
      )
    ]);

    tester.pumpFrame(() {
      return new Navigator(routes);
    });

    expect(tester.findText('X'), isNotNull);
    expect(tester.findText('Y'), isNull);

    tester.tap(tester.findText('X'));
    scheduler.beginFrame(10.0);

    expect(tester.findText('X'), isNotNull);
    expect(tester.findText('Y'), isNotNull);

    scheduler.beginFrame(20.0);
    scheduler.beginFrame(30.0);
    scheduler.beginFrame(1000.0);

    tester.tap(tester.findText('Y'));
    scheduler.beginFrame(1010.0);
    scheduler.beginFrame(1020.0);
    scheduler.beginFrame(1030.0);
    scheduler.beginFrame(2000.0);

    expect(tester.findText('X'), isNotNull);
    expect(tester.findText('Y'), isNull);

  });
}
