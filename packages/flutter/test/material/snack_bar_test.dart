// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SnackBar control test', (WidgetTester tester) async {
    String helloSnackBar = 'Hello SnackBar';
    Key tapTarget = new Key('tap-target');
    await tester.pumpWidget(new MaterialApp(
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
    expect(find.text(helloSnackBar), findsNothing);
    await tester.tap(find.byKey(tapTarget));
    expect(find.text(helloSnackBar), findsNothing);
    await tester.pump(); // schedule animation
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(); // begin animation
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 1.50s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 2.25s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text(helloSnackBar), findsOneWidget); // frame 0 of dismiss animation
    await tester.pump(new Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build
    expect(find.text(helloSnackBar), findsNothing);
  });

  testWidgets('SnackBar twice test', (WidgetTester tester) async {
    int snackBarCount = 0;
    Key tapTarget = new Key('tap-target');
    await tester.pumpWidget(new MaterialApp(
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
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
    await tester.tap(find.byKey(tapTarget)); // queue bar1
    await tester.tap(find.byKey(tapTarget)); // queue bar2
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(); // schedule animation for bar1
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 1.50s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 2.25s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 4.50s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 5.25s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 6.00s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 6.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 7.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
  });

  testWidgets('SnackBar cancel test', (WidgetTester tester) async {
    int snackBarCount = 0;
    Key tapTarget = new Key('tap-target');
    int time;
    ScaffoldFeatureController<SnackBar, Null> lastController;
    await tester.pumpWidget(new MaterialApp(
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
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
    time = 1000;
    await tester.tap(find.byKey(tapTarget)); // queue bar1
    ScaffoldFeatureController<SnackBar, Null> firstController = lastController;
    time = 2;
    await tester.tap(find.byKey(tapTarget)); // queue bar2
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(); // schedule animation for bar1
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 1.50s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 2.25s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 10000)); // 12.25s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);

    firstController.close(); // snackbar is manually dismissed

    await tester.pump(new Duration(milliseconds: 750)); // 13.00s // reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 13.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 14.50s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 15.25s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 16.00s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 16.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(new Duration(milliseconds: 750)); // 17.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
  });

  testWidgets('SnackBar dismiss test', (WidgetTester tester) async {
    int snackBarCount = 0;
    Key tapTarget = new Key('tap-target');
    await tester.pumpWidget(new MaterialApp(
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
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
    await tester.tap(find.byKey(tapTarget)); // queue bar1
    await tester.tap(find.byKey(tapTarget)); // queue bar2
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(); // schedule animation for bar1
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(new Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    await tester.scroll(find.text('bar1'), new Offset(0.0, 50.0));
    await tester.pump(); // bar1 dismissed, bar2 begins animating
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
  });

  testWidgets('SnackBar cannot be tapped twice', (WidgetTester tester) async {
    int tapCount = 0;
    await tester.pumpWidget(new MaterialApp(
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
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    expect(tapCount, equals(0));
    await tester.tap(find.text('ACTION'));
    expect(tapCount, equals(1));
    await tester.tap(find.text('ACTION'));
    expect(tapCount, equals(1));
    await tester.pump();
    await tester.tap(find.text('ACTION'));
    expect(tapCount, equals(1));
  });

  testWidgets('SnackBar button text alignment', (WidgetTester tester) async {
    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        body: new Builder(
          builder: (BuildContext context) {
            return new GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text('I am a snack bar.'),
                  duration: new Duration(seconds: 2),
                  action: new SnackBarAction(label: 'ACTION', onPressed: () {})
                ));
              },
              child: new Text('X')
            );
          }
        )
      )
    ));
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    RenderBox textBox = tester.firstRenderObject(find.text('I am a snack bar.'));
    RenderBox actionTextBox = tester.firstRenderObject(find.text('ACTION'));
    RenderBox snackBarBox = tester.firstRenderObject(find.byType(SnackBar));

    Point textBottomLeft = textBox.localToGlobal(textBox.size.bottomLeft(Point.origin));
    Point textBottomRight = textBox.localToGlobal(textBox.size.bottomRight(Point.origin));
    Point actionTextBottomLeft = actionTextBox.localToGlobal(actionTextBox.size.bottomLeft(Point.origin));
    Point actionTextBottomRight = actionTextBox.localToGlobal(actionTextBox.size.bottomRight(Point.origin));
    Point snackBarBottomLeft = snackBarBox.localToGlobal(snackBarBox.size.bottomLeft(Point.origin));
    Point snackBarBottomRight = snackBarBox.localToGlobal(snackBarBox.size.bottomRight(Point.origin));

    expect(textBottomLeft.x - snackBarBottomLeft.x, 24.0);
    expect(actionTextBottomLeft.x - textBottomRight.x, 24.0);
    expect(snackBarBottomRight.x - actionTextBottomRight.x, 24.0);
  });
}
