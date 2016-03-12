// Copyright 2016 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class TextStyleItem extends StatelessComponent {
  TextStyleItem({ Key key, this.name, this.style, this.text }) : super(key: key) {
    assert(name != null);
    assert(style != null);
    assert(text != null);
  }

  final String name;
  final TextStyle style;
  final String text;

  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle nameStyle = theme.textTheme.body1.copyWith(color: theme.textTheme.caption.color);
    return new Padding(
      padding: const EdgeDims.symmetric(horizontal: 8.0, vertical: 16.0),
      child: new Row(
        alignItems: FlexAlignItems.start,
        children: <Widget>[
          new SizedBox(
            width: 64.0,
            child: new Text(name, style: nameStyle)
          ),
          new Flexible(
            child: new Text(text, style: style)
          )
        ]
      )
    );
  }
}

class TypographyDemo extends StatelessComponent {
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> styleItems = <Widget>[
      new TextStyleItem(name: 'display3', style: textTheme.display3, text: 'Regular 56sp'),
      new TextStyleItem(name: 'display2', style: textTheme.display2, text: 'Regular 45sp'),
      new TextStyleItem(name: 'display1', style: textTheme.display1, text: 'Regular 34sp'),
      new TextStyleItem(name: 'headline', style: textTheme.headline, text: 'Regular 24sp'),
      new TextStyleItem(name: 'title', style: textTheme.title, text: 'Medium 20sp'),
      new TextStyleItem(name: 'subhead', style: textTheme.subhead, text: 'Regular 16sp'),
      new TextStyleItem(name: 'body2', style: textTheme.body2, text: 'Medium 14sp'),
      new TextStyleItem(name: 'body1', style: textTheme.body1, text: 'Reguluar 14sp'),
      new TextStyleItem(name: 'caption', style: textTheme.caption, text: 'Regular 12sp'),
      new TextStyleItem(name: 'button', style: textTheme.button, text: 'MEDIUM (ALL CAPS) 14sp')
    ];

    if (MediaQuery.of(context).size.width > 500.0) {
      styleItems.insert(0, new TextStyleItem(
        name: 'display4',
        style: textTheme.display4,
        text: 'Light 112sp'
      ));
    }

    return new Scaffold(
      toolBar: new ToolBar(center: new Text('Typography')),
      body: new Block(children: styleItems)
    );
  }
}
