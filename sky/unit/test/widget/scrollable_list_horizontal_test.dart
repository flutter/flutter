import 'package:sky/rendering.dart';
import 'package:sky/src/fn3.dart';
import 'package:test/test.dart';

import 'widget_tester.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];

Widget buildFrame() {
  return new Center(
    child: new Container(
      height: 50.0,
      child: new ScrollableList<int>(
        items: items,
        itemBuilder: (BuildContext context, int item) {
          return new Container(
            key: new ValueKey<int>(item),
            child: new Text('$item')
          );
        },
        itemExtent: 290.0,
        scrollDirection: ScrollDirection.horizontal
      )
    )
  );
}

void main() {
  double t = 0.0;
  WidgetTester tester = new WidgetTester();
  tester.pumpFrame(buildFrame());

  test('Drag to the left using item 1', () {
    tester.pumpFrameWithoutChange(t += 1000.0);
    tester.scroll(tester.findText('1'), const Offset(-300.0, 0.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // screen is 800px wide, and has the following items:
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

  test('Drag to the left using item 3', () {
    // the center of item 3 is visible, so this works;
    // if item 3 was a bit wider, such that it's center was past the 800px mark, this would fail,
    // because it wouldn't be hit tested when scrolling from its center, as scroll() does.
    tester.pumpFrameWithoutChange(t += 1000.0);
    tester.scroll(tester.findText('3'), const Offset(-290.0, 0.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // screen is 800px wide, and has the following items:
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

  test('Drag up using item 3', () {
    tester.pumpFrameWithoutChange(t += 1000.0);
    tester.scroll(tester.findText('3'), const Offset(0.0, -290.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // unchanged
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNull);
  });

  test('Drag to the left using item 3 again', () {
    tester.pumpFrameWithoutChange(t += 1000.0);
    tester.scroll(tester.findText('3'), const Offset(-290.0, 0.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // screen is 800px wide, and has the following items:
    //   -10..280 = 3
    //   280..570 = 4
    //   570..860 = 5
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNull);
    expect(tester.findText('2'), isNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNotNull);
  });

  test('Drag to the left using item 3 again again (past the end of the list)', () {
    tester.pumpFrameWithoutChange(t += 1000.0);
    // at this point we can drag 60 pixels further before we hit the friction zone
    // then, every pixel we drag is equivalent to half a pixel of movement
    // to move item 3 entirely off screen therefore takes:
    //  60 + (290-60)*2 = 520 pixels
    // plus a couple more to be sure
    tester.scroll(tester.findText('3'), const Offset(-522.0, 0.0));
    tester.pumpFrameWithoutChange(t += 0.0); // just after release
    // screen is 800px wide, and has the following items:
    //   -11..279 = 4
    //   279..569 = 5
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNull);
    expect(tester.findText('2'), isNull);
    expect(tester.findText('3'), isNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNotNull);
    tester.pumpFrameWithoutChange(t += 1000.0); // a second after release
    // screen is 800px wide, and has the following items:
    //   -70..220 = 3
    //   220..510 = 4
    //   510..800 = 5
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNull);
    expect(tester.findText('2'), isNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNotNull);
  });

  test('Drag to the left using item 2 when the scroll offset is big', () {
    tester.reset();
    tester.pumpFrame(buildFrame(), t += 1000.0);
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
    tester.pumpFrameWithoutChange(t += 1000.0);
    tester.scroll(tester.findText('2'), const Offset(-290.0, 0.0));
    tester.pumpFrameWithoutChange(t += 1000.0);
    // screen is 800px wide, and has the following items:
    //  -280..10  = 1
    //    10..300 = 2
    //   300..590 = 3
    //   590..880 = 4
    expect(tester.findText('0'), isNull);
    expect(tester.findText('1'), isNotNull);
    expect(tester.findText('2'), isNotNull);
    expect(tester.findText('3'), isNotNull);
    expect(tester.findText('4'), isNotNull);
    expect(tester.findText('5'), isNull);
  });

}
