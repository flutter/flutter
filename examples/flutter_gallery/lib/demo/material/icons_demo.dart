// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

class IconsDemo extends StatefulWidget {
  static const String routeName = '/material/icons';

  @override
  IconsDemoState createState() => new IconsDemoState();
}

class IconsDemoState extends State<IconsDemo> {
  static final List<MaterialColor> iconColors = <MaterialColor>[
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.deepPurple,
    Colors.indigo,
    Colors.blue,
    Colors.lightBlue,
    Colors.cyan,
    Colors.teal,
    Colors.green,
    Colors.lightGreen,
    Colors.lime,
    Colors.yellow,
    Colors.amber,
    Colors.orange,
    Colors.deepOrange,
    Colors.brown,
    Colors.grey,
    Colors.blueGrey,
  ];

  int iconColorIndex = 8; // teal

  Color get iconColor => iconColors[iconColorIndex];

  void handleIconButtonPress() {
    setState(() {
      iconColorIndex = (iconColorIndex + 1) % iconColors.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Icons')
      ),
      body: new IconTheme(
        data: new IconThemeData(color: iconColor),
        child: new Padding(
          padding: const EdgeInsets.all(24.0),
          child: new SafeArea(
            top: false,
            bottom: false,
            child: new Column(
              children: <Widget>[
                new _IconsDemoCard(handleIconButtonPress),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconsDemoCard extends StatelessWidget {

  const _IconsDemoCard(this.handleIconButtonPress);

  final VoidCallback handleIconButtonPress;

  Widget _buildIconButton(double iconSize, IconData icon, bool enabled) {
    return new IconButton(
      icon: new Icon(icon),
      iconSize: iconSize,
      tooltip: "${enabled ? 'Enabled' : 'Disabled'} icon button",
      onPressed: enabled ? handleIconButtonPress : null
    );
  }

  Widget _centeredText(String label) =>
    new Padding(
      // Match the default padding of IconButton.
      padding: const EdgeInsets.all(8.0),
      child: new Text(label, textAlign: TextAlign.center),
    );

  TableRow _buildIconRow(double size) {
    return new TableRow(
      children: <Widget> [
        _centeredText(size.floor().toString()),
        _buildIconButton(size, Icons.face, true),
        _buildIconButton(size, Icons.face, false),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);
    return new Card(
      child: new DefaultTextStyle(
        style: textStyle,
        child: new Semantics(
          explicitChildNodes: true,
          child: new Table(
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: <TableRow> [
              new TableRow(
                children: <Widget> [
                  _centeredText('Size'),
                  _centeredText('Enabled'),
                  _centeredText('Disabled'),
                ]
              ),
              _buildIconRow(18.0),
              _buildIconRow(24.0),
              _buildIconRow(36.0),
              _buildIconRow(48.0),
            ],
          ),
        ),
      ),
    );
  }
}
