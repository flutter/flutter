// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../rendering/mock_canvas.dart';

void main() {
  testWidgets('Circles can have uniform borders', (WidgetTester tester) async {
    await tester.pumpWidget(
      new Container(
        padding: const EdgeInsets.all(50.0),
        decoration: new BoxDecoration(
          shape: BoxShape.circle,
          border: new Border.all(width: 10.0, color: const Color(0x80FF00FF)),
          color: Colors.teal[600]
        )
      )
    );
  });

  testWidgets('Bordered Container insets its child', (WidgetTester tester) async {
    final Key key = const Key('outerContainer');
    await tester.pumpWidget(
      new Center(
        child: new Container(
          key: key,
          decoration: new BoxDecoration(border: new Border.all(width: 10.0)),
          child: new Container(
            width: 25.0,
            height: 25.0
          )
        )
      )
    );
    expect(tester.getSize(find.byKey(key)), equals(const Size(45.0, 45.0)));
  });

  testWidgets('BoxDecoration paints its border correctly', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/7672

    final Key key = const Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      return new Center(
        child: new Container(
          key: key,
          width: 100.0,
          height: 50.0,
          decoration: new BoxDecoration(border: border),
        ),
      );
    }

    final Color black = const Color(0xFF000000);

    await tester.pumpWidget(buildFrame(new Border.all()));
    expect(find.byKey(key), paints
      ..path(color: black, style: PaintingStyle.fill)
      ..path(color: black, style: PaintingStyle.fill)
      ..path(color: black, style: PaintingStyle.fill)
      ..path(color: black, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(new Border.all(width: 0.0)));
    expect(find.byKey(key), paints
      ..path(color: black, style: PaintingStyle.stroke)
      ..path(color: black, style: PaintingStyle.stroke)
      ..path(color: black, style: PaintingStyle.stroke)
      ..path(color: black, style: PaintingStyle.stroke));

    final Color green = const Color(0xFF000000);
    final BorderSide greenSide = new BorderSide(color: green, width: 10.0);

    await tester.pumpWidget(buildFrame(new Border(top: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(new Border(left: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(new Border(right: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));

    await tester.pumpWidget(buildFrame(new Border(bottom: greenSide)));
    expect(find.byKey(key), paints..path(color: green, style: PaintingStyle.fill));
  });


  testWidgets('Can hit test on BoxDecoration', (WidgetTester tester) async {

    List<int> itemsTapped;

    final Key key = const Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      itemsTapped = <int>[];
      return new Center(
        child: new GestureDetector( 
            behavior: HitTestBehavior.deferToChild,
            child: new Container(
            key: key,
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(border: border),
          ),
          onTap: () {
            itemsTapped.add(1);
          },
        )
      );
    }

    await tester.pumpWidget(buildFrame(new Border.all()));
    expect(itemsTapped, isEmpty);

    await tester.tap(find.byKey(key));
    expect(itemsTapped, <int>[1]);

    await tester.tapAt(const Offset(350.0, 275.0));
    expect(itemsTapped, <int>[1,1]);

    await tester.tapAt(const Offset(449.0, 324.0));
    expect(itemsTapped, <int>[1,1,1]);
  
  });

  testWidgets('Can hit test on BoxDecoration circle', (WidgetTester tester) async {

    List<int> itemsTapped;

    final Key key = const Key('Container with BoxDecoration');
    Widget buildFrame(Border border) {
      itemsTapped = <int>[];
      return new Center(
        child: new GestureDetector( 
            behavior: HitTestBehavior.deferToChild,
            child: new Container(
            key: key,
            width: 100.0,
            height: 50.0,
            decoration: new BoxDecoration(border: border, shape: BoxShape.circle),
          ),
          onTap: () {
            itemsTapped.add(1);
          },
        )
      );
    }

    await tester.pumpWidget(buildFrame(new Border.all()));
    expect(itemsTapped, isEmpty);

    await tester.tapAt(const Offset(0.0, 0.0));
    expect(itemsTapped, isEmpty);

    await tester.tapAt(const Offset(350.0, 275.0));
    expect(itemsTapped, isEmpty);

    await tester.tapAt(const Offset(400.0, 300.0));
    expect(itemsTapped, <int>[1]);

    await tester.tap(find.byKey(key));
    expect(itemsTapped, <int>[1,1]);
  
  });

}
