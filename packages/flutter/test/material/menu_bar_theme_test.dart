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

  Finder findMenuTopLevelBar() {
    return find.byWidgetPredicate((Widget widget) => widget.runtimeType.toString() == '_MenuBarTopLevelBar');
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
    await tester.tap(find.text(TestMenu.mainMenu1.label));
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
  /// TODO(gspencergoog): add more tests...
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
}) {
  final List<MenuItem> result = <MenuItem>[
    MenuBarMenu(
      label: TestMenu.mainMenu0.label,
      onOpen: onOpen != null ? () => onOpen(TestMenu.mainMenu0) : null,
      onClose: onClose != null ? () => onClose(TestMenu.mainMenu0) : null,
      menus: <MenuItem>[
        MenuBarItem(
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
            MenuBarItem(
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
                MenuBarItem(
                  label: TestMenu.subSubMenu100.label,
                  onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu100) : null,
                  shortcut: shortcuts[TestMenu.subSubMenu100],
                ),
              ],
            ),
            MenuBarItem(
              label: TestMenu.subSubMenu101.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu101) : null,
              shortcut: shortcuts[TestMenu.subSubMenu101],
            ),
            MenuBarItem(
              label: TestMenu.subSubMenu102.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu102) : null,
              shortcut: shortcuts[TestMenu.subSubMenu102],
            ),
            MenuBarItem(
              label: TestMenu.subSubMenu103.label,
              onSelected: onSelected != null ? () => onSelected(TestMenu.subSubMenu103) : null,
              shortcut: shortcuts[TestMenu.subSubMenu103],
            ),
          ],
        ),
        MenuBarItem(
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
        MenuBarItem(
          // Always disabled.
          label: TestMenu.subMenu20.label,
          shortcut: shortcuts[TestMenu.subMenu20],
        ),
      ],
    ),
  ];
  return result;
}
