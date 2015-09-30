import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../fn3/widget_tester.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];

Widget buildFrame() {
  return new ScrollableList<int>(
    items: items,
    itemBuilder: (BuildContext context, int item) {
      return new Container(
        key: new ValueKey<int>(item),
        child: new Text('$item')
      );
    },
    itemExtent: 290.0,
    scrollDirection: ScrollDirection.vertical
  );
}

void main() {
  WidgetTester tester = new WidgetTester();
  tester.pumpFrame(buildFrame());

  test('Drag up using item 1', () {
    tester.pumpFrameWithoutChange();
    tester.scroll(tester.findText('1'), const Offset(0.0, -300.0));
    tester.pumpFrameWithoutChange();
    // screen is 600px high, and has the following items:
    //   -10..280 = 1
    //   280..570 = 2
    //   570..860 = 3
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNotNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNull);
    expect(tester.findText('5'), isNull);
  });

  test('Drag up using item 2', () {
    tester.pumpFrameWithoutChange();
    tester.scroll(tester.findText('2'), const Offset(0.0, -290.0));
    tester.pumpFrameWithoutChange();
    // screen is 600px high, and has the following items:
    //   -10..280 = 2
    //   280..570 = 3
    //   570..860 = 4
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNull);
  });

  test('Drag to the left using item 3', () {
    tester.pumpFrameWithoutChange();
    tester.scroll(tester.findText('3'), const Offset(-300.0, 0.0));
    tester.pumpFrameWithoutChange();
    // nothing should have changed
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNull);
  });

}
