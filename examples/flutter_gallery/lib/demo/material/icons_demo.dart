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
  double iconOpacity = 1.0;

  Color get iconColor => iconColors[iconColorIndex];

  void handleIconButtonPress() {
    setState(() {
      iconColorIndex = (iconColorIndex + 1) % iconColors.length;
    });
  }

  Widget buildIconButton(double iconSize, IconData icon, bool enabled) {
    return new IconButton(
      icon: new Icon(icon),
      iconSize: iconSize,
      color: iconColor,
      tooltip: "${enabled ? 'Enabled' : 'Disabled'} icon button",
      onPressed: enabled ? handleIconButtonPress : null
    );
  }

  Widget buildSizeLabel(int size, TextStyle style) {
    return new SizedBox(
      height: size.toDouble() + 16.0, // to match an IconButton's padded height
      child: new Center(
        child: new Text('$size', style: style)
      )
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle textStyle = theme.textTheme.subhead.copyWith(color: theme.textTheme.caption.color);

    return new Scaffold(
      appBar: new AppBar(
        title: const Text('Icons')
      ),
      body: new IconTheme(
        data: new IconThemeData(opacity: iconOpacity),
        child: new Padding(
          padding: const EdgeInsets.all(24.0),
          child: new Column(
            children: <Widget>[
              new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  new Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      new Text('Size', style: textStyle),
                      buildSizeLabel(18, textStyle),
                      buildSizeLabel(24, textStyle),
                      buildSizeLabel(36, textStyle),
                      buildSizeLabel(48, textStyle),
                    ],
                  ),
                  new Expanded(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Text('Enabled', style: textStyle),
                        buildIconButton(18.0, Icons.face, true),
                        buildIconButton(24.0, Icons.alarm, true),
                        buildIconButton(36.0, Icons.home, true),
                        buildIconButton(48.0, Icons.android, true),
                      ],
                    )
                  ),
                  new Expanded(
                    child: new Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: <Widget>[
                        new Text('Disabled', style: textStyle),
                        buildIconButton(18.0, Icons.face, false),
                        buildIconButton(24.0, Icons.alarm, false),
                        buildIconButton(36.0, Icons.home, false),
                        buildIconButton(48.0, Icons.android, false),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
