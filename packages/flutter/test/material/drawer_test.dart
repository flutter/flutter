// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:leak_tracker_flutter_testing/leak_tracker_flutter_testing.dart';

import '../widgets/semantics_tester.dart';

void main() {
  testWidgetsWithLeakTracking('Drawer control test', (WidgetTester tester) async {
    const Key containerKey = Key('container');

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: false),
        home: Scaffold(
          drawer: Drawer(
            child: ListView(
              children: <Widget>[
                DrawerHeader(
                  child: Container(
                    key: containerKey,
                    child: const Text('header'),
                  ),
                ),
                const ListTile(
                  leading: Icon(Icons.archive),
                  title: Text('Archive'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Archive'), findsNothing);
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Archive'), findsOneWidget);

    RenderBox box = tester.renderObject(find.byType(DrawerHeader));
    expect(box.size.height, equals(160.0 + 8.0 + 1.0)); // height + bottom margin + bottom edge

    final double drawerWidth = box.size.width;
    final double drawerHeight = box.size.height;

    box = tester.renderObject(find.byKey(containerKey));
    expect(box.size.width, equals(drawerWidth - 2 * 16.0));
    expect(box.size.height, equals(drawerHeight - 2 * 16.0));

    expect(find.text('header'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('Drawer dismiss barrier has label', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: Drawer(),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, includesNodeWith(
      label: const DefaultMaterialLocalizations().modalBarrierDismissLabel,
      actions: <SemanticsAction>[SemanticsAction.tap],
    ));

    semantics.dispose();
  }, variant: const TargetPlatformVariant(<TargetPlatform>{ TargetPlatform.iOS,  TargetPlatform.macOS }));

  testWidgetsWithLeakTracking('Drawer dismiss barrier has no label', (WidgetTester tester) async {
    final SemanticsTester semantics = SemanticsTester(tester);
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
            drawer: Drawer(),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    expect(semantics, isNot(includesNodeWith(
      label: const DefaultMaterialLocalizations().modalBarrierDismissLabel,
      actions: <SemanticsAction>[SemanticsAction.tap],
    )));

    semantics.dispose();
  }, variant: TargetPlatformVariant.only(TargetPlatform.android));

  testWidgetsWithLeakTracking('Scaffold drawerScrimColor', (WidgetTester tester) async {
    // The scrim is a Container within a Semantics node labeled "Dismiss",
    // within a DrawerController. Sorry.
    Container getScrim() {
      return tester.widget<Container>(
        find.descendant(
          of: find.descendant(
            of: find.byType(DrawerController),
            matching: find.byWidgetPredicate((Widget widget) {
              return widget is Semantics
                  && widget.properties.label == 'Dismiss';
            }),
          ),
          matching: find.byType(Container),
        ),
      );
    }

    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    Widget buildFrame({ Color? drawerScrimColor }) {
      return MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawerScrimColor: drawerScrimColor,
          drawer: Drawer(
            child: Builder(
              builder: (BuildContext context) {
                return GestureDetector(
                  onTap: () { Navigator.pop(context); }, // close drawer
                );
              },
            ),
          ),
        ),
      );
    }

    // Default drawerScrimColor

    await tester.pumpWidget(buildFrame());
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(getScrim().color, Colors.black54);

    await tester.tap(find.byType(Drawer));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);

    // Specific drawerScrimColor

    await tester.pumpWidget(buildFrame(drawerScrimColor: const Color(0xFF323232)));
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();

    expect(getScrim().color, const Color(0xFF323232));

    await tester.tap(find.byType(Drawer));
    await tester.pumpAndSettle();
    expect(find.byType(Drawer), findsNothing);
  });

  testWidgetsWithLeakTracking('Open/close drawers by flinging', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: Drawer(
            child: Text('start drawer'),
          ),
          endDrawer: Drawer(
            child: Text('end drawer'),
          ),
        ),
      ),
    );

    // In the beginning, drawers are closed
    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    expect(state.isDrawerOpen, equals(false));
    expect(state.isEndDrawerOpen, equals(false));
    final Size size = tester.getSize(find.byType(Scaffold));

    // A fling from the left opens the start drawer
    await tester.flingFrom(Offset(0, size.height / 2), const Offset(80, 0), 500);
    await tester.pumpAndSettle();
    expect(state.isDrawerOpen, equals(true));
    expect(state.isEndDrawerOpen, equals(false));

    // Now, a fling from the right closes the drawer
    await tester.flingFrom(Offset(size.width - 1, size.height / 2), const Offset(-80, 0), 500);
    await tester.pumpAndSettle();
    expect(state.isDrawerOpen, equals(false));
    expect(state.isEndDrawerOpen, equals(false));

    // Another fling from the right opens the end drawer
    await tester.flingFrom(Offset(size.width - 1, size.height / 2), const Offset(-80, 0), 500);
    await tester.pumpAndSettle();
    expect(state.isDrawerOpen, equals(false));
    expect(state.isEndDrawerOpen, equals(true));

    // And a fling from the left closes it
    await tester.flingFrom( Offset(0, size.height / 2), const Offset(80, 0), 500);
    await tester.pumpAndSettle();
    expect(state.isDrawerOpen, equals(false));
    expect(state.isEndDrawerOpen, equals(false));
  });

  testWidgetsWithLeakTracking('Scaffold.drawer - null restorationId ', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Text('drawer'),
          body: Container(),
        ),
      ),
    );
    await tester.pump(); // no effect
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsOneWidget);

    await tester.restartAndRestore();
    // Drawer state should not have been saved.
    expect(find.text('drawer'), findsNothing);
  });

  testWidgetsWithLeakTracking('Scaffold.endDrawer - null restorationId ', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Text('endDrawer'),
          body: Container(),
        ),
      ),
    );
    await tester.pump(); // no effect
    expect(find.text('endDrawer'), findsNothing);
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('endDrawer'), findsOneWidget);

    await tester.restartAndRestore();
    // Drawer state should not have been saved.
    expect(find.text('endDrawer'), findsNothing);
  });

  testWidgetsWithLeakTracking('Scaffold.drawer state restoration test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          key: scaffoldKey,
          restorationId: 'scaffold',
          drawer: const Text('drawer'),
          body: Container(),
        ),
      ),
    );
    await tester.pump(); // no effect
    expect(find.text('drawer'), findsNothing);
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsOneWidget);

    await tester.restartAndRestore();
    expect(find.text('drawer'), findsOneWidget);

    final TestRestorationData data = await tester.getRestorationData();
    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsNothing);

    await tester.restoreFrom(data);
    expect(find.text('drawer'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('Scaffold.endDrawer state restoration test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          key: scaffoldKey,
          restorationId: 'scaffold',
          endDrawer: const Text('endDrawer'),
          body: Container(),
        ),
      ),
    );
    await tester.pump(); // no effect
    expect(find.text('endDrawer'), findsNothing);
    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('endDrawer'), findsOneWidget);

    await tester.restartAndRestore();
    expect(find.text('endDrawer'), findsOneWidget);

    final TestRestorationData data = await tester.getRestorationData();
    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pumpAndSettle();
    expect(find.text('endDrawer'), findsNothing);

    await tester.restoreFrom(data);
    expect(find.text('endDrawer'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('Both drawer and endDrawer state restoration test', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        restorationScopeId: 'app',
        home: Scaffold(
          restorationId: 'scaffold',
          key: scaffoldKey,
          drawer: const Text('drawer'),
          endDrawer: const Text('endDrawer'),
          body: Container(),
        ),
      ),
    );
    await tester.pump(); // no effect
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsNothing);
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsOneWidget);
    expect(find.text('endDrawer'), findsNothing);

    await tester.restartAndRestore();
    expect(find.text('drawer'), findsOneWidget);
    expect(find.text('endDrawer'), findsNothing);

    TestRestorationData data = await tester.getRestorationData();
    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsNothing);

    await tester.restoreFrom(data);
    expect(find.text('drawer'), findsOneWidget);
    expect(find.text('endDrawer'), findsNothing);

    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsNothing);

    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsOneWidget);

    await tester.restartAndRestore();
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsOneWidget);

    data = await tester.getRestorationData();
    await tester.tapAt(const Offset(750.0, 100.0)); // on the mask
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsNothing);

    await tester.restoreFrom(data);
    expect(find.text('drawer'), findsNothing);
    expect(find.text('endDrawer'), findsOneWidget);
  });

  testWidgetsWithLeakTracking('ScaffoldState close drawer', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Text('Drawer'),
          body: Container(),
        ),
      ),
    );

    expect(find.text('Drawer'), findsNothing);

    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Drawer'), findsOneWidget);

    scaffoldKey.currentState!.closeDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Drawer'), findsNothing);
  });

  testWidgetsWithLeakTracking('ScaffoldState close drawer do not crash if drawer is already closed', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          drawer: const Text('Drawer'),
          body: Container(),
        ),
      ),
    );

    expect(find.text('Drawer'), findsNothing);

    scaffoldKey.currentState!.closeDrawer();
    await tester.pumpAndSettle();
    expect(find.text('Drawer'), findsNothing);
  });

  testWidgetsWithLeakTracking('Disposing drawer does not crash if drawer is open and framework is locked', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/34978
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1800.0, 2400.0);

    await tester.pumpWidget(
      MaterialApp(
        home: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            switch (orientation) {
              case Orientation.portrait:
                return Scaffold(
                  drawer: const Text('drawer'),
                  body: Container(),
                );
              case Orientation.landscape:
                return Scaffold(
                  appBar: AppBar(),
                  body: Container(),
                );
            }
          },
        ),
      ),
    );

    expect(find.text('drawer'), findsNothing);

    // Using a global key is a workaround for this issue.
    final ScaffoldState portraitScaffoldState = tester.firstState(find.byType(Scaffold));
    portraitScaffoldState.openDrawer();
    await tester.pumpAndSettle();
    expect(find.text('drawer'), findsOneWidget);

    // Change the orientation and cause the drawer controller to be disposed
    // while the framework is locked.
    tester.view.physicalSize = const Size(2400.0, 1800.0);
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgetsWithLeakTracking('Disposing endDrawer does not crash if endDrawer is open and framework is locked', (WidgetTester tester) async {
    // Regression test for https://github.com/flutter/flutter/issues/34978
    addTearDown(tester.view.reset);
    tester.view.physicalSize = const Size(1800.0, 2400.0);

    await tester.pumpWidget(
      MaterialApp(
        home: OrientationBuilder(
          builder: (BuildContext context, Orientation orientation) {
            switch (orientation) {
              case Orientation.portrait:
                return Scaffold(
                  endDrawer: const Text('endDrawer'),
                  body: Container(),
                );
              case Orientation.landscape:
                return Scaffold(
                  appBar: AppBar(),
                  body: Container(),
                );
            }
          },
        ),
      ),
    );

    expect(find.text('endDrawer'), findsNothing);

    // Using a global key is a workaround for this issue.
    final ScaffoldState portraitScaffoldState = tester.firstState(find.byType(Scaffold));
    portraitScaffoldState.openEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('endDrawer'), findsOneWidget);

    // Change the orientation and cause the drawer controller to be disposed
    // while the framework is locked.
    tester.view.physicalSize = const Size(2400.0, 1800.0);
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgetsWithLeakTracking('ScaffoldState close end drawer', (WidgetTester tester) async {
    final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          key: scaffoldKey,
          endDrawer: const Text('endDrawer'),
          body: Container(),
        ),
      ),
    );

    expect(find.text('endDrawer'), findsNothing);

    scaffoldKey.currentState!.openEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('endDrawer'), findsOneWidget);

    scaffoldKey.currentState!.closeEndDrawer();
    await tester.pumpAndSettle();
    expect(find.text('endDrawer'), findsNothing);
  });

  testWidgetsWithLeakTracking('Drawer width defaults to Material spec', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: Drawer(),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    final RenderBox box = tester.renderObject(find.byType(Drawer));
    expect(box.size.width, equals(304.0));
  });

  testWidgetsWithLeakTracking('Drawer width can be customized by parameter', (WidgetTester tester) async {
    const double smallWidth = 200;

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          drawer: Drawer(
            width: smallWidth,
          ),
        ),
      ),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));
    state.openDrawer();

    await tester.pumpAndSettle();

    final RenderBox box = tester.renderObject(find.byType(Drawer));
    expect(box.size.width, equals(smallWidth));
  });

  testWidgetsWithLeakTracking('Drawer default shape (ltr)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Directionality(
          textDirection: TextDirection.ltr,
          child: Scaffold(
            drawer: Drawer(),
            endDrawer: Drawer(),
          ),
        ),
      ),
    );

    final Finder drawerMaterial = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Material),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));

    // Open the drawer.
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Test the drawer shape.
    Material material = tester.widget<Material>(drawerMaterial);
    expect(
      material.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16.0),
          bottomRight: Radius.circular(16.0),
        ),
      ),
    );

    // Close the opened drawer.
    await tester.tapAt(const Offset(750, 300));
    await tester.pumpAndSettle();

    // Open the end drawer.
    state.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Test the end drawer shape.
    material = tester.widget<Material>(drawerMaterial);
    expect(
      material.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          bottomLeft: Radius.circular(16.0),
        ),
      ),
    );
  });

  testWidgetsWithLeakTracking('Drawer default shape (rtl)', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Directionality(
          textDirection: TextDirection.rtl,
          child: Scaffold(
            drawer: Drawer(),
            endDrawer: Drawer(),
          ),
        ),
      ),
    );

    final Finder drawerMaterial = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Material),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));

    // Open the drawer.
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Test the drawer shape.
    Material material = tester.widget<Material>(drawerMaterial);
    expect(
      material.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16.0),
          bottomLeft: Radius.circular(16.0),
        ),
      ),
    );

    // Close the opened drawer.
    await tester.tapAt(const Offset(750, 300));
    await tester.pumpAndSettle();

    // Open the end drawer.
    state.openEndDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Test the end drawer shape.
    material = tester.widget<Material>(drawerMaterial);
    expect(
      material.shape,
      const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(16.0),
          bottomRight: Radius.circular(16.0),
        ),
      ),
    );
  });

  testWidgetsWithLeakTracking('Drawer clip behavior', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          drawer: Drawer(),
        ),
      ),
    );

    final Finder drawerMaterial = find.descendant(
      of: find.byType(Drawer),
      matching: find.byType(Material),
    );

    final ScaffoldState state = tester.firstState(find.byType(Scaffold));

    // Open the drawer.
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Test default clip behavior.
    Material material = tester.widget<Material>(drawerMaterial);
    expect(material.clipBehavior, Clip.hardEdge);

    state.closeDrawer();
    await tester.pumpAndSettle();

    // Provide a custom clip behavior.
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: const Scaffold(
          drawer: Drawer(
            clipBehavior: Clip.antiAlias,
          ),
        ),
      ),
    );

    // Open the drawer again.
    state.openDrawer();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    // Clip behavior is now updated.
    material = tester.widget<Material>(drawerMaterial);
    expect(material.clipBehavior, Clip.antiAlias);
  });

  group('Material 2', () {
    // These tests are only relevant for Material 2. Once Material 2
    // support is deprecated and the APIs are removed, these tests
    // can be deleted.

    testWidgetsWithLeakTracking('Drawer default shape', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(
            drawer: Drawer(),
            endDrawer: Drawer(),
          ),
        ),
      );

      final Finder drawerMaterial = find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Material),
      );

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));

      // Open the drawer.
      state.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Test the drawer shape.
      Material material = tester.widget<Material>(drawerMaterial);
      expect(material.shape, null);

      // Close the opened drawer.
      await tester.tapAt(const Offset(750, 300));
      await tester.pumpAndSettle();

      // Open the end drawer.
      state.openEndDrawer();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Test the end drawer shape.
      material = tester.widget<Material>(drawerMaterial);
      expect(material.shape, null);
    });

    testWidgetsWithLeakTracking('Drawer clip behavior', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(
            drawer: Drawer(),
          ),
        ),
      );

      final Finder drawerMaterial = find.descendant(
        of: find.byType(Drawer),
        matching: find.byType(Material),
      );

      final ScaffoldState state = tester.firstState(find.byType(Scaffold));

      // Open the drawer.
      state.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Test default clip behavior.
      Material material = tester.widget<Material>(drawerMaterial);
      expect(material.clipBehavior, Clip.none);

      state.closeDrawer();
      await tester.pumpAndSettle();

      // Provide a shape and custom clip behavior.
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(useMaterial3: false),
          home: const Scaffold(
            drawer: Drawer(
              clipBehavior: Clip.hardEdge,
              shape: RoundedRectangleBorder(),
            ),
          ),
        ),
      );

      // Open the drawer again.
      state.openDrawer();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Clip behavior is now updated.
      material = tester.widget<Material>(drawerMaterial);
      expect(material.clipBehavior, Clip.hardEdge);
    });
  });
}
