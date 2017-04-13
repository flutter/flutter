// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SnackBar control test', (WidgetTester tester) async {
    final String helloSnackBar = 'Hello SnackBar';
    final Key tapTarget = const Key('tap-target');
    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        body: new Builder(
          builder: (BuildContext context) {
            return new GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text(helloSnackBar),
                  duration: const Duration(seconds: 2)
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
    await tester.pump(const Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 1.50s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 2.25s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text(helloSnackBar), findsOneWidget); // frame 0 of dismiss animation
    await tester.pump(const Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build
    expect(find.text(helloSnackBar), findsNothing);
  });

  testWidgets('SnackBar twice test', (WidgetTester tester) async {
    int snackBarCount = 0;
    final Key tapTarget = const Key('tap-target');
    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        body: new Builder(
          builder: (BuildContext context) {
            return new GestureDetector(
              onTap: () {
                snackBarCount += 1;
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text("bar$snackBarCount"),
                  duration: const Duration(seconds: 2)
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
    await tester.pump(const Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 1.50s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 2.25s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 3.00s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 3.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 4.50s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 5.25s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 6.00s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 6.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 7.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
  });

  testWidgets('SnackBar cancel test', (WidgetTester tester) async {
    int snackBarCount = 0;
    final Key tapTarget = const Key('tap-target');
    int time;
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> lastController;
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
    final ScaffoldFeatureController<SnackBar, SnackBarClosedReason> firstController = lastController;
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
    await tester.pump(const Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 1.50s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 2.25s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 10000)); // 12.25s
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);

    firstController.close(); // snackbar is manually dismissed

    await tester.pump(const Duration(milliseconds: 750)); // 13.00s // reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsOneWidget);
    expect(find.text('bar2'), findsNothing);
    await tester.pump(const Duration(milliseconds: 750)); // 13.75s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 14.50s // animation last frame; two second timer starts here
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 15.25s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 16.00s
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 16.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 17.50s // last frame of animation, snackbar removed from build, new snack bar put in its place
    expect(find.text('bar1'), findsNothing);
    expect(find.text('bar2'), findsNothing);
  });

  testWidgets('SnackBar dismiss test', (WidgetTester tester) async {
    int snackBarCount = 0;
    final Key tapTarget = const Key('tap-target');
    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        body: new Builder(
          builder: (BuildContext context) {
            return new GestureDetector(
              onTap: () {
                snackBarCount += 1;
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: new Text("bar$snackBarCount"),
                  duration: const Duration(seconds: 2)
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
    await tester.pump(const Duration(milliseconds: 750)); // 0.75s // animation last frame; two second timer starts here
    await tester.drag(find.text('bar1'), const Offset(0.0, 50.0));
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
                  content: const Text('I am a snack bar.'),
                  duration: const Duration(seconds: 2),
                  action: new SnackBarAction(
                    label: 'ACTION',
                    onPressed: () {
                      ++tapCount;
                    }
                  )
                ));
              },
              child: const Text('X')
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
                  content: const Text('I am a snack bar.'),
                  duration: const Duration(seconds: 2),
                  action: new SnackBarAction(label: 'ACTION', onPressed: () {})
                ));
              },
              child: const Text('X')
            );
          }
        )
      )
    ));
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final RenderBox textBox = tester.firstRenderObject(find.text('I am a snack bar.'));
    final RenderBox actionTextBox = tester.firstRenderObject(find.text('ACTION'));
    final RenderBox snackBarBox = tester.firstRenderObject(find.byType(SnackBar));

    final Offset textBottomLeft = textBox.localToGlobal(textBox.size.bottomLeft(Offset.zero));
    final Offset textBottomRight = textBox.localToGlobal(textBox.size.bottomRight(Offset.zero));
    final Offset actionTextBottomLeft = actionTextBox.localToGlobal(actionTextBox.size.bottomLeft(Offset.zero));
    final Offset actionTextBottomRight = actionTextBox.localToGlobal(actionTextBox.size.bottomRight(Offset.zero));
    final Offset snackBarBottomLeft = snackBarBox.localToGlobal(snackBarBox.size.bottomLeft(Offset.zero));
    final Offset snackBarBottomRight = snackBarBox.localToGlobal(snackBarBox.size.bottomRight(Offset.zero));

    expect(textBottomLeft.dx - snackBarBottomLeft.dx, 24.0);
    expect(actionTextBottomLeft.dx - textBottomRight.dx, 24.0);
    expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 24.0);
  });

  testWidgets('SnackBarClosedReason', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = new GlobalKey<ScaffoldState>();
    bool actionPressed = false;
    SnackBarClosedReason closedReason;

    await tester.pumpWidget(new MaterialApp(
      home: new Scaffold(
        key: scaffoldKey,
        body: new Builder(
          builder: (BuildContext context) {
            return new GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(new SnackBar(
                  content: const Text('snack'),
                  duration: const Duration(seconds: 2),
                  action: new SnackBarAction(
                    label: 'ACTION',
                    onPressed: () {
                      actionPressed = true;
                    }
                  ),
                )).closed.then<Null>((SnackBarClosedReason reason) {
                  closedReason = reason;
                });
              },
              child: const Text('X')
            );
          },
        )
      )
    ));

    // Pop up the snack bar and then press its action button.
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));
    expect(actionPressed, isFalse);
    await tester.tap(find.text('ACTION'));
    expect(actionPressed, isTrue);
    await tester.pump(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.action));

    // Pop up the snack bar and then swipe downwards to dismiss it.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.drag(find.text('snack'), const Offset(0.0, 50.0));
    await tester.pump();
    expect(closedReason, equals(SnackBarClosedReason.swipe));

    // Pop up the snack bar and then remove it.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    scaffoldKey.currentState.removeCurrentSnackBar();
    await tester.pump(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.remove));

    // Pop up the snack bar and then hide it.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    scaffoldKey.currentState.hideCurrentSnackBar();
    await tester.pump(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.hide));

    // Pop up the snack bar and then let it time out.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(); // begin animation
    await tester.pump(const Duration(milliseconds: 750));
    expect(closedReason, equals(SnackBarClosedReason.timeout));
  });

}
