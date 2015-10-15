import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

class FirstComponent extends StatelessComponent {
  FirstComponent(this.navigator);

  final NavigatorState navigator;

  Widget build(BuildContext context) {
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

  final NavigatorState navigator;

  SecondComponentState createState() => new SecondComponentState();
}

class SecondComponentState extends State<SecondComponent> {
  Widget build(BuildContext context) {
    return new GestureDetector(
      onTap: config.navigator.pop,
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
    testWidgets((WidgetTester tester) {
      final Map<String, RouteBuilder> routes = <String, RouteBuilder>{
        '/': (RouteArguments args) => new FirstComponent(args.navigator),
        '/second': (RouteArguments args) => new SecondComponent(args.navigator),
      };

      tester.pumpWidget(new Navigator(routes: routes));

      expect(tester.findText('X'), isNotNull);
      expect(tester.findText('Y'), isNull);

      tester.tap(tester.findText('X'));
      tester.pump(const Duration(milliseconds: 10));

      expect(tester.findText('X'), isNotNull);
      expect(tester.findText('Y'), isNotNull);

      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(seconds: 1));

      tester.tap(tester.findText('Y'));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(milliseconds: 10));
      tester.pump(const Duration(seconds: 1));

      expect(tester.findText('X'), isNotNull);
      expect(tester.findText('Y'), isNull);
    });
  });
}
