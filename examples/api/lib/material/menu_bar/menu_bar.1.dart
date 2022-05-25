// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Example for MenuBar.adaptive.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Adaptive Menu Sample',
    home: Material(child: Home()),
  ));
}

enum MenuSelection {
  edit,
  cut,
  copy,
  paste,
  file,
  open,
  quit,
  save,
  saveAs,
}

String getLabel(MenuSelection selection) {
  // Use a switch so that the analyzer will warn us if we aren't handling a
  // case.
  switch (selection) {
    case MenuSelection.edit:
      return 'Edit';
    case MenuSelection.cut:
      return 'Cut';
    case MenuSelection.copy:
      return 'Copy';
    case MenuSelection.paste:
      return 'Paste';
    case MenuSelection.file:
      return 'File';
    case MenuSelection.open:
      return 'Open';
    case MenuSelection.quit:
      return 'Quit';
    case MenuSelection.save:
      return 'Save';
    case MenuSelection.saveAs:
      return 'Save As...';
  }
}

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isPlatformMenu = false;
  TextDirection textDirection = TextDirection.ltr;
  bool enabled = true;
  bool checked = false;

  void _onSelected(MenuSelection item) {
    debugPrint('Activated ${item.name}');
  }

  @override
  Widget build(BuildContext context) {
    final bool isMacOS = defaultTargetPlatform == TargetPlatform.macOS;
    final bool meta = isMacOS;
    final bool control = !meta;
    final bool hasAbout = PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about);
    final bool hasQuit = PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit);

    return Column(
      children: <Widget>[
        MenuBar.adaptive(
          enabled: enabled,
          menus: <MenuItem>[
            MenuBarMenu(
              label: getLabel(MenuSelection.file),
              menus: <MenuItem>[
                if (hasAbout) const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
                MenuItemGroup(
                  members: <MenuItem>[
                    MenuBarItem(
                      label: getLabel(MenuSelection.open),
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyO,
                        control: control,
                        meta: meta,
                      ),
                      onSelected: () {
                        _onSelected(MenuSelection.open);
                      },
                    ),
                    MenuBarItem(
                      label: getLabel(MenuSelection.save),
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyS,
                        control: control,
                        meta: meta,
                      ),
                      onSelected: () {
                        _onSelected(MenuSelection.save);
                      },
                    ),
                    MenuBarItem(
                      label: getLabel(MenuSelection.saveAs),
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyS,
                        shift: true,
                        control: control,
                        meta: meta,
                      ),
                      onSelected: () {
                        _onSelected(MenuSelection.saveAs);
                      },
                    ),
                  ],
                ),
                if (hasQuit) const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.quit),
              ],
            ),
            MenuBarMenu(
              label: getLabel(MenuSelection.edit),
              menus: <MenuItem>[
                MenuBarItem(
                  label: getLabel(MenuSelection.cut),
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyX,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(MenuSelection.cut),
                ),
                MenuBarItem(
                  label: getLabel(MenuSelection.copy),
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyC,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(MenuSelection.copy),
                ),
                MenuBarItem(
                  label: getLabel(MenuSelection.paste),
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyV,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(MenuSelection.paste),
                ),
              ],
            ),
          ],
        ),
        const Expanded(
          child: Center(
            child: Text('Body'),
          ),
        ),
      ],
    );
  }
}
