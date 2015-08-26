import 'package:sky/widgets.dart';
import 'package:test/test.dart';

import 'build_utils.dart';

void main() {
  test('Can select a day', () {
    WidgetTester tester = new WidgetTester();

    DateTime currentValue;

    Widget builder() {
      return new Block([
        new DatePicker(
          selectedDate: new DateTime.utc(2015, 6, 9, 7, 12),
          firstDate: new DateTime.utc(2013),
          lastDate: new DateTime.utc(2018),
          onChanged: (DateTime dateTime) {
            currentValue = dateTime;
          }
        )
      ]);
    }

    tester.pumpFrame(builder);
    // TODO(abarth): We shouldn't need to pump a second frame here.
    tester.pumpFrame(builder);

    expect(currentValue, isNull);
    tester.tap(tester.findText('2015'));
    tester.pumpFrame(builder);
    // TODO(jackson): We shouldn't need to pump a second frame here.
    tester.pumpFrame(builder);
    tester.tap(tester.findText('2014'));
    tester.pumpFrame(builder);
    // TODO(jackson): We shouldn't need to pump a second frame here.
    tester.pumpFrame(builder);
    expect(currentValue, equals(new DateTime(2014, 6, 9)));
    tester.tap(tester.findText('30'));
    expect(currentValue, equals(new DateTime(2013, 1, 30)));
  });
}
