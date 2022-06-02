// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// Example for MenuBar.adaptive.

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MaterialApp(
    title: 'Adaptive Menu Sample',
    home: Material(child: MenuApp()),
  ));
}

enum MenuSelection {
  about('About'),
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

class MenuApp extends StatelessWidget {
  const MenuApp({super.key});

  void _onSelected(BuildContext context, MenuSelection item) {
    debugPrint('Selected ${item.name}');
    switch (item) {
      case MenuSelection.about:
        showAboutDialog(
          context: context,
          applicationName: 'MenuBar Sample',
          applicationVersion: '1.0.0',
        );
        break;
      case MenuSelection.edit:
      case MenuSelection.cut:
      case MenuSelection.copy:
      case MenuSelection.paste:
      case MenuSelection.file:
      case MenuSelection.open:
      case MenuSelection.save:
      case MenuSelection.saveAs:
        break;
      case MenuSelection.quit:
        exit(0);
    }
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

    return Column(
      children: <Widget>[
        MenuBar.adaptive(
          menus: <MenuBarItem>[
            MenuBarMenu(
              label: MenuSelection.file.label,
              menus: <MenuBarItem>[
                MenuBarButton(
                  label: MenuSelection.about.label,
                  onSelected: () {
                    _onSelected(context, MenuSelection.about);
                  },
                ),
                MenuItemGroup(
                  members: <MenuBarItem>[
                    MenuBarButton(
                      label: MenuSelection.open.label,
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyO,
                        control: control,
                        meta: meta,
                      ),
                      onSelected: () {
                        _onSelected(context, MenuSelection.open);
                      },
                    ),
                    MenuBarButton(
                      label: MenuSelection.save.label,
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyS,
                        control: control,
                        meta: meta,
                      ),
                      onSelected: () {
                        _onSelected(context, MenuSelection.save);
                      },
                    ),
                    MenuBarButton(
                      label: MenuSelection.saveAs.label,
                      shortcut: SingleActivator(
                        LogicalKeyboardKey.keyS,
                        shift: true,
                        control: control,
                        meta: meta,
                      ),
                      onSelected: () {
                        _onSelected(context, MenuSelection.saveAs);
                      },
                    ),
                  ],
                ),
                MenuBarButton(
                  label: MenuSelection.quit.label,
                  onSelected: () {
                    _onSelected(context, MenuSelection.quit);
                  },
                ),
              ],
            ),
            MenuBarMenu(
              label: MenuSelection.edit.label,
              menus: <MenuBarItem>[
                MenuBarButton(
                  label: MenuSelection.cut.label,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyX,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(context, MenuSelection.cut),
                ),
                MenuBarButton(
                  label: MenuSelection.copy.label,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyC,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(context, MenuSelection.copy),
                ),
                MenuBarButton(
                  label: MenuSelection.paste.label,
                  shortcut: SingleActivator(
                    LogicalKeyboardKey.keyV,
                    control: control,
                    meta: meta,
                  ),
                  onSelected: () => _onSelected(context, MenuSelection.paste),
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
