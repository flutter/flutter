// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late MenuBarController controller;
  void onSelected(TestMenu item) {}

  setUp(() {
    controller = MenuBarController();
  });

  tearDown(() {
    controller.closeAll();
  });

  Finder findMenuBarMenu() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarMenuList');
  }

  Finder findMenuBarMenuMaterial() {
    return find.ancestor(of: findMenuBarMenu().last, matching: find.byType(Material)).first;
  }

  Finder findMenuTopLevelBar() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarTopLevelBar');
  }

  Finder findMenuTopLevelBarMaterial() {
    return find.descendant(of: findMenuTopLevelBar(), matching: find.byType(Material)).first;
  }

  Finder findSubMenuItem() {
    return find.descendant(of: findMenuBarMenu().last, matching: find.byType(MenuBarButton));
  }

  Material getMenuTopLevelBarMaterial(WidgetTester tester) {
    return tester.widget<Material>(findMenuTopLevelBarMaterial());
  }

  Material getMenuBarMenuMaterial(WidgetTester tester) {
    return tester.widget<Material>(findMenuBarMenuMaterial().first);
  }

  DefaultTextStyle getLabelStyle(WidgetTester tester, String labelText) {
    return tester.widget<DefaultTextStyle>(
      find.ancestor(
        of: find.text(labelText),
        matching: find.byType(DefaultTextStyle),
      ).first,
    );
  }

  testWidgets('theme is honored', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(builder: (BuildContext context) {
            return MenuTheme(
              data: MenuTheme.of(context).copyWith(
                barBackgroundColor: MaterialStateProperty.all<Color?>(Colors.green),
                itemTextStyle: MaterialStateProperty.all<TextStyle?>(Theme.of(context).textTheme.titleMedium),
                barElevation: MaterialStateProperty.all<double?>(20.0),
                barMinimumHeight: 52.0,
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
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();
    expect(tester.getRect(findMenuTopLevelBar()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 52.0)));
    final Material menuBarMaterial = getMenuTopLevelBarMaterial(tester);
    expect(menuBarMaterial.elevation, equals(20));
    expect(menuBarMaterial.color, equals(Colors.green));

    final Material subMenuMaterial = getMenuBarMenuMaterial(tester);
    expect(tester.getRect(findMenuBarMenuMaterial().last), equals(const Rect.fromLTRB(108.0, 50.0, 412.0, 230.0)));
    expect(subMenuMaterial.elevation, equals(15));
    expect(subMenuMaterial.color, equals(Colors.red));
  });

  testWidgets('Constructor parameters override theme parameters', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: Builder(builder: (BuildContext context) {
            return MenuTheme(
              data: MenuTheme.of(context).copyWith(
                barBackgroundColor: MaterialStateProperty.all<Color?>(Colors.green),
                itemTextStyle: MaterialStateProperty.all<TextStyle?>(Theme.of(context).textTheme.titleMedium),
                barElevation: MaterialStateProperty.all<double?>(20.0),
                barMinimumHeight: 52.0,
                menuBackgroundColor: MaterialStateProperty.all<Color?>(Colors.red),
                menuElevation: MaterialStateProperty.all<double?>(15.0),
                menuShape: MaterialStateProperty.all<ShapeBorder?>(const StadiumBorder()),
                menuPadding: const EdgeInsets.all(10.0),
              ),
              child: Column(
                children: <Widget>[
                  MenuBar(
                    menus: createTestMenus(
                      onSelected: onSelected,
                      menuBackground: Colors.cyan,
                      menuElevation: 18.0,
                      menuPadding: const EdgeInsets.all(14.0),
                      menuShape: const BeveledRectangleBorder(),
                      itemBackground: Colors.amber,
                      itemForeground: Colors.grey,
                      itemOverlay: Colors.blueGrey,
                      itemPadding: const EdgeInsets.all(11.0),
                      itemShape: const BeveledRectangleBorder(),
                    ),
                    backgroundColor: MaterialStateProperty.all<Color?>(Colors.blue),
                    minimumHeight: 50.0,
                    elevation: MaterialStateProperty.all<double?>(10.0),
                    padding: const EdgeInsets.all(12.0),
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
    await tester.tap(find.text(TestMenu.mainMenu1.label));
    await tester.pump();

    expect(tester.getRect(findMenuTopLevelBar()), equals(const Rect.fromLTRB(0.0, 0.0, 800.0, 74.0)));
    final Material menuBarMaterial = getMenuTopLevelBarMaterial(tester);
    expect(menuBarMaterial.elevation, equals(10.0));
    expect(menuBarMaterial.color, equals(Colors.blue));

    final Material subMenuMaterial = getMenuBarMenuMaterial(tester);
    expect(tester.getRect(findMenuBarMenuMaterial().last), equals(const Rect.fromLTRB(116.0, 61.0, 428.0, 249.0)));
    expect(subMenuMaterial.elevation, equals(15));
    expect(subMenuMaterial.color, equals(Colors.cyan));
    expect(subMenuMaterial.shape, equals(const BeveledRectangleBorder()));

    final Finder menuItem = findSubMenuItem();
    expect(tester.getRect(menuItem.first), equals(const Rect.fromLTRB(130.0, 75.0, 414.0, 123.0)));
    final Material menuItemMaterial = tester.widget<Material>(find.ancestor(of: find.text(TestMenu.subMenu10.label), matching: find.byType(Material)).first);
    expect(menuItemMaterial.color, equals(Colors.amber));
    expect(menuItemMaterial.elevation, equals(0.0));
    expect(menuItemMaterial.shape, equals(const BeveledRectangleBorder()));
    expect(getLabelStyle(tester, TestMenu.subMenu10.label).style.color, equals(Colors.grey));
    final ButtonStyle? textButtonStyle = tester.widget<TextButton>(find.ancestor(
      of: find.text(TestMenu.subMenu10.label),
      matching: find.byType(TextButton),
    ).first).style;
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

List<MenuItem> createTestMenus({
  void Function(TestMenu)? onSelected,
  void Function(TestMenu)? onOpen,
  void Function(TestMenu)? onClose,
  Map<TestMenu, MenuSerializableShortcut> shortcuts = const <TestMenu, MenuSerializableShortcut>{},
  bool includeStandard = false,
  Color? itemOverlay,
  Color? itemBackground,
  Color? itemForeground,
  EdgeInsets? itemPadding,
  Color? menuBackground,
  EdgeInsets? menuPadding,
  ShapeBorder? menuShape,
  double? menuElevation,
  OutlinedBorder? itemShape,
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
      padding: menuPadding,
      backgroundColor: menuBackground != null ? MaterialStatePropertyAll<Color?>(menuBackground) : null,
      elevation: menuElevation != null ? MaterialStatePropertyAll<double?>(menuElevation) : null,
      shape: menuShape != null ? MaterialStatePropertyAll<ShapeBorder?>(menuShape) : null,
      menus: <MenuItem>[
        MenuItemGroup(
          members: <MenuItem>[
            MenuBarButton(
              label: TestMenu.subMenu10.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subMenu10) : null,
              shortcut: shortcuts[TestMenu.subMenu10],
              padding: itemPadding,
              shape: itemShape != null ? MaterialStatePropertyAll<OutlinedBorder?>(itemShape) : null,
              foregroundColor: itemForeground != null ? MaterialStatePropertyAll<Color?>(itemForeground) : null,
              backgroundColor: itemBackground != null ? MaterialStatePropertyAll<Color?>(itemBackground) : null,
              overlayColor: itemOverlay != null ? MaterialStatePropertyAll<Color?>(itemOverlay) : null,
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
  ];
  return result;
}
