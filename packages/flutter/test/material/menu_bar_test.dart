// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuBarController controller;
  String? openPath;
  String? focusedMenu;
  final List<TestMenu> selected = <TestMenu>[];
  final List<TestMenu> opened = <TestMenu>[];
  final List<TestMenu> closed = <TestMenu>[];

  void collectPath() {
    openPath = controller.debugCurrentItem;
  }

  void onSelected(TestMenu item) {
    selected.add(item);
    collectPath();
  }

  void onOpen(TestMenu item) {
    opened.add(item);
    collectPath();
  }

  void onClose(TestMenu item) {
    closed.add(item);
    collectPath();
  }

  void handleFocusChange() {
    focusedMenu = controller.debugFocusedItem;
  }

  setUp(() {
    openPath = null;
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuBarController();
    collectPath();
    focusedMenu = controller.debugFocusedItem;
  });

  tearDown(() {
    controller.closeAll();
  });

  void listenForFocusChanges() {
    FocusManager.instance.addListener(handleFocusChange);
    addTearDown(() => FocusManager.instance.removeListener(handleFocusChange));
  }

  Finder findDividers() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemDivider');
  }

  Finder findMenuBarMenus() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarMenuList');
  }

  Finder findMenuTopLevelBars() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarTopLevelBar');
  }

  Finder findMenuBarItemLabels() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarItemLabel');
  }

  // Finds the mnemonic associated with the menu item that has the given label.
  Finder findMnemonic(String label) {
    return find
        .descendant(
            of: find.ancestor(of: find.text(label), matching: findMenuBarItemLabels()), matching: find.byType(Text))
        .last;
  }

  Future<TestGesture> hoverOver(WidgetTester tester, Finder finder) async {
    final TestGesture gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    return gesture;
  }

  Material getMenuBarMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(of: findMenuTopLevelBars(), matching: find.byType(Material)).first,
    );
  }

  group('MenuBar', () {
    testWidgets('basic menu structure', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu100.label), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu100.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu101.label), findsNothing);
      expect(find.text(TestMenu.subSubMenu102.label), findsNothing);
      expect(opened.last, equals(TestMenu.mainMenu1));
      opened.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(find.text(TestMenu.mainMenu0.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu1.label), findsOneWidget);
      expect(find.text(TestMenu.mainMenu2.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu10.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu11.label), findsOneWidget);
      expect(find.text(TestMenu.subMenu12.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu100.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu101.label), findsOneWidget);
      expect(find.text(TestMenu.subSubMenu102.label), findsOneWidget);
      expect(opened.last, equals(TestMenu.subMenu11));
    });
    testWidgets('geometry', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  menus: createTestMenus(onSelected: onSelected),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(120.0, 73.0, 274.0, 87.0)),
      );
      expect(tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
          equals(const Rect.fromLTRB(96.0, 48.0, 358.0, 224.0)));
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(96.0, 104.0, 358.0, 120.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
    });
    testWidgets('geometry with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Directionality(
              textDirection: TextDirection.rtl,
              child: Column(
                children: <Widget>[
                  MenuBar(
                    menus: createTestMenus(onSelected: onSelected),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(526.0, 73.0, 680.0, 87.0)),
      );
      expect(tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
          equals(const Rect.fromLTRB(442.0, 48.0, 704.0, 224.0)));
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(442.0, 104.0, 704.0, 120.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(0, 0, 800, 48)));
    });
    testWidgets('works with Padding around menu and overlay', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: MenuBar(
                      menus: createTestMenus(onSelected: onSelected),
                    ),
                  ),
                  const Expanded(child: Placeholder()),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(142.0, 95.0, 296.0, 109.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(118.0, 70.0, 380.0, 246.0)),
      );
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(118.0, 126.0, 380.0, 142.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });
    testWidgets('works with Padding around menu and overlay with RTL direction', (WidgetTester tester) async {
      await tester.pumpWidget(
        Padding(
          padding: const EdgeInsets.all(10.0),
          child: MaterialApp(
            home: Material(
              child: Directionality(
                textDirection: TextDirection.rtl,
                child: Column(
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: MenuBar(
                        menus: createTestMenus(onSelected: onSelected),
                      ),
                    ),
                    const Expanded(child: Placeholder()),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
      expect(
        tester.getRect(find.text(TestMenu.subMenu10.label)),
        equals(const Rect.fromLTRB(504.0, 95.0, 658.0, 109.0)),
      );
      expect(
        tester.getRect(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).at(1)),
        equals(const Rect.fromLTRB(420.0, 70.0, 682.0, 246.0)),
      );
      expect(tester.getRect(findDividers()), equals(const Rect.fromLTRB(420.0, 126.0, 682.0, 142.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTRB(22.0, 22.0, 778.0, 70.0)));
    });
    testWidgets('visual attributes can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  minimumHeight: 50,
                  elevation: MaterialStateProperty.all<double?>(10),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  menus: createTestMenus(onSelected: onSelected),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );
      expect(tester.getRect(findMenuTopLevelBars()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
      final Material material = getMenuBarMaterial(tester);
      expect(material.elevation, equals(10));
      expect(material.color, equals(Colors.red));
    });
    testWidgets('open and close works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(onSelected: onSelected, onOpen: onOpen, onClose: onClose),
            ),
          ),
        ),
      );

      expect(openPath, isNull);
      expect(opened, isEmpty);
      expect(closed, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));
      expect(opened, equals(<TestMenu>[TestMenu.subMenu11]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(opened, isEmpty);
      expect(closed, equals(<TestMenu>[TestMenu.subMenu11]));
      opened.clear();
      closed.clear();

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu0]));
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu1]));
    });
    testWidgets('select works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(onSelected: onSelected, onOpen: onOpen, onClose: onClose),
            ),
          ),
        ),
      );

      expect(openPath, isNull);
      expect(openPath, isNull);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.tap(find.text(TestMenu.subSubMenu100.label));
      await tester.pump();

      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu100]));

      // Selecting a non-submenu item should close all the menus.
      expect(openPath, isNull);
      expect(find.text(TestMenu.subSubMenu100.label), findsNothing);
      expect(find.text(TestMenu.subMenu11.label), findsNothing);
    });
    testWidgets('diagnostics toStringDeep', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: <MenuItem>[
                MenuBarMenu(
                  shape: MaterialStateProperty.all<ShapeBorder?>(const RoundedRectangleBorder()),
                  label: TestMenu.mainMenu0.label,
                  elevation: MaterialStateProperty.all<double?>(10.0),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  menus: <MenuItem>[
                    MenuItemGroup(
                      members: <MenuItem>[
                        MenuBarButton(
                          label: TestMenu.subMenu00.label,
                          semanticsLabel: 'semanticLabel',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      final MenuBar menuBar = tester.widget(find.byType(MenuBar));
      expect(
        menuBar.toStringDeep(),
        equalsIgnoringHashCodes(
          'MenuBar#00000\n'
          " │ controller: Instance of 'MenuBarController'\n"
          ' └MenuBarMenu#00000(Menu 0)(label: "Menu 0", backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336))), shape: MaterialStatePropertyAll(RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)), elevation: MaterialStatePropertyAll(10.0))\n'
          '  └MenuItemGroup#00000()(members: [MenuBarButton#00000(Sub Menu 00)(DISABLED, label: "Sub Menu 00", semanticLabel: "semanticLabel")])\n',
        ),
      );
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      const MenuBarButton item = MenuBarButton(
        label: 'label2',
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
      );
      final MenuBar menuBar = MenuBar(
        controller: MenuBarController(),
        enabled: false,
        backgroundColor: MaterialStateProperty.all(Colors.red),
        minimumHeight: 40,
        elevation: MaterialStateProperty.all<double?>(10.0),
        menus: const <MenuItem>[item],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: menuBar,
          ),
        ),
      );
      await tester.pump();

      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      menuBar.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(
        description.join('\n'),
        equalsIgnoringHashCodes('DISABLED\n'
            "controller: Instance of 'MenuBarController'\n"
            'backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336)))\n'
            'height: 40.0\n'
            'elevation: MaterialStatePropertyAll(10.0)'),
      );
    });
    testWidgets('activation via shortcut works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  menus: createTestMenus(
                    onSelected: onSelected,
                    onOpen: onOpen,
                    onClose: onClose,
                    shortcuts: <TestMenu, MenuSerializableShortcut>{
                      TestMenu.subSubMenu100: const SingleActivator(
                        LogicalKeyboardKey.keyA,
                        control: true,
                      ),
                    },
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Focus(
                      autofocus: true,
                      child: Text('Body'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);

      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu100]));

      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect(openPath, isNull);
    });
    testWidgets('Having the same shortcut assigned to more than one menu item should throw an error.',
        (WidgetTester tester) async {
      const SingleActivator duplicateActivator = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: duplicateActivator,
                  TestMenu.subSubMenu101: duplicateActivator,
                },
              ),
            ),
          ),
        ),
      );
      final dynamic exception = tester.takeException();
      expect(exception, isFlutterError);
      final FlutterError error = exception as FlutterError;
      expect(
        error.message,
        contains(
          RegExp(r'The same shortcut has been bound to two different menus with different select '
              r'functions or intents: SingleActivator#.....\(keys: Control \+ Key A\)'),
        ),
      );
    });
    testWidgets(
        'Having the same shortcut assigned to more than one menu item should not throw an error if they have the same callback.',
        (WidgetTester tester) async {
      const SingleActivator sameShortcut = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
      );
      void sameCallback() {}
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: <MenuItem>[
                MenuBarMenu(
                  label: TestMenu.mainMenu0.label,
                  menus: <MenuItem>[
                    MenuBarButton(
                      label: TestMenu.subMenu10.label,
                      onSelected: sameCallback,
                      shortcut: sameShortcut,
                    ),
                    MenuBarButton(
                      label: TestMenu.subMenu11.label,
                      onSelected: sameCallback,
                      shortcut: sameShortcut,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      final dynamic exception = tester.takeException();
      expect(exception, isNull);
    });
    testWidgets('keyboard tab traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  menus: createTestMenus(
                    onSelected: onSelected,
                    onOpen: onOpen,
                    onClose: onClose,
                  ),
                ),
                const Expanded(child: Placeholder()),
              ],
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 00)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 101)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 102)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 103)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 12)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 00)'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 12)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 103)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 102)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 101)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);

      // Test closing a menu with enter.
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(focusedMenu, isNull);
      expect(openPath, isNull);
    });
    testWidgets('keyboard directional traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarButton#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarButton#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarButton#00000(Sub Menu 10)'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 101)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 102)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 103)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 103)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));

      // Wrap around.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));

      // Wrap around the other way.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
    });
    testWidgets('keyboard directional traversal works in RTL mode', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Material(
              child: MenuBar(
                controller: controller,
                menus: createTestMenus(
                  onSelected: onSelected,
                  onOpen: onOpen,
                  onClose: onClose,
                ),
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarButton#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarButton#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarButton#00000(Sub Menu 10)'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 101)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 102)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 103)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 103)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));

      // Wrap around.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));

      // Wrap around the other way.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
    });
    testWidgets('hover traversal works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      listenForFocusChanges();

      // Hovering when the menu is not yet open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, isNull);
      expect(openPath, isNull);

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pumpAndSettle();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));

      // Hovering when the menu is already  open does nothing.
      await hoverOver(tester, find.text(TestMenu.mainMenu0.label));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));

      // Hovering over the other main menu items opens them now.
      await hoverOver(tester, find.text(TestMenu.mainMenu2.label));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));

      await hoverOver(tester, find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      // Hovering over the menu items focuses them.
      await hoverOver(tester, find.text(TestMenu.subMenu10.label));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await hoverOver(tester, find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await hoverOver(tester, find.text(TestMenu.subSubMenu100.label));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarButton#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));
    });
  });
  group('MenuItemGroup', () {
    testWidgets('Top level menu groups have appropriate dividers', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                includeExtraGroups: true,
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      expect(findDividers(), findsNWidgets(2));

      // Children of the top level menu bar should be in the right order (with
      // the dividers between the right items).
      final Finder topLevelMenuBar = findMenuTopLevelBars().first;
      final Finder topLevelList = find.descendant(of: topLevelMenuBar, matching: findMenuBarMenus().first);
      // ignore: avoid_dynamic_calls
      final List<Widget> children = (tester.widget(topLevelList) as dynamic).children as List<Widget>;
      expect(
        children.map<String>((Widget child) => child.runtimeType.toString()),
        equals(
          <String>[
            '_MenuNodeWrapper',
            '_MenuNodeWrapper',
            '_MenuNodeWrapper',
            '_MenuItemDivider',
            '_MenuNodeWrapper',
            '_MenuItemDivider',
            '_MenuNodeWrapper',
          ],
        ),
      );
    });
    testWidgets('Submenus have appropriate dividers', (WidgetTester tester) async {
      final GlobalKey menuKey = GlobalKey(debugLabel: 'MenuBar');
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              key: menuKey,
              controller: controller,
              menus: createTestMenus(
                includeExtraGroups: true,
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu4.label));
      await tester.pumpAndSettle();

      expect(findDividers(), findsNWidgets(4));

      // The menu item that is open.
      final Finder firstMenuList = find.descendant(
        of: find.byWidget(Navigator.of(menuKey.currentContext!).overlay!.widget),
        matching: findMenuBarMenus().first,
      );
      // ignore: avoid_dynamic_calls
      final List<Widget> children = (tester.widget(firstMenuList) as dynamic).children as List<Widget>;
      expect(
        children.map<String>((Widget child) => child.runtimeType.toString()),
        equals(
          <String>[
            '_MenuNodeWrapper',
            '_MenuNodeWrapper',
            '_MenuNodeWrapper',
            '_MenuItemDivider',
            '_MenuNodeWrapper',
            '_MenuItemDivider',
            '_MenuNodeWrapper',
          ],
        ),
      );
    });
  });
  group('MenuBarController', () {
    testWidgets('enable and disable works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  menus: createTestMenus(
                    onSelected: onSelected,
                    onOpen: onOpen,
                    onClose: onClose,
                    shortcuts: <TestMenu, MenuSerializableShortcut>{
                      TestMenu.subSubMenu100: const SingleActivator(
                        LogicalKeyboardKey.keyA,
                        control: true,
                      )
                    },
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Focus(
                      autofocus: true,
                      child: Text('Body'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump(); // Wait for focus.

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      // The menu should handle shortcuts.
      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu100]));
      expect(closed, isEmpty);
      expect(opened, isEmpty);
      selected.clear();

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1]));

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      expect(closed, isEmpty);
      expect(selected, isEmpty);
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Disable the menu bar
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  enabled: false,
                  menus: createTestMenus(
                    onSelected: onSelected,
                    onOpen: onOpen,
                    onClose: onClose,
                    shortcuts: <TestMenu, MenuSerializableShortcut>{
                      TestMenu.subSubMenu100: const SingleActivator(
                        LogicalKeyboardKey.keyA,
                        control: true,
                      )
                    },
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Focus(
                      autofocus: true,
                      child: Text('Body'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      // The menu should go away,
      expect(openPath, isNull);
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      closed.clear();
      expect(opened, isEmpty);
      expect(selected, isEmpty);

      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      // The menu should not respond to the tap.
      expect(openPath, isNull);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      // The menu should not handle shortcuts.
      expect(selected, isEmpty);

      // Re-enable the menu bar.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  controller: controller,
                  menus: createTestMenus(
                    onSelected: onSelected,
                    onOpen: onOpen,
                    onClose: onClose,
                    shortcuts: <TestMenu, MenuSerializableShortcut>{
                      TestMenu.subSubMenu100: const SingleActivator(
                        LogicalKeyboardKey.keyA,
                        control: true,
                      )
                    },
                  ),
                ),
                const Expanded(
                  child: Center(
                    child: Focus(
                      autofocus: true,
                      child: Text('Body'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      // The menu should now handle shortcuts.
      expect(selected, equals(<TestMenu>[TestMenu.subSubMenu100]));

      // The menu should again accept taps.
      await tester.tap(find.text(TestMenu.mainMenu2.label));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(closed, isEmpty);
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu2]));
      // Item disabled by its parameter should still be disabled.
      final TextButton button =
          tester.widget(find.ancestor(of: find.text(TestMenu.subMenu20.label), matching: find.byType(TextButton)));
      expect(button.onPressed, isNull);
      expect(button.onHover, isNull);
      closed.clear();
    });
    testWidgets('closing via controller works', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                onSelected: onSelected,
                onOpen: onOpen,
                onClose: onClose,
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(
                    LogicalKeyboardKey.keyA,
                    control: true,
                  )
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();
      expect(opened, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      opened.clear();
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Close menus using the controller
      controller.closeAll();
      await tester.pump();

      // The menu should go away,
      expect(openPath, isNull);
      expect(closed, equals(<TestMenu>[TestMenu.mainMenu1, TestMenu.subMenu11]));
      expect(opened, isEmpty);
    });
  });
  group('MenuBarItem', () {
    testWidgets('Shortcut mnemonics are displayed', (WidgetTester tester) async {
      final MenuBarController controller = MenuBarController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                  TestMenu.subSubMenu101: const SingleActivator(LogicalKeyboardKey.keyB, shift: true),
                  TestMenu.subSubMenu102: const SingleActivator(LogicalKeyboardKey.keyC, alt: true),
                  TestMenu.subSubMenu103: const SingleActivator(LogicalKeyboardKey.keyD, meta: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(TestMenu.mainMenu1.label));
      await tester.pump();

      await tester.tap(find.text(TestMenu.subMenu11.label));
      await tester.pump();

      Text mnemonic0;
      Text mnemonic1;
      Text mnemonic2;
      Text mnemonic3;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
          expect(mnemonic3.data, equals('Meta D'));
          break;
        case TargetPlatform.windows:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
          expect(mnemonic3.data, equals('Win D'));
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
          expect(mnemonic0.data, equals('⌃ A'));
          mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
          expect(mnemonic2.data, equals('⌥ C'));
          mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
          expect(mnemonic3.data, equals('⌘ D'));
          break;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.arrowRight),
                  TestMenu.subSubMenu101: const SingleActivator(LogicalKeyboardKey.arrowLeft),
                  TestMenu.subSubMenu102: const SingleActivator(LogicalKeyboardKey.arrowUp),
                  TestMenu.subSubMenu103: const SingleActivator(LogicalKeyboardKey.arrowDown),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
      expect(mnemonic0.data, equals('→'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
      expect(mnemonic1.data, equals('←'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
      expect(mnemonic2.data, equals('↑'));
      mnemonic3 = tester.widget(findMnemonic(TestMenu.subSubMenu103.label));
      expect(mnemonic3.data, equals('↓'));

      // Try some weirder ones.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                shortcuts: <TestMenu, MenuSerializableShortcut>{
                  TestMenu.subSubMenu100: const SingleActivator(LogicalKeyboardKey.escape),
                  TestMenu.subSubMenu101: const SingleActivator(LogicalKeyboardKey.fn),
                  TestMenu.subSubMenu102: const SingleActivator(LogicalKeyboardKey.enter),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      mnemonic0 = tester.widget(findMnemonic(TestMenu.subSubMenu100.label));
      expect(mnemonic0.data, equals('Esc'));
      mnemonic1 = tester.widget(findMnemonic(TestMenu.subSubMenu101.label));
      expect(mnemonic1.data, equals('Fn'));
      mnemonic2 = tester.widget(findMnemonic(TestMenu.subSubMenu102.label));
      expect(mnemonic2.data, equals('↵'));
    }, variant: TargetPlatformVariant.all());

    testWidgets('leadingIcon is used when set', (WidgetTester tester) async {
      final MenuBarController controller = MenuBarController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: <MenuItem>[
                MenuBarMenu(
                  label: TestMenu.mainMenu0.label,
                  menus: <MenuItem>[
                    MenuBarButton(
                      leadingIcon: const Text('leadingIcon'),
                      label: TestMenu.subMenu00.label,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('leadingIcon'), findsOneWidget);
    });
    testWidgets('trailingIcon is used when set', (WidgetTester tester) async {
      final MenuBarController controller = MenuBarController();
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: <MenuItem>[
                MenuBarMenu(
                  label: TestMenu.mainMenu0.label,
                  menus: <MenuItem>[
                    MenuBarButton(
                      label: TestMenu.subMenu00.label,
                      trailingIcon: const Text('trailingIcon'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text('trailingIcon'), findsOneWidget);
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: <MenuItem>[
                MenuBarMenu(
                  shape: MaterialStateProperty.all<ShapeBorder?>(const RoundedRectangleBorder()),
                  label: TestMenu.mainMenu0.label,
                  elevation: MaterialStateProperty.all<double?>(10.0),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  menus: <MenuItem>[
                    MenuItemGroup(
                      members: <MenuItem>[
                        MenuBarButton(
                          label: TestMenu.subMenu00.label,
                          semanticsLabel: 'semanticLabel',
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      final MenuBarMenu submenu = tester.widget(find.byType(MenuBarMenu));
      final DiagnosticPropertiesBuilder builder = DiagnosticPropertiesBuilder();
      submenu.debugFillProperties(builder);

      final List<String> description = builder.properties
          .where((DiagnosticsNode node) => !node.isFiltered(DiagnosticLevel.info))
          .map((DiagnosticsNode node) => node.toString())
          .toList();

      expect(description, <String>[
        'label: "Menu 0"',
        'backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336)))',
        'shape: MaterialStatePropertyAll(RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero))',
        'elevation: MaterialStatePropertyAll(10.0)',
      ]);
    });
  });
  group('LocalizedShortcutLabeler', () {
    testWidgets('getShortcutLabel returns the right labels', (WidgetTester tester) async {
      String expectedMeta;
      String expectedCtrl;
      String expectedAlt;
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          expectedCtrl = 'Ctrl';
          expectedMeta = 'Meta';
          expectedAlt = 'Alt';
          break;
        case TargetPlatform.windows:
          expectedCtrl = 'Ctrl';
          expectedMeta = 'Win';
          expectedAlt = 'Alt';
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          expectedCtrl = '⌃';
          expectedMeta = '⌘';
          expectedAlt = '⌥';
          break;
      }

      const SingleActivator allModifiers = SingleActivator(
        LogicalKeyboardKey.keyA,
        control: true,
        meta: true,
        shift: true,
        alt: true,
      );
      final String allExpected = '$expectedAlt $expectedCtrl $expectedMeta ⇧ A';
      const CharacterActivator charShortcuts = CharacterActivator('ñ');
      const String charExpected = 'ñ';
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: <MenuItem>[
                MenuBarMenu(
                  label: TestMenu.mainMenu0.label,
                  menus: <MenuItem>[
                    MenuBarButton(
                      label: TestMenu.subMenu10.label,
                      shortcut: allModifiers,
                    ),
                    MenuBarButton(
                      label: TestMenu.subMenu11.label,
                      shortcut: charShortcuts,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text(TestMenu.mainMenu0.label));
      await tester.pump();

      expect(find.text(allExpected), findsOneWidget);
      expect(find.text(charExpected), findsOneWidget);
    }, variant: TargetPlatformVariant.all());
  });
}

enum TestMenu {
  mainMenu0('Menu 0'),
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  mainMenu3('Menu 3'),
  mainMenu4('Menu 4'),
  subMenu00('Sub Menu 00'),
  subMenu10('Sub Menu 10'),
  subMenu11('Sub Menu 11'),
  subMenu12('Sub Menu 12'),
  subMenu20('Sub Menu 20'),
  subMenu30('Sub Menu 30'),
  subMenu40('Sub Menu 40'),
  subMenu41('Sub Menu 41'),
  subMenu42('Sub Menu 42'),
  subSubMenu100('Sub Sub Menu 100'),
  subSubMenu101('Sub Sub Menu 101'),
  subSubMenu102('Sub Sub Menu 102'),
  subSubMenu103('Sub Sub Menu 103');

  const TestMenu(this.label);
  final String label;
}

List<MenuItem> createTestMenus({
  void Function(TestMenu)? onSelected,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeStandard = false,
  bool includeExtraGroups = false,
}) {
  final List<MenuItem> result = <MenuItem>[
    MenuBarMenu(
      label: TestMenu.mainMenu0.label,
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      menus: <MenuItem>[
        MenuBarButton(
          label: TestMenu.subMenu00.label,
          onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu00) : null,
          shortcut: shortcuts[TestMenu.subMenu00],
        ),
      ],
    ),
    MenuBarMenu(
      label: TestMenu.mainMenu1.label,
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu1) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu1) : null,
      menus: <MenuItem>[
        MenuItemGroup(
          members: <MenuItem>[
            MenuBarButton(
              label: TestMenu.subMenu10.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu10) : null,
              shortcut: shortcuts[TestMenu.subMenu10],
            ),
          ],
        ),
        MenuBarMenu(
          label: TestMenu.subMenu11.label,
          onOpen: onOpen != null ? () => onOpen(TestMenu.subMenu11) : null,
          onClose: onClose != null ? () => onClose(TestMenu.subMenu11) : null,
          menus: <MenuItem>[
            MenuItemGroup(
              members: <MenuItem>[
                MenuBarButton(
                  label: TestMenu.subSubMenu100.label,
                  onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu100) : null,
                  shortcut: shortcuts[TestMenu.subSubMenu100],
                ),
              ],
            ),
            MenuBarButton(
              label: TestMenu.subSubMenu101.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu101) : null,
              shortcut: shortcuts[TestMenu.subSubMenu101],
            ),
            MenuBarButton(
              label: TestMenu.subSubMenu102.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu102) : null,
              shortcut: shortcuts[TestMenu.subSubMenu102],
            ),
            MenuBarButton(
              label: TestMenu.subSubMenu103.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu103) : null,
              shortcut: shortcuts[TestMenu.subSubMenu103],
            ),
          ],
        ),
        MenuBarButton(
          label: TestMenu.subMenu12.label,
          onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu12) : null,
          shortcut: shortcuts[TestMenu.subMenu12],
        ),
      ],
    ),
    MenuBarMenu(
      label: TestMenu.mainMenu2.label,
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu2) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu2) : null,
      menus: <MenuItem>[
        MenuBarButton(
          // Always disabled.
          label: TestMenu.subMenu20.label,
          shortcut: shortcuts[TestMenu.subMenu20],
        ),
      ],
    ),
    if (includeExtraGroups)
      MenuItemGroup(members: <MenuItem>[
        MenuBarMenu(
          label: TestMenu.mainMenu3.label,
          onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu3) : null,
          onClose: onClose != null ? () => onClose(TestMenu.mainMenu3) : null,
          menus: <MenuItem>[
            MenuBarButton(
              // Always disabled.
              label: TestMenu.subMenu30.label,
              shortcut: shortcuts[TestMenu.subMenu30],
            ),
          ],
        ),
      ]),
    if (includeExtraGroups)
      MenuItemGroup(members: <MenuItem>[
        MenuBarMenu(
          label: TestMenu.mainMenu4.label,
          onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu4) : null,
          onClose: onClose != null ? () => onClose(TestMenu.mainMenu4) : null,
          menus: <MenuItem>[
            MenuBarButton(
              // Always disabled.
              label: TestMenu.subMenu40.label,
              shortcut: shortcuts[TestMenu.subMenu40],
            ),
            MenuItemGroup(members: <MenuItem>[
              MenuBarButton(
                // Always disabled.
                label: TestMenu.subMenu41.label,
                shortcut: shortcuts[TestMenu.subMenu41],
              ),
            ]),
            MenuItemGroup(members: <MenuItem>[
              MenuBarButton(
                // Always disabled.
                label: TestMenu.subMenu42.label,
                shortcut: shortcuts[TestMenu.subMenu42],
              ),
            ]),
          ],
        ),
      ]),
  ];
  return result;
}
