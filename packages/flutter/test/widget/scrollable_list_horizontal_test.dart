// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];

Widget buildFrame() {
  return new Center(
    child: new Container(
      height: 50.0,
      child: new ScrollableList<int>(
        items: items,
        itemBuilder: (BuildContext context, int item, int index) {
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
  test('Drag horizontally', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(buildFrame());

      tester.pump(const Duration(seconds: 1));
      tester.scroll(tester.findText('1'), const Offset(-300.0, 0.0));
      tester.pump(const Duration(seconds: 1));
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

      // the center of item 3 is visible, so this works;
      // if item 3 was a bit wider, such that it's center was past the 800px mark, this would fail,
      // because it wouldn't be hit tested when scrolling from its center, as scroll() does.
      tester.pump(const Duration(seconds: 1));
      tester.scroll(tester.findText('3'), const Offset(-290.0, 0.0));
      tester.pump(const Duration(seconds: 1));
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

      tester.pump(const Duration(seconds: 1));
      tester.scroll(tester.findText('3'), const Offset(0.0, -290.0));
      tester.pump(const Duration(seconds: 1));
      // unchanged
      expect(tester.findText('0'), isNull);
      expect(tester.findText('1'), isNull);
      expect(tester.findText('2'), isNotNull);
      expect(tester.findText('3'), isNotNull);
      expect(tester.findText('4'), isNotNull);
      expect(tester.findText('5'), isNull);

      tester.pump(const Duration(seconds: 1));
      tester.scroll(tester.findText('3'), const Offset(-290.0, 0.0));
      tester.pump(const Duration(seconds: 1));
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

      tester.pump(const Duration(seconds: 1));
      // at this point we can drag 60 pixels further before we hit the friction zone
      // then, every pixel we drag is equivalent to half a pixel of movement
      // to move item 3 entirely off screen therefore takes:
      //  60 + (290-60)*2 = 520 pixels
      // plus a couple more to be sure
      tester.scroll(tester.findText('3'), const Offset(-522.0, 0.0));
      tester.pump(); // just after release
      // screen is 800px wide, and has the following items:
      //   -11..279 = 4
      //   279..569 = 5
      expect(tester.findText('0'), isNull);
      expect(tester.findText('1'), isNull);
      expect(tester.findText('2'), isNull);
      expect(tester.findText('3'), isNull);
      expect(tester.findText('4'), isNotNull);
      expect(tester.findText('5'), isNotNull);
      tester.pump(const Duration(seconds: 1)); // a second after release
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

      tester.pumpWidget(new Container());
      tester.pumpWidget(buildFrame(), const Duration(seconds: 1));
      tester.scroll(tester.findText('2'), const Offset(-280.0, 0.0));
      tester.pump(const Duration(seconds: 1));
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
      tester.pump(const Duration(seconds: 1));
      tester.scroll(tester.findText('2'), const Offset(-290.0, 0.0));
      tester.pump(const Duration(seconds: 1));
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
  });
}
