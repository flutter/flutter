// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/gestures.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgets('Tapping on a modal BottomSheet should not dismiss it', (WidgetTester tester) async {
    BuildContext savedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            savedContext = context;
            return Container();
          },
        ),
      ),
    );

    await tester.pump();
    expect(find.text('BottomSheet'), findsNothing);

    bool showBottomSheetThenCalled = false;
    showModalBottomSheet<void>(
      context: savedContext,
      builder: (BuildContext context) => const Text('BottomSheet'),
    ).then<void>((void value) {
      showBottomSheetThenCalled = true;
    });

    await tester.pumpAndSettle();
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);

    // Tap on the bottom sheet itself, it should not be dismissed
    await tester.tap(find.text('BottomSheet'));
    await tester.pumpAndSettle();
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);
  });

  testWidgets('Tapping outside a modal BottomSheet should dismiss it by default', (WidgetTester tester) async {
    BuildContext savedContext;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          savedContext = context;
          return Container();
        },
      ),
    ));

    await tester.pump();
    expect(find.text('BottomSheet'), findsNothing);

    bool showBottomSheetThenCalled = false;
    showModalBottomSheet<void>(
      context: savedContext,
      builder: (BuildContext context) => const Text('BottomSheet'),
    ).then<void>((void value) {
      showBottomSheetThenCalled = true;
    });

    await tester.pumpAndSettle();
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);

    // Tap above the bottom sheet to dismiss it.
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pumpAndSettle(); // Bottom sheet dismiss animation.
    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsNothing);
  });

  testWidgets('Tapping outside a modal BottomSheet should dismiss it when isDismissible=true', (WidgetTester tester) async {
    BuildContext savedContext;

    await tester.pumpWidget(MaterialApp(
      home: Builder(
        builder: (BuildContext context) {
          savedContext = context;
          return Container();
        },
      ),
    ));

    await tester.pump();
    expect(find.text('BottomSheet'), findsNothing);

    bool showBottomSheetThenCalled = false;
    showModalBottomSheet<void>(
      context: savedContext,
      builder: (BuildContext context) => const Text('BottomSheet'),
      isDismissible: true,
    ).then<void>((void value) {
      showBottomSheetThenCalled = true;
    });

    await tester.pumpAndSettle();
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);

    // Tap above the bottom sheet to dismiss it.
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pumpAndSettle(); // Bottom sheet dismiss animation.
    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsNothing);
  });

  testWidgets('Tapping outside a modal BottomSheet should not dismiss it when isDismissible=false', (WidgetTester tester) async {
    BuildContext savedContext;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (BuildContext context) {
            savedContext = context;
            return Container();
          },
        ),
      ),
    );

    await tester.pump();
    expect(find.text('BottomSheet'), findsNothing);

    bool showBottomSheetThenCalled = false;
    showModalBottomSheet<void>(
      context: savedContext,
      builder: (BuildContext context) => const Text('BottomSheet'),
      isDismissible: false,
    ).then<void>((void value) {
      showBottomSheetThenCalled = true;
    });

    await tester.pumpAndSettle();
    expect(find.text('BottomSheet'), findsOneWidget);
    expect(showBottomSheetThenCalled, isFalse);

    // Tap above the bottom sheet, attempting to dismiss it.
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pumpAndSettle(); // Bottom sheet should not dismiss.
    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsOneWidget);
  });

  testWidgets('Verify that a downwards fling dismisses a persistent BottomSheet', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    bool showBottomSheetThenCalled = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsNothing);

    scaffoldKey.currentState.showBottomSheet<void>((BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(40.0),
        child: const Text('BottomSheet'),
      );
    }).closed.whenComplete(() {
      showBottomSheetThenCalled = true;
    });

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsNothing);

    await tester.pump(); // bottom sheet show animation starts

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(showBottomSheetThenCalled, isFalse);
    expect(find.text('BottomSheet'), findsOneWidget);

    // The fling below must be such that the velocity estimation examines an
    // offset greater than the kTouchSlop. Too slow or too short a distance, and
    // it won't trigger. Also, it musn't be so much that it drags the bottom
    // sheet off the screen, or we won't see it after we pump!
    await tester.fling(find.text('BottomSheet'), const Offset(0.0, 50.0), 2000.0);
    await tester.pump(); // drain the microtask queue (Future completion callback)

    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.pump(); // bottom sheet dismiss animation starts

    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(showBottomSheetThenCalled, isTrue);
    expect(find.text('BottomSheet'), findsNothing);
  });

  testWidgets('Verify that dragging past the bottom dismisses a persistent BottomSheet', (WidgetTester tester) async {
    // This is a regression test for https://github.com/flutter/flutter/issues/5528
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    scaffoldKey.currentState.showBottomSheet<void>((BuildContext context) {
      return Container(
        margin: const EdgeInsets.all(40.0),
        child: const Text('BottomSheet'),
      );
    });

    await tester.pump(); // bottom sheet show animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done
    expect(find.text('BottomSheet'), findsOneWidget);

    await tester.fling(find.text('BottomSheet'), const Offset(0.0, 400.0), 1000.0);
    await tester.pump(); // drain the microtask queue (Future completion callback)
    await tester.pump(); // bottom sheet dismiss animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(find.text('BottomSheet'), findsNothing);
  });

  testWidgets('modal BottomSheet has no top MediaQuery', (WidgetTester tester) async {
    BuildContext outerContext;
    BuildContext innerContext;

    await tester.pumpWidget(Localizations(
      locale: const Locale('en', 'US'),
      delegates: const <LocalizationsDelegate<dynamic>>[
        DefaultWidgetsLocalizations.delegate,
        DefaultMaterialLocalizations.delegate,
      ],
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: MediaQuery(
          data: const MediaQueryData(
            padding: EdgeInsets.all(50.0),
            size: Size(400.0, 600.0),
          ),
          child: Navigator(
            onGenerateRoute: (_) {
              return PageRouteBuilder<void>(
                pageBuilder: (BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
                  outerContext = context;
                  return Container();
                },
              );
            },
          ),
        ),
      ),
    ));

    showModalBottomSheet<void>(
      context: outerContext,
      builder: (BuildContext context) {
        innerContext = context;
        return Container();
      },
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(
      MediaQuery.of(outerContext).padding,
      const EdgeInsets.all(50.0),
    );
    expect(
      MediaQuery.of(innerContext).padding,
      const EdgeInsets.only(left: 50.0, right: 50.0, bottom: 50.0),
    );
  });

  testWidgets('modal BottomSheet has semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));


    showModalBottomSheet<void>(context: scaffoldKey.currentContext, builder: (BuildContext context) {
      return Container(
        child: const Text('BottomSheet'),
      );
    });

    await tester.pump(); // bottom sheet show animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'Dialog',
              textDirection: TextDirection.ltr,
              flags: <SemanticsFlag>[
                SemanticsFlag.scopesRoute,
                SemanticsFlag.namesRoute,
              ],
              children: <TestSemantics>[
                TestSemantics(
                  label: 'BottomSheet',
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true, ignoreId: true));
    semantics.dispose();
  });

  testWidgets('Verify that visual properties are passed through', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    const Color color = Colors.pink;
    const double elevation = 9.0;
    final ShapeBorder shape = BeveledRectangleBorder(borderRadius: BorderRadius.circular(12));
    const Clip clipBehavior = Clip.antiAlias;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));

    showModalBottomSheet<void>(
      context: scaffoldKey.currentContext,
      backgroundColor: color,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      builder: (BuildContext context) {
        return Container(
          child: const Text('BottomSheet'),
        );
      },
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final BottomSheet bottomSheet = tester.widget(find.byType(BottomSheet));
    expect(bottomSheet.backgroundColor, color);
    expect(bottomSheet.elevation, elevation);
    expect(bottomSheet.shape, shape);
    expect(bottomSheet.clipBehavior, clipBehavior);
  });

  testWidgets('modal BottomSheet with scrollController has semantics', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        key: scaffoldKey,
        body: const Center(child: Text('body')),
      ),
    ));


    showModalBottomSheet<void>(
      context: scaffoldKey.currentContext,
      builder: (BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (_, ScrollController controller) {
            return SingleChildScrollView(
              controller: controller,
              child: Container(
                child: const Text('BottomSheet'),
              ),
            );
          },
        );
      },
    );

    await tester.pump(); // bottom sheet show animation starts
    await tester.pump(const Duration(seconds: 1)); // animation done

    expect(semantics, hasSemantics(TestSemantics.root(
      children: <TestSemantics>[
        TestSemantics.rootChild(
          children: <TestSemantics>[
            TestSemantics(
              label: 'Dialog',
              textDirection: TextDirection.ltr,
              flags: <SemanticsFlag>[
                SemanticsFlag.scopesRoute,
                SemanticsFlag.namesRoute,
              ],
              children: <TestSemantics>[
                TestSemantics(
                  flags: <SemanticsFlag>[SemanticsFlag.hasImplicitScrolling],
                  actions: <SemanticsAction>[SemanticsAction.scrollDown, SemanticsAction.scrollUp],
                  children: <TestSemantics>[
                    TestSemantics(
                      label: 'BottomSheet',
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ), ignoreTransform: true, ignoreRect: true, ignoreId: true));
    semantics.dispose();
  });

  testWidgets('showModalBottomSheet does not use root Navigator by default', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Navigator(onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(builder: (_) {
          return const _TestPage();
        })),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('Item 1'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              title: Text('Item 2'),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Show bottom sheet'));
    await tester.pumpAndSettle();

    // Bottom sheet is displayed in correct position within the inner navigator
    // and above the BottomNavigationBar.
    expect(tester.getBottomLeft(find.byType(BottomSheet)).dy, 544.0);
  });

  testWidgets('showModalBottomSheet uses root Navigator when specified', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Navigator(onGenerateRoute: (RouteSettings settings) => MaterialPageRoute<void>(builder: (_) {
          return const _TestPage(useRootNavigator: true);
        })),
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.ac_unit),
              title: Text('Item 1'),
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.style),
              title: Text('Item 2'),
            ),
          ],
        ),
      ),
    ));

    await tester.tap(find.text('Show bottom sheet'));
    await tester.pumpAndSettle();

    // Bottom sheet is displayed in correct position above all content including
    // the BottomNavigationBar.
    expect(tester.getBottomLeft(find.byType(BottomSheet)).dy, 600.0);
  });
}

class _TestPage extends StatelessWidget {
  const _TestPage({Key key, this.useRootNavigator}) : super(key: key);

  final bool useRootNavigator;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FlatButton(
        child: const Text('Show bottom sheet'),
        onPressed: () {
          if (useRootNavigator != null) {
            showModalBottomSheet<void>(
              useRootNavigator: useRootNavigator,
              context: context,
              builder: (_) => const Text('Modal bottom sheet'),
            );
          } else {
            showModalBottomSheet<void>(
              context: context,
              builder: (_) => const Text('Modal bottom sheet'),
            );
          }
        },
      ),
    );
  }
}
