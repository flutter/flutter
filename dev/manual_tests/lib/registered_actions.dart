// Copyright 2014 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

// @dart = 2.13

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class Item {
  const Item(this.name);

  final String name;

  @override
  String toString() {
    return name;
  }
}

class Model extends ChangeNotifier {
  Model()
      : items = <Item>[],
        selectedItems = <Item>{};

  final List<Item> items;
  final Set<Item> selectedItems;

  void toggleSelect(Item item) {
    if (selectedItems.contains(item)) {
      deselect(item);
    } else {
      select(item);
    }
  }

  void select(Item item) {
    print('$item selected.');
    selectedItems.add(item);
    notifyListeners();
  }

  void deselect(Item item) {
    print('$item deselected.');
    selectedItems.remove(item);
    notifyListeners();
  }

  void selectAll() {
    print('Selected ${items.length - selectedItems.length} items.');
    selectedItems.clear();
    selectedItems.addAll(items);
    notifyListeners();
  }

  void selectNone() {
    print('Deselected ${selectedItems.length} items.');
    selectedItems.clear();
    notifyListeners();
  }
}

Model model = Model();

void main() {
  model.items.addAll(
    List<Item>.generate(100, (int index) {
      return Item('Item ${index + 1}');
    }),
  );
  runApp(const MyApp());
}

/// The top level application class.
///
/// Shortcuts can be defined here, and they will be in effect for the whole app,
/// although different widgets may fulfill them differently.
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String title = 'Shortcuts and Actions Demo';

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: MyApp.title,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Material(
        color: Colors.grey.shade100,
        child: Shortcuts(
          manager: LoggingShortcutManager(),
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.keyA, control: true): SelectAllIntent(),
            SingleActivator(LogicalKeyboardKey.keyS, control: true): SelectNoneIntent(),
            SingleActivator(LogicalKeyboardKey.keyD, control: true): ToggleIndividualSelectIntent(),
            SingleActivator(LogicalKeyboardKey.digit1): ToggleSelectIntent(0),
            SingleActivator(LogicalKeyboardKey.digit2): ToggleSelectIntent(1),
            SingleActivator(LogicalKeyboardKey.digit3): ToggleSelectIntent(2),
            SingleActivator(LogicalKeyboardKey.digit4): ToggleSelectIntent(3),
            SingleActivator(LogicalKeyboardKey.digit5): ToggleSelectIntent(4),
          },
          child: Actions(
            dispatcher: LoggingActionDispatcher(),
            actions: const <Type, Action<Intent>>{},
            child: FocusScope(
              child: Row(
                children: <Widget>[
                  const Expanded(flex: 1, child: MyMenu()),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      /// Adding this ActionsRegistry means that "select all"
                      /// will not be registered above here, so only the other
                      /// grid will be selected by the buttons or the shortcut
                      /// if the focus is on the buttons. If the keyboard focus
                      /// enters the first grid, then select all will apply
                      /// there, AND in the second grid.
                      child: ActionsRegistry(
                        child: MyGrid(
                          label: 'First',
                          items: model.items.getRange(0, model.items.length ~/ 2).toList(),
                        ),
                      ),
                    ),
                  ),
                  const VerticalDivider(),
                  Expanded(
                    flex: 5,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: MyGrid(
                        label: 'Second',
                        items: model.items
                            .getRange(model.items.length ~/ 2, model.items.length)
                            .toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MyGrid extends StatelessWidget {
  const MyGrid({Key? key, required this.label, required this.items}) : super(key: key);

  final String label;
  final List<Item> items;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: Actions(
        registeredActions: <Type, Action<Intent>>{
          SelectAllIntent: SelectAllAction(items),
          SelectNoneIntent: SelectNoneAction(items),
        },
        actions: <Type, Action<Intent>>{
          ToggleSelectIntent: ToggleSelectAction(model),
          ToggleSelectItemIntent: ToggleSelectItemAction(model),
        },
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
          ),
          itemCount: items.length,
          itemBuilder: (BuildContext context, int index) {
            return ItemBox(
              label: label,
              item: items[index],
            );
          },
        ),
      ),
    );
  }
}

class MyMenu extends StatefulWidget {
  const MyMenu({Key? key}) : super(key: key);

  @override
  State<MyMenu> createState() => _MyMenuState();
}

class _MyMenuState extends State<MyMenu> {
  final FocusNode focusNode = FocusNode(debugLabel: 'Menu Focus');

  @override
  void initState() {
    super.initState();
    focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Tooltip(
            message: 'Control-A',
            child: TextButton(
              focusNode: focusNode,
              child: const Text('SELECT ALL'),
              onPressed: () {
                Actions.invoke<SelectAllIntent>(context, const SelectAllIntent());
              },
            ),
          ),
          Tooltip(
            message: 'Control-S',
            child: TextButton(
              child: const Text('SELECT NONE'),
              onPressed: () {
                Actions.invoke<SelectNoneIntent>(context, const SelectNoneIntent());
              },
            ),
          ),
        ],
      ),
    );
  }
}

class ItemBox extends StatelessWidget {
  const ItemBox({Key? key, required this.item, required this.label}) : super(key: key);

  final String label;
  final Item item;

  @override
  Widget build(BuildContext context) {
    return Actions(
      registeredActions: <Type, Action<Intent>>{
        ToggleIndividualSelectIntent: ToggleIndividualSelectAction(model, item),
      },
      child: AnimatedBuilder(
        animation: model,
        builder: (BuildContext context, Widget? child) {
          return Container(
            margin: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              color: model.selectedItems.contains(item)
                  ? const Color(0x80ff8080)
                  : const Color(0x80ffffff),
            ),
            child: InkWell(
              autofocus: false,
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              highlightColor: Colors.indigo.shade100,
              focusColor: Colors.indigo.shade400,
              hoverColor: Colors.indigo.shade200,
              onTap: () {
                Actions.maybeInvoke(context, ToggleSelectItemIntent(item));
              },
              child: Center(
                child: Text('$label ${item.name}'),
              ),
            ),
          );
        },
      ),
    );
  }
}

class SelectAllIntent extends Intent {
  const SelectAllIntent();
}

class SelectAllAction extends Action<SelectAllIntent> {
  SelectAllAction(this.items);

  final Iterable<Item> items;

  @override
  Object? invoke(covariant SelectAllIntent intent) {
    items.forEach(model.select);
  }
}

class SelectNoneIntent extends Intent {
  const SelectNoneIntent();
}

class SelectNoneAction extends Action<SelectNoneIntent> {
  SelectNoneAction(this.items);

  final Iterable<Item> items;

  @override
  Object? invoke(covariant SelectNoneIntent intent) {
    items.forEach(model.deselect);
  }
}

class SelectIndexIntent extends Intent {
  const SelectIndexIntent(this.index);

  final int index;
}

class SelectIndexAction extends Action<SelectIndexIntent> {
  SelectIndexAction(this.model);

  final Model model;

  @override
  Object? invoke(covariant SelectIndexIntent intent) {
    model.select(model.items[intent.index]);
  }
}

class ToggleIndividualSelectIntent extends Intent {
  const ToggleIndividualSelectIntent();
}

class ToggleIndividualSelectAction extends Action<ToggleIndividualSelectIntent> {
  ToggleIndividualSelectAction(this.model, this.item);

  final Model model;
  final Item item;

  @override
  Object? invoke(covariant ToggleIndividualSelectIntent intent) {
    model.toggleSelect(item);
  }
}

class ToggleSelectItemIntent extends Intent {
  const ToggleSelectItemIntent(this.item);

  final Item item;
}

class ToggleSelectItemAction extends Action<ToggleSelectItemIntent> {
  ToggleSelectItemAction(this.model);

  final Model model;

  @override
  Object? invoke(covariant ToggleSelectItemIntent intent) {
    model.toggleSelect(intent.item);
  }
}

class DeselectIndexIntent extends Intent {
  const DeselectIndexIntent(this.index);

  final int index;
}

class DeselectIndexAction extends Action<DeselectIndexIntent> {
  DeselectIndexAction(this.model);

  final Model model;

  @override
  Object? invoke(covariant DeselectIndexIntent intent) {
    model.deselect(model.items[intent.index]);
  }
}

class ToggleSelectIntent extends Intent {
  const ToggleSelectIntent(this.index);

  final int index;
}

class ToggleSelectAction extends Action<ToggleSelectIntent> {
  ToggleSelectAction(this.model);

  final Model model;

  @override
  Object? invoke(covariant ToggleSelectIntent intent) {
    model.toggleSelect(model.items[intent.index]);
  }
}

/// A ShortcutManager that logs all keys that it handles.
class LoggingShortcutManager extends ShortcutManager {
  @override
  KeyEventResult handleKeypress(BuildContext context, RawKeyEvent event) {
    final KeyEventResult result = super.handleKeypress(context, event);
    if (result == KeyEventResult.handled) {
      print('Handled shortcut $event in $context');
    }
    return result;
  }
}

/// An ActionDispatcher that logs all the actions that it invokes.
class LoggingActionDispatcher extends ActionDispatcher {
  @override
  Object? invokeAction(
    covariant Action<Intent> action,
    covariant Intent intent, [
    BuildContext? context,
  ]) {
    print('Action invoked: $action($intent) from $context');
    super.invokeAction(action, intent, context);
  }
}
