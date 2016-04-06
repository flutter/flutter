// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';

import 'flexible_space_demo.dart';

class _BarGraphic extends StatelessWidget {
  _BarGraphic({ Key key, this.height, this.color, this.leftText, this.rightText: '' })
    : super(key: key) {
    assert(height != null);
    assert(color != null);
    assert(leftText != null);
  }

  final double height;
  final Color color;
  final String leftText;
  final String rightText;

  @override
  Widget build(BuildContext context) {
    return new Container(
      height: height,
      width: 200.0,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: new BoxDecoration(backgroundColor: color),
      child: new DefaultTextStyle(
        style: Theme.of(context).textTheme.body1.copyWith(color: Colors.white),
        child: new Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            new Text(leftText),
            new Text(rightText)
          ]
        )
      )
    );
  }
}

class _StatusBarGraphic extends _BarGraphic {
  _StatusBarGraphic() : super(
    height: 24.0,
    color: Colors.green[400],
    leftText: 'Status Bar',
    rightText: '24dp'
  );
}

class _AppBarGraphic extends _BarGraphic {
  _AppBarGraphic() : super(
    height: 48.0,
    color: Colors.blue[400],
    leftText: 'Tool Bar',
    rightText: '48dp'
  );
}

class _TabBarGraphic extends _BarGraphic {
  _TabBarGraphic() : super(
    height: 48.0,
    color: Colors.purple[400],
    leftText: 'Tab Bar',
    rightText: '56dp'
  );
}

class _FlexibleSpaceGraphic extends _BarGraphic {
  _FlexibleSpaceGraphic() : super(
    height: 128.0,
    color: Colors.pink[400],
    leftText: 'Flexible Space'
  );
}

class _TechniqueItem extends StatelessWidget {
  _TechniqueItem({ this.titleText, this.barGraphics, this.builder });

  final String titleText;
  final List<Widget> barGraphics;
  final WidgetBuilder builder;

  void showDemo(BuildContext context) {
    Navigator.push(context, new MaterialPageRoute<Null>(builder: builder));
  }

  @override
  Widget build(BuildContext context) {
    return new Card(
      child: new InkWell(
        onTap: () { showDemo(context); },
        child: new Padding(
          padding: const EdgeInsets.all(16.0),
          child: new Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children :<Widget>[
              new Text(titleText),
              new Column(children: barGraphics)
            ]
          )
        )
      )
    );
  }
}

const String _introText =
  "An AppBar is a combination of a ToolBar and a TabBar or a flexible space "
  "Widget that is managed by the Scaffold. The Scaffold pads the ToolBar so that "
  "it appears behind the device's status bar. When a flexible space Widget is "
  "specified it is stacked on top of the ToolBar.";

class ScrollingTechniquesDemo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(title: new Text('Scrolling techniques')),
      body: new Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: new Block(
          children: <Widget>[
            new Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 32.0),
              child: new Text(_introText, style: Theme.of(context).textTheme.caption)
            ),
            new _TechniqueItem(
              builder: (BuildContext context) => new FlexibleSpaceDemo(),
              titleText: 'Standard',
              barGraphics: <Widget>[
                new _StatusBarGraphic(),
                new _AppBarGraphic()
              ]
            ),
            new _TechniqueItem(
              titleText: 'Tabs',
              builder: (BuildContext context) => new FlexibleSpaceDemo(),
              barGraphics: <Widget>[
                new _StatusBarGraphic(),
                new _AppBarGraphic(),
                new _TabBarGraphic()
              ]
            ),
            new _TechniqueItem(
              titleText: 'Flexible',
              builder: (BuildContext context) => new FlexibleSpaceDemo(),
              barGraphics: <Widget>[
                new _StatusBarGraphic(),
                new _AppBarGraphic(),
                new _FlexibleSpaceGraphic()
              ]
            )
          ]
        )
      )
    );
  }
}
