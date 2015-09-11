import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

void main() {
  test('Can be placed in an infinte box', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Block([new Center()]);
    });
  });

}
