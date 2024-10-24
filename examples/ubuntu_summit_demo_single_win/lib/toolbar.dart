import 'package:flutter/material.dart';

/// A class for consolidating the definition of menu entries.
///
/// This sort of class is not required, but illustrates one way that defining
/// menus could be done.
class MenuEntry {
  const MenuEntry({required this.label, this.onPressed, this.menuChildren})
      : assert(menuChildren == null || onPressed == null,
            'onPressed is ignored if menuChildren are provided');
  final String label;

  final VoidCallback? onPressed;
  final List<MenuEntry>? menuChildren;

  static List<Widget> build(List<MenuEntry> selections) {
    Widget buildSelection(MenuEntry selection) {
      if (selection.menuChildren != null) {
        return SubmenuButton(
          menuChildren: MenuEntry.build(selection.menuChildren!),
          child: Text(selection.label),
        );
      }
      return MenuItemButton(
        onPressed: selection.onPressed,
        child: Text(selection.label),
      );
    }

    return selections.map<Widget>(buildSelection).toList();
  }

  static Map<MenuSerializableShortcut, Intent> shortcuts(
      List<MenuEntry> selections) {
    final Map<MenuSerializableShortcut, Intent> result =
        <MenuSerializableShortcut, Intent>{};
    for (final MenuEntry selection in selections) {
      if (selection.menuChildren != null) {
        result.addAll(MenuEntry.shortcuts(selection.menuChildren!));
      }
    }
    return result;
  }
}

const Map<String, Color> _kColorSelection = {
  "Red": Colors.red,
  "Green": Colors.green,
  "Purple": Colors.deepPurple,
  "Blue": Colors.blue,
  "Gray": Colors.grey,
  "Blue Gray": Colors.blueGrey,
  "Amber": Colors.amber,
  "Yellow": Colors.yellow,
  "Orange": Colors.orange,
  "White": Colors.white,
  "Black": Colors.black87,
  "Brown": Colors.brown,
  "Lime": Colors.lime,
  "Teal": Colors.teal,
  "Cyan": Colors.cyan,
  "Indigo": Colors.indigo
};

class Toolbar extends StatelessWidget {
  const Toolbar({super.key, required this.onBackgroundColorSelected});

  final void Function(Color) onBackgroundColorSelected;

  @override
  Widget build(BuildContext context) {
    Window? mainWindow = WindowContext.of(context)?.window;
    return Expanded(
      child: MenuBar(
        children: MenuEntry.build(_getMenus(mainWindow)),
      ),
    );
  }

  List<MenuEntry> _getMenus(Window? parent) {
    List<MenuEntry> entries = [];
    for (final kvp in _kColorSelection.entries) {
      entries.add(MenuEntry(
          label: kvp.key,
          onPressed: () {
            onBackgroundColorSelected(kvp.value);
          }));
    }

    final List<MenuEntry> result = <MenuEntry>[
      MenuEntry(
        label: 'File',
        menuChildren: <MenuEntry>[
          const MenuEntry(label: 'About'),
          MenuEntry(label: 'App Color', menuChildren: entries),
        ],
      ),
    ];

    return result;
  }
}
