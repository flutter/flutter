// Copyright 2015 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('SnackBar control test', (WidgetTester tester) async {
    const String helloSnackBar = 'Hello SnackBar';
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(const SnackBar(
                  content: Text(helloSnackBar),
                  duration: Duration(seconds: 2)
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
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
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                snackBarCount += 1;
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text('bar$snackBarCount'),
                  duration: const Duration(seconds: 2)
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
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
    const Key tapTarget = Key('tap-target');
    int time;
    ScaffoldFeatureController<SnackBar, SnackBarClosedReason> lastController;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                snackBarCount += 1;
                lastController = Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text('bar$snackBarCount'),
                  duration: Duration(seconds: time)
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
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
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                snackBarCount += 1;
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text('bar$snackBarCount'),
                  duration: const Duration(seconds: 2)
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
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
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: const Text('I am a snack bar.'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
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

  testWidgets('Snackbar labels can be colored', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('I am a snack bar.'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(
                        textColor: Colors.lightBlue,
                        disabledTextColor: Colors.red,
                        label: 'ACTION',
                        onPressed: () {},
                      ),
                    ),
                  );
                },
                child: const Text('X')
              );
            }
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final Element actionTextBox = tester.element(find.text('ACTION'));
    final Widget textWidget = actionTextBox.widget;
    final DefaultTextStyle defaultTextStyle = DefaultTextStyle.of(actionTextBox);
    if (textWidget is Text) {
      TextStyle effectiveStyle = textWidget.style;
      effectiveStyle = defaultTextStyle.style.merge(textWidget.style);
      expect(effectiveStyle.color, Colors.lightBlue);
    } else
      expect(false, true);
  });

  testWidgets('SnackBar button text alignment', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(
            left: 10.0,
            top: 20.0,
            right: 30.0,
            bottom: 40.0,
          ),
        ),
        child: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: const Text('I am a snack bar.'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(label: 'ACTION', onPressed: () {})
                  ));
                },
                child: const Text('X')
              );
            }
          ),
        ),
      ),
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

    expect(textBottomLeft.dx - snackBarBottomLeft.dx, 24.0 + 10.0); // margin + left padding
    expect(snackBarBottomLeft.dy - textBottomLeft.dy, 17.0 + 40.0); // margin + bottom padding
    expect(actionTextBottomLeft.dx - textBottomRight.dx, 24.0);
    expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 24.0 + 30.0); // margin + right padding
    expect(snackBarBottomRight.dy - actionTextBottomRight.dy, 17.0 + 40.0); // margin + bottom padding
  });

  testWidgets('SnackBar is positioned above BottomNavigationBar', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: MediaQuery(
        data: const MediaQueryData(
          padding: EdgeInsets.only(
            left: 10.0,
            top: 20.0,
            right: 30.0,
            bottom: 40.0,
          ),
        ),
        child: Scaffold(
          bottomNavigationBar: BottomNavigationBar(
            items: const <BottomNavigationBarItem>[
              BottomNavigationBarItem(icon: Icon(Icons.favorite), title: Text('Animutation')),
              BottomNavigationBarItem(icon: Icon(Icons.block), title: Text('Zombo.com')),
            ],
          ),
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: const Text('I am a snack bar.'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(label: 'ACTION', onPressed: () {})
                  ));
                },
                child: const Text('X')
              );
            }
          ),
        ),
      ),
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

    expect(textBottomLeft.dx - snackBarBottomLeft.dx, 24.0 + 10.0); // margin + left padding
    expect(snackBarBottomLeft.dy - textBottomLeft.dy, 17.0); // margin (with no bottom padding)
    expect(actionTextBottomLeft.dx - textBottomRight.dx, 24.0);
    expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 24.0 + 30.0); // margin + right padding
    expect(snackBarBottomRight.dy - actionTextBottomRight.dy, 17.0); // margin (with no bottom padding)
  });

  testWidgets('SnackBarClosedReason', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    bool actionPressed = false;
    SnackBarClosedReason closedReason;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: const Text('snack'),
                  duration: const Duration(seconds: 2),
                  action: SnackBarAction(
                    label: 'ACTION',
                    onPressed: () {
                      actionPressed = true;
                    }
                  ),
                )).closed.then<void>((SnackBarClosedReason reason) {
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
    // Closed reason is only set when the animation is complete.
    await tester.pump(const Duration(milliseconds: 250));
    expect(closedReason, isNull);
    // Wait for animation to complete.
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.action));

    // Pop up the snack bar and then swipe downwards to dismiss it.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.drag(find.text('snack'), const Offset(0.0, 50.0));
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.swipe));

    // Pop up the snack bar and then remove it.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    scaffoldKey.currentState.removeCurrentSnackBar();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.remove));

    // Pop up the snack bar and then hide it.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    scaffoldKey.currentState.hideCurrentSnackBar();
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.hide));

    // Pop up the snack bar and then let it time out.
    await tester.tap(find.text('X'));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 750));
    await tester.pump(const Duration(milliseconds: 1500));
    await tester.pump(); // begin animation
    await tester.pumpAndSettle(const Duration(seconds: 1));
    expect(closedReason, equals(SnackBarClosedReason.timeout));
  });

  testWidgets('accessible navigation behavior with action', (WidgetTester tester) async {
      final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(accessibleNavigation: true),
          child: Scaffold(
            key: scaffoldKey,
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: const Text('snack'),
                      duration: const Duration(seconds: 1),
                      action: SnackBarAction(
                        label: 'ACTION',
                        onPressed: () {}
                      ),
                    ));
                  },
                  child: const Text('X')
                );
              },
            )
          )
        )
      ));
      await tester.tap(find.text('X'));
      await tester.pump();
      // Find action immediately
      expect(find.text('ACTION'), findsOneWidget);
      // Snackbar doesn't close
      await tester.pump(const Duration(seconds: 10));
      expect(find.text('ACTION'), findsOneWidget);
      await tester.tap(find.text('ACTION'));
      await tester.pump();
      // Snackbar closes immediately
      expect(find.text('ACTION'), findsNothing);
  });

  testWidgets('contributes dismiss semantics', (WidgetTester tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
            data: const MediaQueryData(accessibleNavigation: true),
            child: Scaffold(
                key: scaffoldKey,
                body: Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                        onTap: () {
                          Scaffold.of(context).showSnackBar(SnackBar(
                            content: const Text('snack'),
                            duration: const Duration(seconds: 1),
                            action: SnackBarAction(
                                label: 'ACTION',
                                onPressed: () {}
                            ),
                          ));
                        },
                        child: const Text('X')
                    );
                  },
                )
            )
        )
    ));
    await tester.tap(find.text('X'));
    await tester.pumpAndSettle();

    expect(tester.getSemantics(find.text('snack')), matchesSemantics(
      isLiveRegion: true,
      hasDismissAction: true,
      hasScrollDownAction: true,
      hasScrollUpAction: true,
      label: 'snack',
      textDirection: TextDirection.ltr,
    ));
    handle.dispose();
  });

  testWidgets('SnackBar default display duration test', (WidgetTester tester) async {
    const String helloSnackBar = 'Hello SnackBar';
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                      onTap: () {
                        Scaffold.of(context).showSnackBar(const SnackBar(
                            content: Text(helloSnackBar)
                        ));
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
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
    await tester.pump(const Duration(milliseconds: 750)); // 0.75s // animation last frame; four second timer starts here
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 1.50s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 2.25s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 3.00s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 750)); // 3.75s
    expect(find.text(helloSnackBar), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1000)); // 4.75s // timer triggers to dismiss snackbar, reverse animation is scheduled
    await tester.pump(); // begin animation
    expect(find.text(helloSnackBar), findsOneWidget); // frame 0 of dismiss animation
    await tester.pump(const Duration(milliseconds: 750)); // 5.50s // last frame of animation, snackbar removed from build
    expect(find.text(helloSnackBar), findsNothing);
  });

  testWidgets('SnackBar handles updates to accessibleNavigation', (WidgetTester tester) async {
    Future<void> boilerplate({bool accessibleNavigation}) {
      return tester.pumpWidget(MaterialApp(
          home: MediaQuery(
              data: MediaQueryData(accessibleNavigation: accessibleNavigation),
              child: Scaffold(
                  body: Builder(
                      builder: (BuildContext context) {
                        return GestureDetector(
                            onTap: () {
                              Scaffold.of(context).showSnackBar(SnackBar(
                                  content: const Text('test'),
                                  action: SnackBarAction(label: 'foo', onPressed: () {}),
                              ));
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Text('X'),
                        );
                      }
                  )
              )
          )
      ));
    }

    await boilerplate(accessibleNavigation: false);
    expect(find.text('test'), findsNothing);
    await tester.tap(find.text('X'));
    await tester.pump(); // schedule animation
    expect(find.text('test'), findsOneWidget);
    await tester.pump(); // begin animation
    await tester.pump(const Duration(milliseconds: 4750)); // 4.75s
    expect(find.text('test'), findsOneWidget);

    // Enabled accessible navigation
    await boilerplate(accessibleNavigation: true);

    await tester.pump(const Duration(milliseconds: 4000)); // 8.75s
    await tester.pump();
    expect(find.text('test'), findsOneWidget);

    // disable accessible navigation
    await boilerplate(accessibleNavigation: false);
    await tester.pumpAndSettle(const Duration(milliseconds: 5750));

    expect(find.text('test'), findsNothing);
  });

  testWidgets('Snackbar asserts if passed a null duration', (WidgetTester tester) async {
    const Key tapTarget = Key('tap-target');
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: Text(nonconst('hello')),
                  duration: null,
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget
              ),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.byKey(tapTarget));
    expect(tester.takeException(), isNotNull);
  });
}
