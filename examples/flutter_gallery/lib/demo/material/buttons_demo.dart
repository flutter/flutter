// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import '../../gallery/demo.dart';

const String _raisedText =
    'Raised buttons add dimension to mostly flat layouts. They emphasize '
    'functions on busy or wide spaces.';

const String _raisedCode = 'buttons_raised';

const String _flatText = 'A flat button displays an ink splash on press '
    'but does not lift. Use flat buttons on toolbars, in dialogs and '
    'inline with padding';

const String _flatCode = 'buttons_flat';

const String _outlineText =
    'Outline buttons become opaque and elevate when pressed. They are often '
    'paired with raised buttons to indicate an alternative, secondary action.';

const String _outlineCode = 'buttons_outline';

const String _dropdownText =
    'A dropdown button displays a menu that\'s used to select a value from a '
    'small set of values. The button displays the current value and a down '
    'arrow.';

const String _dropdownCode = 'buttons_dropdown';

const String _iconText =
    'IconButtons are appropriate for toggle buttons that allow a single choice '
    'to be selected or deselected, such as adding or removing an item\'s star.';

const String _iconCode = 'buttons_icon';

const String _actionText =
    'Floating action buttons are used for a promoted action. They are '
    'distinguished by a circled icon floating above the UI and can have motion '
    'behaviors that include morphing, launching, and a transferring anchor '
    'point.';

const String _actionCode = 'buttons_action';

class ButtonsDemo extends StatefulWidget {
  static const String routeName = '/material//buttons';

  @override
  _ButtonsDemoState createState() => new _ButtonsDemoState();
}

class _ButtonsDemoState extends State<ButtonsDemo> {
  @override
  Widget build(BuildContext context) {
    final List<ComponentDemoTabData> demos = <ComponentDemoTabData>[
      new ComponentDemoTabData(
        tabName: 'RAISED',
        description: _raisedText,
        demoWidget: buildRaisedButton(),
        exampleCodeTag: _raisedCode,
      ),
      new ComponentDemoTabData(
        tabName: 'FLAT',
        description: _flatText,
        demoWidget: buildFlatButton(),
        exampleCodeTag: _flatCode,
      ),
      new ComponentDemoTabData(
        tabName: 'OUTLINE',
        description: _outlineText,
        demoWidget: buildOutlineButton(),
        exampleCodeTag: _outlineCode,
      ),
      new ComponentDemoTabData(
        tabName: 'DROPDOWN',
        description: _dropdownText,
        demoWidget: buildDropdownButton(),
        exampleCodeTag: _dropdownCode,
      ),
      new ComponentDemoTabData(
        tabName: 'ICON',
        description: _iconText,
        demoWidget: buildIconButton(),
        exampleCodeTag: _iconCode,
      ),
      new ComponentDemoTabData(
        tabName: 'ACTION',
        description: _actionText,
        demoWidget: buildActionButton(),
        exampleCodeTag: _actionCode,
      ),
    ];

    return new TabbedComponentDemoScaffold(
      title: 'Buttons',
      demos: demos,
    );
  }

  Widget buildRaisedButton() {
    return new Align(
      alignment: const Alignment(0.0, -0.2),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new RaisedButton(
                child: const Text('RAISED BUTTON'),
                onPressed: () {
                  // Perform some action
                },
              ),
              const RaisedButton(
                child: const Text('DISABLED'),
                onPressed: null,
              ),
            ],
          ),
          new ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new RaisedButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('RAISED BUTTON'),
                onPressed: () {
                  // Perform some action
                },
              ),
              new RaisedButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('DISABLED'),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFlatButton() {
    return new Align(
      alignment: const Alignment(0.0, -0.2),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new FlatButton(
                child: const Text('FLAT BUTTON'),
                onPressed: () {
                  // Perform some action
                },
              ),
              const FlatButton(
                child: const Text('DISABLED'),
                onPressed: null,
              ),
            ],
          ),
          new ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new FlatButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18.0),
                label: const Text('FLAT BUTTON'),
                onPressed: () {
                  // Perform some action
                },
              ),
              new FlatButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18.0),
                label: const Text('DISABLED'),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildOutlineButton() {
    return new Align(
      alignment: const Alignment(0.0, -0.2),
      child: new Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new OutlineButton(
                child: const Text('OUTLINE BUTTON'),
                onPressed: () {
                  // Perform some action
                },
              ),
              const RaisedButton(
                child: const Text('DISABLED'),
                onPressed: null,
              ),
            ],
          ),
          new ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              new OutlineButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('OUTLINE BUTTON'),
                onPressed: () {
                  // Perform some action
                },
              ),
              new OutlineButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('DISABLED'),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  // https://en.wikipedia.org/wiki/Free_Four
  String dropdown1Value = 'Free';
  String dropdown2Value;
  String dropdown3Value = 'Four';

  Widget buildDropdownButton() {
    return new Padding(
      padding: const EdgeInsets.all(24.0),
      child: new Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          new ListTile(
            title: const Text('Simple dropdown:'),
            trailing: new DropdownButton<String>(
              value: dropdown1Value,
              onChanged: (String newValue) {
                setState(() {
                  dropdown1Value = newValue;
                });
              },
              items: <String>['One', 'Two', 'Free', 'Four'].map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(
            height: 24.0,
          ),
          new ListTile(
            title: const Text('Dropdown with a hint:'),
            trailing: new DropdownButton<String>(
              value: dropdown2Value,
              hint: const Text('Choose'),
              onChanged: (String newValue) {
                setState(() {
                  dropdown2Value = newValue;
                });
              },
              items: <String>['One', 'Two', 'Free', 'Four'].map((String value) {
                return new DropdownMenuItem<String>(
                  value: value,
                  child: new Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(
            height: 24.0,
          ),
          new ListTile(
            title: const Text('Scrollable dropdown:'),
            trailing: new DropdownButton<String>(
              value: dropdown3Value,
              onChanged: (String newValue) {
                setState(() {
                  dropdown3Value = newValue;
                });
              },
              items: <String>[
                  'One', 'Two', 'Free', 'Four', 'Can', 'I', 'Have', 'A', 'Little',
                  'Bit', 'More', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten'
                 ]
                .map((String value) {
                  return new DropdownMenuItem<String>(
                    value: value,
                    child: new Text(value),
                  );
                })
                .toList(),
             ),
          ),
        ],
      ),
    );
  }

  bool iconButtonToggle = false;

  Widget buildIconButton() {
    return new Align(
      alignment: const Alignment(0.0, -0.2),
      child: new Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          new IconButton(
            icon: const Icon(
              Icons.thumb_up,
              semanticLabel: 'Thumbs up',
            ),
            onPressed: () {
              setState(() => iconButtonToggle = !iconButtonToggle);
            },
            color: iconButtonToggle ? Theme.of(context).primaryColor : null,
          ),
          const IconButton(
            icon: const Icon(
              Icons.thumb_up,
              semanticLabel: 'Thumbs up',
            ),
            onPressed: null,
          )
        ]
        .map((Widget button) => new SizedBox(width: 64.0, height: 64.0, child: button))
        .toList(),
      ),
    );
  }

  Widget buildActionButton() {
    return new Align(
      alignment: const Alignment(0.0, -0.2),
      child: new FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Perform some action
        },
      ),
    );
  }
}
