// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

void main() {
  test('SnackBar control test', () {
    testWidgets((WidgetTester tester) {
      String helloSnackBar = 'Hello SnackBar';
      Key tapTarget = new Key('tap-target');
      tester.pumpWidget(new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text(helloSnackBar),
                    duration: new Duration(seconds: 2)
                  ));
                },
                behavior: HitTestBehavior.opaque,
                child: new Container(
                  height: 100.0,
                  width: 100.0,
                  key: tapTarget
                )
              );
            }
          )
        )
      ));
      expect(tester, doesNotHaveWidget(find.text(helloSnackBar)));
      tester.tap(find.byKey(tapTarget));
      expect(tester, doesNotHaveWidget(find.text(helloSnackBar)));
      tester.pump(); // schedule animation
      expect(tester, hasWidget(find.text(helloSnackBar)));
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text(helloSnackBar)));
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      expect(tester, hasWidget(find.text(helloSnackBar)));
      tester.pump(new Duration(milliseconds: 750)); // 1.50s
      expect(tester, hasWidget(find.text(helloSnackBar)));
      tester.pump(new Duration(milliseconds: 750)); // 2.25s
      expect(tester, hasWidget(find.text(helloSnackBar)));
      tester.pump(new Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text(helloSnackBar))); // frame 0 of dismiss animation
      tester.pump(new Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build
      expect(tester, doesNotHaveWidget(find.text(helloSnackBar)));
    });
  });

  test('SnackBar twice test', () {
    testWidgets((WidgetTester tester) {
      int snackBarCount = 0;
      Key tapTarget = new Key('tap-target');
      tester.pumpWidget(new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  snackBarCount += 1;
                  Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text("bar$snackBarCount"),
                    duration: new Duration(seconds: 2)
                  ));
                },
                behavior: HitTestBehavior.opaque,
                child: new Container(
                  height: 100.0,
                  width: 100.0,
                  key: tapTarget
                )
              );
            }
          )
        )
      ));
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.tap(find.byKey(tapTarget)); // queue bar1
      tester.tap(find.byKey(tapTarget)); // queue bar2
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(); // schedule animation for bar1
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 1.50s
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 2.25s
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(); // begin animation
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 4.50s // animation last frame; two second timer starts here
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 5.25s
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 6.00s
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 6.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 7.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
    });
  });

  test('SnackBar cancel test', () {
    testWidgets((WidgetTester tester) {
      int snackBarCount = 0;
      Key tapTarget = new Key('tap-target');
      int time;
      ScaffoldFeatureController<SnackBar, Null> lastController;
      tester.pumpWidget(new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  snackBarCount += 1;
                  lastController = Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text("bar$snackBarCount"),
                    duration: new Duration(seconds: time)
                  ));
                },
                behavior: HitTestBehavior.opaque,
                child: new Container(
                  height: 100.0,
                  width: 100.0,
                  key: tapTarget
                )
              );
            }
          )
        )
      ));
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      time = 1000;
      tester.tap(find.byKey(tapTarget)); // queue bar1
      ScaffoldFeatureController<SnackBar, Null> firstController = lastController;
      time = 2;
      tester.tap(find.byKey(tapTarget)); // queue bar2
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(); // schedule animation for bar1
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 1.50s
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 2.25s
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 10000)); // 12.25s
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));

      firstController.close(); // snackbar is manually dismissed

      tester.pump(new Duration(milliseconds: 750)); // 13.00s // reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 13.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(); // begin animation
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 14.50s // animation last frame; two second timer starts here
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 15.25s
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 16.00s
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 16.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 17.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
    });
  });

  test('SnackBar dismiss test', () {
    testWidgets((WidgetTester tester) {
      int snackBarCount = 0;
      Key tapTarget = new Key('tap-target');
      tester.pumpWidget(new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  snackBarCount += 1;
                  Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text("bar$snackBarCount"),
                    duration: new Duration(seconds: 2)
                  ));
                },
                behavior: HitTestBehavior.opaque,
                child: new Container(
                  height: 100.0,
                  width: 100.0,
                  key: tapTarget
                )
              );
            }
          )
        )
      ));
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.tap(find.byKey(tapTarget)); // queue bar1
      tester.tap(find.byKey(tapTarget)); // queue bar2
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(); // schedule animation for bar1
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(); // begin animation
      expect(tester, hasWidget(find.text('bar1')));
      expect(tester, doesNotHaveWidget(find.text('bar2')));
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      tester.scroll(find.text('bar1'), new Offset(0.0, 50.0));
      tester.pump(); // bar1 dismissed, bar2 begins animating
      expect(tester, doesNotHaveWidget(find.text('bar1')));
      expect(tester, hasWidget(find.text('bar2')));
    });
  });

  test('SnackBar cannot be tapped twice', () {
    testWidgets((WidgetTester tester) {
      int tapCount = 0;
      tester.pumpWidget(new MaterialApp(
        home: new Scaffold(
          body: new Builder(
            builder: (BuildContext context) {
              return new GestureDetector(
                onTap: () {
                  Scaffold.of(context).showSnackBar(new SnackBar(
                    content: new Text('I am a snack bar.'),
                    duration: new Duration(seconds: 2),
                    action: new SnackBarAction(
                      label: 'ACTION',
                      onPressed: () {
                        ++tapCount;
                      }
                    )
                  ));
                },
                child: new Text('X')
              );
            }
          )
        )
      ));
      tester.tap(find.text('X'));
      tester.pump(); // start animation
      tester.pump(const Duration(milliseconds: 750));

      expect(tapCount, equals(0));
      tester.tap(find.text('ACTION'));
      expect(tapCount, equals(1));
      tester.tap(find.text('ACTION'));
      expect(tapCount, equals(1));
      tester.pump();
      tester.tap(find.text('ACTION'));
      expect(tapCount, equals(1));
    });
  });
}
