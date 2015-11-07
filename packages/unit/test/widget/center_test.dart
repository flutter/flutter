import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can be placed in an infinte box', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(new Block(<Widget>[new Center()]));
    });
  });
}
