// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.12

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

// ---------------------- Menu Widgets --------------------

class SubmenuButton<T> extends StatefulWidget {
  const SubmenuButton({
    Key? key,
    required this.label,
    this.enabled = true,
    this.onTap,
    this.icon,
  }) : super(key: key);

  final String label;
  final VoidCallback? onTap;
  final bool enabled;
  final IconData? icon;

  @override
  _SubmenuButtonState<T> createState() => _SubmenuButtonState<T>();
}

class _SubmenuButtonState<T> extends State<SubmenuButton<T>> {
  @override
  Widget build(BuildContext context) {
    assert(debugCheckHasMaterialLocalizations(context));
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: InkWell(
        onTap: widget.enabled ? widget.onTap : null,
        canRequestFocus: widget.enabled,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: <Widget>[
              if (widget.icon != null) Icon(widget.icon),
              SizedBox(height: 20, child: Text(widget.label)),
            ],
          ),
        ),
      ),
    );
  }
}

class MenuBarButton<T> extends StatefulWidget {
  const MenuBarButton({
    Key? key,
    required this.menuItem,
    this.enabled = true,
  }) : super(key: key);

  final MenuItem<T> menuItem;
  final bool enabled;

  @override
  _MenuBarButtonState<T> createState() => _MenuBarButtonState<T>();
}

class _MenuBarButtonState<T> extends State<MenuBarButton<T>> {
  bool get hasSubmenu => widget.menuItem.isNotEmpty;
  bool get showingSubmenu => hasSubmenu && widget.menuItem.isOpen;

  @override
  void dispose() {
    // widget.menuItem.removeSelectionListener(handleSelection);
    widget.menuItem.removeChangeListener(handleChange);
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // widget.menuItem.addSelectionListener(handleSelection);
    widget.menuItem.addChangeListener(handleChange);
  }

  void handleChange(MenuItem<T> item) => setState((){});

  // void handleSelection(MenuItem<T> item) {
  //   if (hasSubmenu) {
  //     print('Submenu $item selected');
  //     setState(() {
  //       if (showingSubmenu) {
  //         widget.menuItem.icon = Icons.arrow_drop_down;
  //       } else {
  //         widget.menuItem.icon = Icons.arrow_drop_up;
  //       }
  //     });
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    Widget child = SubmenuButton<T>(
      label: widget.menuItem.label,
      icon: hasSubmenu ? (showingSubmenu ? Icons.arrow_drop_down : Icons.arrow_drop_up) : null,
      enabled: widget.enabled,
      onTap: () => widget.menuItem.select(),
    );

    if (showingSubmenu) {
      child = Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          child,
          ...widget.menuItem.items.map<Widget>((MenuItem<T> item) {
            return Padding(
              padding: const EdgeInsetsDirectional.only(start: 10.0),
              child: MenuBarButton<T>(menuItem: item),
            );
          }),
        ],
      );
    }

    return child;
  }
}

/// A widget that serves as a container for cascading menus.
class MenuBar<T> extends StatefulWidget {
  /// A constructor for a cascading menu.
  const MenuBar(this.model, {Key? key}) : super(key: key);

  /// The root menu used to describe the cascading menus in this menu bar.
  /// The [MenuItem.items] in this model are treated as the top-level entries
  /// in the menu bar, and are rendered in a row.
  final MenuItem<T> model;

  @override
  _MenuBarState<T> createState() => _MenuBarState<T>();
}

class _MenuBarState<T> extends State<MenuBar<T>> {
  @override
  Widget build(BuildContext context) {
    final List<Widget> topLevelMenus = <Widget>[];
    for (final MenuItem<T> item in widget.model.items) {
      topLevelMenus.add(MenuBarButton<T>(menuItem: item));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: topLevelMenus,
    );
  }
}

// -------------------------- Actions ------------------------------

class MenuSelectIntent extends SelectIntent {
  const MenuSelectIntent(this.item);
  final MenuItem<dynamic> item;
}

class MenuSelectAction<T> extends SelectAction {
  @override
  Object? invoke(covariant MenuSelectIntent intent) {
    print('Selected menu item ${intent.item}');
  }
}

// --------------------------- Custom Menu Nodes -----------------------

typedef ContextCallback = BuildContext Function();

class Node<T> extends MenuItem<T> {
  Node(
    T value,
    this.contextCallback, {
    required String description,
    List<Node<T>>? items,
    this.intent,
  }) : super(
          value,
          description: description,
          items: items ?? <Node<T>>[],
        ) {
    selectCallback = _onSelect;
  }

  final ContextCallback contextCallback;
  final Intent? intent;

  void _onSelect(MenuItem<T> item) {
    Actions.invoke(
      contextCallback(),
      intent ?? MenuSelectIntent(this),
    );
  }
}

class SubmenuNode<T> extends Node<T> {
  SubmenuNode(
    T value,
    ContextCallback contextCallback, {
    required String description,
    List<Node<T>>? items,
  }) : super(
          value,
          contextCallback,
          intent: DoNothingIntent(),
          description: description,
          items: items ?? <Node<T>>[],
        );
}

// ----------------------- App -----------------------

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  late Node<String> menu;

  @override
  void initState() {
    super.initState();
    menu = SubmenuNode<String>('root', () => context,
        description: 'Root Menu Node',
        items: <Node<String>>[
          Node<String>('root1', () => context,
              description: 'Root Menu Entry 1'),
          SubmenuNode<String>(
            'parent1',
            () => context,
            description: 'Cascading Menu Parent 1',
            items: <Node<String>>[
              Node<String>('child1', () => context,
                  description: 'Child Menu Entry 1'),
              Node<String>('child2', () => context,
                  description: 'Child Menu Entry 2'),
              SubmenuNode<String>(
                'parent2',
                () => context,
                description: 'Cascading Menu Parent 2',
                items: <Node<String>>[
                  Node<String>('child3', () => context,
                      description: 'Child Menu Entry 3'),
                  Node<String>('child4', () => context,
                      description: 'Child Menu Entry 4'),
                ],
              ),
            ],
          ),
          Node<String>('rootEntry2', () => context,
              description: 'Root Menu Entry 2'),
        ]);
    print('Initial menu model:\n${menu.toStringDeep()}');
    menu.added();
    menu.addChangeListener(_onChange);
    menu.addSelectionListener(_handleSelection);
  }

  void _handleSelection(MenuItem<String> item) {
    print('Got Selection for $item');
    if (item.isEmpty) {
      menu.closeAll();
    }
  }

  void _onChange(MenuItem<String> item) {
    print('${item.value} (${item.description}) changed');
    print('Model: ${menu.toStringDeep()}');
  }

  @override
  void dispose() {
    menu.removeChangeListener(_onChange);
    menu.removeSelectionListener(_handleSelection);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.topStart,
      child: MenuBar<String>(menu),
    );
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Material(
        child: Actions(
          actions: <Type, Action<Intent>>{
            MenuSelectIntent: MenuSelectAction<String>(),
          },
          child: const MyHomePage(),
        ),
      ),
    );
  }
}
