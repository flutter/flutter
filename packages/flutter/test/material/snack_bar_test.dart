// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.8

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

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
                  duration: Duration(seconds: 2),
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }
        ),
      ),
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
                  duration: const Duration(seconds: 2),
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }
        ),
      ),
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
                  duration: Duration(seconds: time),
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }
        ),
      ),
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
                  duration: const Duration(seconds: 2),
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          }
        ),
      ),
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
                    },
                  ),
                ));
              },
              child: const Text('X'),
            );
          }
        ),
      ),
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

  testWidgets('Light theme SnackBar has dark background', (WidgetTester tester) async {
    final ThemeData lightTheme = ThemeData.light();
    await tester.pumpWidget(
      MaterialApp(
        theme: lightTheme,
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
                          label: 'ACTION',
                          onPressed: () { },
                        ),
                      ),
                    );
                  },
                  child: const Text('X'),
                );
              }
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final RenderPhysicalModel renderModel = tester.renderObject(
        find.widgetWithText(Material, 'I am a snack bar.').first
    );
    // There is a somewhat complicated background color calculation based
    // off of the surface color. For the default light theme it
    // should be this value.
    expect(renderModel.color, equals(const Color(0xFF333333)));
  });

  testWidgets('Dark theme SnackBar has light background', (WidgetTester tester) async {
    final ThemeData darkTheme = ThemeData.dark();
    await tester.pumpWidget(
      MaterialApp(
        theme: darkTheme,
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
                        label: 'ACTION',
                        onPressed: () { },
                      ),
                    ),
                  );
                },
                child: const Text('X'),
              );
            }
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final RenderPhysicalModel renderModel = tester.renderObject(
      find.widgetWithText(Material, 'I am a snack bar.').first
    );
    expect(renderModel.color, equals(darkTheme.colorScheme.onSurface));
  });

  testWidgets('Snackbar margin can be customized', (WidgetTester tester) async {
    const double padding = 20.0;
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
                        margin: const EdgeInsets.all(padding),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('X'),
                );
              }
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final Finder materialFinder = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Material),
    );
    final Offset snackBarBottomLeft = tester.getBottomLeft(materialFinder);
    final Offset snackBarBottomRight = tester.getBottomRight(materialFinder);
    expect(snackBarBottomLeft.dx, padding);
    expect(snackBarBottomLeft.dy, 600 - padding); // Device height is 600.
    expect(snackBarBottomRight.dx, 800 - padding); // Device width is 800.
  });

  testWidgets('SnackbarBehavior.floating is positioned within safe area', (WidgetTester tester) async {
    const double viewPadding = 50.0;
    const double floatingSnackBarDefaultBottomMargin = 10.0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            // Simulate non-safe area.
            viewPadding: EdgeInsets.only(bottom: viewPadding),
          ),
          child: Scaffold(
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('I am a snack bar.'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('X'),
                );
              }
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // Start animation
    await tester.pump(const Duration(milliseconds: 750));

    final Finder materialFinder = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Material),
    );
    final Offset snackBarBottomLeft = tester.getBottomLeft(materialFinder);
    expect(
      snackBarBottomLeft.dy,
      // Device height is 600.
      600 - viewPadding - floatingSnackBarDefaultBottomMargin,
    );
  });

  testWidgets('Snackbar padding can be customized', (WidgetTester tester) async {
    const double padding = 20.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('I am a snack bar.'),
                        padding: EdgeInsets.all(padding),
                      ),
                    );
                  },
                  child: const Text('X'),
                );
              }
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final Finder textFinder = find.text('I am a snack bar.');
    final Finder materialFinder = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Material),
    );
    final Offset textBottomLeft = tester.getBottomLeft(textFinder);
    final Offset textTopRight = tester.getTopRight(textFinder);
    final Offset snackBarBottomLeft = tester.getBottomLeft(materialFinder);
    final Offset snackBarTopRight = tester.getTopRight(materialFinder);
    expect(textBottomLeft.dx - snackBarBottomLeft.dx, padding);
    expect(snackBarTopRight.dx - textTopRight.dx, padding);
    // The text is given a vertical padding of 14 already.
    expect(snackBarBottomLeft.dy - textBottomLeft.dy, padding + 14);
    expect(textTopRight.dy - snackBarTopRight.dy, padding + 14);
  });

  testWidgets('Snackbar width can be customized', (WidgetTester tester) async {
    const double width = 200.0;
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
                        width: width,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: const Text('X'),
                );
              }
          ),
        ),
      ),
    );

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750));

    final Finder materialFinder = find.descendant(
      of: find.byType(SnackBar),
      matching: find.byType(Material),
    );
    final Offset snackBarBottomLeft = tester.getBottomLeft(materialFinder);
    final Offset snackBarBottomRight = tester.getBottomRight(materialFinder);
    expect(snackBarBottomLeft.dx, (800 - width) / 2); // Device width is 800.
    expect(snackBarBottomRight.dx, (800 + width) / 2); // Device width is 800.
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
                        onPressed: () { },
                      ),
                    ),
                  );
                },
                child: const Text('X'),
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
    } else {
      expect(false, true);
    }
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
                    action: SnackBarAction(label: 'ACTION', onPressed: () { }),
                  ));
                },
                child: const Text('X'),
              );
            }
          ),
        ),
      ),
    ));
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750)); // Animation last frame.

    final Offset textBottomLeft = tester.getBottomLeft(find.text('I am a snack bar.'));
    final Offset textBottomRight = tester.getBottomRight(find.text('I am a snack bar.'));
    final Offset actionTextBottomLeft = tester.getBottomLeft(find.text('ACTION'));
    final Offset actionTextBottomRight = tester.getBottomRight(find.text('ACTION'));
    final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
    final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));

    expect(textBottomLeft.dx - snackBarBottomLeft.dx, 24.0 + 10.0); // margin + left padding
    expect(snackBarBottomLeft.dy - textBottomLeft.dy, 17.0 + 40.0); // margin + bottom padding
    expect(actionTextBottomLeft.dx - textBottomRight.dx, 24.0);
    expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 24.0 + 30.0); // margin + right padding
    expect(snackBarBottomRight.dy - actionTextBottomRight.dy, 17.0 + 40.0); // margin + bottom padding
  });

  testWidgets(
    'Custom padding between SnackBar and its contents when set to SnackBarBehavior.fixed',
    (WidgetTester tester) async {
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
                      action: SnackBarAction(label: 'ACTION', onPressed: () {}),
                    ));
                  },
                  child: const Text('X'),
                );
              }
            ),
          ),
        ),
      ));
      await tester.tap(find.text('X'));
      await tester.pump(); // start animation
      await tester.pump(const Duration(milliseconds: 750)); // Animation last frame.

      final Offset textBottomLeft = tester.getBottomLeft(find.text('I am a snack bar.'));
      final Offset textBottomRight = tester.getBottomRight(find.text('I am a snack bar.'));
      final Offset actionTextBottomLeft = tester.getBottomLeft(find.text('ACTION'));
      final Offset actionTextBottomRight = tester.getBottomRight(find.text('ACTION'));
      final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
      final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));

      expect(textBottomLeft.dx - snackBarBottomLeft.dx, 24.0 + 10.0); // margin + left padding
      expect(snackBarBottomLeft.dy - textBottomLeft.dy, 17.0); // margin (with no bottom padding)
      expect(actionTextBottomLeft.dx - textBottomRight.dx, 24.0);
      expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 24.0 + 30.0); // margin + right padding
      expect(snackBarBottomRight.dy - actionTextBottomRight.dy, 17.0); // margin (with no bottom padding)
    });

  testWidgets('SnackBar should push FloatingActionButton above', (WidgetTester tester) async {
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
          floatingActionButton: FloatingActionButton(
            child: const Icon(Icons.send),
            onPressed: () {},
          ),
          body: Builder(
            builder: (BuildContext context) {
              return GestureDetector(
                onTap: () {
                  Scaffold.of(context).showSnackBar(SnackBar(
                    content: const Text('I am a snack bar.'),
                    duration: const Duration(seconds: 2),
                    action: SnackBarAction(label: 'ACTION', onPressed: () {}),
                  ));
                },
                child: const Text('X'),
              );
            }
          ),
        ),
      ),
    ));

    // Get the Rect of the FAB to compare after the SnackBar appears.
    final Rect originalFabRect = tester.getRect(find.byType(FloatingActionButton));

    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750)); // Animation last frame.

    final Rect fabRect = tester.getRect(find.byType(FloatingActionButton));

    // FAB should shift upwards after SnackBar appears.
    expect(fabRect.center.dy, lessThan(originalFabRect.center.dy));

    final Offset snackBarTopRight = tester.getTopRight(find.byType(SnackBar));

    // FAB's surrounding padding is set to [kFloatingActionButtonMargin] in floating_action_button_location.dart by default.
    const int defaultFabPadding = 16;

    // FAB should be positioned above the SnackBar by the default padding.
    expect(fabRect.bottomRight.dy, snackBarTopRight.dy - defaultFabPadding);
  });

  testWidgets('Floating SnackBar button text alignment', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: ThemeData(
        snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating,)
      ),
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
                    action: SnackBarAction(label: 'ACTION', onPressed: () {}),
                  ));
                },
                child: const Text('X'),
              );
            }
          ),
        ),
      ),
    ));
    await tester.tap(find.text('X'));
    await tester.pump(); // start animation
    await tester.pump(const Duration(milliseconds: 750)); // Animation last frame.

    final Offset textBottomLeft = tester.getBottomLeft(find.text('I am a snack bar.'));
    final Offset textBottomRight = tester.getBottomRight(find.text('I am a snack bar.'));
    final Offset actionTextBottomLeft = tester.getBottomLeft(find.text('ACTION'));
    final Offset actionTextBottomRight = tester.getBottomRight(find.text('ACTION'));
    final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
    final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));

    expect(textBottomLeft.dx - snackBarBottomLeft.dx, 31.0 + 10.0); // margin + left padding
    expect(snackBarBottomLeft.dy - textBottomLeft.dy, 27.0); // margin (with no bottom padding)
    expect(actionTextBottomLeft.dx - textBottomRight.dx, 16.0);
    expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 31.0 + 30.0); // margin + right padding
    expect(snackBarBottomRight.dy - actionTextBottomRight.dy, 27.0); // margin (with no bottom padding)
  });

  testWidgets(
    'Custom padding between SnackBar and its contents when set to SnackBarBehavior.floating',
    (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(
          snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating)
        ),
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
                      action: SnackBarAction(label: 'ACTION', onPressed: () {}),
                    ));
                  },
                  child: const Text('X'),
                );
              }
            ),
          ),
        ),
      ));
      await tester.tap(find.text('X'));
      await tester.pump(); // start animation
      await tester.pump(const Duration(milliseconds: 750)); // Animation last frame.

      final Offset textBottomLeft = tester.getBottomLeft(find.text('I am a snack bar.'));
      final Offset textBottomRight = tester.getBottomRight(find.text('I am a snack bar.'));
      final Offset actionTextBottomLeft = tester.getBottomLeft(find.text('ACTION'));
      final Offset actionTextBottomRight = tester.getBottomRight(find.text('ACTION'));
      final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
      final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));

      expect(textBottomLeft.dx - snackBarBottomLeft.dx, 31.0 + 10.0); // margin + left padding
      expect(snackBarBottomLeft.dy - textBottomLeft.dy, 27.0); // margin (with no bottom padding)
      expect(actionTextBottomLeft.dx - textBottomRight.dx, 16.0);
      expect(snackBarBottomRight.dx - actionTextBottomRight.dx, 31.0 + 30.0); // margin + right padding
      expect(snackBarBottomRight.dy - actionTextBottomRight.dy, 27.0); // margin (with no bottom padding)
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
                    },
                  ),
                )).closed.then<void>((SnackBarClosedReason reason) {
                  closedReason = reason;
                });
              },
              child: const Text('X'),
            );
          },
        ),
      ),
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
                      onPressed: () { },
                    ),
                  ));
                },
                child: const Text('X'),
              );
            },
          ),
        ),
      ),
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
                                onPressed: () { },
                            ),
                          ));
                        },
                        child: const Text('X'),
                    );
                  },
                ),
            ),
        ),
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
                            content: Text(helloSnackBar),
                        ));
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                          height: 100.0,
                          width: 100.0,
                          key: tapTarget,
                      ),
                  );
                }
            ),
        ),
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
    Future<void> boilerplate({ bool accessibleNavigation }) {
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
                                  action: SnackBarAction(label: 'foo', onPressed: () { }),
                              ));
                            },
                            behavior: HitTestBehavior.opaque,
                            child: const Text('X'),
                        );
                      }
                  ),
              ),
          ),
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
                key: tapTarget,
              ),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.byKey(tapTarget));
    expect(tester.takeException(), isNotNull);
  });

  testWidgets('Snackbar calls onVisible once', (WidgetTester tester) async {
    const Key tapTarget = Key('tap-target');
    int called = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: const Text('hello'),
                  duration: const Duration(seconds: 1),
                  onVisible: () {
                    called += 1;
                  },
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.byKey(tapTarget));
    await tester.pump(); // start animation
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
    expect(called, 1);
  });

  testWidgets('Snackbar does not call onVisible when it is queued', (WidgetTester tester) async {
    const Key tapTarget = Key('tap-target');
    int called = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (BuildContext context) {
            return GestureDetector(
              onTap: () {
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: const Text('hello'),
                  duration: const Duration(seconds: 1),
                  onVisible: () {
                    called += 1;
                  },
                ));
                Scaffold.of(context).showSnackBar(SnackBar(
                  content: const Text('hello 2'),
                  duration: const Duration(seconds: 1),
                  onVisible: () {
                    called += 1;
                  },
                ));
              },
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 100.0,
                width: 100.0,
                key: tapTarget,
              ),
            );
          },
        ),
      ),
    ));

    await tester.tap(find.byKey(tapTarget));
    await tester.pump(); // start animation
    await tester.pumpAndSettle();

    expect(find.text('hello'), findsOneWidget);
    expect(called, 1);
  });

  group('SnackBar position', () {
    for (final SnackBarBehavior behavior in SnackBarBehavior.values) {
      final SnackBar snackBar = SnackBar(
        content: const Text('SnackBar text'),
        behavior: behavior,
      );

      testWidgets(
        '$behavior should align SnackBar with the bottom of Scaffold '
        'when Scaffold has no other elements',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Container(),
              ),
            ),
          );

          final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
          scaffoldState.showSnackBar(snackBar);

          await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

          final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));
          final Offset scaffoldBottomRight = tester.getBottomRight(find.byType(Scaffold));

          expect(snackBarBottomRight, equals(scaffoldBottomRight));

          final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
          final Offset scaffoldBottomLeft = tester.getBottomLeft(find.byType(Scaffold));

          expect(snackBarBottomLeft, equals(scaffoldBottomLeft));
        },
      );

      testWidgets(
        '$behavior should align SnackBar with the top of BottomNavigationBar '
        'when Scaffold has no FloatingActionButton',
        (WidgetTester tester) async {
          final UniqueKey boxKey = UniqueKey();
          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: Container(),
                bottomNavigationBar: SizedBox(key: boxKey, width: 800, height: 60),
              ),
            ),
          );

          final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
          scaffoldState.showSnackBar(snackBar);

          await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

          final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));
          final Offset bottomNavigationBarTopRight = tester.getTopRight(find.byKey(boxKey));

          expect(snackBarBottomRight, equals(bottomNavigationBarTopRight));

          final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
          final Offset bottomNavigationBarTopLeft = tester.getTopLeft(find.byKey(boxKey));

          expect(snackBarBottomLeft, equals(bottomNavigationBarTopLeft));
        },
      );

      testWidgets(
        'Padding of $behavior is not consumed by viewInsets',
        (WidgetTester tester) async {
          final Widget child = Directionality(
            textDirection: TextDirection.ltr,
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              floatingActionButton: FloatingActionButton(
                child: const Icon(Icons.send),
                onPressed: () {},
              ),
              body: Builder(
                builder: (BuildContext context) {
                  return GestureDetector(
                    onTap: () {
                      Scaffold.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('I am a snack bar.'),
                          duration: const Duration(seconds: 2),
                          action: SnackBarAction(label: 'ACTION', onPressed: () {}),
                          behavior: behavior,
                        ),
                      );
                    },
                    child: const Text('X'),
                  );
                },
              ),
            ),
          );

          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.only(bottom: 20.0),
              ),
              child: child,
            ),
          );
          await tester.tap(find.text('X'));
          await tester.pumpAndSettle(); // Show snackbar
          final Offset initialBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
          final Offset initialBottomRight = tester.getBottomRight(find.byType(SnackBar));
          // Consume bottom padding - as if by the keyboard opening
          await tester.pumpWidget(
            MediaQuery(
              data: const MediaQueryData(
                padding: EdgeInsets.zero,
                viewPadding: EdgeInsets.all(20),
                viewInsets: EdgeInsets.all(100),
              ),
              child: child,
            ),
          );
          await tester.tap(find.text('X'));
          await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

          final Offset finalBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
          final Offset finalBottomRight = tester.getBottomRight(find.byType(SnackBar));

          expect(initialBottomLeft, finalBottomLeft);
          expect(initialBottomRight, finalBottomRight);
        },
      );
    }

    testWidgets(
      '${SnackBarBehavior.fixed} should align SnackBar with the bottom of Scaffold '
      'when Scaffold has a FloatingActionButton',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(),
              floatingActionButton: FloatingActionButton(onPressed: () {}),
            ),
          ),
        );

        final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
        scaffoldState.showSnackBar(
          const SnackBar(
            content: Text('Snackbar text'),
            behavior: SnackBarBehavior.fixed,
          ),
        );

        await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

        final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));
        final Offset scaffoldBottomRight = tester.getBottomRight(find.byType(Scaffold));

        expect(snackBarBottomRight, equals(scaffoldBottomRight));

        final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
        final Offset scaffoldBottomLeft = tester.getBottomLeft(find.byType(Scaffold));

        expect(snackBarBottomLeft, equals(scaffoldBottomLeft));
      },
    );

    testWidgets(
      '${SnackBarBehavior.floating} should align SnackBar with the top of FloatingActionButton'
      'when Scaffold has a FloatingActionButton',
      (WidgetTester tester) async {
        await tester.pumpWidget(MaterialApp(
          home: Scaffold(
            floatingActionButton: FloatingActionButton(
              child: const Icon(Icons.send),
              onPressed: () {},
            ),
            body: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () {
                    Scaffold.of(context).showSnackBar(SnackBar(
                      content: const Text('I am a snack bar.'),
                      duration: const Duration(seconds: 2),
                      action: SnackBarAction(label: 'ACTION', onPressed: () {}),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  child: const Text('X'),
                );
              },
            ),
          ),
        ));
        await tester.tap(find.text('X'));
        await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

        final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
        final Offset floatingActionButtonTopLeft = tester.getTopLeft(
          find.byType(FloatingActionButton),
        );

        // Since padding between the SnackBar and the FAB is created by the SnackBar,
        // the bottom offset of the SnackBar should be equal to the top offset of the FAB
        expect(snackBarBottomLeft.dy, floatingActionButtonTopLeft.dy);
      },
    );

    testWidgets(
      '${SnackBarBehavior.fixed} should align SnackBar with the top of BottomNavigationBar '
      'when Scaffold has a BottomNavigationBar and FloatingActionButton',
      (WidgetTester tester) async {
        final UniqueKey boxKey = UniqueKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(),
              bottomNavigationBar: SizedBox(key: boxKey, width: 800, height: 60),
              floatingActionButton: FloatingActionButton(onPressed: () {}),
            ),
          ),
        );

        final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
        scaffoldState.showSnackBar(
          const SnackBar(
            content: Text('SnackBar text'),
            behavior: SnackBarBehavior.fixed,
          ),
        );

        await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

        final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));
        final Offset bottomNavigationBarTopRight = tester.getTopRight(find.byKey(boxKey));

        expect(snackBarBottomRight, equals(bottomNavigationBarTopRight));

        final Offset snackBarBottomLeft = tester.getBottomLeft(find.byType(SnackBar));
        final Offset bottomNavigationBarTopLeft = tester.getTopLeft(find.byKey(boxKey));

        expect(snackBarBottomLeft, equals(bottomNavigationBarTopLeft));
      },
    );

    testWidgets(
      '${SnackBarBehavior.floating} should align SnackBar with the top of FloatingActionButton '
      'when Scaffold has BottomNavigationBar and FloatingActionButton',
      (WidgetTester tester) async {
        final UniqueKey boxKey = UniqueKey();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Container(),
              bottomNavigationBar: SizedBox(key: boxKey, width: 800, height: 60),
              floatingActionButton: FloatingActionButton(onPressed: () {}),
            ),
          ),
        );

        final ScaffoldState scaffoldState = tester.state(find.byType(Scaffold));
        scaffoldState.showSnackBar(
          const SnackBar(
            content: Text('SnackBar text'),
            behavior: SnackBarBehavior.floating,
          ),
        );

        await tester.pumpAndSettle(); // Have the SnackBar fully animate out.

        final Offset snackBarBottomRight = tester.getBottomRight(find.byType(SnackBar));
        final Offset fabTopRight = tester.getTopRight(find.byType(FloatingActionButton));

        expect(snackBarBottomRight.dy, equals(fabTopRight.dy));
      },
    );
  });
}
