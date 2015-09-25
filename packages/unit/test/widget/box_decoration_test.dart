import 'package:sky/material.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../fn3/widget_tester.dart';

void main() {
  test('Circles can have uniform borders', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(
      new Container(
        padding: new EdgeDims.all(50.0),
        decoration: new BoxDecoration(
          shape: Shape.circle,
          border: new Border.all(width: 10.0, color: const Color(0x80FF00FF)),
          backgroundColor: Colors.teal[600]
        )
      )
    );

  });
}
