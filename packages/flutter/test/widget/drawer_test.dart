// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:test/test.dart';

void main() {

  test('Drawer control test', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
      BuildContext savedContext;
      tester.pumpWidget(
        new MaterialApp(
          home: new Builder(
            builder: (BuildContext context) {
              savedContext = context;
              return new Scaffold(
                key: scaffoldKey,
                drawer: new Text('drawer'),
                body: new Container()
              );
            }
          )
        )
      );
      tester.pump(); // no effect
      expect(tester, doesNotHaveWidget(find.text('drawer')));
      scaffoldKey.currentState.openDrawer();
      tester.pump(); // drawer should be starting to animate in
      expect(tester, hasWidget(find.text('drawer')));
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, hasWidget(find.text('drawer')));
      Navigator.pop(savedContext);
      tester.pump(); // drawer should be starting to animate away
      expect(tester, hasWidget(find.text('drawer')));
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, doesNotHaveWidget(find.text('drawer')));
    });
  });

  test('Drawer tap test', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
      tester.pumpWidget(
        new MaterialApp(
          home: new Scaffold(
            key: scaffoldKey,
            drawer: new Text('drawer'),
            body: new Container()
          )
        )
      );
      tester.pump(); // no effect
      expect(tester, doesNotHaveWidget(find.text('drawer')));
      scaffoldKey.currentState.openDrawer();
      tester.pump(); // drawer should be starting to animate in
      expect(tester, hasWidget(find.text('drawer')));
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, hasWidget(find.text('drawer')));
      tester.tap(find.text('drawer'));
      tester.pump(); // nothing should have happened
      expect(tester, hasWidget(find.text('drawer')));
      tester.pump(new Duration(seconds: 1)); // ditto
      expect(tester, hasWidget(find.text('drawer')));
      tester.tapAt(const Point(750.0, 100.0)); // on the mask
      tester.pump();
      tester.pump(new Duration(milliseconds: 10));
      // drawer should be starting to animate away
      expect(tester, hasWidget(find.text('drawer')));
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, doesNotHaveWidget(find.text('drawer')));
    });
  });

  test('Drawer drag cancel resume', () {
    testWidgets((WidgetTester tester) {
      GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
      tester.pumpWidget(
        new MaterialApp(
          home: new Scaffold(
            key: scaffoldKey,
            drawer: new Drawer(
              child: new Block(
                children: <Widget>[
                  new Text('drawer'),
                  new Container(
                    height: 1000.0,
                    decoration: new BoxDecoration(
                      backgroundColor: Colors.blue[500]
                    )
                  ),
                ]
              )
            ),
            body: new Container()
          )
        )
      );
      expect(tester, doesNotHaveWidget(find.text('drawer')));
      scaffoldKey.currentState.openDrawer();
      tester.pump(); // drawer should be starting to animate in
      expect(tester, hasWidget(find.text('drawer')));
      tester.pump(new Duration(seconds: 1)); // animation done
      expect(tester, hasWidget(find.text('drawer')));

      tester.tapAt(const Point(750.0, 100.0)); // on the mask
      tester.pump();
      tester.pump(new Duration(milliseconds: 10));
      // drawer should be starting to animate away
      RenderBox textBox = tester.renderObjectOf(find.text('drawer'));
      double textLeft = textBox.localToGlobal(Point.origin).x;
      expect(textLeft, lessThan(0.0));

      TestGesture gesture = tester.startGesture(new Point(100.0, 100.0));
      // drawer should be stopped.
      tester.pump();
      tester.pump(new Duration(milliseconds: 10));
      expect(textBox.localToGlobal(Point.origin).x, equals(textLeft));

      gesture.moveBy(new Offset(0.0, -50.0));
      // drawer should be returning to visible
      tester.pump();
      tester.pump(new Duration(seconds: 1));
      expect(textBox.localToGlobal(Point.origin).x, equals(0.0));

      gesture.up();
    });
  });

}
