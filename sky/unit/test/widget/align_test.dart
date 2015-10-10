import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Align smoke test', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(
        new Align(
          child: new Container(),
          horizontal: 0.75,
          vertical: 0.75
        )
      );

      tester.pumpWidget(
        new Align(
          child: new Container(),
          horizontal: 0.5,
          vertical: 0.5
        )
      );
    });
  });
}
