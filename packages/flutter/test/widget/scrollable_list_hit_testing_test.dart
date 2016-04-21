// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

const List<int> items = const <int>[0, 1, 2, 3, 4, 5];

void main() {
  testWidgets('Tap item after scroll - horizontal', (WidgetTester tester) {
      List<int> tapped = <int>[];
      tester.pumpWidget(new Center(
        child: new Container(
          height: 50.0,
          child: new ScrollableList(
            key: new GlobalKey(),
            itemExtent: 290.0,
            scrollDirection: Axis.horizontal,
            children: items.map((int item) {
              return new Container(
                child: new GestureDetector(
                  onTap: () { tapped.add(item); },
                  child: new Text('$item')
                )
              );
            })
          )
        )
      ));
      tester.scroll(find.text('2'), const Offset(-280.0, 0.0));
      tester.pump(const Duration(seconds: 1));
      // screen is 800px wide, and has the following items:
      //  -280..10  = 0
      //    10..300 = 1
      //   300..590 = 2
      //   590..880 = 3
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsNothing);
      expect(find.text('5'), findsNothing);
      expect(tapped, equals([]));
      tester.tap(find.text('2'));
      expect(tapped, equals([2]));
  });

  testWidgets('Tap item after scroll - vertical', (WidgetTester tester) {
      List<int> tapped = <int>[];
      tester.pumpWidget(new Center(
        child: new Container(
          width: 50.0,
          child: new ScrollableList(
            key: new GlobalKey(),
            itemExtent: 290.0,
            scrollDirection: Axis.vertical,
            children: items.map((int item) {
              return new Container(
                child: new GestureDetector(
                  onTap: () { tapped.add(item); },
                  child: new Text('$item')
                )
              );
            })
          )
        )
      ));
      tester.scroll(find.text('1'), const Offset(0.0, -280.0));
      tester.pump(const Duration(seconds: 1));
      // screen is 600px tall, and has the following items:
      //  -280..10  = 0
      //    10..300 = 1
      //   300..590 = 2
      //   590..880 = 3
      expect(find.text('0'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsNothing);
      expect(find.text('5'), findsNothing);
      expect(tapped, equals([]));
      tester.tap(find.text('1'));
      expect(tapped, equals([1]));
      tester.tap(find.text('3'));
      expect(tapped, equals([1])); // the center of the third item is off-screen so it shouldn't get hit
  });

  testWidgets('Padding scroll anchor start', (WidgetTester tester) {
      List<int> tapped = <int>[];

      tester.pumpWidget(
        new ScrollableList(
          key: new GlobalKey(),
          itemExtent: 290.0,
          padding: new EdgeInsets.fromLTRB(5.0, 20.0, 15.0, 10.0),
          children: items.map((int item) {
            return new Container(
              child: new GestureDetector(
                onTap: () { tapped.add(item); },
                child: new Text('$item')
              )
            );
          })
        )
      );
      tester.tapAt(new Point(200.0, 19.0));
      expect(tapped, equals([]));
      tester.tapAt(new Point(200.0, 21.0));
      expect(tapped, equals([0]));
      tester.tapAt(new Point(4.0, 400.0));
      expect(tapped, equals([0]));
      tester.tapAt(new Point(6.0, 400.0));
      expect(tapped, equals([0, 1]));
      tester.tapAt(new Point(800.0 - 14.0, 400.0));
      expect(tapped, equals([0, 1]));
      tester.tapAt(new Point(800.0 - 16.0, 400.0));
      expect(tapped, equals([0, 1, 1]));
  });

  testWidgets('Padding scroll anchor end', (WidgetTester tester) {
      List<int> tapped = <int>[];

      tester.pumpWidget(
        new ScrollableList(
          key: new GlobalKey(),
          itemExtent: 290.0,
          scrollAnchor: ViewportAnchor.end,
          padding: new EdgeInsets.fromLTRB(5.0, 20.0, 15.0, 10.0),
          children: items.map((int item) {
            return new Container(
              child: new GestureDetector(
                onTap: () { tapped.add(item); },
                child: new Text('$item')
              )
            );
          })
        )
      );
      tester.tapAt(new Point(200.0, 600.0 - 9.0));
      expect(tapped, equals([]));
      tester.tapAt(new Point(200.0, 600.0 - 11.0));
      expect(tapped, equals([5]));
      tester.tapAt(new Point(4.0, 200.0));
      expect(tapped, equals([5]));
      tester.tapAt(new Point(6.0, 200.0));
      expect(tapped, equals([5, 4]));
      tester.tapAt(new Point(800.0 - 14.0, 200.0));
      expect(tapped, equals([5, 4]));
      tester.tapAt(new Point(800.0 - 16.0, 200.0));
      expect(tapped, equals([5, 4, 4]));
  });
}
