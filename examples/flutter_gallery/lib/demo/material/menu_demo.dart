// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class MenuDemo extends StatefulWidget {
  const MenuDemo({ Key key }) : super(key: key);

  static const String routeName = '/material/menu';

  @override
  MenuDemoState createState() => new MenuDemoState();
}

class MenuDemoState extends State<MenuDemo> {
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();

  final String _simpleValue1 = 'Menu item value one';
  final String _simpleValue2 = 'Menu item value two';
  final String _simpleValue3 = 'Menu item value three';
  String _simpleValue;

  final String _checkedValue1 = 'One';
  final String _checkedValue2 = 'Two';
  final String _checkedValue3 = 'Free';
  final String _checkedValue4 = 'Four';
  List<String> _checkedValues;

  @override
  void initState() {
    super.initState();
    _simpleValue = _simpleValue2;
    _checkedValues = <String>[_checkedValue3];
  }

  void showInSnackBar(String value) {
    _scaffoldKey.currentState.showSnackBar(new SnackBar(
     content: new Text(value)
    ));
  }

  void showMenuSelection(String value) {
    if (<String>[_simpleValue1, _simpleValue2, _simpleValue3].contains(value))
      _simpleValue = value;
    showInSnackBar('You selected: $value');
  }

  void showCheckedMenuSelections(String value) {
    if (_checkedValues.contains(value))
      _checkedValues.remove(value);
    else
      _checkedValues.add(value);

    showInSnackBar('Checked $_checkedValues');
  }

  bool isChecked(String value) => _checkedValues.contains(value);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: _scaffoldKey,
      appBar: new AppBar(
        title: const Text('Menus'),
        actions: <Widget>[
          new PopupMenuButton<String>(
            onSelected: showMenuSelection,
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              const PopupMenuItem<String>(
                value: 'Toolbar menu',
                child: const Text('Toolbar menu')
              ),
              const PopupMenuItem<String>(
                value: 'Right here',
                child: const Text('Right here')
              ),
              const PopupMenuItem<String>(
                value: 'Hooray!',
                child: const Text('Hooray!')
              ),
            ],
          ),
        ],
      ),
      body: new ListView(
        padding: kMaterialListPadding,
        children: <Widget>[
          // Pressing the PopupMenuButton on the right of this item shows
          // a simple menu with one disabled item. Typically the contents
          // of this "contextual menu" would reflect the app's state.
          new ListTile(
            title: const Text('An item with a context menu button'),
            trailing: new PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: showMenuSelection,
              itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                new PopupMenuItem<String>(
                  value: _simpleValue1,
                  child: const Text('Context menu item one')
                ),
                const PopupMenuItem<String>(
                  enabled: false,
                  child: const Text('A disabled menu item')
                ),
                new PopupMenuItem<String>(
                  value: _simpleValue3,
                  child: const Text('Context menu item three')
                ),
              ]
            )
          ),
          // Pressing the PopupMenuButton on the right of this item shows
          // a menu whose items have text labels and icons and a divider
          // That separates the first three items from the last one.
          new ListTile(
            title: const Text('An item with a sectioned menu'),
            trailing: new PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: showMenuSelection,
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'Preview',
                  child: const ListTile(
                    leading: const Icon(Icons.visibility),
                    title: const Text('Preview')
                  )
                ),
                const PopupMenuItem<String>(
                  value: 'Share',
                  child: const ListTile(
                    leading: const Icon(Icons.person_add),
                    title: const Text('Share')
                  )
                ),
                const PopupMenuItem<String>(
                  value: 'Get Link',
                  child: const ListTile(
                    leading: const Icon(Icons.link),
                    title: const Text('Get link')
                  )
                ),
                const PopupMenuDivider(), // ignore: list_element_type_not_assignable, https://github.com/flutter/flutter/issues/5771
                const PopupMenuItem<String>(
                  value: 'Remove',
                  child: const ListTile(
                    leading: const Icon(Icons.delete),
                    title: const Text('Remove')
                  )
                )
              ]
            )
          ),
          // This entire list item is a PopupMenuButton. Tapping anywhere shows
          // a menu whose current value is highlighted and aligned over the
          // list item's center line.
          new PopupMenuButton<String>(
            padding: EdgeInsets.zero,
            initialValue: _simpleValue,
            onSelected: showMenuSelection,
            child: new ListTile(
              title: const Text('An item with a simple menu'),
              subtitle: new Text(_simpleValue)
            ),
            itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
              new PopupMenuItem<String>(
                value: _simpleValue1,
                child: new Text(_simpleValue1)
              ),
              new PopupMenuItem<String>(
                value: _simpleValue2,
                child: new Text(_simpleValue2)
              ),
              new PopupMenuItem<String>(
                value: _simpleValue3,
                child: new Text(_simpleValue3)
              )
            ]
          ),
          // Pressing the PopupMenuButton on the right of this item shows a menu
          // whose items have checked icons that reflect this app's state.
          new ListTile(
            title: const Text('An item with a checklist menu'),
            trailing: new PopupMenuButton<String>(
              padding: EdgeInsets.zero,
              onSelected: showCheckedMenuSelections,
              itemBuilder: (BuildContext context) => <PopupMenuItem<String>>[
                new CheckedPopupMenuItem<String>(
                  value: _checkedValue1,
                  checked: isChecked(_checkedValue1),
                  child: new Text(_checkedValue1)
                ),
                new CheckedPopupMenuItem<String>(
                  value: _checkedValue2,
                  enabled: false,
                  checked: isChecked(_checkedValue2),
                  child: new Text(_checkedValue2)
                ),
                new CheckedPopupMenuItem<String>(
                  value: _checkedValue3,
                  checked: isChecked(_checkedValue3),
                  child: new Text(_checkedValue3)
                ),
                new CheckedPopupMenuItem<String>(
                  value: _checkedValue4,
                  checked: isChecked(_checkedValue4),
                  child: new Text(_checkedValue4)
                )
              ]
            )
          )
        ]
      )
    );
  }
}
