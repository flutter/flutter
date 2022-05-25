// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:ui' show PointerDeviceKind;

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
  final List<String> selected = <String>[];
  final List<String> opened = <String>[];
  final List<String> closed = <String>[];

  void collectPath() {
    openPath = controller.testingCurrentItem;
  }

  void onSelected(String item) {
    selected.add(item);
    collectPath();
  }

  void onOpen(String item) {
    opened.add(item);
    collectPath();
  }

  void onClose(String item) {
    closed.add(item);
    collectPath();
  }

  void handleFocusChange() {
    focusedMenu = controller.testingFocusedItem;
  }

  setUp(() {
    openPath = null;
    focusedMenu = null;
    selected.clear();
    opened.clear();
    closed.clear();
    controller = MenuBarController();
    collectPath();
    focusedMenu = controller.testingFocusedItem;
  });

  tearDown(() {
    controller.closeAll();
  });

  void listenForFocusChanges() {
    FocusManager.instance.addListener(handleFocusChange);
    addTearDown(() => FocusManager.instance.removeListener(handleFocusChange));
  }

  Finder findDivider() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuItemDivider');
  }

  Finder findMenuBarMenu() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarMenuList');
  }

  Finder findMenuTopLevelBar() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarTopLevelBar');
  }

  Finder findMenuBarItemLabel() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarItemLabel');
  }

  // Finds the mnemonic associated with the menu item that has the given label.
  Finder findMnemonic(String label) {
    return find
        .descendant(
            of: find.ancestor(of: find.text(label), matching: findMenuBarItemLabel()), matching: find.byType(Text))
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
      find.descendant(of: findMenuTopLevelBar(), matching: find.byType(Material)).first,
    );
  }

  Material getSubMenuMaterial(WidgetTester tester) {
    return tester.widget<Material>(
      find.descendant(of: findMenuBarMenu(), matching: find.byType(Material)).first,
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

      expect(find.text(mainMenu[0]), findsOneWidget);
      expect(find.text(mainMenu[1]), findsOneWidget);
      expect(find.text(mainMenu[2]), findsOneWidget);
      expect(find.text(subMenu1[0]), findsNothing);
      expect(find.text(subSubMenu10[0]), findsNothing);
      expect(opened, isEmpty);

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(find.text(mainMenu[0]), findsOneWidget);
      expect(find.text(mainMenu[1]), findsOneWidget);
      expect(find.text(mainMenu[2]), findsOneWidget);
      expect(find.text(subMenu1[0]), findsOneWidget);
      expect(find.text(subMenu1[1]), findsOneWidget);
      expect(find.text(subMenu1[2]), findsOneWidget);
      expect(find.text(subSubMenu10[0]), findsNothing);
      expect(find.text(subSubMenu10[1]), findsNothing);
      expect(find.text(subSubMenu10[2]), findsNothing);
      expect(opened.last, equals(mainMenu[1]));
      opened.clear();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(find.text(mainMenu[0]), findsOneWidget);
      expect(find.text(mainMenu[1]), findsOneWidget);
      expect(find.text(mainMenu[2]), findsOneWidget);
      expect(find.text(subMenu1[0]), findsOneWidget);
      expect(find.text(subMenu1[1]), findsOneWidget);
      expect(find.text(subMenu1[2]), findsOneWidget);
      expect(find.text(subSubMenu10[0]), findsOneWidget);
      expect(find.text(subSubMenu10[1]), findsOneWidget);
      expect(find.text(subSubMenu10[2]), findsOneWidget);
      expect(opened.last, equals(subMenu1[1]));
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

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTWH(0, 0, 800, 48)));

      // Open and make sure things are the right size.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTWH(0, 0, 800, 48)));
      expect(tester.getRect(find.text(subMenu1[0])), equals(const Rect.fromLTRB(148.0, 73.0, 302.0, 87.0)));
      expect(tester.getRect(find.ancestor(of: find.text(subMenu1[0]), matching: findMenuBarMenu())),
          equals(const Rect.fromLTRB(124.0, 48.0, 386.0, 224.0)));
      expect(tester.getRect(findDivider()), equals(const Rect.fromLTRB(124.0, 104.0, 386.0, 120.0)));

      // Close and make sure it goes back where it was.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(tester.getRect(find.byType(MenuBar)), equals(const Rect.fromLTWH(0, 0, 800, 48)));
    });
    testWidgets('visual attributes can be set', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Column(
              children: <Widget>[
                MenuBar(
                  height: 50,
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
      expect(tester.getRect(findMenuTopLevelBar()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 50.0)));
      final Material material = getMenuBarMaterial(tester);
      expect(material.elevation, equals(10));
      expect(material.color, equals(Colors.red));
    });
    testWidgets('theme is honored', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: Builder(builder: (BuildContext context) {
              return MenuBarTheme(
                data: MenuBarTheme.of(context).copyWith(
                  barBackgroundColor: MaterialStateProperty.all<Color?>(Colors.green),
                  itemTextStyle: MaterialStateProperty.all<TextStyle?>(Theme.of(context).textTheme.titleMedium),
                  barElevation: MaterialStateProperty.all<double?>(20.0),
                  barHeight: 52.0,
                  menuBackgroundColor: MaterialStateProperty.all<Color?>(Colors.red),
                  menuElevation: MaterialStateProperty.all<double?>(15.0),
                  menuShape: MaterialStateProperty.all<ShapeBorder?>(const StadiumBorder()),
                  menuPadding: const EdgeInsets.all(10.0),
                ),
                child: Column(
                  children: <Widget>[
                    MenuBar(
                      menus: createTestMenus(onSelected: onSelected),
                    ),
                    const Expanded(child: Placeholder()),
                  ],
                ),
              );
            }),
          ),
        ),
      );

      // Open a test menu.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();
      expect(tester.getRect(findMenuTopLevelBar()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 52.0)));
      final Material menuBarMaterial = getMenuBarMaterial(tester);
      expect(menuBarMaterial.elevation, equals(20));
      expect(menuBarMaterial.color, equals(Colors.green));

      final Material subMenuMaterial = getSubMenuMaterial(tester);
      expect(tester.getRect(findMenuBarMenu()), equals(const Rect.fromLTRB(136.0, 50.0, 440.0, 230.0)));
      expect(subMenuMaterial.elevation, equals(15));
      expect(subMenuMaterial.color, equals(Colors.red));
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

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(opened, equals(<String>[mainMenu[1]]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));
      expect(opened, equals(<String>[subMenu1[1]]));
      expect(closed, isEmpty);
      opened.clear();
      closed.clear();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(opened, isEmpty);
      expect(closed, equals(<String>[subMenu1[1]]));
      opened.clear();
      closed.clear();

      await tester.tap(find.text(mainMenu[0]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(opened, equals(<String>[mainMenu[0]]));
      expect(closed, equals(<String>[mainMenu[1]]));
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

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.tap(find.text(subSubMenu10[0]));
      await tester.pump();

      expect(selected, equals(<String>[subSubMenu10[0]]));

      // Selecting a non-submenu item should close all the menus.
      expect(openPath, isNull);
      expect(find.text(subSubMenu10[0]), findsNothing);
      expect(find.text(subMenu1[1]), findsNothing);
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
                  label: mainMenu[0],
                  elevation: MaterialStateProperty.all<double?>(10.0),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  menus: <MenuItem>[
                    MenuItemGroup(
                      members: <MenuItem>[
                        MenuBarItem(
                          label: subMenu0[0],
                          semanticLabel: 'semanticLabel',
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

      await tester.tap(find.text(mainMenu[0]));
      await tester.pump();

      final MenuBar menuBar = tester.widget(find.byType(MenuBar));
      expect(
        menuBar.toStringDeep(),
        equalsIgnoringHashCodes(
          'MenuBar#00000\n'
          ' │ controller: _MenuBarController#00000\n'
          ' └MenuBarMenu#00000(Menu 0)(label: "Menu 0", backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336))), shape: MaterialStatePropertyAll(RoundedRectangleBorder(BorderSide(Color(0xff000000), 0.0, BorderStyle.none), BorderRadius.zero)), elevation: MaterialStatePropertyAll(10.0))\n'
          '  └MenuItemGroup(members: [MenuBarItem#00000(Sub Menu 00)(DISABLED, label: "Sub Menu 00", semanticLabel: "semanticLabel")])\n',
        ),
      );
    });
    testWidgets('diagnostics', (WidgetTester tester) async {
      const MenuBarItem item = MenuBarItem(
        label: 'label2',
        shortcut: SingleActivator(LogicalKeyboardKey.keyA),
      );
      final MenuBar menuBar = MenuBar(
        controller: MenuBarController(),
        enabled: false,
        backgroundColor: MaterialStateProperty.all(Colors.red),
        height: 40,
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
        equalsIgnoringHashCodes(
          <String>[
            'DISABLED',
            'controller: _MenuBarController#00000',
            'backgroundColor: MaterialStatePropertyAll(MaterialColor(primary value: Color(0xfff44336)))',
            'height: 40.0',
            'elevation: MaterialStatePropertyAll(10.0)'
          ].join('\n'),
        ),
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
                    shortcuts: <String, MenuSerializableShortcut>{
                      subSubMenu10[0]: const SingleActivator(
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

      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyA);

      expect(selected, equals(<String>[subSubMenu10[0]]));

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
                shortcuts: <String, MenuSerializableShortcut>{
                  subSubMenu10[0]: duplicateActivator,
                  subSubMenu10[1]: duplicateActivator,
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
                  label: mainMenu[0],
                  menus: <MenuItem>[
                    MenuBarItem(
                      label: subMenu1[0],
                      onSelected: sameCallback,
                      shortcut: sameShortcut,
                    ),
                    MenuBarItem(
                      label: subMenu1[1],
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
      await tester.tap(find.text(mainMenu[0]));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 00)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 101)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 102)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 103)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 12)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 00)'));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 12)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 103)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 102)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 101)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
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
      await tester.tap(find.text(mainMenu[0]));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarItem#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarItem#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarItem#00000(Sub Menu 10)'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 101)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 102)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 103)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 103)'));
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
      await tester.tap(find.text(mainMenu[0]));
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarItem#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 12)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarItem#00000(Sub Menu 12)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Go back, close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Move up, should close the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarItem#00000(Sub Menu 10)'));

      // Move down, should reopen the submenu.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Open the next submenu again.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 101)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 102)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 103)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 103)'));
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
      await hoverOver(tester, find.text(mainMenu[0]));
      await tester.pump();
      expect(focusedMenu, isNull);
      expect(openPath, isNull);

      // Have to open a menu initially to start things going.
      await tester.tap(find.text(mainMenu[0]));
      await tester.pumpAndSettle();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));

      // Hovering when the menu is already  open does nothing.
      await hoverOver(tester, find.text(mainMenu[0]));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 0)'));

      // Hovering over the other main menu items opens them now.
      await hoverOver(tester, find.text(mainMenu[2]));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));

      await hoverOver(tester, find.text(mainMenu[1]));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      // Hovering over the menu items focuses them.
      await hoverOver(tester, find.text(subMenu1[0]));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Menu 10)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1)'));

      await hoverOver(tester, find.text(subMenu1[1]));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarMenu#00000(Sub Menu 11)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      await hoverOver(tester, find.text(subSubMenu10[0]));
      await tester.pump();
      expect(focusedMenu, equalsIgnoringHashCodes('MenuBarItem#00000(Sub Sub Menu 100)'));
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));
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
                    shortcuts: <String, MenuSerializableShortcut>{
                      subSubMenu10[0]: const SingleActivator(
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
      expect(selected, equals(<String>[subSubMenu10[0]]));
      expect(closed, isEmpty);
      expect(opened, isEmpty);
      selected.clear();

      // Open a menu initially.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();
      expect(opened, equals(<String>[mainMenu[1], subMenu1[1]]));
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
                    shortcuts: <String, MenuSerializableShortcut>{
                      subSubMenu10[0]: const SingleActivator(
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
      expect(closed, equals(<String>[mainMenu[1], subMenu1[1]]));
      closed.clear();
      expect(opened, isEmpty);
      expect(selected, isEmpty);

      await tester.tap(find.text(mainMenu[1]));
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
                    shortcuts: <String, MenuSerializableShortcut>{
                      subSubMenu10[0]: const SingleActivator(
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
      expect(selected, equals(<String>[subSubMenu10[0]]));

      // The menu should again accept taps.
      await tester.tap(find.text(mainMenu[2]));
      await tester.pump();

      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 2)'));
      expect(closed, isEmpty);
      expect(opened, equals(<String>[mainMenu[2]]));
      // Item disabled by its parameter should still be disabled.
      final TextButton button =
          tester.widget(find.ancestor(of: find.text(subMenu2[0]), matching: find.byType(TextButton)));
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
                shortcuts: <String, MenuSerializableShortcut>{
                  subSubMenu10[0]: const SingleActivator(
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
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();
      expect(opened, equals(<String>[mainMenu[1], subMenu1[1]]));
      opened.clear();
      expect(openPath, equalsIgnoringHashCodes('MenuBarMenu#00000(Menu 1) > MenuBarMenu#00000(Sub Menu 11)'));

      // Close menus using the controller
      controller.closeAll();
      await tester.pump();

      // The menu should go away,
      expect(openPath, isNull);
      expect(closed, equals(<String>[mainMenu[1], subMenu1[1]]));
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
                shortcuts: <String, MenuSerializableShortcut>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.keyA, control: true),
                  subSubMenu10[1]: const SingleActivator(LogicalKeyboardKey.keyB, shift: true),
                  subSubMenu10[2]: const SingleActivator(LogicalKeyboardKey.keyC, alt: true),
                  subSubMenu10[3]: const SingleActivator(LogicalKeyboardKey.keyD, meta: true),
                },
              ),
            ),
          ),
        ),
      );

      // Open a menu initially.
      await tester.tap(find.text(mainMenu[1]));
      await tester.pump();

      await tester.tap(find.text(subMenu1[1]));
      await tester.pump();

      Text mnemonic0;
      Text mnemonic1;
      Text mnemonic2;
      Text mnemonic3;

      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
        case TargetPlatform.fuchsia:
        case TargetPlatform.linux:
          mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
          expect(mnemonic3.data, equals('Meta D'));
          break;
        case TargetPlatform.windows:
          mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
          expect(mnemonic0.data, equals('Ctrl A'));
          mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
          expect(mnemonic2.data, equals('Alt C'));
          mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
          expect(mnemonic3.data, equals('Win D'));
          break;
        case TargetPlatform.iOS:
        case TargetPlatform.macOS:
          mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
          expect(mnemonic0.data, equals('⌃ A'));
          mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
          expect(mnemonic1.data, equals('⇧ B'));
          mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
          expect(mnemonic2.data, equals('⌥ C'));
          mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
          expect(mnemonic3.data, equals('⌘ D'));
          break;
      }

      debugPrint('Updating tree');
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                shortcuts: <String, MenuSerializableShortcut>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.arrowRight),
                  subSubMenu10[1]: const SingleActivator(LogicalKeyboardKey.arrowLeft),
                  subSubMenu10[2]: const SingleActivator(LogicalKeyboardKey.arrowUp),
                  subSubMenu10[3]: const SingleActivator(LogicalKeyboardKey.arrowDown),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      debugPrint('Should be rebuilt now');

      mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
      expect(mnemonic0.data, equals('→'));
      mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
      expect(mnemonic1.data, equals('←'));
      mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
      expect(mnemonic2.data, equals('↑'));
      mnemonic3 = tester.widget(findMnemonic(subSubMenu10[3]));
      expect(mnemonic3.data, equals('↓'));

      // Try some weirder ones.
      await tester.pumpWidget(
        MaterialApp(
          home: Material(
            child: MenuBar(
              controller: controller,
              menus: createTestMenus(
                shortcuts: <String, MenuSerializableShortcut>{
                  subSubMenu10[0]: const SingleActivator(LogicalKeyboardKey.escape),
                  subSubMenu10[1]: const SingleActivator(LogicalKeyboardKey.fn),
                  subSubMenu10[2]: const SingleActivator(LogicalKeyboardKey.enter),
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      mnemonic0 = tester.widget(findMnemonic(subSubMenu10[0]));
      expect(mnemonic0.data, equals('Esc'));
      mnemonic1 = tester.widget(findMnemonic(subSubMenu10[1]));
      expect(mnemonic1.data, equals('Fn'));
      mnemonic2 = tester.widget(findMnemonic(subSubMenu10[2]));
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
                  label: mainMenu[0],
                  menus: <MenuItem>[
                    MenuBarItem(
                      leadingIcon: const Text('leadingIcon'),
                      label: subMenu0[0],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(mainMenu[0]));
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
                  label: mainMenu[0],
                  menus: <MenuItem>[
                    MenuBarItem(
                      label: subMenu0[0],
                      trailingIcon: const Text('trailingIcon'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text(mainMenu[0]));
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
                  label: mainMenu[0],
                  elevation: MaterialStateProperty.all<double?>(10.0),
                  backgroundColor: MaterialStateProperty.all(Colors.red),
                  menus: <MenuItem>[
                    MenuItemGroup(
                      members: <MenuItem>[
                        MenuBarItem(
                          label: subMenu0[0],
                          semanticLabel: 'semanticLabel',
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

      await tester.tap(find.text(mainMenu[0]));
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
                  label: mainMenu[0],
                  menus: <MenuItem>[
                    MenuBarItem(
                      label: subMenu1[0],
                      shortcut: allModifiers,
                    ),
                    MenuBarItem(
                      label: subMenu1[1],
                      shortcut: charShortcuts,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text(mainMenu[0]));
      await tester.pump();

      expect(find.text(allExpected), findsOneWidget);
      expect(find.text(charExpected), findsOneWidget);
    }, variant: TargetPlatformVariant.all());
  });
}

const List<String> mainMenu = <String>[
  'Menu 0',
  'Menu 1',
  'Menu 2',
];

const List<String> subMenu0 = <String>[
  'Sub Menu 00',
];

const List<String> subMenu1 = <String>[
  'Sub Menu 10',
  'Sub Menu 11',
  'Sub Menu 12',
];

const List<String> subSubMenu10 = <String>[
  'Sub Sub Menu 100',
  'Sub Sub Menu 101',
  'Sub Sub Menu 102',
  'Sub Sub Menu 103',
];

const List<String> subMenu2 = <String>[
  'Sub Menu 20',
];

List<MenuItem> createTestMenus({
  void Function(String)? onSelected,
  void Function(String)? onOpen,
  void Function(String)? onClose,
  Map<String, MenuSerializableShortcut> shortcuts = const <String, MenuSerializableShortcut>{},
  bool includeStandard = false,
}) {
  final List<MenuItem> result = <MenuItem>[
    MenuBarMenu(
      label: mainMenu[0],
      onOpen: onOpen != null ? () => onOpen(mainMenu[0]) : null,
      onClose: onClose != null ? () => onClose(mainMenu[0]) : null,
      menus: <MenuItem>[
        MenuBarItem(
          label: subMenu0[0],
          onSelected: onSelected != null ? () => onSelected(subMenu0[0]) : null,
          shortcut: shortcuts[subMenu0[0]],
        ),
      ],
    ),
    MenuBarMenu(
      label: mainMenu[1],
      onOpen: onOpen != null ? () => onOpen(mainMenu[1]) : null,
      onClose: onClose != null ? () => onClose(mainMenu[1]) : null,
      menus: <MenuItem>[
        MenuItemGroup(
          members: <MenuItem>[
            MenuBarItem(
              label: subMenu1[0],
              onSelected: onSelected != null ? () => onSelected(subMenu1[0]) : null,
              shortcut: shortcuts[subMenu1[0]],
            ),
          ],
        ),
        MenuBarMenu(
          label: subMenu1[1],
          onOpen: onOpen != null ? () => onOpen(subMenu1[1]) : null,
          onClose: onClose != null ? () => onClose(subMenu1[1]) : null,
          menus: <MenuItem>[
            MenuItemGroup(
              members: <MenuItem>[
                MenuBarItem(
                  label: subSubMenu10[0],
                  onSelected: onSelected != null ? () => onSelected(subSubMenu10[0]) : null,
                  shortcut: shortcuts[subSubMenu10[0]],
                ),
              ],
            ),
            MenuBarItem(
              label: subSubMenu10[1],
              onSelected: onSelected != null ? () => onSelected(subSubMenu10[1]) : null,
              shortcut: shortcuts[subSubMenu10[1]],
            ),
            MenuBarItem(
              label: subSubMenu10[2],
              onSelected: onSelected != null ? () => onSelected(subSubMenu10[2]) : null,
              shortcut: shortcuts[subSubMenu10[2]],
            ),
            MenuBarItem(
              label: subSubMenu10[3],
              onSelected: onSelected != null ? () => onSelected(subSubMenu10[3]) : null,
              shortcut: shortcuts[subSubMenu10[3]],
            ),
          ],
        ),
        MenuBarItem(
          label: subMenu1[2],
          onSelected: onSelected != null ? () => onSelected(subMenu1[2]) : null,
          shortcut: shortcuts[subMenu1[2]],
        ),
      ],
    ),
    MenuBarMenu(
      label: mainMenu[2],
      onOpen: onOpen != null ? () => onOpen(mainMenu[2]) : null,
      onClose: onClose != null ? () => onClose(mainMenu[2]) : null,
      menus: <MenuItem>[
        MenuBarItem(
          // Always disabled.
          label: subMenu2[0],
          shortcut: shortcuts[subMenu2[0]],
        ),
      ],
    ),
  ];
  return result;
}
