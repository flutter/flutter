// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../gallery/demo.dart';

const String _raisedText =
  "# Raised buttons\n"
  "Raised buttons add dimension to mostly flat layouts. They emphasize "
  "functions on busy or wide spaces.";

const String _raisedCode =
"""// Create a raised button.
new RaisedButton(
  child: new Text('BUTTON TITLE'),
  onPressed: () {
    // Perform some action
  }
);

// Create a disabled button.
// Buttons are disabled when onPressed isn't
// specified or is null.
new RaisedButton(
  child: new Text('BUTTON TITLE')
);""";

const String _flatText =
  "# Flat buttons\n"
  "A flat button displays an ink splash on press "
  "but does not lift. Use flat buttons on toolbars, in dialogs and "
  "inline with padding";

const String _flatCode =
"""// Create a flat button.
new FlatButton(
  child: new Text('BUTTON TITLE'),
  onPressed: () {
    // Perform some action
  }
);

// Create a disabled button.
// Buttons are disabled when onPressed isn't
// specified or is null.
new FlatButton(
  child: new Text('BUTTON TITLE')
);""";

const String _dropdownText =
  "# Dropdown buttons\n"
  "A dropdown button displays a menu that's used to select a value from a "
  "small set of values. The button displays the current value and a down "
  "arrow.";

const String _dropdownCode =
"""// Member variable holding value.
String dropdownValue

// Drop down button with string values.
new DropDownButton<String>(
  value: dropdownValue,
  onChanged: (String newValue) {
    // null indicates the user didn't select a
    // new value.
    setState(() {
      if (newValue != null)
        dropdownValue = newValue;
    });
  },
  items: <String>['One', 'Two', 'Free', 'Four']
    .map((String value) {
      return new DropDownMenuItem<String>(
        value: value,
        child: new Text(value));
    })
    .toList()
)""";

const String _iconText =
  "IconButtons are appropriate for toggle buttons that allow a single choice to be "
  "selected or deselected, such as adding or removing an item's star.";

const String _iconCode =
"""// Member variable holding toggle value.
bool value;

// Toggleable icon button.
new IconButton(
  icon: Icons.thumb_up,
  onPressed: () {
    setState(() => value = !value);
  },
  color: value ? Theme.of(context).primaryColor : null
)""";

const String _actionText =
  "# Floating action buttons\n"
  "Floating action buttons are used for a promoted action. They are "
  "distinguished by a circled icon floating above the UI and can have motion "
  "behaviors that include morphing, launching, and a transferring anchor "
  "point.";

const String _actionCode =
"""// Floating action button in Scaffold.
new Scaffold(
  appBar: new AppBar(
    title: new Text('Demo')
  ),
  floatingActionButton: new FloatingActionButton(
    child: new Icon(icon: Icons.add)
  )
);""";

class ButtonsDemo extends StatefulWidget {
  @override
  _ButtonsDemoState createState() => new _ButtonsDemoState();
}

class _ButtonsDemoState extends State<ButtonsDemo> {
  @override
  Widget build(BuildContext context) {
    List<ComponentDemoTabData> demos = <ComponentDemoTabData>[
      new ComponentDemoTabData(
        tabName: 'RAISED',
        description: _raisedText,
        widget: buildRaisedButton(),
        exampleCode: _raisedCode
      ),
      new ComponentDemoTabData(
        tabName: 'FLAT',
        description: _flatText,
        widget: buildFlatButton(),
        exampleCode: _flatCode
      ),
      new ComponentDemoTabData(
        tabName: 'DROPDOWN',
        description: _dropdownText,
        widget: buildDropdownButton(),
        exampleCode:
        _dropdownCode
      ),
      new ComponentDemoTabData(
        tabName: 'ICON',
        description: _iconText,
        widget: buildIconButton(),
        exampleCode: _iconCode
      ),
      new ComponentDemoTabData(
        tabName: 'ACTION',
        description: _actionText,
        widget: buildActionButton(),
        exampleCode: _actionCode
      ),
    ];

    return new TabbedComponentDemoScaffold(
      title: 'Buttons',
      demos: demos
    );
  }

  Widget buildRaisedButton() {
    return new Align(
      alignment: new FractionalOffset(0.5, 0.4),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.collapse,
        children: <Widget>[
          new RaisedButton(
            child: new Text('RAISED BUTTON'),
            onPressed: () {
              // Perform some action
            }
          ),
          new RaisedButton(
            child: new Text('DISABLED')
          )
        ]
      )
    );
  }

  Widget buildFlatButton() {
    return new Align(
      alignment: new FractionalOffset(0.5, 0.4),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.collapse,
        children: <Widget>[
          new FlatButton(
            child: new Text('FLAT BUTTON'),
            onPressed: () {
              // Perform some action
            }
          ),
          new FlatButton(
            child: new Text('DISABLED')
          )
        ]
      )
    );
  }

  String dropdownValue = 'Free';

  Widget buildDropdownButton() {
    return new Align(
      alignment: new FractionalOffset(0.5, 0.4),
      child: new DropDownButton<String>(
        value: dropdownValue,
        onChanged: (String newValue) {
          setState(() {
            if (newValue != null)
              dropdownValue = newValue;
          });
        },
        items: <String>['One', 'Two', 'Free', 'Four']
          .map((String value) {
            return new DropDownMenuItem<String>(
              value: value,
              child: new Text(value));
          })
          .toList()
      )
    );
  }

  bool iconButtonToggle = false;

  Widget buildIconButton() {
    return new Align(
      alignment: new FractionalOffset(0.5, 0.4),
      child: new Row(
        mainAxisAlignment: MainAxisAlignment.collapse,
        children: <Widget>[
          new IconButton(
            icon: Icons.thumb_up,
            onPressed: () {
              setState(() => iconButtonToggle = !iconButtonToggle);
            },
            color: iconButtonToggle ? Theme.of(context).primaryColor : null
          ),
          new IconButton(
            icon: Icons.thumb_up
          )
        ]
      )
    );
  }

  Widget buildActionButton() {
    return new Align(
      alignment: new FractionalOffset(0.5, 0.4),
      child: new FloatingActionButton(
        child: new Icon(icon: Icons.add),
        onPressed: () {
          // Perform some action
        }
      )
    );
  }
}
