// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

/// A model for cascading menus
class MenuItemModel<T> {
  /// Creates a const menu model.
  const MenuItemModel(this.value, {this.activateCallback});

  /// The value that this menu item represents.
  final T value;

  /// The callback invoked if this menu item is triggered.
  final VoidCallback? activateCallback;

  /// Activates the menu item by invoking the associated intent with the given
  /// context.
  @mustCallSuper
  void invoke() {
    activateCallback?.call();
  }

  /// Whether this entry represents a particular value.
  /// Default implementation just compares with [value].
  bool represents(T? value) => value == this.value;
}

/// Creates a submenu.
class MenuModel<T> extends MenuItemModel<T> with ChangeNotifier {
  /// Creates a const menu model.
  MenuModel(T value, this._items, {VoidCallback? activateCallback})
      : super(value, activateCallback: activateCallback);

  /// The menu items that are children of this menu, in the order they appear.
  /// Visual order is affected by the layout anchor and direction of the
  /// [MenuBar] they are managed by. Returns a copy of the actual list, to avoid
  /// inadvertent modification of the order or contents without notifying
  /// listeners.
  List<MenuItemModel<T>> get items => _items.toList();
  final List<MenuItemModel<T>> _items;

  /// Whether or not this submenu is currently open.
  bool isOpen = false;

  /// Toggles whether or not this submenu is open.
  @override
  void invoke() {
    super.invoke();
    isOpen = !isOpen;
    notifyListeners();
  }

  /// Opens the sub menu if it is closed.
  void open() {
    if (!isOpen) {
      invoke();
    }
  }

  /// Closes the sub menu if it is open.
  void close() {
    if (isOpen) {
      invoke();
    }
  }

  /// Append an item at the end of this sub menu.
  void add(MenuItemModel<T> item) {
    _items.add(item);
    notifyListeners();
  }

  /// Insert an item at a particular index of this sub menu.
  void insert(int index, MenuItemModel<T> item) {
    _items.insert(index, item);
    notifyListeners();
  }

  /// Removes an item from the sub menu.
  /// Returns true if it found the item and removed it.
  bool remove(MenuItemModel<T> item) {
    final bool removed = _items.remove(item);
    notifyListeners();
    return removed;
  }

  /// Removes the item at `index`.
  void removeAt(int index) {
    _items.removeAt(index);
    notifyListeners();
  }

  /// Removes an item by value.
  /// Returns true if it found the item and removed it.
  bool removeByValue(T value) {
    bool removed = false;
    _items.removeWhere((MenuItemModel<T> item) {
      if (item.represents(value)) {
        removed = true;
        return true;
      }
      return false;
    });
    notifyListeners();
    return removed;
  }
}

/// A widget that serves as a container for cascading menus.
class MenuBar<T> extends StatefulWidget {
  /// A constructor for a cascading menu.
  const MenuBar(this.model, {Key? key}) : super(key: key);

  /// The root menu used to describe the cascading menus in this menu bar.
  /// The [MenuModel.items] in this model are treated as the top-level entries
  /// in the menu bar, and are rendered in a row.
  final MenuModel<T> model;

  @override
  _MenuBarState<T> createState() => _MenuBarState<T>();
}

class _MenuBarState<T> extends State<MenuBar<T>> {
  List<PopupMenuEntry<MenuItemModel<T>>> _generateMenus(MenuItemModel<T> model) {
    final List<PopupMenuEntry<MenuItemModel<T>>> items = <PopupMenuEntry<MenuItemModel<T>>>[];
    if (model is MenuModel<T>) {
      for (final MenuItemModel<T> item in model.items) {
        if (item is MenuModel<T>) {
          items.add(
            PopupMenuItem<MenuItemModel<T>>(
              value: item,
              child: PopupMenuButton<MenuItemModel<T>>(
                itemBuilder: (BuildContext context) {
                  return _generateMenus(item);
                },
                child: Text(item.value.toString()),
                onSelected: (MenuItemModel<T> value) {
                  value.invoke();
                },
              ),
            ),
          );
        } else {
          items.add(
            PopupMenuItem<MenuItemModel<T>>(
              value: item,
              child: Text(item.value.toString()),
            ),
          );
        }
      }
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> topLevelMenus = <Widget>[];
    for (final MenuItemModel<T> item in widget.model.items) {
      topLevelMenus.add(
        PopupMenuButton<MenuItemModel<T>>(
          itemBuilder: (BuildContext context) {
            return _generateMenus(item);
          },
          child: Text(
            item.value.toString(),
          ),
        ),
      );
    }
    return Row(children: topLevelMenus);
  }
}
