// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/navigator_utils.dart';

// Matches _kTopGapRatio in cupertino/sheet.dart.
const double _kTopGapRatio = 0.08;

void main() {
  testWidgets('Sheet route does not cover the whole screen', (WidgetTester tester) async {
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push<void>(
                      scaffoldKey.currentContext!,
                      CupertinoSheetRoute<void>(
                        builder: (BuildContext context) {
                          return const CupertinoPageScaffold(child: Text('Page 2'));
                        },
                      ),
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      greaterThan(0.0),
    );
  });

  testWidgets('Previous route moves slight downward when sheet route is pushed', (
    WidgetTester tester,
  ) async {
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Column(
            children: <Widget>[
              const Text('Page 1'),
              CupertinoButton(
                onPressed: () {
                  Navigator.push<void>(
                    scaffoldKey.currentContext!,
                    CupertinoSheetRoute<void>(
                      builder: (BuildContext context) {
                        return const CupertinoPageScaffold(child: Text('Page 2'));
                      },
                    ),
                  );
                },
                child: const Text('Push Page 2'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.text('Page 2'), findsNothing);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    // Previous page is still visible behind the new sheet.
    expect(find.text('Page 1'), findsOneWidget);
    final Offset pageOneOffset = tester.getTopLeft(
      find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
    );
    expect(pageOneOffset.dy, greaterThan(0.0));
    expect(pageOneOffset.dx, greaterThan(0.0));
    expect(find.text('Page 2'), findsOneWidget);
    final double pageTwoYOffset = tester
        .getTopLeft(
          find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
        )
        .dy;
    expect(pageTwoYOffset, greaterThan(pageOneOffset.dy));
  });

  testWidgets('If a sheet covers another sheet, then the previous sheet moves slightly upwards', (
    WidgetTester tester,
  ) async {
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Column(
            children: <Widget>[
              const Text('Page 1'),
              CupertinoButton(
                onPressed: () {
                  Navigator.push<void>(
                    scaffoldKey.currentContext!,
                    CupertinoSheetRoute<void>(
                      builder: (BuildContext context) {
                        return CupertinoPageScaffold(
                          child: Column(
                            children: <Widget>[
                              const Text('Page 2'),
                              CupertinoButton(
                                onPressed: () {
                                  Navigator.push<void>(
                                    scaffoldKey.currentContext!,
                                    CupertinoSheetRoute<void>(
                                      builder: (BuildContext context) {
                                        return const CupertinoPageScaffold(child: Text('Page 3'));
                                      },
                                    ),
                                  );
                                },
                                child: const Text('Push Page 3'),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Push Page 2'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);
    final double previousPageTwoDY = tester
        .getTopLeft(
          find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
        )
        .dy;

    await tester.tap(find.text('Push Page 3'));
    await tester.pumpAndSettle();

    expect(find.text('Page 3'), findsOneWidget);
    expect(previousPageTwoDY, greaterThan(0.0));
    expect(
      previousPageTwoDY,
      greaterThan(
        tester
            .getTopLeft(
              find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
            )
            .dy,
      ),
    );
  });

  testWidgets('by default showCupertinoSheet does not enable nested navigation', (
    WidgetTester tester,
  ) async {
    final GlobalKey scaffoldKey = GlobalKey();

    Widget sheetScaffoldContent(BuildContext context) {
      return Column(
        children: <Widget>[
          const Text('Page 2'),
          CupertinoButton(
            onPressed: () {
              Navigator.push<void>(
                context,
                CupertinoPageRoute<void>(
                  builder: (BuildContext context) {
                    return CupertinoPageScaffold(
                      child: Column(
                        children: <Widget>[
                          const Text('Page 3'),
                          CupertinoButton(onPressed: () {}, child: const Text('Pop Page 3')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            child: const Text('Push Page 3'),
          ),
        ],
      );
    }

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoSheet<void>(
                      context: scaffoldKey.currentContext!,
                      pageBuilder: (BuildContext context) {
                        return CupertinoPageScaffold(child: sheetScaffoldContent(context));
                      },
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      greaterThan(0.0),
    );

    await tester.tap(find.text('Push Page 3'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);
    // New route should be at the top of the screen.
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 3'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
  });

  testWidgets('useNestedNavigation set to true enables nested navigation', (
    WidgetTester tester,
  ) async {
    final GlobalKey scaffoldKey = GlobalKey();

    Widget sheetScaffoldContent(BuildContext context) {
      return Column(
        children: <Widget>[
          const Text('Page 2'),
          CupertinoButton(
            onPressed: () {
              Navigator.push<void>(
                context,
                CupertinoPageRoute<void>(
                  builder: (BuildContext context) {
                    return CupertinoPageScaffold(
                      child: Column(
                        children: <Widget>[
                          const Text('Page 3'),
                          CupertinoButton(onPressed: () {}, child: const Text('Pop Page 3')),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            child: const Text('Push Page 3'),
          ),
        ],
      );
    }

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoSheet<void>(
                      context: scaffoldKey.currentContext!,
                      useNestedNavigation: true,
                      pageBuilder: (BuildContext context) {
                        return CupertinoPageScaffold(child: sheetScaffoldContent(context));
                      },
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    final double pageTwoDY = tester
        .getTopLeft(
          find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
        )
        .dy;
    expect(pageTwoDY, greaterThan(0.0));

    await tester.tap(find.text('Push Page 3'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsOneWidget);

    // New route should be at the same height as the previous route.
    final double pageThreeDY = tester
        .getTopLeft(
          find.ancestor(of: find.text('Page 3'), matching: find.byType(CupertinoPageScaffold)),
        )
        .dy;
    expect(pageThreeDY, greaterThan(0.0));
    expect(pageThreeDY, equals(pageTwoDY));
  });

  testWidgets('useNestedNavigation handles programmatic pops', (WidgetTester tester) async {
    final GlobalKey scaffoldKey = GlobalKey();

    Widget sheetScaffoldContent(BuildContext context) {
      return Column(
        children: <Widget>[
          const Text('Page 2'),
          CupertinoButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text('Go Back'),
          ),
        ],
      );
    }

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoSheet<void>(
                      context: scaffoldKey.currentContext!,
                      useNestedNavigation: true,
                      pageBuilder: (BuildContext context) {
                        return CupertinoPageScaffold(child: sheetScaffoldContent(context));
                      },
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    // The first page is at the top of the screen.
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.text('Page 2'), findsNothing);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);

    // The first page, which is behind the top sheet but still partially visibile, is moved downwards.
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      greaterThan(0.0),
    );

    await tester.tap(find.text('Go Back'));
    await tester.pumpAndSettle();

    // The first page would correctly transition back and sit at the top of the screen.
    expect(find.text('Page 1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets('useNestedNavigation handles system pop gestures', (WidgetTester tester) async {
    final GlobalKey scaffoldKey = GlobalKey();

    Widget sheetScaffoldContent(BuildContext context) {
      return Column(
        children: <Widget>[
          const Text('Page 2'),
          CupertinoButton(
            onPressed: () {
              Navigator.of(context).push(
                CupertinoPageRoute<void>(
                  builder: (BuildContext context) {
                    return CupertinoPageScaffold(
                      child: Column(
                        children: <Widget>[
                          const Text('Page 3'),
                          CupertinoButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            child: const Text('Go back'),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
            child: const Text('Push Page 3'),
          ),
        ],
      );
    }

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoSheet<void>(
                      context: scaffoldKey.currentContext!,
                      useNestedNavigation: true,
                      pageBuilder: (BuildContext context) {
                        return CupertinoPageScaffold(child: sheetScaffoldContent(context));
                      },
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    // The first page is at the top of the screen.
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.text('Page 2'), findsNothing);
    expect(find.text('Page 3'), findsNothing);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    // The first page, which is behind the top sheet but still partially visibile, is moved downwards.
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      greaterThan(0.0),
    );

    await tester.tap(find.text('Push Page 3'));
    await tester.pumpAndSettle();

    expect(find.text('Page 3'), findsOneWidget);

    // Simulate a system back gesture.
    await simulateSystemBack();
    await tester.pumpAndSettle();

    // Go back to the first page within the sheet.
    expect(find.text('Page 2'), findsOneWidget);
    expect(find.text('Page 3'), findsNothing);

    // The first page is still stacked behind the sheet.
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      greaterThan(0.0),
    );

    await simulateSystemBack();
    await tester.pumpAndSettle();

    // The first page would correctly transition back and sit at the top of the screen.
    expect(find.text('Page 1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.text('Page 2'), findsNothing);
  });

  testWidgets('sheet has route settings', (WidgetTester tester) async {
    await tester.pumpWidget(
      CupertinoApp(
        initialRoute: '/',
        onGenerateRoute: (RouteSettings settings) {
          if (settings.name == '/') {
            return PageRouteBuilder<void>(
              pageBuilder:
                  (
                    BuildContext context,
                    Animation<double> animation,
                    Animation<double> secondaryAnimation,
                  ) {
                    return CupertinoPageScaffold(
                      navigationBar: const CupertinoNavigationBar(middle: Text('Page 1')),
                      child: Container(),
                    );
                  },
            );
          }
          return CupertinoSheetRoute<void>(
            builder: (BuildContext context) {
              return CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(middle: Text('Page: ${settings.name}')),
                child: Container(),
              );
            },
          );
        },
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(find.text('Page 2'), findsNothing);

    tester.state<NavigatorState>(find.byType(Navigator)).pushNamed('/next');
    await tester.pumpAndSettle();

    expect(find.text('Page: /next'), findsOneWidget);
  });

  testWidgets('content does not go below the bottom of the screen', (WidgetTester tester) async {
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push<void>(
                      scaffoldKey.currentContext!,
                      CupertinoSheetRoute<void>(
                        builder: (BuildContext context) {
                          return CupertinoPageScaffold(child: Container());
                        },
                      ),
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(tester.getSize(find.byType(Container)).height, 600.0 - (600.0 * _kTopGapRatio));
  });

  testWidgets('nested navbars remove MediaQuery top padding', (WidgetTester tester) async {
    final GlobalKey scaffoldKey = GlobalKey();
    final GlobalKey appBarKey = GlobalKey();
    final GlobalKey sheetBarKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.fromLTRB(0, 20, 0, 0)),
          child: CupertinoPageScaffold(
            key: scaffoldKey,
            navigationBar: CupertinoNavigationBar(
              key: appBarKey,
              middle: const Text('Navbar'),
              backgroundColor: const Color(0xFFF8F8F8),
            ),
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.push<void>(
                        scaffoldKey.currentContext!,
                        CupertinoSheetRoute<void>(
                          builder: (BuildContext context) {
                            return CupertinoPageScaffold(
                              navigationBar: CupertinoNavigationBar(
                                key: sheetBarKey,
                                middle: const Text('Navbar'),
                              ),
                              child: Container(),
                            );
                          },
                        ),
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    final double homeNavBardHeight = tester.getSize(find.byKey(appBarKey)).height;

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    final double sheetNavBarHeight = tester.getSize(find.byKey(sheetBarKey)).height;

    expect(sheetNavBarHeight, lessThan(homeNavBardHeight));
  });

  testWidgets('Previous route corner radius goes to same when sheet route is popped', (
    WidgetTester tester,
  ) async {
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          child: Column(
            children: <Widget>[
              const Text('Page 1'),
              CupertinoButton(
                onPressed: () {
                  Navigator.push<void>(
                    scaffoldKey.currentContext!,
                    CupertinoSheetRoute<void>(
                      builder: (BuildContext context) {
                        return CupertinoPageScaffold(
                          child: GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: const Icon(Icons.arrow_back_ios),
                          ),
                        );
                      },
                    ),
                  );
                },
                child: const Text('Push Page 2'),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Page 1'), findsOneWidget);
    expect(
      tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy,
      equals(0.0),
    );
    expect(find.byType(Icon), findsNothing);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    // Previous page is still visible behind the new sheet.
    expect(find.text('Page 1'), findsOneWidget);
    final Offset pageOneOffset = tester.getTopLeft(
      find.ancestor(of: find.text('Page 1'), matching: find.byType(CupertinoPageScaffold)),
    );
    expect(pageOneOffset.dy, greaterThan(0.0));
    expect(pageOneOffset.dx, greaterThan(0.0));
    expect(find.byType(Icon), findsOneWidget);

    // Pop Sheet Route
    await tester.tap(find.byType(Icon));
    await tester.pumpAndSettle();

    expect(find.byType(ClipRSuperellipse), findsNothing);
    expect(find.byType(ClipRRect), findsNothing);
  });

  testWidgets('Sheet transition does not interfere after popping', (WidgetTester tester) async {
    final GlobalKey homeKey = GlobalKey();
    final GlobalKey sheetKey = GlobalKey();
    final GlobalKey popupMenuButtonKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: CupertinoPageScaffold(
          key: homeKey,
          child: CupertinoListTile(
            onTap: () {
              showCupertinoSheet<void>(
                context: homeKey.currentContext!,
                pageBuilder: (BuildContext context) {
                  return CupertinoPageScaffold(
                    key: sheetKey,
                    child: const Center(child: Text('Page 2')),
                  );
                },
              );
            },
            title: const Text('ListItem 0'),
            trailing: Material(
              type: MaterialType.transparency,
              child: PopupMenuButton<int>(
                key: popupMenuButtonKey,
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<int>>[
                    const PopupMenuItem<int>(child: Text('Item 0')),
                    const PopupMenuItem<int>(child: Text('Item 1')),
                  ];
                },
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('ListItem 0'));
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsOneWidget);

    final TestGesture gesture = await tester.startGesture(const Offset(100, 200));
    await gesture.moveBy(const Offset(0, 350));
    await tester.pump();

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('Page 2'), findsNothing);
    expect(find.text('ListItem 0'), findsOneWidget);

    await tester.tap(find.byKey(popupMenuButtonKey));
    await tester.pumpAndSettle();

    expect(find.text('Item 0'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('drag dismiss gesture', () {
    Widget dragGestureApp(GlobalKey homeScaffoldKey, GlobalKey sheetScaffoldKey) {
      return CupertinoApp(
        home: CupertinoPageScaffold(
          key: homeScaffoldKey,
          child: Center(
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    showCupertinoSheet<void>(
                      context: homeScaffoldKey.currentContext!,
                      pageBuilder: (BuildContext context) {
                        return CupertinoPageScaffold(
                          key: sheetScaffoldKey,
                          child: const Center(child: Text('Page 2')),
                        );
                      },
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    testWidgets('partial drag and drop does not pop the sheet', (WidgetTester tester) async {
      final GlobalKey homeKey = GlobalKey();
      final GlobalKey sheetKey = GlobalKey();

      await tester.pumpWidget(dragGestureApp(homeKey, sheetKey));

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      var box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double initialPosition = box.localToGlobal(Offset.zero).dy;

      final TestGesture gesture = await tester.startGesture(const Offset(100, 200));
      // Partial drag down
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();

      box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double middlePosition = box.localToGlobal(Offset.zero).dy;
      expect(middlePosition, greaterThan(initialPosition));

      // Release gesture. Sheet should not pop and slide back up.
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double finalPosition = box.localToGlobal(Offset.zero).dy;

      expect(finalPosition, lessThan(middlePosition));
      expect(finalPosition, equals(initialPosition));
    });

    testWidgets('dropping the drag further down the page pops the sheet', (
      WidgetTester tester,
    ) async {
      final GlobalKey homeKey = GlobalKey();
      final GlobalKey sheetKey = GlobalKey();

      await tester.pumpWidget(dragGestureApp(homeKey, sheetKey));

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      final TestGesture gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.moveBy(const Offset(0, 350));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsNothing);
    });

    testWidgets('dismissing with a drag pops all nested routes', (WidgetTester tester) async {
      final GlobalKey homeKey = GlobalKey();
      final GlobalKey sheetKey = GlobalKey();

      Widget sheetScaffoldContent(BuildContext context) {
        return Column(
          children: <Widget>[
            const Text('Page 2'),
            CupertinoButton(
              onPressed: () {
                Navigator.of(context).push(
                  CupertinoPageRoute<void>(
                    builder: (BuildContext context) {
                      return const CupertinoPageScaffold(child: Center(child: Text('Page 3')));
                    },
                  ),
                );
              },
              child: const Text('Push Page 3'),
            ),
          ],
        );
      }

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: homeKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      showCupertinoSheet<void>(
                        context: homeKey.currentContext!,
                        useNestedNavigation: true,
                        pageBuilder: (BuildContext context) {
                          return CupertinoPageScaffold(
                            key: sheetKey,
                            child: sheetScaffoldContent(context),
                          );
                        },
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      await tester.tap(find.text('Push Page 3'));
      await tester.pumpAndSettle();

      expect(find.text('Page 3'), findsOneWidget);

      final TestGesture gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.moveBy(const Offset(0, 350));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsNothing);
      expect(find.text('Page 3'), findsNothing);
    });

    testWidgets('Popping the sheet during drag should not crash', (WidgetTester tester) async {
      final GlobalKey homeKey = GlobalKey();
      final GlobalKey sheetKey = GlobalKey();

      await tester.pumpWidget(dragGestureApp(homeKey, sheetKey));

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      final TestGesture gesture = await tester.createGesture();

      await gesture.down(const Offset(100, 200));

      // Need 2 events to form a valid drag
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(const Offset(100, 300), timeStamp: const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveTo(const Offset(100, 500), timeStamp: const Duration(milliseconds: 200));

      Navigator.of(homeKey.currentContext!).pop();

      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
      expect(find.text('Page 2'), findsNothing);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page 1'), findsOneWidget);
    });

    testWidgets('Sheet should not block nested scroll', (WidgetTester tester) async {
      final GlobalKey homeKey = GlobalKey();

      Widget sheetScaffoldContent(BuildContext context) {
        return ListView(
          children: const <Widget>[
            Text('Top of Scroll'),
            SizedBox(width: double.infinity, height: 100),
            Text('Middle of Scroll'),
            SizedBox(width: double.infinity, height: 100),
          ],
        );
      }

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: homeKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      showCupertinoSheet<void>(
                        context: homeKey.currentContext!,
                        pageBuilder: (BuildContext context) {
                          return CupertinoPageScaffold(child: sheetScaffoldContent(context));
                        },
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Top of Scroll'), findsOneWidget);
      final double startPosition = tester.getTopLeft(find.text('Middle of Scroll')).dy;

      final TestGesture gesture = await tester.createGesture();

      await gesture.down(const Offset(100, 100));

      // Need 2 events to form a valid drag.
      await tester.pump(const Duration(milliseconds: 100));
      await gesture.moveTo(const Offset(100, 80), timeStamp: const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 200));
      await gesture.moveTo(const Offset(100, 50), timeStamp: const Duration(milliseconds: 200));

      await tester.pumpAndSettle();

      final double endPosition = tester.getTopLeft(find.text('Middle of Scroll')).dy;

      // Final position should be higher.
      expect(endPosition, lessThan(startPosition));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('drag dismiss uses route navigator instead of root navigator', (
      WidgetTester tester,
    ) async {
      final GlobalKey homeKey = GlobalKey();
      final GlobalKey nestedNavigatorKey = GlobalKey<NavigatorState>();
      final GlobalKey sheetKey = GlobalKey();
      var wasPopped = false;
      var rootNavigatorPopped = false;

      await tester.pumpWidget(
        CupertinoApp(
          home: PopScope(
            onPopInvokedWithResult: (bool didPop, Object? result) {
              if (didPop) {
                rootNavigatorPopped = true;
              }
            },
            child: CupertinoPageScaffold(
              key: homeKey,
              child: Navigator(
                key: nestedNavigatorKey,
                onGenerateRoute: (RouteSettings settings) {
                  return CupertinoPageRoute<void>(
                    settings: settings,
                    builder: (BuildContext context) {
                      return Center(
                        child: Column(
                          children: <Widget>[
                            const Text('Page 1'),
                            CupertinoButton(
                              onPressed: () {
                                Navigator.push<void>(
                                  context,
                                  CupertinoSheetRoute<void>(
                                    builder: (BuildContext context) {
                                      return PopScope(
                                        onPopInvokedWithResult: (bool didPop, Object? result) {
                                          if (didPop) {
                                            wasPopped = true;
                                          }
                                        },
                                        child: CupertinoPageScaffold(
                                          key: sheetKey,
                                          child: const Center(child: Text('Page 2')),
                                        ),
                                      );
                                    },
                                  ),
                                );
                              },
                              child: const Text('Push Page 2'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);
      expect(wasPopped, false);
      expect(rootNavigatorPopped, false);

      // Start drag gesture and drag down far enough to trigger dismissal
      final TestGesture gesture = await tester.startGesture(const Offset(100, 200));
      await gesture.moveBy(const Offset(0, 350));
      await tester.pump();

      await gesture.up();
      await tester.pumpAndSettle();

      // Verify the sheet was dismissed and the PopScope callback was triggered
      expect(find.text('Page 2'), findsNothing);
      expect(find.text('Page 1'), findsOneWidget);
      // Verify that the nested navigator was used (sheet PopScope triggered)
      // but the root navigator was NOT used (root PopScope not triggered)
      expect(wasPopped, true);
      expect(rootNavigatorPopped, false);
    });

    testWidgets('dragging does not move the sheet when enableDrag is false', (
      WidgetTester tester,
    ) async {
      Widget nonDragGestureApp(GlobalKey homeScaffoldKey, GlobalKey sheetScaffoldKey) {
        return CupertinoApp(
          home: CupertinoPageScaffold(
            key: homeScaffoldKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      showCupertinoSheet<void>(
                        context: homeScaffoldKey.currentContext!,
                        pageBuilder: (BuildContext context) {
                          return CupertinoPageScaffold(
                            key: sheetScaffoldKey,
                            child: const Center(child: Text('Page 2')),
                          );
                        },
                        enableDrag: false,
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      final GlobalKey homeKey = GlobalKey();
      final GlobalKey sheetKey = GlobalKey();

      await tester.pumpWidget(nonDragGestureApp(homeKey, sheetKey));

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      var box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double initialPosition = box.localToGlobal(Offset.zero).dy;

      final TestGesture gesture = await tester.startGesture(const Offset(100, 200));
      // Partial drag down
      await gesture.moveBy(const Offset(0, 200));
      await tester.pump();

      // Release gesture. Sheet should not move.
      box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double middlePosition = box.localToGlobal(Offset.zero).dy;

      expect(middlePosition, equals(initialPosition));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double finalPosition = box.localToGlobal(Offset.zero).dy;

      expect(finalPosition, equals(middlePosition));
      expect(finalPosition, equals(initialPosition));
    });

    // Regression test for https://github.com/flutter/flutter/issues/163572.
    testWidgets('showCupertinoSheet shows snackbar at bottom of screen', (
      WidgetTester tester,
    ) async {
      final scaffoldKey = GlobalKey<ScaffoldMessengerState>();

      void showSheet(BuildContext context) {
        showCupertinoSheet<void>(
          context: context,
          pageBuilder: (BuildContext context) {
            return Scaffold(
              body: Column(
                children: <Widget>[
                  const Text('Cupertino Sheet'),
                  CupertinoButton(
                    onPressed: () {
                      scaffoldKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('SnackBar'), backgroundColor: Colors.red),
                      );
                    },
                    child: const Text('Show SnackBar'),
                  ),
                ],
              ),
            );
          },
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          scaffoldMessengerKey: scaffoldKey,
          home: Scaffold(
            body: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  Builder(
                    builder: (BuildContext context) {
                      return CupertinoButton(
                        onPressed: () {
                          showSheet(context);
                        },
                        child: const Text('Show Cupertino Sheet'),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);

      await tester.tap(find.text('Show Cupertino Sheet'));
      await tester.pumpAndSettle();

      expect(
        tester
            .getTopLeft(
              find.ancestor(of: find.text('Cupertino Sheet'), matching: find.byType(Scaffold)),
            )
            .dy,
        greaterThan(0.0),
      );

      await tester.tap(find.text('Show SnackBar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsAtLeast(1));
      expect(
        tester.getBottomLeft(find.byType(Scaffold).first).dy,
        equals(tester.getBottomLeft(find.byType(SnackBar).first).dy),
      );

      final TestGesture gesture = await tester.startGesture(const Offset(200, 400));
      await tester.pump();
      expect(
        tester.getBottomLeft(find.byType(Scaffold).first).dy,
        equals(tester.getBottomLeft(find.byType(SnackBar).first).dy),
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        tester.getBottomLeft(find.byType(Scaffold).first).dy,
        equals(tester.getBottomLeft(find.byType(SnackBar).first).dy),
      );
    });

    testWidgets('partial upward drag stretches and returns without popping', (
      WidgetTester tester,
    ) async {
      final GlobalKey homeKey = GlobalKey();
      final GlobalKey sheetKey = GlobalKey();

      await tester.pumpWidget(dragGestureApp(homeKey, sheetKey));

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      var box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double initialPosition = box.localToGlobal(Offset.zero).dy;

      final TestGesture gesture = await tester.startGesture(const Offset(100, 400));
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double stretchedPosition = box.localToGlobal(Offset.zero).dy;
      expect(stretchedPosition, lessThan(initialPosition));

      await gesture.up();
      await tester.pumpAndSettle();

      box = tester.renderObject(find.byKey(sheetKey)) as RenderBox;
      final double finalPosition = box.localToGlobal(Offset.zero).dy;
      expect(finalPosition, initialPosition);
    });
  });

  testWidgets('CupertinoSheet causes SystemUiOverlayStyle changes', (WidgetTester tester) async {
    final GlobalKey scaffoldKey = GlobalKey();

    await tester.pumpWidget(
      CupertinoApp(
        home: CupertinoPageScaffold(
          key: scaffoldKey,
          navigationBar: const CupertinoNavigationBar(middle: Text('SystemUiOverlayStyle')),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push<void>(
                      scaffoldKey.currentContext!,
                      CupertinoSheetRoute<void>(
                        builder: (BuildContext context) {
                          return const CupertinoPageScaffold(child: Text('Page 2'));
                        },
                      ),
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(SystemChrome.latestStyle!.statusBarBrightness, Brightness.light);
    expect(SystemChrome.latestStyle!.statusBarIconBrightness, Brightness.dark);

    await tester.tap(find.text('Push Page 2'));
    await tester.pumpAndSettle();

    expect(SystemChrome.latestStyle!.statusBarBrightness, Brightness.dark);
    expect(SystemChrome.latestStyle!.statusBarIconBrightness, Brightness.light);

    // Returning to the previous page reverts the system UI.
    Navigator.of(scaffoldKey.currentContext!).pop();
    await tester.pumpAndSettle();

    expect(SystemChrome.latestStyle!.statusBarBrightness, Brightness.light);
    expect(SystemChrome.latestStyle!.statusBarIconBrightness, Brightness.dark);
  });

  testWidgets(
    'content placed in safe area of showCupertinoSheet is rendered within the safe area bounds',
    (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      Widget sheetScaffoldContent(BuildContext context) {
        return const SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SizedBox(height: 80, width: double.infinity, child: Text('Top container')),
              SizedBox(height: 80, width: double.infinity, child: Text('Bottom container')),
            ],
          ),
        );
      }

      const double bottomPadding = 50;
      await tester.pumpWidget(
        Builder(
          builder: (BuildContext context) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                padding: const EdgeInsets.fromLTRB(0, 20, 0, bottomPadding),
                viewPadding: const EdgeInsets.fromLTRB(0, 20, 0, bottomPadding),
              ),
              child: CupertinoApp(
                home: CupertinoPageScaffold(
                  key: scaffoldKey,
                  child: Center(
                    child: Column(
                      children: <Widget>[
                        const Text('Page 1'),
                        CupertinoButton(
                          onPressed: () {
                            showCupertinoSheet<void>(
                              context: scaffoldKey.currentContext!,
                              pageBuilder: (BuildContext context) {
                                return CupertinoPageScaffold(child: sheetScaffoldContent(context));
                              },
                            );
                          },
                          child: const Text('Push Page 2'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );

      expect(find.text('Page 1'), findsOneWidget);

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      final double pageHeight = tester
          .getRect(
            find.ancestor(
              of: find.text('Top container'),
              matching: find.byType(CupertinoPageScaffold),
            ),
          )
          .bottom;
      expect(
        pageHeight -
            tester
                .getBottomLeft(
                  find
                      .ancestor(of: find.text('Bottom container'), matching: find.byType(SizedBox))
                      .first,
                )
                .dy,
        bottomPadding,
      );
    },
  );

  group('topGap parameter tests', () {
    testWidgets('sheet uses default topGap when not specified', (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: scaffoldKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.push<void>(
                        scaffoldKey.currentContext!,
                        CupertinoSheetRoute<void>(
                          builder: (BuildContext context) {
                            return const CupertinoPageScaffold(child: Text('Page 2'));
                          },
                        ),
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      final double sheetTopOffset = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      // Should use default topGap ratio (8% of screen height = 0.08 * 600.0 = 48.0)
      expect(sheetTopOffset, equals(600.0 * _kTopGapRatio));
    });

    testWidgets('sheet with custom topGap uses custom positioning', (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: scaffoldKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      Navigator.push<void>(
                        scaffoldKey.currentContext!,
                        CupertinoSheetRoute<void>(
                          builder: (BuildContext context) {
                            return const CupertinoPageScaffold(child: Text('Page 2'));
                          },
                          topGap: 0.0,
                        ),
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      final double sheetTopOffset = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      expect(sheetTopOffset, equals(0.0));
    });

    testWidgets('showCupertinoSheet accepts topGap parameter', (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: scaffoldKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      showCupertinoSheet<void>(
                        context: scaffoldKey.currentContext!,
                        topGap: 0.15,
                        builder: (BuildContext context) {
                          return const CupertinoPageScaffold(child: Text('Page 2'));
                        },
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      final double sheetTopOffset = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      expect(sheetTopOffset, equals(600.0 * 0.15));
    });

    testWidgets('custom topGap disables delegated transitions', (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: scaffoldKey,
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push<void>(
                      scaffoldKey.currentContext!,
                      CupertinoSheetRoute<void>(
                        builder: (BuildContext context) {
                          return CupertinoPageScaffold(
                            child: Column(
                              children: <Widget>[
                                const Text('Page 2'),
                                CupertinoButton(
                                  onPressed: () {
                                    Navigator.push<void>(
                                      scaffoldKey.currentContext!,
                                      CupertinoSheetRoute<void>(
                                        builder: (BuildContext context) {
                                          return const CupertinoPageScaffold(child: Text('Page 3'));
                                        },
                                        topGap: 0.1, // Custom topGap should disable transitions
                                      ),
                                    );
                                  },
                                  child: const Text('Push Page 3'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      final double pageTwoYBeforePage3 = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      await tester.tap(find.text('Push Page 3'));
      await tester.pumpAndSettle();

      final double pageTwoYAfterPage3 = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      // Page 2 should remain at the same position because custom topGap disables transitions
      expect(pageTwoYAfterPage3, equals(pageTwoYBeforePage3));

      final double pageThreeY = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 3'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      expect(pageThreeY, equals(600.0 * 0.1));
    });

    testWidgets('default topGap allows delegated transitions', (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      await tester.pumpWidget(
        CupertinoApp(
          home: CupertinoPageScaffold(
            key: scaffoldKey,
            child: Column(
              children: <Widget>[
                const Text('Page 1'),
                CupertinoButton(
                  onPressed: () {
                    Navigator.push<void>(
                      scaffoldKey.currentContext!,
                      CupertinoSheetRoute<void>(
                        builder: (BuildContext context) {
                          return CupertinoPageScaffold(
                            child: Column(
                              children: <Widget>[
                                const Text('Page 2'),
                                CupertinoButton(
                                  onPressed: () {
                                    Navigator.push<void>(
                                      scaffoldKey.currentContext!,
                                      CupertinoSheetRoute<void>(
                                        builder: (BuildContext context) {
                                          return const CupertinoPageScaffold(child: Text('Page 3'));
                                        },
                                        // No topGap specified - should use default and allow transitions
                                      ),
                                    );
                                  },
                                  child: const Text('Push Page 3'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Push Page 2'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      final double pageTwoYBeforePage3 = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      await tester.tap(find.text('Push Page 3'));
      await tester.pumpAndSettle();

      final double pageTwoYAfterPage3 = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      // Page 2 should move upward because default topGap allows delegated transitions
      expect(pageTwoYAfterPage3, lessThan(pageTwoYBeforePage3));
    });

    testWidgets('topGap affects drag gesture calculations', (WidgetTester tester) async {
      final GlobalKey scaffoldKey = GlobalKey();

      Widget dragGestureAppWithTopGap(double topGap) {
        return CupertinoApp(
          home: CupertinoPageScaffold(
            key: scaffoldKey,
            child: Center(
              child: Column(
                children: <Widget>[
                  const Text('Page 1'),
                  CupertinoButton(
                    onPressed: () {
                      showCupertinoSheet<void>(
                        context: scaffoldKey.currentContext!,
                        topGap: topGap,
                        pageBuilder: (BuildContext context) {
                          return const CupertinoPageScaffold(child: Center(child: Text('Page 2')));
                        },
                      );
                    },
                    child: const Text('Push Page 2'),
                  ),
                ],
              ),
            ),
          ),
        );
      }

      // Test with custom topGap of 0.3
      await tester.pumpWidget(dragGestureAppWithTopGap(0.3));

      await tester.tap(find.text('Push Page 2'));
      await tester.pumpAndSettle();

      expect(find.text('Page 2'), findsOneWidget);

      final double sheetTopOffset = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      expect(sheetTopOffset, equals(600.0 * 0.3));

      // Test that drag still works with custom topGap
      final TestGesture gesture = await tester.startGesture(const Offset(100, 300));
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      final double draggedPosition = tester
          .getTopLeft(
            find.ancestor(of: find.text('Page 2'), matching: find.byType(CupertinoPageScaffold)),
          )
          .dy;

      // Sheet should move down when dragged
      expect(draggedPosition, greaterThan(sheetTopOffset));

      await gesture.up();
      await tester.pumpAndSettle();
    });
  });
}
