import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import '../fn3/widget_tester.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];
List<int> tapped = <int>[];

void main() {
  double t = 0.0;
  WidgetTester tester = new WidgetTester();

  test('Tap item after scroll - horizontal', () {
    tester.pumpFrame(new Center(
      child: new Container(
        height: 50.0,
        child: new ScrollableList<int>(
          key: new GlobalKey(),
          items: items,
          itemBuilder: (BuildContext context, int item) {
            return new Container(
              key: new ValueKey<int>(item),
              child: new GestureDetector(
                onTap: () { tapped.add(item); },
                child: new Text('$item')
              )
            );
          },
          itemExtent: 290.0,
          scrollDirection: ScrollDirection.horizontal
        )
      )
    ), t);
    tester.scroll(tester.findText('2'), const Offset(-280.0, 0.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // screen is 800px wide, and has the following items:
    //  -280..10  = 0
    //    10..300 = 1
    //   300..590 = 2
    //   590..880 = 3
    expect(tester.findText('0'), isNotNull);
    expect(tester.findText('1'), isNotNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNull);
    expect(tester.findText('5'), isNull);
    expect(tapped, equals([]));
    tester.tap(tester.findText('2'));
    expect(tapped, equals([2]));
  });

  test('Tap item after scroll - vertical', () {
    tester.pumpFrame(new Center(
      child: new Container(
        width: 50.0,
        child: new ScrollableList<int>(
          key: new GlobalKey(),
          items: items,
          itemBuilder: (BuildContext context, int item) {
            return new Container(
              key: new ValueKey<int>(item),
              child: new GestureDetector(
                onTap: () { tapped.add(item); },
                child: new Text('$item')
              )
            );
          },
          itemExtent: 290.0,
          scrollDirection: ScrollDirection.vertical
        )
      )
    ), t);
    tester.scroll(tester.findText('1'), const Offset(0.0, -280.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // screen is 600px tall, and has the following items:
    //  -280..10  = 0
    //    10..300 = 1
    //   300..590 = 2
    //   590..880 = 3
    expect(tester.findText('0'), isNotNull);
    expect(tester.findText('1'), isNotNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNull);
    expect(tester.findText('5'), isNull);
    expect(tapped, equals([2]));
    tester.tap(tester.findText('1'));
    expect(tapped, equals([2, 1]));
    tester.tap(tester.findText('3'));
    expect(tapped, equals([2, 1])); // the center of the third item is off-screen so it shouldn't get hit
  });

}
