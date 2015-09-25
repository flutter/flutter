import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../fn3/widget_tester.dart';

void main() {
  test('Can select a day', () {
    WidgetTester tester = new WidgetTester();

    DateTime currentValue;

    Widget widget = new Block([
      new DatePicker(
        selectedDate: new DateTime.utc(2015, 6, 9, 7, 12),
        firstDate: new DateTime.utc(2013),
        lastDate: new DateTime.utc(2018),
        onChanged: (DateTime dateTime) {
          currentValue = dateTime;
        }
      )
    ]);

    tester.pumpFrame(widget);

    expect(currentValue, isNull);
    tester.tap(tester.findText('2015'));
    tester.pumpFrame(widget);
    tester.tap(tester.findText('2014'));
    tester.pumpFrame(widget);
    expect(currentValue, equals(new DateTime(2014, 6, 9)));
    tester.tap(tester.findText('30'));
    expect(currentValue, equals(new DateTime(2013, 1, 30)));
  });
}
