// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('defaults are used when no theme is specified.', (WidgetTester tester) async {

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
