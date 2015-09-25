import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../fn3/widget_tester.dart';

void main() {
  test('Can be placed in an infinte box', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(new Block([new Center()]));
  });

}
