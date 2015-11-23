// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:test/test.dart';

class Builder extends StatelessComponent {
  Builder({ this.builder });
  final WidgetBuilder builder;
  Widget build(BuildContext context) => builder(context);
}

void main() {
  test('SnackBar control test', () {
    testWidgets((WidgetTester tester) {
      String helloSnackBar = 'Hello SnackBar';
      Key tapTarget = new Key('tap-target');
      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new Scaffold(
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
            );
          }
        }
      ));
      expect(tester.findText(helloSnackBar), isNull);
      tester.tap(tester.findElementByKey(tapTarget));
      expect(tester.findText(helloSnackBar), isNull);
      tester.pump(); // schedule animation
      expect(tester.findText(helloSnackBar), isNotNull);
      tester.pump(); // begin animation
      expect(tester.findText(helloSnackBar), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      expect(tester.findText(helloSnackBar), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 1.50s
      expect(tester.findText(helloSnackBar), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 2.25s
      expect(tester.findText(helloSnackBar), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester.findText(helloSnackBar), isNotNull); // frame 0 of dismiss animation
      tester.pump(new Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build
      expect(tester.findText(helloSnackBar), isNull);
    });
  });

  test('SnackBar twice test', () {
    testWidgets((WidgetTester tester) {
      int snackBarCount = 0;
      Key tapTarget = new Key('tap-target');
      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new Scaffold(
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
            );
          }
        }
      ));
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNull);
      tester.tap(tester.findElementByKey(tapTarget)); // queue bar1
      tester.tap(tester.findElementByKey(tapTarget)); // queue bar2
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(); // schedule animation for bar1
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 1.50s
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 2.25s
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 4.50s // animation last frame; two second timer starts here
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 5.25s
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 6.00s
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 6.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 7.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNull);
    });
  });

  test('SnackBar cancel test', () {
    testWidgets((WidgetTester tester) {
      int snackBarCount = 0;
      Key tapTarget = new Key('tap-target');
      int time;
      ScaffoldFeatureController<SnackBar> lastController;
      tester.pumpWidget(new MaterialApp(
        routes: <String, RouteBuilder>{
          '/': (RouteArguments args) {
            return new Scaffold(
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
            );
          }
        }
      ));
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNull);
      time = 1000;
      tester.tap(tester.findElementByKey(tapTarget)); // queue bar1
      ScaffoldFeatureController<SnackBar> firstController = lastController;
      time = 2;
      tester.tap(tester.findElementByKey(tapTarget)); // queue bar2
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(); // schedule animation for bar1
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 1.50s
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 2.25s
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 10000)); // 12.25s
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);

      firstController.close(); // snackbar is manually dismissed

      tester.pump(new Duration(milliseconds: 750)); // 13.00s // reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNotNull);
      expect(tester.findText('bar2'), isNull);
      tester.pump(new Duration(milliseconds: 750)); // 13.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 14.50s // animation last frame; two second timer starts here
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 15.25s
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 16.00s
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 16.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
      tester.pump(); // begin animation
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNotNull);
      tester.pump(new Duration(milliseconds: 750)); // 17.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
      expect(tester.findText('bar1'), isNull);
      expect(tester.findText('bar2'), isNull);
    });
  });
}
