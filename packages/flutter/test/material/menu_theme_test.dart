// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuController controller;
  void onPressed(TestMenu item) {}

  setUp(() {
    controller = MenuController();
  });

  tearDown(() {
    controller.closeAll();
  });

  Finder findMenuPanels(Axis orientation) {
    return find.byWidgetPredicate((Widget widget) {
      // ignore: avoid_dynamic_calls
      return widget.runtimeType.toString() == '_MenuPanel' && (widget as dynamic)._orientation == orientation;
    });
  }

  Finder findMenuBarPanel() {
    return findMenuPanels(Axis.horizontal);
  }

  Finder findSubmenuPanel() {
    return findMenuPanels(Axis.vertical);
  }

  Finder findSubMenuItem() {
    return find.descendant(of: findSubmenuPanel().last, matching: find.byType(MenuItemButton));
  }

  Material getMenuBarPanelMaterial(WidgetTester tester) {
    return tester.widget<Material>(find.descendant(of: findMenuBarPanel(), matching: find.byType(Material)).first);
  }

  Material getSubmenuPanelMaterial(WidgetTester tester) {
    return tester.widget<Material>(find.descendant(of: findSubmenuPanel(), matching: find.byType(Material)).first);
  }

  DefaultTextStyle getLabelStyle(WidgetTester tester, String labelText) {
    return tester.widget<DefaultTextStyle>(
      find
          .ancestor(
            of: find.text(labelText),
            matching: find.byType(DefaultTextStyle),
          )
          .first,
    );
  }

  testWidgets('theme is honored', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(builder: (BuildContext context) {
            return MenuBarTheme(
              data: const MenuBarThemeData(
                style: MenuStyle(
                  backgroundColor: MaterialStatePropertyAll<Color?>(Colors.green),
                  elevation: MaterialStatePropertyAll<double?>(20.0),
                ),
              ),
              child: MenuTheme(
                data: const MenuThemeData(
                  style: MenuStyle(
                    backgroundColor: MaterialStatePropertyAll<Color?>(Colors.red),
                    elevation: MaterialStatePropertyAll<double?>(15.0),
                    shape: MaterialStatePropertyAll<OutlinedBorder?>(StadiumBorder()),
                    padding: MaterialStatePropertyAll<EdgeInsetsGeometry>(
                      EdgeInsetsDirectional.all(10.0),
                    ),
                  ),
                ),
                child: Column(
                  children: <Widget>[
                    MenuBar(
                      children: createTestMenus(onPressed: onPressed),
                    ),
                    const Expanded(child: Placeholder()),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );

    // Open a test menu.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();
    expect(tester.getRect(findMenuBarPanel().first), equals(const Rect.fromLTRB(246.0, 0.0, 554.0, 48.0)));
    final Material menuBarMaterial = getMenuBarPanelMaterial(tester);
    expect(menuBarMaterial.elevation, equals(20));
    expect(menuBarMaterial.color, equals(Colors.green));

    final Material subMenuMaterial = getSubmenuPanelMaterial(tester);
    expect(tester.getRect(findSubmenuPanel()), equals(const Rect.fromLTRB(340.0, 48.0, 590.0, 212.0)));
    expect(subMenuMaterial.elevation, equals(15));
    expect(subMenuMaterial.color, equals(Colors.red));
  });

  testWidgets('Constructor parameters override theme parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(
            builder: (BuildContext context) {
              return MenuBarTheme(
                data: const MenuBarThemeData(
                  style: MenuStyle(
                    backgroundColor: MaterialStatePropertyAll<Color?>(Colors.green),
                    elevation: MaterialStatePropertyAll<double?>(20.0),
                  ),
                ),
                child: MenuTheme(
                  data: const MenuThemeData(
                    style: MenuStyle(
                      backgroundColor: MaterialStatePropertyAll<Color?>(Colors.red),
                      elevation: MaterialStatePropertyAll<double?>(15.0),
                      shape: MaterialStatePropertyAll<OutlinedBorder?>(StadiumBorder()),
                      padding: MaterialStatePropertyAll<EdgeInsetsGeometry>(
                        EdgeInsetsDirectional.all(10.0),
                      ),
                    ),
                  ),
                  child: Column(
                    children: <Widget>[
                      MenuBar(
                        style: const MenuStyle(
                          backgroundColor: MaterialStatePropertyAll<Color?>(Colors.blue),
                          elevation: MaterialStatePropertyAll<double?>(10.0),
                          padding: MaterialStatePropertyAll<EdgeInsetsGeometry>(
                            EdgeInsetsDirectional.all(12.0),
                          ),
                        ),
                        children: createTestMenus(
                          onPressed: onPressed,
                          menuBackground: Colors.cyan,
                          menuElevation: 18.0,
                          menuPadding: const EdgeInsetsDirectional.all(14.0),
                          menuShape: const BeveledRectangleBorder(),
                          itemBackground: Colors.amber,
                          itemForeground: Colors.grey,
                          itemOverlay: Colors.blueGrey,
                          itemPadding: const EdgeInsetsDirectional.all(11.0),
                          itemShape: const StadiumBorder(),
                        ),
                      ),
                      const Expanded(child: Placeholder()),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );

    // Open a test menu.
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    expect(tester.getRect(findMenuBarPanel().first), equals(const Rect.fromLTRB(238.0, 0.0, 562.0, 72.0)));
    final Material menuBarMaterial = getMenuBarPanelMaterial(tester);
    expect(menuBarMaterial.elevation, equals(10.0));
    expect(menuBarMaterial.color, equals(Colors.blue));

    final Material subMenuMaterial = getSubmenuPanelMaterial(tester);
    expect(tester.getRect(findSubmenuPanel()), equals(const Rect.fromLTRB(336.0, 60.0, 594.0, 232.0)));
    expect(subMenuMaterial.elevation, equals(18));
    expect(subMenuMaterial.color, equals(Colors.cyan));
    expect(subMenuMaterial.shape, equals(const BeveledRectangleBorder()));

    final Finder menuItem = findSubMenuItem();
    expect(tester.getRect(menuItem.first), equals(const Rect.fromLTRB(350.0, 74.0, 580.0, 122.0)));
    final Material menuItemMaterial = tester.widget<Material>(
        find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).first);
    expect(menuItemMaterial.color, equals(Colors.amber));
    expect(menuItemMaterial.elevation, equals(0.0));
    expect(menuItemMaterial.shape, equals(const StadiumBorder()));
    expect(getLabelStyle(tester, TestMenu.subMenu10.label).style.color, equals(Colors.grey));
    final ButtonStyle? textButtonStyle = tester
        .widget<TextButton>(find
            .ancestor(
              of: find.text(TestMenu.subMenu10.label),
              matching: find.byType(TextButton),
            )
            .first)
        .style;
    expect(textButtonStyle?.overlayColor?.resolve(<MaterialState>{MaterialState.hovered}), equals(Colors.blueGrey));
  });
}

enum TestMenu {
  mainMenu0('Menu 0'),
  mainMenu1('Menu 1'),
  mainMenu2('Menu 2'),
  subMenu00('Sub Menu 00'),
  subMenu10('Sub Menu 10'),
  subMenu11('Sub Menu 11'),
  subMenu12('Sub Menu 12'),
  subMenu20('Sub Menu 20'),
  subSubMenu100('Sub Sub Menu 100'),
  subSubMenu101('Sub Sub Menu 101'),
  subSubMenu102('Sub Sub Menu 102'),
  subSubMenu103('Sub Sub Menu 103');

  const TestMenu(this.label);
  final String label;
}

List<Widget> createTestMenus({
  void Function(TestMenu)? onPressed,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeStandard = false,
  Color? itemOverlay,
  Color? itemBackground,
  Color? itemForeground,
  EdgeInsetsDirectional? itemPadding,
  Color? menuBackground,
  EdgeInsetsDirectional? menuPadding,
  OutlinedBorder? menuShape,
  double? menuElevation,
  OutlinedBorder? itemShape,
}) {
  final MenuStyle menuStyle = MenuStyle(
    padding: menuPadding != null ? MaterialStatePropertyAll<EdgeInsetsGeometry>(menuPadding) : null,
    backgroundColor: menuBackground != null ? MaterialStatePropertyAll<Color>(menuBackground) : null,
    elevation: menuElevation != null ? MaterialStatePropertyAll<double>(menuElevation) : null,
    shape: menuShape != null ? MaterialStatePropertyAll<OutlinedBorder>(menuShape) : null,
  );
  final ButtonStyle itemStyle = ButtonStyle(
    padding: itemPadding != null ? MaterialStatePropertyAll<EdgeInsetsGeometry>(itemPadding) : null,
    shape: itemShape != null ? MaterialStatePropertyAll<OutlinedBorder>(itemShape) : null,
    foregroundColor: itemForeground != null ? MaterialStatePropertyAll<Color>(itemForeground) : null,
    backgroundColor: itemBackground != null ? MaterialStatePropertyAll<Color>(itemBackground) : null,
    overlayColor: itemOverlay != null ? MaterialStatePropertyAll<Color>(itemOverlay) : null,
  );
  final List<Widget> result = <Widget>[
    MenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu00) : null,
          shortcut: shortcuts[TestMenu.subMenu00],
          child: Text(TestMenu.subMenu00.label),
        ),
      ],
      child: Text(TestMenu.mainMenu0.label),
    ),
    MenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu1) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu1) : null,
      menuStyle: menuStyle,
      menuChildren: <Widget>[
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu10) : null,
          shortcut: shortcuts[TestMenu.subMenu10],
          style: itemStyle,
          child: Text(TestMenu.subMenu10.label),
        ),
        MenuButton(
          onOpen: onOpen != null ? () => onOpen(TestMenu.subMenu11) : null,
          onClose: onClose != null ? () => onClose(TestMenu.subMenu11) : null,
          menuChildren: <Widget>[
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu100) : null,
              shortcut: shortcuts[TestMenu.subSubMenu100],
              child: Text(TestMenu.subSubMenu100.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu101) : null,
              shortcut: shortcuts[TestMenu.subSubMenu101],
              child: Text(TestMenu.subSubMenu101.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu102) : null,
              shortcut: shortcuts[TestMenu.subSubMenu102],
              child: Text(TestMenu.subSubMenu102.label),
            ),
            MenuItemButton(
              onPressed: onPressed != null ? () => onPressed(TestMenu.subSubMenu103) : null,
              shortcut: shortcuts[TestMenu.subSubMenu103],
              child: Text(TestMenu.subSubMenu103.label),
            ),
          ],
          child: Text(TestMenu.subMenu11.label),
        ),
        MenuItemButton(
          onPressed: onPressed != null ? () => onPressed(TestMenu.subMenu12) : null,
          shortcut: shortcuts[TestMenu.subMenu12],
          child: Text(TestMenu.subMenu12.label),
        ),
      ],
      child: Text(TestMenu.mainMenu1.label),
    ),
    MenuButton(
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu2) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu2) : null,
      menuChildren: <Widget>[
        MenuItemButton(
          // Always disabled.
          shortcut: shortcuts[TestMenu.subMenu20],
          // Always disabled.
          child: Text(TestMenu.subMenu20.label),
        ),
      ],
      child: Text(TestMenu.mainMenu2.label),
    ),
  ];
  return result;
}
