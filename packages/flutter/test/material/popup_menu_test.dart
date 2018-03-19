// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show window;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

void main() {
  testWidgets('Navigator.push works within a PopupMenuButton', (WidgetTester tester) async {
    final Key targetKey = new UniqueKey();
    await tester.pumpWidget(
      new MaterialApp(
        routes: <String, WidgetBuilder> {
          '/next': (BuildContext context) {
            return const Text('Next');
          },
        },
        home: new Material(
          child: new Center(
            child: new Builder(
              key: targetKey,
              builder: (BuildContext context) {
                return new PopupMenuButton<int>(
                  onSelected: (int value) {
                    Navigator.pushNamed(context, '/next');
                  },
                  itemBuilder: (BuildContext context) {
                    return <PopupMenuItem<int>>[
                      const PopupMenuItem<int>(
                        value: 1,
                        child: const Text('One')
                      ),
                    ];
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(targetKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // finish the menu animation

    expect(find.text('One'), findsOneWidget);
    expect(find.text('Next'), findsNothing);

    await tester.tap(find.text('One'));
    await tester.pump(); // return the future
    await tester.pump(); // start the navigation
    await tester.pump(const Duration(seconds: 1)); // end the navigation

    expect(find.text('One'), findsNothing);
    expect(find.text('Next'), findsOneWidget);
  });

  testWidgets('PopupMenuButton calls onCanceled callback when an item is not selected', (WidgetTester tester) async {
    int cancels = 0;
    BuildContext popupContext;
    final Key noCallbackKey = new UniqueKey();
    final Key withCallbackKey = new UniqueKey();

    await tester.pumpWidget(
      new MaterialApp(
        home: new Material(
          child: new Column(
            children: <Widget>[
              new PopupMenuButton<int>(
                key: noCallbackKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(
                      value: 1,
                      child: const Text('Tap me please!'),
                    ),
                  ];
                },
              ),
              new PopupMenuButton<int>(
                key: withCallbackKey,
                onCanceled: () => cancels++,
                itemBuilder: (BuildContext context) {
                  popupContext = context;
                  return <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(
                      value: 1,
                      child: const Text('Tap me, too!'),
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      ),
    );

    // Make sure everything works if no callback is provided
    await tester.tap(find.byKey(noCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(const Offset(0.0, 0.0));
    await tester.pump();
    expect(cancels, equals(0));

    // Make sure callback is called when a non-selection tap occurs
    await tester.tap(find.byKey(withCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.tapAt(const Offset(0.0, 0.0));
    await tester.pump();
    expect(cancels, equals(1));

    // Make sure callback is called when back navigation occurs
    await tester.tap(find.byKey(withCallbackKey));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    Navigator.of(popupContext).pop();
    await tester.pump();
    expect(cancels, equals(2));
  });

  testWidgets('PopupMenuButton is horizontal on iOS', (WidgetTester tester) async {
    Widget build(TargetPlatform platform) {
      return new MaterialApp(
        theme: new ThemeData(platform: platform),
        home: new Scaffold(
          appBar: new AppBar(
            actions: <Widget>[
              new PopupMenuButton<int>(
                itemBuilder: (BuildContext context) {
                  return <PopupMenuItem<int>>[
                    const PopupMenuItem<int>(
                      value: 1,
                      child: const Text('One')
                    ),
                  ];
                },
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(build(TargetPlatform.android));

    expect(find.byIcon(Icons.more_vert), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    await tester.pumpWidget(build(TargetPlatform.iOS));
    await tester.pumpAndSettle(); // Run theme change animation.

    expect(find.byIcon(Icons.more_vert), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);
  });

  group('PopupMenuButton with Icon', () {
    // Helper function to create simple and valid popup menus.
    List<PopupMenuItem<int>> simplePopupMenuItemBuilder(BuildContext context) {
      return <PopupMenuItem<int>>[
        const PopupMenuItem<int>(
            value: 1,
            child: const Text('1'),
        ),
      ];
    }

    testWidgets('PopupMenuButton fails when given both child and icon', (WidgetTester tester) async {
      expect(() {
        new PopupMenuButton<int>(
            child: const Text('heyo'),
            icon: const Icon(Icons.view_carousel),
            itemBuilder: simplePopupMenuItemBuilder,
        );
      }, throwsA(const isInstanceOf<AssertionError>()));
    });

    testWidgets('PopupMenuButton creates IconButton when given an icon', (WidgetTester tester) async {
      final PopupMenuButton<int> button = new PopupMenuButton<int>(
        icon: const Icon(Icons.view_carousel),
        itemBuilder: simplePopupMenuItemBuilder,
      );

      await tester.pumpWidget(new MaterialApp(
          home: new Scaffold(
            appBar: new AppBar(
              actions: <Widget>[button],
            ),
          ),
        ),
      );

      expect(find.byType(IconButton), findsOneWidget);
      expect(find.byIcon(Icons.view_carousel), findsOneWidget);
    });
  });

  testWidgets('PopupMenu positioning', (WidgetTester tester) async {
    final Widget testButton = new PopupMenuButton<int>(
      itemBuilder: (BuildContext context) {
        return <PopupMenuItem<int>>[
          const PopupMenuItem<int>(value: 1, child: const Text('AAA')),
          const PopupMenuItem<int>(value: 2, child: const Text('BBB')),
          const PopupMenuItem<int>(value: 3, child: const Text('CCC')),
        ];
      },
      child: const SizedBox(
        height: 100.0,
        width: 100.0,
        child: const Text('XXX'),
      ),
    );
    final WidgetPredicate popupMenu = (Widget widget) {
      final String widgetType = widget.runtimeType.toString();
      // TODO(mraleph): Remove the old case below.
      return widgetType == '_PopupMenu<int>' // normal case
          || widgetType == '_PopupMenu'; // for old versions of Dart that don't reify method type arguments
    };

    Future<Null> openMenu(TextDirection textDirection, Alignment alignment) async {
      return TestAsyncUtils.guard(() async {
        await tester.pumpWidget(new Container()); // reset in case we had a menu up already
        await tester.pumpWidget(new TestApp(
          textDirection: textDirection,
          child: new Align(
            alignment: alignment,
            child: testButton,
          ),
        ));
        await tester.tap(find.text('XXX'));
        await tester.pump();
      });
    }

    Future<Null> testPositioningDown(
      WidgetTester tester,
      TextDirection textDirection,
      Alignment alignment,
      TextDirection growthDirection,
      Rect startRect,
    ) {
      return TestAsyncUtils.guard(() async {
        await openMenu(textDirection, alignment);
        Rect rect = tester.getRect(find.byWidgetPredicate(popupMenu));
        expect(rect, startRect);
        bool doneVertically = false;
        bool doneHorizontally = false;
        do {
          await tester.pump(const Duration(milliseconds: 20));
          final Rect newRect = tester.getRect(find.byWidgetPredicate(popupMenu));
          expect(newRect.top, rect.top);
          if (doneVertically) {
            expect(newRect.bottom, rect.bottom);
          } else {
            if (newRect.bottom == rect.bottom) {
              doneVertically = true;
            } else {
              expect(newRect.bottom, greaterThan(rect.bottom));
            }
          }
          switch (growthDirection) {
            case TextDirection.rtl:
              expect(newRect.right, rect.right);
              if (doneHorizontally) {
                expect(newRect.left, rect.left);
              } else {
                if (newRect.left == rect.left) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.left, lessThan(rect.left));
                }
              }
              break;
            case TextDirection.ltr:
              expect(newRect.left, rect.left);
              if (doneHorizontally) {
                expect(newRect.right, rect.right);
              } else {
                if (newRect.right == rect.right) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.right, greaterThan(rect.right));
                }
              }
              break;
          }
          rect = newRect;
        } while (tester.binding.hasScheduledFrame);
      });
    }

    Future<Null> testPositioningDownThenUp(
      WidgetTester tester,
      TextDirection textDirection,
      Alignment alignment,
      TextDirection growthDirection,
      Rect startRect,
    ) {
      return TestAsyncUtils.guard(() async {
        await openMenu(textDirection, alignment);
        Rect rect = tester.getRect(find.byWidgetPredicate(popupMenu));
        expect(rect, startRect);
        int verticalStage = 0; // 0=down, 1=up, 2=done
        bool doneHorizontally = false;
        do {
          await tester.pump(const Duration(milliseconds: 20));
          final Rect newRect = tester.getRect(find.byWidgetPredicate(popupMenu));
          switch (verticalStage) {
            case 0:
              if (newRect.top < rect.top) {
                verticalStage = 1;
                expect(newRect.bottom, greaterThanOrEqualTo(rect.bottom));
                break;
              }
              expect(newRect.top, rect.top);
              expect(newRect.bottom, greaterThan(rect.bottom));
              break;
            case 1:
              if (newRect.top == rect.top) {
                verticalStage = 2;
                expect(newRect.bottom, rect.bottom);
                break;
              }
              expect(newRect.top, lessThan(rect.top));
              expect(newRect.bottom, rect.bottom);
              break;
            case 2:
              expect(newRect.bottom, rect.bottom);
              expect(newRect.top, rect.top);
              break;
            default:
              assert(false);
          }
          switch (growthDirection) {
            case TextDirection.rtl:
              expect(newRect.right, rect.right);
              if (doneHorizontally) {
                expect(newRect.left, rect.left);
              } else {
                if (newRect.left == rect.left) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.left, lessThan(rect.left));
                }
              }
              break;
            case TextDirection.ltr:
              expect(newRect.left, rect.left);
              if (doneHorizontally) {
                expect(newRect.right, rect.right);
              } else {
                if (newRect.right == rect.right) {
                  doneHorizontally = true;
                } else {
                  expect(newRect.right, greaterThan(rect.right));
                }
              }
              break;
          }
          rect = newRect;
        } while (tester.binding.hasScheduledFrame);
      });
    }

    await testPositioningDown(tester, TextDirection.ltr, Alignment.topRight, TextDirection.rtl, new Rect.fromLTWH(792.0, 8.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.rtl, Alignment.topRight, TextDirection.rtl, new Rect.fromLTWH(792.0, 8.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.ltr, Alignment.topLeft, TextDirection.ltr, new Rect.fromLTWH(8.0, 8.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.rtl, Alignment.topLeft, TextDirection.ltr, new Rect.fromLTWH(8.0, 8.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.ltr, Alignment.topCenter, TextDirection.ltr, new Rect.fromLTWH(350.0, 8.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.rtl, Alignment.topCenter, TextDirection.rtl, new Rect.fromLTWH(450.0, 8.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.ltr, Alignment.centerRight, TextDirection.rtl, new Rect.fromLTWH(792.0, 250.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.rtl, Alignment.centerRight, TextDirection.rtl, new Rect.fromLTWH(792.0, 250.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.ltr, Alignment.centerLeft, TextDirection.ltr, new Rect.fromLTWH(8.0, 250.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.rtl, Alignment.centerLeft, TextDirection.ltr, new Rect.fromLTWH(8.0, 250.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.ltr, Alignment.center, TextDirection.ltr, new Rect.fromLTWH(350.0, 250.0, 0.0, 0.0));
    await testPositioningDown(tester, TextDirection.rtl, Alignment.center, TextDirection.rtl, new Rect.fromLTWH(450.0, 250.0, 0.0, 0.0));
    await testPositioningDownThenUp(tester, TextDirection.ltr, Alignment.bottomRight, TextDirection.rtl, new Rect.fromLTWH(792.0, 500.0, 0.0, 0.0));
    await testPositioningDownThenUp(tester, TextDirection.rtl, Alignment.bottomRight, TextDirection.rtl, new Rect.fromLTWH(792.0, 500.0, 0.0, 0.0));
    await testPositioningDownThenUp(tester, TextDirection.ltr, Alignment.bottomLeft, TextDirection.ltr, new Rect.fromLTWH(8.0, 500.0, 0.0, 0.0));
    await testPositioningDownThenUp(tester, TextDirection.rtl, Alignment.bottomLeft, TextDirection.ltr, new Rect.fromLTWH(8.0, 500.0, 0.0, 0.0));
    await testPositioningDownThenUp(tester, TextDirection.ltr, Alignment.bottomCenter, TextDirection.ltr, new Rect.fromLTWH(350.0, 500.0, 0.0, 0.0));
    await testPositioningDownThenUp(tester, TextDirection.rtl, Alignment.bottomCenter, TextDirection.rtl, new Rect.fromLTWH(450.0, 500.0, 0.0, 0.0));
  });

  testWidgets('PopupMenu removes MediaQuery padding', (WidgetTester tester) async {
    BuildContext popupContext;

    await tester.pumpWidget(new MaterialApp(
      home: new MediaQuery(
        data: const MediaQueryData(
          padding: const EdgeInsets.all(50.0),
        ),
        child: new Material(
          child: new PopupMenuButton<int>(
            itemBuilder: (BuildContext context) {
              popupContext = context;
              return <PopupMenuItem<int>>[
                new PopupMenuItem<int>(
                  value: 1,
                  child: new Builder(
                    builder: (BuildContext context) {
                      popupContext = context;
                      return const Text('AAA');
                    },
                  ),
                ),
              ];
            },
            child: const SizedBox(
              height: 100.0,
              width: 100.0,
              child: const Text('XXX'),
            ),
          ),
        ),
      )
    ));

    await tester.tap(find.text('XXX'));

    await tester.pump();

    expect(MediaQuery.of(popupContext).padding, EdgeInsets.zero);
  });
}

class TestApp extends StatefulWidget {
  const TestApp({ this.textDirection, this.child });
  final TextDirection textDirection;
  final Widget child;
  @override
  _TestAppState createState() => new _TestAppState();
}

class _TestAppState extends State<TestApp> {
  @override
  Widget build(BuildContext context) {
    return new Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: new MediaQuery(
        data: new MediaQueryData.fromWindow(window),
        child: new Directionality(
          textDirection: widget.textDirection,
          child: new Navigator(
            onGenerateRoute: (RouteSettings settings) {
              assert(settings.name == '/');
              return new MaterialPageRoute<dynamic>(
                settings: settings,
                builder: (BuildContext context) => new Material(
                  child: widget.child,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
