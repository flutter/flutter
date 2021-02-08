// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// A model for cascading menus
class MenuItem<T> {
  /// Creates a const menu model.
  const MenuItem(
    this.model,
    this.value, {
    this.description,
    this.activateCallback,
    this.icon,
  });

  /// Model that this entry blongs to.
  final MenuModel<T> model;

  /// The value that this menu item represents.w
  final T value;

  /// The label displayed on the entry for this item in the menu. Defaults to
  /// the string representation of [value].
  String get label => value.toString();

  /// An optional string description for this model.
  ///
  /// This is meant to be a slightly longer description than the label, telling
  /// the user what this item represents. For example, this can be used when
  /// describing the menu item in a UI for assigning a shortcut.
  final String? description;

  /// The callback invoked if this menu item is triggered.
  final VoidCallback? activateCallback;

  /// The optional icon to place before the label in the menu.
  final IconData? icon;

  /// Activates the menu item by invoking the associated callback.
  @mustCallSuper
  void invoke() {
    activateCallback?.call();
  }

  /// Whether this entry represents a particular value. The default
  /// implementation just compares the given `testValue` with [value].
  bool represents(T? testValue) => testValue == value;
}

/// Represents a submenu.
class SubmenuItem<T> extends MenuItem<T> {
  /// Creates a const menu model.
  SubmenuItem(
    MenuModel<T> model,
    T value, {
    required String description,
    List<MenuItem<T>>? items,
    VoidCallback? activateCallback,
  })  : _items = items ?? <MenuItem<T>>[],
        super(
          model,
          value,
          description: description,
          activateCallback: activateCallback,
        );

  /// The menu items that are children of this menu, in the order they appear.
  /// Visual order is affected by the layout anchor and direction of the
  /// [MenuBar] they are managed by. Returns a copy of the actual list, to avoid
  /// inadvertent modification of the order or contents without notifying
  /// listeners.
  List<MenuItem<T>> get items => _items.toList();
  final List<MenuItem<T>> _items;
  set items(List<MenuItem<T>> value) {
    if (value != _items) {
      _items.clear();
      _items.addAll(value);
      model.notifyListeners(this);
    }
  }

  /// Returns the `i`th element in the list of child menu items.
  MenuItem<T> operator [](int i) => _items[i];

  /// Returns the number of child menu items.
  int get length => items.length;

  /// Returns true if the list is empty
  bool get isEmpty => items.isEmpty;

  /// Returns true if the list is not empty.
  bool get isNotEmpty => items.isNotEmpty;

  /// Whether or not this submenu is currently open.
  bool isOpen = false;

  /// Calling [invoke] on a [SubmenuItem] toggles whether or not this
  /// submenu is open.
  @override
  void invoke() {
    super.invoke();
    isOpen = !isOpen;
    model.notifyListeners(this);
  }

  /// Opens this sub menu if it is closed.
  /// Does not open any sub menus of this sub menu.
  void open() {
    if (!isOpen) {
      invoke();
    }
  }

  /// Closes this sub menu if it is open.
  /// Does not close any parent menus.
  void close() {
    if (isOpen) {
      invoke();
    }
  }

  /// Append an item at the end of this sub menu.
  void add(MenuItem<T> item) {
    _items.add(item);
  }

  /// Insert an item at a particular index of this sub menu.
  void insert(int index, MenuItem<T> item) {
    _items.insert(index, item);
    model.notifyListeners(this);
  }

  /// Removes an item from the sub menu.
  /// Returns true if it found the item and removed it.
  bool remove(MenuItem<T> item) {
    final bool removed = _items.remove(item);
    model.notifyListeners(this);
    return removed;
  }

  /// Removes the item at `index`.
  void removeAt(int index) {
    _items.removeAt(index);
    model.notifyListeners(this);
  }

  /// Removes an item by value.
  /// Returns true if it found an and removed it.
  bool removeByValue(T value) {
    bool removed = false;
    _items.removeWhere((MenuItem<T> item) {
      if (item.represents(value)) {
        removed = true;
        return true;
      }
      return false;
    });
    model.notifyListeners(this);
    return removed;
  }
}

class MenuModel<T> {
  /// Creates a const menu model.
  MenuModel({
    required T rootValue,
    List<MenuItem<T>>? items,
  }) {
    root = SubmenuItem<T>(this, rootValue, description: '', items: items);
  }

  final List<ValueChanged<MenuItem<T>>> _listeners =
      <ValueChanged<MenuItem<T>>>[];

  /// Register a listener that is called every time the model changes.
  ///
  /// Listeners can be removed with [removeListener].
  void addListener(ValueChanged<MenuItem<T>> listener) {
    _listeners.add(listener);
  }

  /// Stop calling the given listener every time the model changes.
  ///
  /// Listeners can be added with [addListener].
  void removeListener(ValueChanged<MenuItem<T>> listener) {
    _listeners.remove(listener);
  }

  late final SubmenuItem<T> root;

  void notifyListeners(MenuItem<T> item) {
    // Send the event to passive listeners.
    for (final ValueChanged<MenuItem<T>> listener
        in List<ValueChanged<MenuItem<T>>>.from(_listeners)) {
      if (_listeners.contains(listener)) {
        listener(item);
      }
    }
  }
}

// =============================================================================

class ChildlessMenuBarButton<T> extends PopupMenuItem<T> {
  const ChildlessMenuBarButton({
    Key? key,
    required T value,
    bool enabled = true,
    double height = kMinInteractiveDimension,
    TextStyle? textStyle,
    MouseCursor? mouseCursor,
    required this.onSelected,
    required Widget child,
  }) : super(
            key: key,
            value: value,
            enabled: enabled,
            height: height,
            textStyle: textStyle,
            mouseCursor: mouseCursor,
            child: child);

  final PopupMenuItemSelected<T>? onSelected;

  @override
  PopupMenuItemState<T, PopupMenuItem<T>> createState() =>
      ChildlessMenuBarButtonState<T>();
}

class ChildlessMenuBarButtonState<T>
    extends PopupMenuItemState<T, PopupMenuItem<T>> {
  @override
  @protected
  void handleTap() {
    if (widget.value == null) {
      return;
    }
    // Since this button will not be in a submenu, just call the onSelected from
    // the widget.
    // ignore: null_check_on_nullable_type_parameter
    (widget as ChildlessMenuBarButton<T>).onSelected?.call(widget.value!);
  }

  @override
  Widget build(BuildContext context) {
    final bool enableFeedback =
        PopupMenuTheme.of(context).enableFeedback ?? true;

    assert(debugCheckHasMaterialLocalizations(context));

    return InkWell(
      onTap: widget.enabled ? handleTap : null,
      canRequestFocus: widget.enabled,
      enableFeedback: enableFeedback,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          return UnconstrainedBox(
            constrainedAxis: Axis.horizontal,
            child: LimitedBox(
              maxHeight: constraints.maxHeight,
              child: UnconstrainedBox(child: super.build(context)),
            ),
          );
        },
      ),
    );
  }
}

class MenuBarButton<T> extends StatelessWidget {
  const MenuBarButton({Key? key, required this.model}) : super(key: key);

  final MenuItem<T> model;

  bool get hasSubmenu => model is SubmenuItem<T>;

  List<PopupMenuEntry<MenuItem<T>>> _generateSubMenuItems(SubmenuItem<T> menu) {
    final List<PopupMenuEntry<MenuItem<T>>> items =
        <PopupMenuEntry<MenuItem<T>>>[];
    for (final MenuItem<T> item in menu.items) {
      items.add(
        PopupMenuItem<MenuItem<T>>(
          value: item,
          child: Text(
            item.value.toString(),
          ),
        ),
      );
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    if (hasSubmenu) {
      return PopupMenuButton<MenuItem<T>>(
        itemBuilder: (BuildContext context) {
          return _generateSubMenuItems(model as SubmenuItem<T>);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(model.value.toString()),
        ),
        onSelected: (MenuItem<T> value) {
          value.invoke();
        },
      );
    } else {
      return ChildlessMenuBarButton<T>(
          value: model.value,
          onSelected: (T value) {
            model.invoke();
          },
          child: Text(model.value.toString()));
    }
  }
}

/// A widget that serves as a container for cascading menus.
class MenuBar<T> extends StatelessWidget {
  /// A constructor for a cascading menu.
  const MenuBar(this.model, {Key? key}) : super(key: key);

  /// The root menu used to describe the cascading menus in this menu bar.
  /// The [SubmenuItem.items] in this model are treated as the top-level entries
  /// in the menu bar, and are rendered in a row.
  final MenuModel<T> model;

  @override
  Widget build(BuildContext context) {
    final List<Widget> topLevelMenus = <Widget>[];
    for (final MenuItem<T> item in model.root.items) {
      topLevelMenus.add(MenuBarButton<T>(model: item));
    }
    return Row(children: topLevelMenus);
  }
}

class Node extends MenuItem<String> {
  Node(
    MenuModel<String> owner,
    String name, {
    required String description,
  }) : super(
          owner,
          name,
          description: description,
          activateCallback: () {
            print('$name called');
          },
        );
}

class SubmenuNode extends SubmenuItem<String> {
  SubmenuNode(
    MenuModel<String> owner,
    String name, {
    required String description,
    List<MenuItem<String>>? items,
  }) : super(
          owner,
          name,
          description: description,
          items: items,
          activateCallback: () {
            print('$name called');
          },
        );
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late MenuModel<String> menu;

  @override
  void initState() {
    super.initState();
    menu = MenuModel<String>(rootValue: 'root');
    menu.root.items = <MenuItem<String>>[
      Node(menu, 'rootEntry1', description: 'Root Menu Entry 1'),
      SubmenuNode(
        menu,
        'parent1',
        description: 'Cascading Menu Parent 1',
        items: <MenuItem<String>>[
          Node(menu, 'child1', description: 'Child Menu Entry 1'),
          Node(menu, 'child2', description: 'Child Menu Entry 2'),
          SubmenuNode(
            menu,
            'parent2',
            description: 'Cascading Menu Parent 2',
            items: <MenuItem<String>>[
              Node(menu, 'child3', description: 'Child Menu Entry 3'),
              Node(menu, 'child4', description: 'Child Menu Entry 4'),
            ],
          ),
        ],
      ),
      Node(menu, 'rootEntry2', description: 'Root Menu Entry 2'),
    ];
    menu.addListener((MenuItem<String> item) =>
        print('${item.value} (${item.description}) changed'));
  }

  @override
  Widget build(BuildContext context) {
    return Align(
        alignment: AlignmentDirectional.topStart, child: MenuBar<String>(menu));
  }
}

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: Material(child: MyHomePage()));
  }
}
