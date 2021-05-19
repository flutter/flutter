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
      return Item('Item $index');
    }),
  );
  runApp(const MyApp());
}

/// The top level application class.
///
/// Shortcuts can be defined here, and they will be in effect for the whole app,
/// although different widgets may fulfill them differently.
class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  static const String title = 'Shortcuts and Actions Demo';

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ActionRegistry registry = ActionRegistry();

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
            SingleActivator(LogicalKeyboardKey.digit0): ToggleSelectIntent(0),
            SingleActivator(LogicalKeyboardKey.digit1): ToggleSelectIntent(1),
            SingleActivator(LogicalKeyboardKey.digit2): ToggleSelectIntent(2),
            SingleActivator(LogicalKeyboardKey.digit3): ToggleSelectIntent(3),
            SingleActivator(LogicalKeyboardKey.digit4): ToggleSelectIntent(4),
          },
          child: Actions(
            actions: const <Type, Action<Intent>>{},
            registry: registry,
            child: FocusScope(
              child: Row(
                children: const <Widget>[
                  Expanded(flex: 1, child: MyMenu()),
                  Expanded(flex: 5, child: MyGrid()),
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
  const MyGrid({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      child: RegisteredActions(
        dispatcher: LoggingActionDispatcher(),
        actions: <Type, Action<Intent>>{
          SelectAllIntent: SelectAllAction(model),
          SelectNoneIntent: SelectNoneAction(model),
        },
        child: Actions(
          actions: <Type, Action<Intent>>{
            ToggleSelectIntent: ToggleSelectAction(model),
            ToggleSelectItemIntent: ToggleSelectItemAction(model),
          },
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 200,
            ),
            itemCount: 300,
            itemBuilder: (BuildContext context, int index) {
              return ItemBox(
                item: model.items[index],
              );
            },
          ),
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
    return FocusTraversalGroup(
      child: Container(
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
      ),
    );
  }
}

class ItemBox extends StatelessWidget {
  const ItemBox({Key? key, required this.item}) : super(key: key);

  final Item item;

  @override
  Widget build(BuildContext context) {
    return RegisteredActions(
      actions: <Type, Action<Intent>>{
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
              borderRadius: const BorderRadius.all(Radius.circular(10)),
              highlightColor: Colors.indigo.shade100,
              focusColor: Colors.indigo.shade400,
              hoverColor: Colors.indigo.shade200,
              onTap: () {
                Actions.maybeInvoke(context, ToggleSelectItemIntent(item));
              },
              child: Center(
                child: Text(item.name),
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
  SelectAllAction(this.model);

  final Model model;

  @override
  Object? invoke(covariant SelectAllIntent intent) {
    model.selectAll();
  }
}

class SelectNoneIntent extends Intent {
  const SelectNoneIntent();
}

class SelectNoneAction extends Action<SelectNoneIntent> {
  SelectNoneAction(this.model);

  final Model model;

  @override
  Object? invoke(covariant SelectNoneIntent intent) {
    model.selectNone();
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