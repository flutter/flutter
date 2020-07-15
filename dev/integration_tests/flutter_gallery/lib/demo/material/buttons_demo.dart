// Copyright 2014 The Flutter Authors. All rights reserved.
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
    "A dropdown button displays a menu that's used to select a value from a "
    'small set of values. The button displays the current value and a down '
    'arrow.';

const String _dropdownCode = 'buttons_dropdown';

const String _iconText =
    'IconButtons are appropriate for toggle buttons that allow a single choice '
    "to be selected or deselected, such as adding or removing an item's star.";

const String _iconCode = 'buttons_icon';

const String _actionText =
    'Floating action buttons are used for a promoted action. They are '
    'distinguished by a circled icon floating above the UI and can have motion '
    'behaviors that include morphing, launching, and a transferring anchor '
    'point.';

const String _actionCode = 'buttons_action';

class ButtonsDemo extends StatefulWidget {
  static const String routeName = '/material/buttons';

  @override
  _ButtonsDemoState createState() => _ButtonsDemoState();
}

class _ButtonsDemoState extends State<ButtonsDemo> {
  ShapeBorder _buttonShape;

  @override
  Widget build(BuildContext context) {
    final ButtonThemeData buttonTheme = ButtonTheme.of(context).copyWith(
      shape: _buttonShape
    );

    final List<ComponentDemoTabData> demos = <ComponentDemoTabData>[
      ComponentDemoTabData(
        tabName: 'RAISED',
        description: _raisedText,
        demoWidget: ButtonTheme.fromButtonThemeData(
          data: buttonTheme,
          child: buildRaisedButton(),
        ),
        exampleCodeTag: _raisedCode,
        documentationUrl: 'https://docs.flutter.io/flutter/material/RaisedButton-class.html',
      ),
      ComponentDemoTabData(
        tabName: 'FLAT',
        description: _flatText,
        demoWidget: ButtonTheme.fromButtonThemeData(
          data: buttonTheme,
          child: buildFlatButton(),
        ),
        exampleCodeTag: _flatCode,
        documentationUrl: 'https://docs.flutter.io/flutter/material/FlatButton-class.html',
      ),
      ComponentDemoTabData(
        tabName: 'OUTLINE',
        description: _outlineText,
        demoWidget: ButtonTheme.fromButtonThemeData(
          data: buttonTheme,
          child: buildOutlineButton(),
        ),
        exampleCodeTag: _outlineCode,
        documentationUrl: 'https://docs.flutter.io/flutter/material/OutlineButton-class.html',
      ),
      ComponentDemoTabData(
        tabName: 'DROPDOWN',
        description: _dropdownText,
        demoWidget: buildDropdownButton(),
        exampleCodeTag: _dropdownCode,
        documentationUrl: 'https://docs.flutter.io/flutter/material/DropdownButton-class.html',
      ),
      ComponentDemoTabData(
        tabName: 'ICON',
        description: _iconText,
        demoWidget: buildIconButton(),
        exampleCodeTag: _iconCode,
        documentationUrl: 'https://docs.flutter.io/flutter/material/IconButton-class.html',
      ),
      ComponentDemoTabData(
        tabName: 'ACTION',
        description: _actionText,
        demoWidget: buildActionButton(),
        exampleCodeTag: _actionCode,
        documentationUrl: 'https://docs.flutter.io/flutter/material/FloatingActionButton-class.html',
      ),
    ];

    return TabbedComponentDemoScaffold(
      title: 'Buttons',
      demos: demos,
      actions: <Widget>[
        IconButton(
          icon: const Icon(Icons.sentiment_very_satisfied, semanticLabel: 'Update shape'),
          onPressed: () {
            setState(() {
              _buttonShape = _buttonShape == null ? const StadiumBorder() : null;
            });
          },
        ),
      ],
    );
  }

  Widget buildRaisedButton() {
    return Align(
      alignment: const Alignment(0.0, -0.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RaisedButton(
                child: const Text('RAISED BUTTON', semanticsLabel: 'RAISED BUTTON 1'),
                onPressed: () {
                  // Perform some action
                },
              ),
              const RaisedButton(
                child: Text('DISABLED', semanticsLabel: 'DISABLED BUTTON 1'),
                onPressed: null,
              ),
            ],
          ),
          ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              RaisedButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('RAISED BUTTON', semanticsLabel: 'RAISED BUTTON 2'),
                onPressed: () {
                  // Perform some action
                },
              ),
              RaisedButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('DISABLED', semanticsLabel: 'DISABLED BUTTON 2'),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFlatButton() {
    return Align(
      alignment: const Alignment(0.0, -0.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FlatButton(
                child: const Text('FLAT BUTTON', semanticsLabel: 'FLAT BUTTON 1'),
                onPressed: () {
                  // Perform some action
                },
              ),
              const FlatButton(
                child: Text('DISABLED', semanticsLabel: 'DISABLED BUTTON 3',),
                onPressed: null,
              ),
            ],
          ),
          ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FlatButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18.0),
                label: const Text('FLAT BUTTON', semanticsLabel: 'FLAT BUTTON 2'),
                onPressed: () {
                  // Perform some action
                },
              ),
              FlatButton.icon(
                icon: const Icon(Icons.add_circle_outline, size: 18.0),
                label: const Text('DISABLED', semanticsLabel: 'DISABLED BUTTON 4'),
                onPressed: null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildOutlineButton() {
    return Align(
      alignment: const Alignment(0.0, -0.2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlineButton(
                child: const Text('OUTLINE BUTTON', semanticsLabel: 'OUTLINE BUTTON 1'),
                onPressed: () {
                  // Perform some action
                },
              ),
              const OutlineButton(
                child: Text('DISABLED', semanticsLabel: 'DISABLED BUTTON 5'),
                onPressed: null,
              ),
            ],
          ),
          ButtonBar(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OutlineButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('OUTLINE BUTTON', semanticsLabel: 'OUTLINE BUTTON 2'),
                onPressed: () {
                  // Perform some action
                },
              ),
              OutlineButton.icon(
                icon: const Icon(Icons.add, size: 18.0),
                label: const Text('DISABLED', semanticsLabel: 'DISABLED BUTTON 6'),
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
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          ListTile(
            title: const Text('Simple dropdown:'),
            trailing: DropdownButton<String>(
              value: dropdown1Value,
              onChanged: (String newValue) {
                setState(() {
                  dropdown1Value = newValue;
                });
              },
              items: <String>['One', 'Two', 'Free', 'Four'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(
            height: 24.0,
          ),
          ListTile(
            title: const Text('Dropdown with a hint:'),
            trailing: DropdownButton<String>(
              value: dropdown2Value,
              hint: const Text('Choose'),
              onChanged: (String newValue) {
                setState(() {
                  dropdown2Value = newValue;
                });
              },
              items: <String>['One', 'Two', 'Free', 'Four'].map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
            ),
          ),
          const SizedBox(
            height: 24.0,
          ),
          ListTile(
            title: const Text('Scrollable dropdown:'),
            trailing: DropdownButton<String>(
              value: dropdown3Value,
              onChanged: (String newValue) {
                setState(() {
                  dropdown3Value = newValue;
                });
              },
              items: <String>[
                  'One', 'Two', 'Free', 'Four', 'Can', 'I', 'Have', 'A', 'Little',
                  'Bit', 'More', 'Five', 'Six', 'Seven', 'Eight', 'Nine', 'Ten',
                 ]
                .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
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
    return Align(
      alignment: const Alignment(0.0, -0.2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          IconButton(
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
            icon: Icon(
              Icons.thumb_up,
              semanticLabel: 'Thumbs not up',
            ),
            onPressed: null,
          ),
        ]
        .map<Widget>((Widget button) => SizedBox(width: 64.0, height: 64.0, child: button))
        .toList(),
      ),
    );
  }

  Widget buildActionButton() {
    return Align(
      alignment: const Alignment(0.0, -0.2),
      child: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Perform some action
        },
        tooltip: 'floating action button',
      ),
    );
  }
}
