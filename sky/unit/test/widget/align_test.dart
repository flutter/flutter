import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'build_utils.dart';

void main() {
  test('Align smoke test', () {
    WidgetTester tester = new WidgetTester();

    tester.pumpFrame(() {
      return new Align(
        child: new Container(),
        horizontal: 0.75,
        vertical: 0.75
      );
    });

    tester.pumpFrame(() {
      return new Align(
        child: new Container(),
        horizontal: 0.5,
        vertical: 0.5
      );
    });

  });
}
