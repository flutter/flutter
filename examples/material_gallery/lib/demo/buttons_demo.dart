// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'tabs_fab_demo.dart';
import 'dialog_demo.dart';
import 'snack_bar_demo.dart';

const String _floatingText =
  "A floating action button is a circular material button that lifts "
  "and displays an ink reaction on press. It turns and fades in when "
  "it changes.";

const String _raisedText =
  "A raised button is typically a rectangular material button that lifts "
  "and displays ink reactions on press. Raised buttons add dimension to "
  "mostly flat layouts. They emphasize functions on busy or wide spaces.";

const String _flatText =
  "A flat button is made of ink that displays ink reactions on press "
  "but does not lift. Use flat buttons on toolbars, in dialogs and "
  "inline with padding";

const String _dropdownText =
  "A dropdown button selects between multiple selections. The button "
  "displays the current state and a down arrow.";

class _ButtonDemo {
  _ButtonDemo({ this.title, this.text, this.builder }) {
    assert(title != null);
    assert(text != null);
    assert(builder != null);
  }

  final String title;
  final String text;
  final WidgetBuilder builder;

  TabLabel get tabLabel => new TabLabel(text: title.toUpperCase());

  // The TabBarSelection created below saves and restores _ButtonDemo objects
  // to recover this demo's selected tab. To enable it to compare restored
  // _ButtonDemo objects with new ones, define hashCode and operator== .

  @override
  bool operator==(Object other) {
    if (other.runtimeType != runtimeType)
      return false;
    _ButtonDemo typedOther = other;
    return typedOther.title == title && typedOther.text == text;
  }

  @override
  int get hashCode => hashValues(title.hashCode, text.hashCode);
}

class ButtonsDemo extends StatefulWidget {
  @override
  _ButtonsDemoState createState() => new _ButtonsDemoState();
}

class _ButtonsDemoState extends State<ButtonsDemo> {
  List<_ButtonDemo> _demos;

  @override
  void initState() {
    super.initState();
    _demos = <_ButtonDemo>[
      new _ButtonDemo(title: 'FLOATING', text: _floatingText, builder: buildFloatingButton),
      new _ButtonDemo(title: 'RAISED', text: _raisedText, builder: buildRaisedButton),
      new _ButtonDemo(title: 'FLAT', text: _flatText, builder: buildFlatButton),
      new _ButtonDemo(title: 'DROPDOWN', text: _dropdownText, builder: buildDropdownButton)
    ];
  }

  Widget buildFloatingButton(BuildContext context) {
    return new SizedBox(
      height: 128.0,
      child: new Center(
        child: new FloatingActionButton(
          tooltip: 'Open FAB demos',
          child: new Icon(icon: Icons.add),
          onPressed: () {
            Navigator.push(context, new MaterialPageRoute<Null>(
              builder: (BuildContext context) => new TabsFabDemo()
            ));
          }
        )
      )
    );
  }

  Widget buildRaisedButton(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: new Column(
        children: <Widget>[
          new RaisedButton(
            child: new Text('LAUNCH DEMO'),
            onPressed: () {
              Navigator.push(context, new MaterialPageRoute<Null>(
                builder: (BuildContext context) => new SnackBarDemo()
              ));
            }
          ),
          new RaisedButton(
            child: new Text('DISABLED')
          )
        ]
        .map((Widget child) {
          return new Container(
            margin: const EdgeInsets.symmetric(vertical: 8.0),
            child: child
          );
        })
        .toList()
      )
    );
  }

  Widget buildFlatButton(BuildContext context) {
    return new Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0),
      child: new ButtonTheme(
        color: ButtonColor.accent,
        child: new Column(
          children: <Widget>[
            new FlatButton(
              child: new Text('LAUNCH DEMO'),
              onPressed: () {
                Navigator.push(context, new MaterialPageRoute<Null>(
                  builder: (_) => new DialogDemo()
                ));
              }
            ),
            new FlatButton(
              child: new Text('DISABLED')
            )
          ]
          .map((Widget child) {
            return new Container(
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              child: child
            );
          })
          .toList()
        )
      )
    );
  }

  String dropdownValue = "Free";

  Widget buildDropdownButton(BuildContext context) {
    return new SizedBox(
      height: 256.0,
      child: new Center(
        child: new DropDownButton<String>(
          value: dropdownValue,
          onChanged: (String newValue) {
            setState(() {
              if (newValue != null)
                dropdownValue = newValue;
            });
          },
          items: <String>["One", "Two", "Free", "Four"]
            .map((String value) {
              return new DropDownMenuItem<String>(
                value: value,
                child: new Text(value));
            })
            .toList()
        )
      )
    );
  }

  Widget buildTabView(_ButtonDemo demo) {
    return new Builder(
      builder: (BuildContext context) {
        final TextStyle textStyle = Theme.of(context).textTheme.caption.copyWith(fontSize: 16.0);
        return new Block(
          children: <Widget>[
            demo.builder(context),
            new Padding(
              padding: const EdgeInsets.fromLTRB(32.0, 0.0, 32.0, 24.0),
              child: new Text(demo.text, style: textStyle)
            )
          ]
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return new TabBarSelection<_ButtonDemo>(
      values: _demos,
      child: new Scaffold(
        appBar: new AppBar(
          title: new Text('Buttons'),
          tabBar: new TabBar<_ButtonDemo>(
            isScrollable: true,
            labels: new Map<_ButtonDemo, TabLabel>.fromIterable(_demos, value: (_ButtonDemo demo) => demo.tabLabel)
          )
        ),
        body: new TabBarView<_ButtonDemo>(
          children: _demos.map(buildTabView).toList()
        )
      )
    );
  }
}
