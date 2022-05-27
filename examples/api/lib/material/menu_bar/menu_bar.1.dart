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
  edit('Edit'),
  cut('Cut'),
  copy('Copy'),
  paste('Paste'),
  file('File'),
  open('Open'),
  quit('Quit'),
  save('Save'),
  saveAs('Save As...');

  const MenuSelection(this.label);
  final String label;
}


class Home extends StatelessWidget {
  const Home({super.key});

  void _onSelected(MenuSelection item) {
    debugPrint('Selected ${item.name}');
  }

  @override
  Widget build(BuildContext context) {
    // Because the platforms have different modifier conventions, we need to
    // select whether we want Ctrl or Meta for the modifier key on our
    // shortcuts.
    final bool isAppleOS;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        isAppleOS = false;
        break;
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        isAppleOS = true;
        break;
    }
    final bool meta = isAppleOS;
    final bool control = !isAppleOS;

    final bool hasAbout = PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.about);
    final bool hasQuit = PlatformProvidedMenuItem.hasMenu(PlatformProvidedMenuItemType.quit);

    return Column(
      children: <Widget>[
        MenuBar.adaptive(
          menus: <MenuItem>[
            MenuBarMenu(
              label: MenuSelection.file.label,
              menus: <MenuItem>[
                if (hasAbout) const PlatformProvidedMenuItem(type: PlatformProvidedMenuItemType.about),
                MenuItemGroup(
                  members: <MenuItem>[
                    MenuBarItem(
                      label: MenuSelection.open.label,
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
                      label: MenuSelection.save.label,
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
                      label: MenuSelection.saveAs.label,
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
              label: MenuSelection.edit.label,
              menus: <MenuItem>[
                MenuBarItem(
                  label: MenuSelection.cut.label,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyX,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(MenuSelection.cut),
                ),
                MenuBarItem(
                  label: MenuSelection.copy.label,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyC,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(MenuSelection.copy),
                ),
                MenuBarItem(
                  label: MenuSelection.paste.label,
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
