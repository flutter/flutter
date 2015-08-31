import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Transform origin', () {
    WidgetTester tester = new WidgetTester();

    bool didReceiveTap = false;
    tester.pumpFrame(() {
      return new Stack([
        new Positioned(
          top: 100.0,
          left: 100.0,
          child: new Container(
            width: 100.0,
            height: 100.0,
            decoration: new BoxDecoration(
              backgroundColor: new Color(0xFF0000FF)
            )
          )
        ),
        new Positioned(
          top: 100.0,
          left: 100.0,
          child: new Container(
            width: 100.0,
            height: 100.0,
            child: new Transform(
              transform: new Matrix4.identity().scale(0.5, 0.5),
              origin: new Offset(100.0, 50.0),
              child: new GestureDetector(
                onTap: () {
                  didReceiveTap = true;
                },
                child: new Container()
              )
            )
          )
        )
      ]);
    });

    expect(didReceiveTap, isFalse);
    tester.tapAt(new Point(110.0, 110.0));
    expect(didReceiveTap, isFalse);
    tester.tapAt(new Point(190.0, 150.0));
    expect(didReceiveTap, isTrue);
  });
}
