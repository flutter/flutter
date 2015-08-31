import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can hit test flex children of stacks', () {
    WidgetTester tester = new WidgetTester();

    bool didReceiveTap = false;
    tester.pumpFrame(() {
      return new Container(
        decoration: const BoxDecoration(
          backgroundColor: const Color(0xFF00FF00)
        ),
        child: new Stack([
          new Positioned(
            top: 10.0,
            left: 10.0,
            child: new Column([
              new GestureDetector(
                onTap: () {
                  didReceiveTap = true;
                },
                child: new Container(
                  decoration: const BoxDecoration(
                    backgroundColor: const Color(0xFF0000FF)
                  ),
                  width: 100.0,
                  height: 100.0,
                  child: new Center(
                    child: new Text('X')
                  )
                )
              )
            ])
          )
        ])
      );
    });

    tester.tap(tester.findText('X'));
    expect(didReceiveTap, isTrue);
  });
}
