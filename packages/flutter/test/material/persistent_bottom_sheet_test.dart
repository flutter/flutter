// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Pumps and ensures that the BottomSheet animates non-linearly.
  Future<void> checkNonLinearAnimation(WidgetTester tester) async {
    final Offset firstPosition = tester.getCenter(find.text('One'));
    await tester.pump(const Duration(milliseconds: 30));
    final Offset secondPosition = tester.getCenter(find.text('One'));
    await tester.pump(const Duration(milliseconds: 30));
    final Offset thirdPosition = tester.getCenter(find.text('One'));

    final double dyDelta1 = secondPosition.dy - firstPosition.dy;
    final double dyDelta2 = thirdPosition.dy - secondPosition.dy;

    // If the animation were linear, these two values would be the same.
    expect(dyDelta1, isNot(moreOrLessEquals(dyDelta2, epsilon: 0.1)));
  }

  testWidgets('Persistent draggableScrollableSheet localHistoryEntries test', (
    WidgetTester tester,
  ) async {
    // Regression test for https://github.com/flutter/flutter/issues/110123
    Widget buildFrame(Widget? bottomSheet) {
      return MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('body')),
          bottomSheet: bottomSheet,
          floatingActionButton: const FloatingActionButton(onPressed: null, child: Text('fab')),
        ),
      );
    }

    final Widget draggableScrollableSheet = DraggableScrollableSheet(
      expand: false,
      snap: true,
      initialChildSize: 0.3,
      minChildSize: 0.3,
      builder: (_, ScrollController controller) {
        return ListView.builder(
          itemExtent: 50.0,
          itemCount: 50,
          itemBuilder: (_, int index) => Text('Item $index'),
          controller: controller,
        );
      },
    );

    await tester.pumpWidget(buildFrame(draggableScrollableSheet));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton).hitTestable(), findsNothing);

    await tester.drag(find.text('Item 2'), const Offset(0, -200.0));
    await tester.pumpAndSettle();
    // We've started to drag up, we should have a back button now for a11y
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);

    await tester.fling(find.text('Item 2'), const Offset(0, 200.0), 2000.0);
    await tester.pumpAndSettle();
    // BackButton should be hidden
    expect(find.byType(BackButton).hitTestable(), findsNothing);

    // Show the back button again
    await tester.drag(find.text('Item 2'), const Offset(0, -200.0));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);

    // Remove the draggableScrollableSheet should hide the back button
    await tester.pumpWidget(buildFrame(null));
    expect(find.byType(BackButton).hitTestable(), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/83668
  testWidgets('Scaffold.bottomSheet update test', (WidgetTester tester) async {
    Widget buildFrame(Widget? bottomSheet) {
      return MaterialApp(
        home: Scaffold(body: const Placeholder(), bottomSheet: bottomSheet),
      );
    }

    await tester.pumpWidget(buildFrame(const Text('I love Flutter!')));
    await tester.pumpWidget(buildFrame(null));

    // The disappearing animation has not yet been completed.
    await tester.pumpWidget(buildFrame(const Text('I love Flutter!')));
  });

  testWidgets(
    'Verify that a BottomSheet can be rebuilt with ScaffoldFeatureController.setState()',
    (WidgetTester tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            body: const Center(child: Text('body')),
          ),
        ),
      );

      final PersistentBottomSheetController bottomSheet = scaffoldKey.currentState!.showBottomSheet(
        (_) {
          return Builder(
            builder: (BuildContext context) {
              buildCount += 1;
              return Container(height: 200.0);
            },
          );
        },
      );

      await tester.pump();
      expect(buildCount, equals(1));
      bottomSheet.setState!(() {});
      await tester.pump();
      expect(buildCount, equals(2));
    },
  );

  testWidgets('Verify that a persistent BottomSheet cannot be dismissed', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const Center(child: Text('body')),
          bottomSheet: DraggableScrollableSheet(
            expand: false,
            builder: (_, ScrollController controller) {
              return ListView(
                controller: controller,
                shrinkWrap: true,
                children: const <Widget>[
                  SizedBox(height: 100.0, child: Text('One')),
                  SizedBox(height: 100.0, child: Text('Two')),
                  SizedBox(height: 100.0, child: Text('Three')),
                ],
              );
            },
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
  });

  testWidgets('Verify that a scrollable BottomSheet can be dismissed', (WidgetTester tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('body')),
        ),
      ),
    );

    scaffoldKey.currentState!.showBottomSheet((BuildContext context) {
      return ListView(
        shrinkWrap: true,
        primary: false,
        children: const <Widget>[
          SizedBox(height: 100.0, child: Text('One')),
          SizedBox(height: 100.0, child: Text('Two')),
          SizedBox(height: 100.0, child: Text('Three')),
        ],
      );
    });

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets(
    'Verify DraggableScrollableSheet.shouldCloseOnMinExtent == false prevents dismissal',
    (WidgetTester tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            key: scaffoldKey,
            body: const Center(child: Text('body')),
          ),
        ),
      );

      scaffoldKey.currentState!.showBottomSheet((BuildContext context) {
        return DraggableScrollableSheet(
          expand: false,
          shouldCloseOnMinExtent: false,
          builder: (_, ScrollController controller) {
            return ListView(
              controller: controller,
              shrinkWrap: true,
              children: const <Widget>[
                SizedBox(height: 100.0, child: Text('One')),
                SizedBox(height: 100.0, child: Text('Two')),
                SizedBox(height: 100.0, child: Text('Three')),
              ],
            );
          },
        );
      });

      await tester.pumpAndSettle();

      expect(find.text('Two'), findsOneWidget);

      await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
      await tester.pumpAndSettle();

      expect(find.text('Two'), findsOneWidget);
    },
  );

  testWidgets('Verify that a BottomSheet animates non-linearly', (WidgetTester tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('body')),
        ),
      ),
    );

    scaffoldKey.currentState!.showBottomSheet((BuildContext context) {
      return ListView(
        shrinkWrap: true,
        primary: false,
        children: const <Widget>[
          SizedBox(height: 100.0, child: Text('One')),
          SizedBox(height: 100.0, child: Text('Two')),
          SizedBox(height: 100.0, child: Text('Three')),
        ],
      );
    });
    await tester.pump();
    await checkNonLinearAnimation(tester);

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 200.0));
    await checkNonLinearAnimation(tester);
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets('Verify that a scrollControlled BottomSheet can be dismissed', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('body')),
        ),
      ),
    );

    scaffoldKey.currentState!.showBottomSheet((BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (_, ScrollController controller) {
          return ListView(
            shrinkWrap: true,
            controller: controller,
            children: const <Widget>[
              SizedBox(height: 100.0, child: Text('One')),
              SizedBox(height: 100.0, child: Text('Two')),
              SizedBox(height: 100.0, child: Text('Three')),
            ],
          );
        },
      );
    });

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, 400.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsNothing);
  });

  testWidgets('Verify that a persistent BottomSheet can fling up and hide the fab', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('body')),
          bottomSheet: DraggableScrollableSheet(
            expand: false,
            builder: (_, ScrollController controller) {
              return ListView.builder(
                itemExtent: 50.0,
                itemCount: 50,
                itemBuilder: (_, int index) => Text('Item $index'),
                controller: controller,
              );
            },
          ),
          floatingActionButton: const FloatingActionButton(onPressed: null, child: Text('fab')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);
    expect(find.byType(BackButton).hitTestable(), findsNothing);

    await tester.drag(find.text('Item 2'), const Offset(0, -20.0));
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);

    await tester.fling(find.text('Item 2'), const Offset(0.0, -600.0), 2000.0);
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 22'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsNothing);
  });

  testWidgets('Verify that a back button resets a persistent BottomSheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          appBar: AppBar(),
          body: const Center(child: Text('body')),
          bottomSheet: DraggableScrollableSheet(
            expand: false,
            builder: (_, ScrollController controller) {
              return ListView.builder(
                itemExtent: 50.0,
                itemCount: 50,
                itemBuilder: (_, int index) => Text('Item $index'),
                controller: controller,
              );
            },
          ),
          floatingActionButton: const FloatingActionButton(onPressed: null, child: Text('fab')),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    expect(find.byType(BackButton).hitTestable(), findsNothing);

    await tester.drag(find.text('Item 2'), const Offset(0, -20.0));
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
    // We've started to drag up, we should have a back button now for a11y
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton).hitTestable(), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);

    await tester.fling(find.text('Item 2'), const Offset(0.0, -600.0), 2000.0);
    await tester.pumpAndSettle();

    expect(find.text('Item 2'), findsNothing);
    expect(find.text('Item 22'), findsOneWidget);
    expect(find.byType(BackButton).hitTestable(), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(find.byType(BackButton).hitTestable(), findsNothing);
    expect(find.text('Item 2'), findsOneWidget);
    expect(find.text('Item 22'), findsNothing);
  });

  testWidgets('Verify that a scrollable BottomSheet hides the fab when scrolled up', (
    WidgetTester tester,
  ) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('body')),
          floatingActionButton: const FloatingActionButton(onPressed: null, child: Text('fab')),
        ),
      ),
    );

    scaffoldKey.currentState!.showBottomSheet((BuildContext context) {
      return DraggableScrollableSheet(
        expand: false,
        builder: (_, ScrollController controller) {
          return ListView(
            controller: controller,
            shrinkWrap: true,
            children: const <Widget>[
              SizedBox(height: 100.0, child: Text('One')),
              SizedBox(height: 100.0, child: Text('Two')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
              SizedBox(height: 100.0, child: Text('Three')),
            ],
          );
        },
      );
    });

    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsOneWidget);

    await tester.drag(find.text('Two'), const Offset(0.0, -600.0));
    await tester.pumpAndSettle();

    expect(find.text('Two'), findsOneWidget);
    expect(find.byType(FloatingActionButton), findsOneWidget);
    expect(find.byType(FloatingActionButton).hitTestable(), findsNothing);
  });

  testWidgets('showBottomSheet()', (WidgetTester tester) async {
    final GlobalKey key = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: Placeholder(key: key)),
      ),
    );

    var buildCount = 0;
    showBottomSheet(
      context: key.currentContext!,
      builder: (BuildContext context) {
        return Builder(
          builder: (BuildContext context) {
            buildCount += 1;
            return Container(height: 200.0);
          },
        );
      },
    );
    await tester.pump();
    expect(buildCount, equals(1));
  });

  testWidgets('Scaffold removes top MediaQuery padding', (WidgetTester tester) async {
    late BuildContext scaffoldContext;
    late BuildContext bottomSheetContext;

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(padding: EdgeInsets.all(50.0)),
          child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: Builder(
              builder: (BuildContext context) {
                scaffoldContext = context;
                return Container();
              },
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    showBottomSheet(
      context: scaffoldContext,
      builder: (BuildContext context) {
        bottomSheetContext = context;
        return Container();
      },
    );

    await tester.pump();

    expect(
      MediaQuery.of(bottomSheetContext).padding,
      const EdgeInsets.only(bottom: 50.0, left: 50.0, right: 50.0),
    );
  });

  testWidgets('Scaffold.bottomSheet', (WidgetTester tester) async {
    final Key bottomSheetKey = UniqueKey();

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          body: const Placeholder(),
          bottomSheet: Container(
            key: bottomSheetKey,
            alignment: Alignment.center,
            height: 200.0,
            child: Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  child: const Text('showModalBottomSheet'),
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      builder: (BuildContext context) => const Text('modal bottom sheet'),
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    expect(find.text('showModalBottomSheet'), findsOneWidget);
    expect(tester.getSize(find.byKey(bottomSheetKey)), const Size(800.0, 200.0));
    expect(tester.getTopLeft(find.byKey(bottomSheetKey)), const Offset(0.0, 400.0));

    // Show the modal bottomSheet
    await tester.tap(find.text('showModalBottomSheet'));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsOneWidget);

    // Dismiss the modal bottomSheet by tapping above the sheet
    await tester.tapAt(const Offset(20.0, 20.0));
    await tester.pumpAndSettle();
    expect(find.text('modal bottom sheet'), findsNothing);
    expect(find.text('showModalBottomSheet'), findsOneWidget);

    // Remove the persistent bottomSheet
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: Placeholder())));
    await tester.pumpAndSettle();
    expect(find.text('showModalBottomSheet'), findsNothing);
    expect(find.byKey(bottomSheetKey), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/71435
  testWidgets('Scaffold.bottomSheet should be updated without creating a new RO'
      ' when the new widget has the same key and type.', (WidgetTester tester) async {
    Widget buildFrame(String text) {
      return MaterialApp(
        home: Scaffold(body: const Placeholder(), bottomSheet: Text(text)),
      );
    }

    await tester.pumpWidget(buildFrame('I love Flutter!'));
    final RenderParagraph renderBeforeUpdate = tester.renderObject(find.text('I love Flutter!'));

    await tester.pumpWidget(buildFrame('Flutter is the best!'));
    await tester.pumpAndSettle();
    final RenderParagraph renderAfterUpdate = tester.renderObject(
      find.text('Flutter is the best!'),
    );

    expect(renderBeforeUpdate, renderAfterUpdate);
  });

  testWidgets('Verify that visual properties are passed through', (WidgetTester tester) async {
    final scaffoldKey = GlobalKey<ScaffoldState>();
    const Color color = Colors.pink;
    const elevation = 9.0;
    const ShapeBorder shape = BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    );
    const Clip clipBehavior = Clip.antiAlias;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('body')),
        ),
      ),
    );

    scaffoldKey.currentState!.showBottomSheet(
      (BuildContext context) {
        return ListView(
          shrinkWrap: true,
          primary: false,
          children: const <Widget>[
            SizedBox(height: 100.0, child: Text('One')),
            SizedBox(height: 100.0, child: Text('Two')),
            SizedBox(height: 100.0, child: Text('Three')),
          ],
        );
      },
      backgroundColor: color,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
    );

    await tester.pumpAndSettle();

    final BottomSheet bottomSheet = tester.widget(find.byType(BottomSheet));
    expect(bottomSheet.backgroundColor, color);
    expect(bottomSheet.elevation, elevation);
    expect(bottomSheet.shape, shape);
    expect(bottomSheet.clipBehavior, clipBehavior);
  });

  testWidgets('PersistentBottomSheetController.close dismisses the bottom sheet', (
    WidgetTester tester,
  ) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          body: const Center(child: Text('body')),
        ),
      ),
    );

    final PersistentBottomSheetController bottomSheet = scaffoldKey.currentState!.showBottomSheet((
      _,
    ) {
      return Builder(
        builder: (BuildContext context) {
          return Container(height: 200.0);
        },
      );
    });

    await tester.pump();
    expect(find.byType(BottomSheet), findsOneWidget);

    bottomSheet.close();
    await tester.pump();
    expect(find.byType(BottomSheet), findsNothing);
  });

  // Regression test for https://github.com/flutter/flutter/issues/6451
  testWidgets(
    'Check back gesture with a persistent bottom sheet showing',
    (WidgetTester tester) async {
      final GlobalKey<ScaffoldState> containerKey1 = GlobalKey();
      final GlobalKey<PersistentBottomSheetTestState> containerKey2 = GlobalKey();
      final routes = <String, WidgetBuilder>{
        '/': (_) => Scaffold(key: containerKey1, body: const Text('Home')),
        '/sheet': (_) => PersistentBottomSheetTest(key: containerKey2),
      };

      await tester.pumpWidget(MaterialApp(routes: routes));

      Navigator.pushNamed(containerKey1.currentContext!, '/sheet');

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsNothing);
      expect(find.text('Sheet'), isOnstage);

      // Drag from left edge to invoke the gesture. We should go back.
      TestGesture gesture = await tester.startGesture(const Offset(5.0, 100.0));
      await gesture.moveBy(const Offset(500.0, 0.0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      Navigator.pushNamed(containerKey1.currentContext!, '/sheet');

      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsNothing);
      expect(find.text('Sheet'), isOnstage);

      // Show the bottom sheet.
      final PersistentBottomSheetTestState sheet = containerKey2.currentState!;
      sheet.showBottomSheet();

      await tester.pump(const Duration(seconds: 1));

      // Drag from left edge to invoke the gesture. Nothing should happen.
      gesture = await tester.startGesture(const Offset(5.0, 100.0));
      await gesture.moveBy(const Offset(500.0, 0.0));
      await gesture.up();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home'), findsNothing);
      expect(find.text('Sheet'), isOnstage);

      // Sheet did not call setState (since the gesture did nothing).
      expect(sheet.setStateCalled, isFalse);
    },
    variant: const TargetPlatformVariant(<TargetPlatform>{
      TargetPlatform.iOS,
      TargetPlatform.macOS,
    }),
  );

  group('keyboard inset', () {
    // The Scaffold's persistent bottom sheet is _StandardBottomSheet ->
    // BottomSheet -> Material. This finds that Material.
    Finder sheetMaterial() =>
        find.descendant(of: find.byType(BottomSheet), matching: find.byType(Material)).first;

    Widget buildApp({
      required double keyboardHeight,
      bool resizeToAvoidBottomInset = true,
      Widget? bottomNavigationBar,
      Widget? floatingActionButton,
      FloatingActionButtonLocation? floatingActionButtonLocation,
      Widget? bottomSheet,
    }) {
      return MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
          child: Scaffold(
            resizeToAvoidBottomInset: resizeToAvoidBottomInset,
            bottomNavigationBar: bottomNavigationBar,
            floatingActionButton: floatingActionButton,
            floatingActionButtonLocation: floatingActionButtonLocation,
            bottomSheet:
                bottomSheet ??
                const SizedBox(
                  key: Key('content'),
                  width: double.infinity,
                  height: 100.0,
                  child: Text('sheet'),
                ),
          ),
        ),
      );
    }

    testWidgets('sheet Material extends behind the keyboard, content stays above', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(buildApp(keyboardHeight: 0.0));
      expect(tester.getRect(find.byKey(const Key('content'))).top, 500);
      expect(tester.getRect(find.byKey(const Key('content'))).bottom, 600);
      expect(tester.getRect(sheetMaterial()).top, 500);
      expect(tester.getRect(sheetMaterial()).bottom, 600);

      await tester.pumpWidget(buildApp(keyboardHeight: 200.0));
      // Content avoids the keyboard exactly as before.
      expect(tester.getRect(find.byKey(const Key('content'))).top, 300);
      expect(tester.getRect(find.byKey(const Key('content'))).bottom, 400);
      // The sheet's own Material now continues to the bottom of the screen.
      expect(tester.getRect(sheetMaterial()).top, 300);
      expect(tester.getRect(sheetMaterial()).bottom, 600);
    });

    testWidgets('resizeToAvoidBottomInset: false is unchanged', (WidgetTester tester) async {
      await tester.pumpWidget(buildApp(keyboardHeight: 200.0, resizeToAvoidBottomInset: false));
      expect(tester.getRect(find.byKey(const Key('content'))).top, 500);
      expect(tester.getRect(find.byKey(const Key('content'))).bottom, 600);
      expect(tester.getRect(sheetMaterial()).top, 500);
      expect(tester.getRect(sheetMaterial()).bottom, 600);
    });

    testWidgets('sheet Material stops above a bottomNavigationBar', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildApp(keyboardHeight: 200.0, bottomNavigationBar: const SizedBox(height: 50.0)),
      );
      expect(tester.getRect(find.byKey(const Key('content'))).top, 300);
      expect(tester.getRect(find.byKey(const Key('content'))).bottom, 400);
      // Extends down to the top of the bottom navigation bar, not past it.
      expect(tester.getRect(sheetMaterial()).top, 300);
      expect(tester.getRect(sheetMaterial()).bottom, 550);
    });

    testWidgets('docked FAB still straddles the top edge of the sheet content', (
      WidgetTester tester,
    ) async {
      Future<double> fabCenterY() async => tester.getCenter(find.byType(FloatingActionButton)).dy;

      await tester.pumpWidget(
        buildApp(
          keyboardHeight: 0.0,
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      );
      expect(await fabCenterY(), 500.0);

      await tester.pumpWidget(
        buildApp(
          keyboardHeight: 200.0,
          floatingActionButton: FloatingActionButton(
            onPressed: () {},
            child: const Icon(Icons.add),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        ),
      );
      await tester.pumpAndSettle();
      // Top of the content (300), not the top of the extended Material.
      expect(await fabCenterY(), 300.0);
    });

    testWidgets('keyboard appearing preserves the sheet content state and focus', (
      WidgetTester tester,
    ) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      final Widget sheet = SizedBox(height: 100.0, child: TextField(focusNode: focusNode));
      await tester.pumpWidget(buildApp(keyboardHeight: 0.0, bottomSheet: sheet));
      focusNode.requestFocus();
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      final State before = tester.state(find.byType(EditableText));

      await tester.pumpWidget(buildApp(keyboardHeight: 200.0, bottomSheet: sheet));
      await tester.pump();
      expect(focusNode.hasFocus, isTrue);
      expect(tester.state(find.byType(EditableText)), same(before));
    });

    testWidgets('showBottomSheet sheet can still be flung closed with the keyboard up', (
      WidgetTester tester,
    ) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 200.0)),
            child: Scaffold(key: scaffoldKey, body: const SizedBox.expand()),
          ),
        ),
      );
      scaffoldKey.currentState!.showBottomSheet(
        (BuildContext context) => const SizedBox(height: 100.0, child: Text('sheet')),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(find.text('sheet')).bottom, 400.0);
      expect(tester.getRect(sheetMaterial()).bottom, 600.0);

      await tester.fling(find.text('sheet'), const Offset(0.0, 300.0), 2000.0);
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
    });

    testWidgets('showBottomSheet drag-to-close threshold is measured against the content, '
        'not the Material behind the keyboard', (WidgetTester tester) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 200.0)),
            child: Scaffold(key: scaffoldKey, body: const SizedBox.expand()),
          ),
        ),
      );
      scaffoldKey.currentState!.showBottomSheet(
        (BuildContext context) => const SizedBox(height: 200.0, child: Text('sheet')),
      );
      await tester.pumpAndSettle();
      // Content is 200 tall; the Material behind it is 400 tall.
      expect(tester.getRect(find.text('sheet')).top, 200.0);
      expect(tester.getRect(sheetMaterial()).height, 400.0);

      // Less than half of the content height: springs back open.
      await tester.drag(find.text('sheet'), const Offset(0.0, 60.0));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsOneWidget);
      expect(tester.getRect(find.text('sheet')).top, 200.0);

      // More than half of the content height (but less than half of the
      // Material's height): closes, exactly as it does without a keyboard.
      await tester.drag(find.text('sheet'), const Offset(0.0, 150.0));
      await tester.pumpAndSettle();
      expect(find.text('sheet'), findsNothing);
    });

    testWidgets('constraints.maxHeight bounds the content, not the Material behind the keyboard', (
      WidgetTester tester,
    ) async {
      final scaffoldKey = GlobalKey<ScaffoldState>();
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(viewInsets: EdgeInsets.only(bottom: 200.0)),
            child: Scaffold(key: scaffoldKey, body: const SizedBox.expand()),
          ),
        ),
      );
      scaffoldKey.currentState!.showBottomSheet(
        (BuildContext context) => const SizedBox(height: 400.0, child: Text('sheet')),
        constraints: const BoxConstraints(maxHeight: 250.0),
      );
      await tester.pumpAndSettle();
      // The content gets the full 250 it is allowed, above the keyboard.
      expect(tester.getRect(find.text('sheet')).top, 150.0);
      expect(tester.getRect(find.text('sheet')).bottom, 400.0);
      // The Material is 250 + 200.
      expect(tester.getRect(sheetMaterial()).top, 150.0);
      expect(tester.getRect(sheetMaterial()).bottom, 600.0);
    });

    testWidgets('taps in the Material behind the keyboard do not reach the content', (
      WidgetTester tester,
    ) async {
      var tapCount = 0;
      await tester.pumpWidget(
        buildApp(
          keyboardHeight: 200.0,
          bottomSheet: SizedBox(
            height: 100.0,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => tapCount += 1,
              child: const Text('sheet'),
            ),
          ),
        ),
      );
      expect(tester.getRect(find.text('sheet')).bottom, 400.0);
      expect(tester.getRect(sheetMaterial()).bottom, 600.0);

      // Inside the content.
      await tester.tapAt(const Offset(400.0, 350.0));
      expect(tapCount, 1);

      // In the inset region, which only the keyboard can reach: the sheet's
      // Material absorbs the tap (as the Scaffold's own Material did before it
      // was covered), and the content is not hit.
      await tester.tapAt(const Offset(400.0, 500.0));
      expect(tapCount, 1);
    });

    testWidgets('a Scaffold shorter than the keyboard inset keeps the sheet inside its bounds', (
      WidgetTester tester,
    ) async {
      // A 250px tall Scaffold centered on the 600px screen, so it spans y 175..425.
      Widget buildNested(double keyboardHeight) {
        return MaterialApp(
          theme: ThemeData(
            bottomSheetTheme: const BottomSheetThemeData(
              constraints: BoxConstraints.tightFor(height: 150.0),
            ),
          ),
          home: MediaQuery(
            data: MediaQueryData(viewInsets: EdgeInsets.only(bottom: keyboardHeight)),
            child: const Center(
              child: SizedBox(
                width: 320.0,
                height: 250.0,
                child: Scaffold(
                  body: SizedBox.expand(),
                  bottomSheet: SizedBox.expand(key: Key('content')),
                ),
              ),
            ),
          ),
        );
      }

      for (final keyboardHeight in <double>[0.0, 200.0, 400.0, 0.0]) {
        await tester.pumpWidget(buildNested(keyboardHeight));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        // The content gets whatever is left above the keyboard, at most the
        // theme's 150, exactly as before.
        expect(
          tester.getSize(find.byKey(const Key('content'))).height,
          math.min(150.0, math.max(0.0, 250.0 - keyboardHeight)),
        );
        // The Material always ends at the Scaffold's bottom edge and never
        // leaves the Scaffold, without any clipping.
        expect(tester.getRect(sheetMaterial()).bottom, 425.0);
        expect(tester.getRect(sheetMaterial()).top, greaterThanOrEqualTo(175.0));
      }
    });

    testWidgets('a BottomSheet passed as Scaffold.bottomSheet is not extended twice', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildApp(
          keyboardHeight: 200.0,
          bottomSheet: BottomSheet(
            enableDrag: false,
            onClosing: () {},
            builder: (BuildContext context) =>
                const SizedBox(key: Key('content'), width: double.infinity, height: 100.0),
          ),
        ),
      );
      final Finder sheets = find.byType(BottomSheet);
      expect(sheets, findsNWidgets(2));
      Finder materialOf(Finder sheet) =>
          find.descendant(of: sheet, matching: find.byType(Material)).first;

      // Only the Scaffold's own sheet carries the inset. The user's sheet, and
      // its Material, end with the content.
      expect(tester.widget<BottomSheet>(sheets.first).bottomInset, 200.0);
      expect(tester.widget<BottomSheet>(sheets.last).bottomInset, 0.0);
      expect(tester.getRect(find.byKey(const Key('content'))).bottom, 400.0);
      expect(tester.getRect(materialOf(sheets.first)).bottom, 600.0);
      expect(tester.getRect(materialOf(sheets.last)).bottom, 400.0);
    });
  });
}

class PersistentBottomSheetTest extends StatefulWidget {
  const PersistentBottomSheetTest({super.key});

  @override
  PersistentBottomSheetTestState createState() => PersistentBottomSheetTestState();
}

class PersistentBottomSheetTestState extends State<PersistentBottomSheetTest> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  bool setStateCalled = false;

  void showBottomSheet() {
    _scaffoldKey.currentState!
        .showBottomSheet((BuildContext context) {
          return const Text('bottomSheet');
        })
        .closed
        .whenComplete(() {
          setState(() {
            setStateCalled = true;
          });
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(key: _scaffoldKey, body: const Text('Sheet'));
  }
}
