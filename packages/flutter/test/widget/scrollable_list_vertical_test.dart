// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];

Widget buildFrame() {
  return new ScrollableList<int>(
    items: items,
    itemBuilder: (BuildContext context, int item, int index) {
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
  test('Drag vertically', () {
    testWidgets((WidgetTester tester) {
      tester.pumpWidget(buildFrame());

      tester.pump();
      tester.scroll(tester.findText('1'), const Offset(0.0, -300.0));
      tester.pump();
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

      tester.pump();
      tester.scroll(tester.findText('2'), const Offset(0.0, -290.0));
      tester.pump();
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

      tester.pump();
      tester.scroll(tester.findText('3'), const Offset(-300.0, 0.0));
      tester.pump();
      // nothing should have changed
      expect(tester.findText('0'), isNull);
      expect(tester.findText('1'), isNull);
      expect(tester.findText('2'), isNotNull);
      expect(tester.findText('3'), isNotNull);
      expect(tester.findText('4'), isNotNull);
      expect(tester.findText('5'), isNull);
    });
  });
}
